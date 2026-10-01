import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import '../widgets/gallery_widgets.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Text(
                'Make it yours.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'A few preferences for your everyday view.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle(
                icon: Icons.palette_outlined,
                title: 'Appearance',
              ),
              const SizedBox(height: 12),
              Obx(
                () => RadioGroup<ThemeMode>(
                  groupValue: controller.themeMode.value,
                  onChanged: (mode) {
                    if (mode != null) controller.setTheme(mode);
                  },
                  child: _SettingsCard(
                    children: [
                      for (final mode in ThemeMode.values)
                        RadioListTile<ThemeMode>(
                          value: mode,
                          enabled: !controller.isSaving.value,
                          title: Text(switch (mode) {
                            ThemeMode.system => 'System',
                            ThemeMode.light => 'Light',
                            ThemeMode.dark => 'Dark',
                          }),
                          subtitle: mode == ThemeMode.system
                              ? const Text('Follow your device appearance')
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (controller.autoChangeSupported) ...[
                const _SectionTitle(
                  icon: Icons.autorenew_rounded,
                  title: 'Auto wallpaper',
                ),
                const SizedBox(height: 12),
                Obx(
                  () => _SettingsCard(
                    children: [
                      SwitchListTile(
                        title: const Text('Change wallpaper automatically'),
                        subtitle: const Text(
                          'Picks a random wallpaper from your saved '
                          'favorites on a schedule. Needs internet.',
                        ),
                        value: controller.autoChangeEnabled.value,
                        onChanged: controller.isSaving.value
                            ? null
                            : controller.setAutoChangeEnabled,
                      ),
                      if (controller.autoChangeEnabled.value) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.schedule_rounded),
                          title: const Text('Frequency'),
                          trailing: DropdownButton<int>(
                            value: controller.autoChangeHours.value,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(
                                value: 6,
                                child: Text('Every 6 hours'),
                              ),
                              DropdownMenuItem(
                                value: 12,
                                child: Text('Every 12 hours'),
                              ),
                              DropdownMenuItem(value: 24, child: Text('Daily')),
                              DropdownMenuItem(
                                value: 168,
                                child: Text('Weekly'),
                              ),
                            ],
                            onChanged: controller.isSaving.value
                                ? null
                                : (hours) {
                                    if (hours != null) {
                                      controller.setAutoChangeHours(hours);
                                    }
                                  },
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.wallpaper_rounded),
                          title: const Text('Apply to'),
                          trailing: DropdownButton<String>(
                            value: controller.autoChangeTarget.value,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(
                                value: 'home',
                                child: Text('Home screen'),
                              ),
                              DropdownMenuItem(
                                value: 'lock',
                                child: Text('Lock screen'),
                              ),
                              DropdownMenuItem(
                                value: 'both',
                                child: Text('Home and lock'),
                              ),
                            ],
                            onChanged: controller.isSaving.value
                                ? null
                                : (target) {
                                    if (target != null) {
                                      controller.setAutoChangeTarget(target);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
              const _SectionTitle(
                icon: Icons.storage_rounded,
                title: 'Storage',
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  Obx(
                    () => SwitchListTile(
                      title: const Text('Download on Wi-Fi only'),
                      subtitle: const Text(
                        'Block downloads on mobile data. Downloads stop if Wi-Fi '
                        'disconnects; retry when connected. Previews may still use mobile data.',
                      ),
                      value: controller.wifiOnly.value,
                      onChanged: controller.isSaving.value
                          ? null
                          : controller.setWifiOnly,
                    ),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.photo_library_outlined),
                    title: Text('Download location'),
                    subtitle: Text(
                      'Photos / Gallery on this device. Saved favorites are '
                      'bookmarks and do not download images.',
                    ),
                  ),
                ],
              ),
              Obx(
                () => controller.error.value.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            controller.error.value,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle(
                icon: Icons.info_outline_rounded,
                title: 'About',
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/logo/app_logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: const Text('Walltastic'),
                    subtitle: const Text(
                      'Discover photography from Pexels, preview it in full '
                      'detail, and download your next wallpaper.',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Privacy policy'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        Get.to<void>(() => const PrivacyPolicyScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Pexels photo license'),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => openExternalLink(
                      context,
                      'https://www.pexels.com/license/',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Open-source licenses'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Walltastic',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    ],
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    clipBehavior: Clip.antiAlias,
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).colorScheme.outlineVariant
            : Theme.of(context).colorScheme.outline,
      ),
    ),
    child: Column(children: children),
  );
}
