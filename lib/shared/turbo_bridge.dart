// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:turbo_bridge/turbo_bridge.dart';

void initializeTurboBridge() {
  TurboBridge.start(ensureInitialized: false, config: const BridgeConfig(enableDevTools: true));
}

NavigatorObserver get turboBridgeNavigationObserver => TurboNavigationObserver();

Interceptor get turboBridgeNetworkInterceptor => TurboBridgeDioInterceptor();

TurboBridge? get turboBridge {
  if (kReleaseMode) return null;
  return TurboBridge.instance;
}
