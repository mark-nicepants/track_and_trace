import 'package:equatable/equatable.dart';

class AppEnv(final String name, final String apiBaseUrl, final bool enableLogging) extends Equatable {
  factory AppEnv.fromJson(String name, Map<String, Object?> json) =>
      AppEnv(name, json['apiBaseUrl']! as String, json['enableLogging'] as bool? ?? false);

  static const String fallbackName = 'prod';
  static const List<String> knownNames = ['dev', 'staging', 'prod', 'local'];

  bool get isProd => name == 'prod';

  @override
  List<Object?> get props => [name, apiBaseUrl, enableLogging];
}
