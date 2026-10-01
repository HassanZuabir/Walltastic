import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'controllers/settings_controller.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class WalltasticApp extends StatelessWidget {
  const WalltasticApp({super.key});

  @override
  Widget build(BuildContext context) => Obx(
    () => GetMaterialApp(
      title: 'Walltastic',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(),
      themeMode: Get.find<SettingsController>().themeMode.value,
      builder: (context, child) {
        final theme = Theme.of(context);
        final dark = theme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: theme.scaffoldBackgroundColor,
                systemNavigationBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
              ),
          child: child!,
        );
      },
      defaultTransition: Transition.fadeIn,
      home: const SplashScreen(),
    ),
  );
}
