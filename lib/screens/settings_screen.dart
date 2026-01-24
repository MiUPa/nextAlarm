import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
	const SettingsScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;
		final localeService = context.watch<LocaleService>();

		return Scaffold(
			backgroundColor: AppTheme.background,
			appBar: AppBar(
				title: Text(l10n.settings),
				leading: IconButton(
					icon: const Icon(Icons.arrow_back),
					onPressed: () => Navigator.pop(context),
				),
			),
			body: ListView(
				children: [
					_buildSection(
						context,
						l10n.language,
						_LanguageSelector(
							currentLocale: localeService.locale,
							onChanged: (locale) {
								localeService.setLocale(locale);
							},
						),
					),
				],
			),
		);
	}

	Widget _buildSection(BuildContext context, String title, Widget child) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Padding(
					padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
					child: Text(
						title,
						style: Theme.of(context).textTheme.titleSmall?.copyWith(
							color: AppTheme.onSurfaceSecondary,
							letterSpacing: 0.5,
						),
					),
				),
				child,
			],
		);
	}
}

class _LanguageSelector extends StatelessWidget {
	final Locale? currentLocale;
	final ValueChanged<Locale?> onChanged;

	const _LanguageSelector({
		required this.currentLocale,
		required this.onChanged,
	});

	@override
	Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;

		final options = [
			(null, l10n.languageSystem),
			(const Locale('en'), l10n.languageEnglish),
			(const Locale('ja'), l10n.languageJapanese),
		];

		return Column(
			children: options.map((option) {
				final (locale, label) = option;
				final isSelected = currentLocale?.languageCode == locale?.languageCode;

				return ListTile(
					title: Text(
						label,
						style: TextStyle(
							color: AppTheme.onSurface,
							fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
						),
					),
					trailing: isSelected
						? const Icon(Icons.check, color: AppTheme.primary)
						: null,
					onTap: () => onChanged(locale),
				);
			}).toList(),
		);
	}
}
