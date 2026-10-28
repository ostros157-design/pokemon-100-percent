import 'package:flutter/material.dart';

import '../services/app_appearance.dart';
import '../services/app_update_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool spoilers = false;
  bool animations = true;
  bool _checkingUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Wygląd aplikacji',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: AppAppearance.darkBackground,
            builder: (context, isDark, _) => SwitchListTile(
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Ciemne tło'),
              subtitle: Text(isDark
                  ? 'Tło jest czarne, tekst zachowuje wybrany kolor.'
                  : 'Tło jest białe, tekst zachowuje wybrany kolor.'),
              value: isDark,
              onChanged: (value) async {
                await AppAppearance.setDarkBackground(value);
              },
            ),
          ),
          const Divider(),
          _ColorChoiceTile(
            title: 'Kolor tekstu',
            subtitle: 'Ustaw kolor tekstów w aplikacji niezależnie od tła.',
            value: AppAppearance.textColor,
            onChanged: AppAppearance.setTextColor,
          ),
          _ColorChoiceTile(
            title: 'Kolor znaczków',
            subtitle: 'Kolor akcentów, znaczników i elementów wyróżnionych.',
            value: AppAppearance.badgeColor,
            onChanged: AppAppearance.setBadgeColor,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('Pozostałe ustawienia',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Pokazuj spoilery'),
            subtitle: const Text(
              'Pozwala wyświetlać informacje o późniejszych wydarzeniach.',
            ),
            value: spoilers,
            onChanged: (value) => setState(() => spoilers = value),
          ),
          SwitchListTile(
            title: const Text('Animacje'),
            value: animations,
            onChanged: (value) => setState(() => animations = value),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('Aktualizacje i powiadomienia',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('Aktualizacje Google Play'),
            subtitle: const Text(
              'Aplikacja sprawdza aktualizacje po uruchomieniu i co 24 godziny. '
              'Aktualizacje w aplikacji działają po instalacji z Google Play.',
            ),
            trailing: _checkingUpdates
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _checkingUpdates
                ? null
                : () async {
                    setState(() => _checkingUpdates = true);
                    try {
                      await AppUpdateService.checkForUpdate(
                        context,
                        showStatusWhenUnavailable: true,
                      );
                    } finally {
                      if (mounted) setState(() => _checkingUpdates = false);
                    }
                  },
          ),
          ListTile(
            leading: Icon(
              NotificationService.isConfigured
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
            ),
            title: const Text('Powiadomienia push'),
            subtitle: Text(
              NotificationService.isConfigured
                  ? 'Powiadomienia są skonfigurowane na tym urządzeniu.'
                  : 'Wymaga konfiguracji Firebase w projekcie. Ta funkcja nie jest jeszcze aktywna.',
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Wersja aplikacji'),
            subtitle: Text('Wersja zostanie pokazana na podstawie metadanych kompilacji.'),
          ),
        ],
      ),
    );
  }
}

class _ColorChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final ValueNotifier<Color> value;
  final Future<void> Function(Color) onChanged;

  const _ColorChoiceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: value,
      builder: (context, selected, _) {
        final matchingColors = AppAppearance.colorOptions.entries
            .where((entry) => entry.value.value == selected.value);
        final selectedName = matchingColors.isEmpty
            ? 'Niestandardowy'
            : matchingColors.first.key;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppAppearance.colorOptions.entries.map((entry) {
                  final isSelected = selected.value == entry.value.value;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: entry.key,
                    child: InkWell(
                      onTap: () => onChanged(entry.value),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: entry.value.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Text(
                'Wybrano: $selectedName',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
