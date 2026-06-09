import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:app/ui/shared/router/app_router.dart';
import 'package:app/ui/shared/state/app_env_provider.dart';
import 'package:app/ui/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final env = ref.watch(appEnvProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) {
        L10n.init(context);
        return L10n.translate.appTitle;
      },
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final body = child ?? const SizedBox.shrink();
        if (env.isProd) return body;
        return Banner(
          message: env.name.toUpperCase(),
          location: BannerLocation.topEnd,
          color: _bannerColor(env.name),
          child: body,
        );
      },
    );
  }

  Color _bannerColor(String envName) => switch (envName) {
    'dev' => const Color(0xFFD32F2F), // red
    'staging' => const Color(0xFFF57C00), // orange
    'local' => const Color(0xFF6A1B9A), // purple
    _ => const Color(0xFF455A64), // blue-grey
  };
}
