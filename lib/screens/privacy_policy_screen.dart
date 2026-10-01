import 'package:flutter/material.dart';

import '../widgets/gallery_widgets.dart' show openExternalLink;

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = 'October 1, 2026';
  static const _contactEmail = 'hzstudios.apps@gmail.com';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(
            'Last updated: $_lastUpdated',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const _Section(
            title: 'Overview',
            body:
                'Walltastic is a wallpaper gallery app published by HZ Studios. '
                'It does not require an account and does not collect, store, or '
                'sell any personally identifiable information on our own '
                'servers — we operate no backend of our own.',
          ),
          const _Section(
            title: 'Data stored on your device',
            body:
                'Saved favorites and settings (theme, Wi-Fi-only downloads) are '
                'stored only on your device and never leave it. Wallpapers you '
                'download are saved to your photo gallery at your request. '
                'Uninstalling the app removes all app data.',
          ),
          const _Section(
            title: 'Third-party services',
            body:
                'Pexels — wallpapers are fetched from the Pexels API; your IP '
                'address is visible to Pexels when images load.\n\n'
                'Google AdMob — the app shows ads served by Google. AdMob may '
                'collect your device\'s advertising ID, IP address, and coarse '
                'usage data to serve and measure ads. You can reset or delete '
                'your advertising ID in your device settings.',
          ),
          const _Section(
            title: 'Permissions',
            body:
                'Internet — to fetch wallpapers and serve ads.\n'
                'Photos / media access — only used to save wallpapers you '
                'choose to download.',
          ),
          const _Section(
            title: 'Children',
            body:
                'Walltastic is not directed at children under 13 and does not '
                'knowingly collect personal information from children.',
          ),
          const _Section(
            title: 'Contact',
            body: 'Questions about this policy? Email $_contactEmail.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => openExternalLink(
                  context,
                  'https://www.pexels.com/privacy-policy/',
                ),
                child: const Text('Pexels privacy policy'),
              ),
              OutlinedButton(
                onPressed: () => openExternalLink(
                  context,
                  'https://policies.google.com/privacy',
                ),
                child: const Text('Google privacy policy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
