import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
	static const String _localeKey = 'app_locale';

	Locale? _locale;
	Locale? get locale => _locale;

	/// Supported locales
	static const List<Locale> supportedLocales = [
		Locale('en'),
		Locale('ja'),
	];

	LocaleService() {
		_loadLocale();
	}

	Future<void> _loadLocale() async {
		final prefs = await SharedPreferences.getInstance();
		final localeCode = prefs.getString(_localeKey);

		if (localeCode != null) {
			_locale = Locale(localeCode);
		} else {
			_locale = null; // Use system default
		}

		notifyListeners();
	}

	Future<void> setLocale(Locale? locale) async {
		_locale = locale;

		final prefs = await SharedPreferences.getInstance();
		if (locale != null) {
			await prefs.setString(_localeKey, locale.languageCode);
		} else {
			await prefs.remove(_localeKey);
		}

		notifyListeners();
	}

	/// Get the effective locale (user selected or system default)
	Locale getEffectiveLocale(BuildContext context) {
		if (_locale != null) {
			return _locale!;
		}

		// Use system locale if supported, otherwise default to English
		final systemLocale = Localizations.localeOf(context);
		if (supportedLocales.any((l) => l.languageCode == systemLocale.languageCode)) {
			return systemLocale;
		}

		return const Locale('en');
	}
}
