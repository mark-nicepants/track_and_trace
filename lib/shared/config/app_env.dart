import 'package:equatable/equatable.dart';

class AppEnv(
  final String name,
  final String apiBaseUrl,
  final bool enableLogging,
  final String newRelicToken,
  final String apiKey,
) extends Equatable {
  factory AppEnv.fromJson(String name, Map<String, Object?> json) => AppEnv(
    name,
    json['apiBaseUrl']! as String,
    json['enableLogging'] as bool? ?? false,
    json['newRelicToken'] as String? ?? '',
    json['apiKey'] as String? ?? '',
  );

  static const String fallbackName = 'prod';
  static const List<String> knownNames = ['dev', 'staging', 'prod', 'local'];

  bool get isProd => name == 'prod';

  @override
  List<Object?> get props => [name, apiBaseUrl, enableLogging, newRelicToken, apiKey];
}
