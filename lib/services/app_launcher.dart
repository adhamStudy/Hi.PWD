import 'package:flutter/services.dart';

class AppLauncher {
  static const MethodChannel _channel = MethodChannel('open_apps_channel');

  /// Opens an app by its package name
  /// Returns true if successful, false otherwise
  static Future<bool> openAppByPackageName(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('openAppByPackageName', {
        'packageName': packageName,
      });
      return result;
    } on PlatformException catch (e) {
      print('❌ Failed to open app $packageName: ${e.message}');
      return false;
    }
  }

  /// Opens a system app using Android intent action
  /// Returns true if successful, false otherwise
  static Future<bool> openSystemApp(String action, Map<String, dynamic>? extras) async {
    try {
      final Map<String, dynamic> arguments = {
        'action': action,
      };

      if (extras != null) {
        arguments.addAll(extras);
      }

      final bool result = await _channel.invokeMethod('openSystemApp', arguments);
      return result;
    } on PlatformException catch (e) {
      print('❌ Failed to open system app with action $action: ${e.message}');
      return false;
    }
  }

  /// Makes a phone call using native method
  /// Returns true if successful, false otherwise
  static Future<bool> callNumber(String phoneNumber) async {
    try {
      final bool result = await _channel.invokeMethod('callNumber', {
        'phoneNumber': phoneNumber,
      });
      return result;
    } on PlatformException catch (e) {
      print('❌ Failed to call $phoneNumber: ${e.message}');
      return false;
    }
  }

  /// Common app launchers using package names
  static Future<bool> openSamsungMusic() => openAppByPackageName('com.samsung.android.music');

  static Future<bool> openSamsungCamera() => openAppByPackageName('com.samsung.android.camera');

  static Future<bool> openSamsungCalculator() => openAppByPackageName('com.samsung.android.calculator');

  static Future<bool> openSpotify() => openAppByPackageName('com.spotify.music');

  static Future<bool> openYouTubeMusic() => openAppByPackageName('com.google.android.apps.youtube.music');

  static Future<bool> openGoogleCamera() => openAppByPackageName('com.google.android.GoogleCamera');

  static Future<bool> openGoogleCalculator() => openAppByPackageName('com.google.android.calculator');

  /// Check if an app is installed
  static Future<bool> isAppInstalled(String packageName) async {
    try {
      // Try to open the app and check if it succeeds
      // Note: This might briefly open the app, but it's the most reliable way
      final bool result = await openAppByPackageName(packageName);
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Get a list of commonly used Samsung apps
  static List<String> getSamsungAppPackages() {
    return [
      'com.samsung.android.music',         // Samsung Music
      'com.samsung.android.camera',        // Samsung Camera
      'com.samsung.android.calculator',    // Samsung Calculator
      'com.samsung.android.gallery3d',     // Samsung Gallery
      'com.samsung.android.messaging',     // Samsung Messages
      'com.samsung.android.contacts',      // Samsung Contacts
      'com.samsung.android.calendar',      // Samsung Calendar
      'com.samsung.android.email.provider', // Samsung Email
      'com.samsung.android.app.notes',     // Samsung Notes
      'com.samsung.android.weather',       // Samsung Weather
    ];
  }

  /// Get a list of common music app packages
  static List<String> getMusicAppPackages() {
    return [
      'com.samsung.android.music',         // Samsung Music
      'com.spotify.music',                 // Spotify
      'com.google.android.music',          // Google Play Music
      'com.google.android.apps.youtube.music', // YouTube Music
      'com.amazon.mp3',                    // Amazon Music
      'deezer.android.app',               // Deezer
      'com.soundcloud.android',           // SoundCloud
      'com.pandora.android',              // Pandora
    ];
  }

  /// Get a list of common camera app packages
  static List<String> getCameraAppPackages() {
    return [
      'com.samsung.android.camera',        // Samsung Camera
      'com.android.camera',                // Default Android Camera
      'com.android.camera2',               // Android Camera2
      'com.google.android.GoogleCamera',   // Google Camera
      'com.oneplus.camera',                // OnePlus Camera
      'com.huawei.camera',                 // Huawei Camera
    ];
  }
}