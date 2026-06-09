// Enforces the architecture rules defined in ARCHITECTURE.md:
//   - layer-import direction (data ← domain ← ui, shared imports nothing else)
//   - no `inject<>` and no `package:get_it` import in widgets
//   - raw `GetIt.I` only in the inject helper itself; everything else uses
//     `injector` (re-exported raw instance) or `inject<T>()` (typed lookup)
//   - no aliasing of `L10n.translate` (must be referenced directly)
//
// Run manually: `fvm dart run --enable-experiment=primary-constructors \
//                  tool/check_architecture_violations.dart`
// Invoked from lefthook on pre-commit and pre-push.
//
// Exits 0 when clean, non-zero on any violation.

// ignore_for_file: avoid_print

import 'dart:io';

class LayerRule {
  const LayerRule(this.importerPrefix, this.forbiddenSubstring, this.reason);
  final String importerPrefix;
  final String forbiddenSubstring;
  final String reason;
}

const List<LayerRule> _importRules = [
  LayerRule('lib/data/', 'package:app/domain/', 'data must not depend on domain'),
  LayerRule('lib/data/', 'package:app/ui/', 'data must not depend on ui'),
  LayerRule('lib/domain/', 'package:app/ui/', 'domain must not depend on ui'),
  LayerRule('lib/ui/', 'package:app/data/', 'ui must not depend on data'),
  LayerRule('lib/shared/', 'package:app/data/', 'shared must not depend on data'),
  LayerRule('lib/shared/', 'package:app/domain/', 'shared must not depend on domain'),
  LayerRule('lib/shared/', 'package:app/ui/', 'shared must not depend on ui'),
];

/// `GetIt.I` (raw GetIt singleton access) may only appear in the inject
/// helper itself. Everything else — including bootstrap registration —
/// goes through `injector` (raw GetIt instance, re-exported by the helper)
/// or `inject<T>()` (typed lookup).
const Set<String> _getItAllowList = {'lib/shared/inject.dart'};

final RegExp _widgetExtends = RegExp(r'\bextends\s+(?:Stateless|Stateful|Consumer|HookConsumer|Hook)Widget\b');
final RegExp _rawGetIt = RegExp(r'\bGetIt\.I\b');
final RegExp _l10nAlias = RegExp(r'=\s*L10n\.translate\s*;');

bool _isImportLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('import ') || trimmed.startsWith('import\t');
}

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//');
}

Future<void> main() async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('lib/ directory not found');
    exit(2);
  }

  final violations = <String>[];

  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    final rel = entity.path.replaceAll(r'\', '/');
    final content = await entity.readAsString();
    final lines = content.split('\n');

    for (final rule in _importRules) {
      if (!rel.startsWith(rule.importerPrefix)) continue;
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!_isImportLine(line)) continue;
        if (line.contains(rule.forbiddenSubstring)) {
          violations.add(_format(rel, i + 1, rule.reason, line));
        }
      }
    }

    if (rel.startsWith('lib/ui/') && _widgetExtends.hasMatch(content)) {
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (_isCommentLine(line)) continue;
        if (line.contains('inject<')) {
          violations.add(_format(rel, i + 1, 'widgets must not call inject<>; use a Riverpod provider/notifier', line));
        }
        if (_isImportLine(line) && line.contains('package:get_it')) {
          violations.add(_format(rel, i + 1, 'widgets must not import package:get_it', line));
        }
      }
    }

    if (!_getItAllowList.contains(rel)) {
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (_isCommentLine(line)) continue;
        if (_rawGetIt.hasMatch(line)) {
          violations.add(
            _format(
              rel,
              i + 1,
              'raw GetIt.I is only allowed in ${_getItAllowList.join(", ")}; '
              'use injector (re-exported from lib/shared/inject.dart) for registration, '
              'or inject<T>() for typed lookup',
              line,
            ),
          );
        }
      }
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_l10nAlias.hasMatch(line)) {
        violations.add(
          _format(
            rel,
            i + 1,
            'do not alias L10n.translate; reference L10n.translate.x directly at the call site',
            line,
          ),
        );
      }
    }
  }

  if (violations.isEmpty) {
    print('architecture check: clean');
    return;
  }

  stderr.writeln('architecture check: ${violations.length} violation(s)\n');
  for (final v in violations) {
    stderr.writeln(v);
  }
  exit(1);
}

String _format(String path, int line, String reason, String source) =>
    '  $path:$line  $reason\n      ${source.trim()}\n';
