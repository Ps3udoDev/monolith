import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/data/settings_repository.dart';
import 'core/theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppTokens.bg,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTokens.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  const settingsRepository = SharedPrefsSettingsRepository();
  final initialSettings = await settingsRepository.load();
  AppTokens.accentHueValue = initialSettings.accentHue;

  runApp(MonolithApp(
    settingsRepository: settingsRepository,
    initialSettings: initialSettings,
  ));
}
