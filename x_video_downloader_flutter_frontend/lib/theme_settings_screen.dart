import 'package:flutter/material.dart';
import 'theme_provider.dart';

/// Screen for selecting theme mode (light/dark/system) and accent color.
class ThemeSettingsScreen extends StatelessWidget {
  final ThemeProvider themeProvider;

  const ThemeSettingsScreen({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme mode section
          Text(
            'Theme',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _ThemeModeCard(
            currentMode: themeProvider.mode,
            onModeChanged: themeProvider.setMode,
          ),
          const SizedBox(height: 32),

          // Accent color section
          Text(
            'Accent Color',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _AccentColorGrid(
            currentAccent: themeProvider.accent,
            onAccentChanged: themeProvider.setAccent,
          ),
          const SizedBox(height: 24),

          // Preview card
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _PreviewCard(),
        ],
      ),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onModeChanged;

  const _ThemeModeCard({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: RadioGroup<ThemeMode>(
        groupValue: currentMode,
        onChanged: (v) => onModeChanged(v!),
        child: Column(
          children: [
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              title: const Text('System'),
              subtitle: const Text('Follow device settings'),
              secondary: Icon(Icons.brightness_auto, color: colorScheme.primary),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              title: const Text('Light'),
              secondary: Icon(Icons.light_mode, color: colorScheme.primary),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              title: const Text('Dark'),
              secondary: Icon(Icons.dark_mode, color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentColorGrid extends StatelessWidget {
  final AccentColor currentAccent;
  final ValueChanged<AccentColor> onAccentChanged;

  const _AccentColorGrid({
    required this.currentAccent,
    required this.onAccentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AccentColor.values.map((accent) {
            final isSelected = accent == currentAccent;
            return InkWell(
              onTap: () => onAccentChanged(accent),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.seed,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 3,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accent.seed.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sample Card',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This is how text and controls look with the current theme.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  onPressed: () {},
                  child: const Text('Filled'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('Text'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(label: const Text('Tag')),
                const SizedBox(width: 8),
                Switch(value: true, onChanged: (v) {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
