import 'package:equatable/equatable.dart';

class AppEnv(
  final String name,
  final String apiBaseUrl,
  final bool enableLogging,
  final String apiKey,
  final String crashLogForwardingUrl,
  final String crashLogApiKey,
) extends Equatable {
  factory AppEnv.fromJson(String name, Map<String, Object?> json) => AppEnv(
    name,
    json['apiBaseUrl']! as String,
    json['enableLogging'] as bool? ?? false,
    json['apiKey'] as String? ?? '',
    json['crashLogForwardingUrl'] as String? ?? '',
    json['crashLogApiKey'] as String? ?? '',
  );

  static const String fallbackName = 'prod';
  static const List<String> knownNames = ['dev', 'staging', 'prod', 'local'];

  bool get isProd => name == 'prod';

  @override
  List<Object?> get props => [name, apiBaseUrl, enableLogging, apiKey, crashLogForwardingUrl, crashLogApiKey];
}
