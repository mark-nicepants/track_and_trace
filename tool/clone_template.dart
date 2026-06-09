// Clones this Flutter template into a new sibling project, renaming the
// package + bundle identifiers.
//
// Usage:
//   dart run tool/clone_template.dart \
//     --name my_new_app \
//     --org com.example \
//     [--dest ../my_new_app] \
//     [--no-git] [--no-pub-get]
//
// The script:
//   1. Copies the source tree (skipping .git, .dart_tool, build, env/local.json).
//   2. Replaces 'app' (the template's package name) → '<name>' in pubspec.yaml + every Dart import.
//   3. Updates Android namespace + applicationId + Kotlin package path.
//   4. Updates iOS PRODUCT_BUNDLE_IDENTIFIER.
//   5. Resets env/*.json values to a placeholder.
//   6. Optionally runs `git init` + `flutter pub get` + initial commit.

// ignore_for_file: avoid_print

import 'dart:io';

class _Args {
  _Args({required this.name, required this.org, required this.dest, required this.runGit, required this.runPubGet});
  final String name;
  final String org;
  final Directory dest;
  final bool runGit;
  final bool runPubGet;
}

Future<void> main(List<String> argv) async {
  final args = _parseArgs(argv);
  final src = Directory.current;

  if (args.dest.existsSync()) {
    stderr.writeln('Destination already exists: ${args.dest.path}');
    exit(1);
  }
  args.dest.createSync(recursive: true);

  print('Copying source tree → ${args.dest.path}');
  await _copyTree(src, args.dest);

  print('Renaming identifiers');
  await _renameInFiles(args.dest, args.name, args.org);
  await _renameKotlinPackagePath(args.dest, args.name, args.org);
  await _resetEnvFiles(args.dest);

  if (args.runPubGet) {
    print('Running `fvm flutter pub get`');
    await _run('fvm', ['flutter', 'pub', 'get'], workingDir: args.dest);
  }
  if (args.runGit) {
    print('Initialising git');
    await _run('git', ['init'], workingDir: args.dest);
    await _run('git', ['add', '.'], workingDir: args.dest);
    await _run('git', ['commit', '-m', 'chore: scaffold ${args.name} from template'], workingDir: args.dest);
  }

  print('\nDone. New project at: ${args.dest.path}');
}

_Args _parseArgs(List<String> argv) {
  String? name;
  String? org;
  String? dest;
  var runGit = true;
  var runPubGet = true;
  for (var i = 0; i < argv.length; i++) {
    final a = argv[i];
    switch (a) {
      case '--name':
        name = argv[++i];
      case '--org':
        org = argv[++i];
      case '--dest':
        dest = argv[++i];
      case '--no-git':
        runGit = false;
      case '--no-pub-get':
        runPubGet = false;
      case '-h' || '--help':
        _printUsage();
        exit(0);
      default:
        stderr.writeln('Unknown argument: $a');
        _printUsage();
        exit(1);
    }
  }
  if (name == null || org == null) {
    stderr.writeln('--name and --org are required');
    _printUsage();
    exit(1);
  }
  if (!RegExp(r'^[a-z][a-z0-9_]+$').hasMatch(name)) {
    stderr.writeln('--name must be lower_snake_case');
    exit(1);
  }
  if (!RegExp(r'^[a-z][a-z0-9_]+(\.[a-z][a-z0-9_]+)+$').hasMatch(org)) {
    stderr.writeln('--org must look like com.example or dev.mycompany');
    exit(1);
  }
  final destDir = Directory(dest ?? '../$name');
  return _Args(name: name, org: org, dest: destDir, runGit: runGit, runPubGet: runPubGet);
}

void _printUsage() {
  print(
    'Usage: dart run tool/clone_template.dart --name <app> --org <com.x>'
    ' [--dest <dir>] [--no-git] [--no-pub-get]',
  );
}

const _excludedDirs = {
  '.git',
  '.dart_tool',
  '.idea',
  'build',
  '.flutter-plugins',
  '.flutter-plugins-dependencies',
  'coverage',
};
const _excludedFiles = {'assets/env/local.json'};

Future<void> _copyTree(Directory src, Directory dest) async {
  await for (final entity in src.list(recursive: false, followLinks: false)) {
    final name = entity.path.split(Platform.pathSeparator).last;
    if (_excludedDirs.contains(name)) continue;
    if (entity is Directory) {
      final sub = Directory('${dest.path}/$name');
      sub.createSync(recursive: true);
      await _copyTreeInto(entity, sub);
    } else if (entity is File) {
      if (_excludedFiles.contains(name)) continue;
      File('${dest.path}/$name').writeAsBytesSync(entity.readAsBytesSync());
    }
  }
}

Future<void> _copyTreeInto(Directory from, Directory to) async {
  await for (final entity in from.list(recursive: false, followLinks: false)) {
    final name = entity.path.split(Platform.pathSeparator).last;
    if (_excludedDirs.contains(name)) continue;
    if (entity is Directory) {
      final sub = Directory('${to.path}/$name');
      sub.createSync(recursive: true);
      await _copyTreeInto(entity, sub);
    } else if (entity is File) {
      // Match relative-to-source-root excludes (e.g. "assets/env/local.json").
      final rel = entity.path.replaceAll(r'\', '/');
      final excluded = _excludedFiles.any((f) => rel.endsWith('/$f'));
      if (excluded) continue;
      File('${to.path}/$name').writeAsBytesSync(entity.readAsBytesSync());
    }
  }
}

Future<void> _renameInFiles(Directory dest, String name, String org) async {
  const oldOrg = 'com.datacadabra';
  const iosOldName = 'flutterTemplate';
  final iosNewName = _toLowerCamel(name);

  // The template's Dart package name is `app`. We rename it whole-word only,
  // so `app/` (path), `app.` (qualifier), `package:app/` (imports) all rewrite,
  // but tokens that happen to contain "app" (e.g. `application`) are left alone.
  // Native platform identifiers keep the "track_and_trace" suffix for now;
  // map it explicitly to <name> too.
  final patterns = <(String, String)>[
    ('package:app/', 'package:$name/'),
    ('track_and_trace', name),
    ('$oldOrg.$iosOldName', '$org.$iosNewName'),
    ('$oldOrg.track_and_trace', '$org.$name'),
    (oldOrg, org),
  ];

  final textExtensions = {
    '.dart',
    '.yaml',
    '.yml',
    '.json',
    '.kt',
    '.kts',
    '.gradle',
    '.xml',
    '.plist',
    '.swift',
    '.pbxproj',
    '.xcconfig',
    '.md',
  };

  await for (final entity in dest.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final ext = _extOf(entity.path);
    if (!textExtensions.contains(ext)) continue;
    var content = entity.readAsStringSync();
    var changed = false;
    for (final (from, to) in patterns) {
      if (content.contains(from)) {
        content = content.replaceAll(from, to);
        changed = true;
      }
    }
    if (changed) entity.writeAsStringSync(content);
  }
}

Future<void> _renameKotlinPackagePath(Directory dest, String name, String org) async {
  final oldPath = Directory('${dest.path}/android/app/src/main/kotlin/dev/mooibroek/template/track_and_trace');
  if (!oldPath.existsSync()) return;

  final orgParts = org.split('.');
  final newPath = Directory('${dest.path}/android/app/src/main/kotlin/${orgParts.join('/')}/$name');
  newPath.createSync(recursive: true);

  for (final f in oldPath.listSync()) {
    if (f is File) {
      final n = f.path.split(Platform.pathSeparator).last;
      f.copySync('${newPath.path}/$n');
    }
  }
  // Remove the old kotlin package tree.
  Directory('${dest.path}/android/app/src/main/kotlin/dev').deleteSync(recursive: true);
}

Future<void> _resetEnvFiles(Directory dest) async {
  const placeholder = {
    'dev.json': '{\n  "apiBaseUrl": "https://api.dev.example.com",\n  "enableLogging": true\n}\n',
    'staging.json': '{\n  "apiBaseUrl": "https://api.staging.example.com",\n  "enableLogging": true\n}\n',
    'prod.json': '{\n  "apiBaseUrl": "https://api.example.com",\n  "enableLogging": false\n}\n',
  };
  for (final entry in placeholder.entries) {
    final f = File('${dest.path}/assets/env/${entry.key}');
    if (f.existsSync()) f.writeAsStringSync(entry.value);
  }
}

Future<void> _run(String exec, List<String> args, {required Directory workingDir}) async {
  final r = await Process.run(exec, args, workingDirectory: workingDir.path);
  stdout.write(r.stdout);
  stderr.write(r.stderr);
  if (r.exitCode != 0) {
    throw ProcessException(exec, args, 'exited ${r.exitCode}', r.exitCode);
  }
}

String _extOf(String path) {
  final i = path.lastIndexOf('.');
  return i < 0 ? '' : path.substring(i);
}

String _toLowerCamel(String snake) {
  final parts = snake.split('_');
  return parts.first + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}
