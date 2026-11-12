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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _SettingsSection(
            icon: Icons.palette_outlined,
            title: 'Wygląd aplikacji',
            subtitle: 'Dostosuj tło, tekst i kolory akcentów.',
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: AppAppearance.darkBackground,
                builder: (context, isDark, _) => SwitchListTile(
                  secondary: _SettingsIcon(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: const Text('Ciemne tło'),
                  subtitle: Text(
                    isDark
                        ? 'Włączony ciemny wygląd'
                        : 'Włączony jasny wygląd',
                  ),
                  value: isDark,
                  onChanged: (value) async {
                    await AppAppearance.setDarkBackground(value);
                  },
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ColorChoiceTile(
                icon: Icons.format_color_text,
                title: 'Kolor tekstu',
                subtitle: 'Niezależny od ustawienia tła.',
                value: AppAppearance.textColor,
                onChanged: AppAppearance.setTextColor,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ColorChoiceTile(
                icon: Icons.color_lens_outlined,
                title: 'Kolor znaczków',
                subtitle: 'Kolor akcentów i wyróżnionych elementów.',
                value: AppAppearance.badgeColor,
                onChanged: AppAppearance.setBadgeColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            icon: Icons.tune_rounded,
            title: 'Preferencje',
            subtitle: 'Wybierz sposób wyświetlania treści.',
            children: [
              SwitchListTile(
                secondary: const _SettingsIcon(icon: Icons.visibility_outlined),
                title: const Text('Pokazuj spoilery'),
                subtitle: const Text(
                  'Pozwala wyświetlać informacje o późniejszych wydarzeniach.',
                ),
                value: spoilers,
                onChanged: (value) => setState(() => spoilers = value),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: const _SettingsIcon(icon: Icons.animation),
                title: const Text('Animacje'),
                subtitle: const Text('Włącz lub wyłącz animacje interfejsu.'),
                value: animations,
                onChanged: (value) => setState(() => animations = value),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsSection(
            icon: Icons.cloud_sync_outlined,
            title: 'Aktualizacje i powiadomienia',
            subtitle: 'Zarządzaj aktualizacjami aplikacji.',
            children: [
              ListTile(
                leading: const _SettingsIcon(icon: Icons.system_update_alt),
                title: const Text('Aktualizacje Google Play'),
                subtitle: const Text(
                  'Automatyczne sprawdzanie po uruchomieniu i co 24 godziny. '
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
                            context: context,
                            showStatusWhenUnavailable: true,
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _checkingUpdates = false);
                          }
                        }
                      },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: _SettingsIcon(
                  icon: NotificationService.isConfigured
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                ),
                title: const Text('Powiadomienia push'),
                subtitle: Text(
                  NotificationService.isConfigured
                      ? 'Powiadomienia są skonfigurowane na tym urządzeniu.'
                      : 'Wymaga konfiguracji Firebase w projekcie. '
                          'Ta funkcja nie jest jeszcze aktywna.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: _SettingsIcon(
                icon: Icons.info_outline,
                background: colors.secondaryContainer,
                foreground: colors.onSecondaryContainer,
              ),
              title: const Text('Wersja aplikacji'),
              subtitle: const Text(
                'Nowe wersje będą dostarczane przez prywatny kanał testowy Google Play.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color? background;
  final Color? foreground;

  const _SettingsIcon({
    required this.icon,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: 19,
      backgroundColor: background ?? colors.primaryContainer,
      child: Icon(
        icon,
        size: 20,
        color: foreground ?? colors.onPrimaryContainer,
      ),
    );
  }
}

class _ColorChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueNotifier<Color> value;
  final Future<void> Function(Color) onChanged;

  const _ColorChoiceTile({
    required this.icon,
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SettingsIcon(icon: icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
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
                        width: 40,
                        height: 40,
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
                                size: 19,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Wybrano: $selectedName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
