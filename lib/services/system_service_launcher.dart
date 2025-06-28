

import 'app_launcher.dart';

class SystemServiceLauncher {
  static Future<bool> openCamera() => AppLauncher.openSystemApp('android.media.action.IMAGE_CAPTURE', null);

  static Future<bool> openSettings() => AppLauncher.openSystemApp('android.settings.SETTINGS', null);

  static Future<bool> openBrowser([String? url]) =>
      AppLauncher.openSystemApp(
        'android.intent.action.VIEW',
        {'uri': url ?? ''},
      );

  static Future<bool> openMaps([String? query]) => AppLauncher.openSystemApp(
    'android.intent.action.VIEW',
    {
      'uri': query != null ? 'geo:0,0?q=$query' : 'geo:0,0',
    },
  );

  static Future<bool> openEmail([String? email]) => AppLauncher.openSystemApp(
    'android.intent.action.SENDTO',
    {
      'uri': 'mailto:${email ?? ''}',
    },
  );


  /// Network Settings
  static Future<bool> openWifiSettings() => AppLauncher.openSystemApp('android.settings.WIFI_SETTINGS', null);
  static Future<bool> openMobileNetworkSettings() => AppLauncher.openSystemApp('android.settings.NETWORK_OPERATOR_SETTINGS', null);
  static Future<bool> openAirplaneModeSettings() => AppLauncher.openSystemApp('android.settings.AIRPLANE_MODE_SETTINGS', null);

  /// Bluetooth Settings
  static Future<bool> openBluetoothSettings() => AppLauncher.openSystemApp('android.settings.BLUETOOTH_SETTINGS', null);

  /// App Management
  static Future<bool> openAppSettings([String? packageName]) => AppLauncher.openSystemApp(
    'android.settings.APPLICATION_DETAILS_SETTINGS',
    {
      'uri': 'package:${packageName ?? "com.example.real_time"}'
    },
  );

  static Future<bool> openInstalledApps() => AppLauncher.openSystemApp('android.settings.MANAGE_ALL_APPLICATIONS_SETTINGS', null);

  static Future<bool> openAppNotificationsSettings() => AppLauncher.openSystemApp('android.settings.APP_NOTIFICATION_SETTINGS', null);

  /// Display Settings
  static Future<bool> openDisplaySettings() => AppLauncher.openSystemApp('android.settings.DISPLAY_SETTINGS', null);

  static Future<bool> openBrightnessSettings() => AppLauncher.openSystemApp('android.settings.DISPLAY_SETTINGS', null);

  /// Sound Settings
  static Future<bool> openSoundSettings() => AppLauncher.openSystemApp('android.settings.SOUND_SETTINGS', null);

  static Future<bool> openVolumeSettings() => AppLauncher.openSystemApp('android.settings.SOUND_SETTINGS', null);

  /// Storage Settings
  static Future<bool> openStorageSettings() => AppLauncher.openSystemApp('android.settings.INTERNAL_STORAGE_SETTINGS', null);

  /// Battery Settings
  static Future<bool> openBatterySettings() => AppLauncher.openSystemApp('android.settings.BATTERY_SAVER_SETTINGS', null);

  /// Security Settings
  static Future<bool> openSecuritySettings() => AppLauncher.openSystemApp('android.settings.SECURITY_SETTINGS', null);

  static Future<bool> openLocationSettings() => AppLauncher.openSystemApp('android.settings.LOCATION_SOURCE_SETTINGS', null);

  static Future<bool> openPrivacySettings() => AppLauncher.openSystemApp('android.settings.PRIVACY_SETTINGS', null);

  /// Account Settings
  static Future<bool> openAccountSettings() => AppLauncher.openSystemApp('android.settings.ACCOUNT_SYNC_SETTINGS', null);

  /// Date & Time Settings
  static Future<bool> openDateTimeSettings() => AppLauncher.openSystemApp('android.settings.DATE_SETTINGS', null);

  /// Accessibility Settings
  static Future<bool> openAccessibilitySettings() => AppLauncher.openSystemApp('android.settings.ACCESSIBILITY_SETTINGS', null);

  /// Developer Options
  static Future<bool> openDeveloperOptions() => AppLauncher.openSystemApp('android.settings.APPLICATION_DEVELOPMENT_SETTINGS', null);
}