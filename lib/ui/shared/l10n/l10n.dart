import 'package:app/ui/shared/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

/// Static façade around the generated [AppLocalizations] so widgets can do
/// `L10n.translate.helloUser('Mark')` without passing `BuildContext` around.
///
/// Initialised once from [App.onGenerateTitle] (which always runs with a
/// localised context). Re-runs on locale change because `onGenerateTitle`
/// is invoked again.
class L10n {
  L10n._();

  static late AppLocalizations _instance;

  static AppLocalizations get translate => _instance;

  static String get currentLocale => _instance.localeName;

  static void init(BuildContext context) {
    _instance = AppLocalizations.of(context);
    intl.Intl.defaultLocale = currentLocale;
  }

  static void loadLocale(Locale locale) {
    AppLocalizations.delegate.load(locale).then((r) => _instance = r);
  }

  static List<LocalizationsDelegate<Object?>> get localizationsDelegates => AppLocalizations.localizationsDelegates;

  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;
}
