import 'dart:io';

import 'package:flutter/services.dart';

class AppLauncher {
  static const channel = MethodChannel('open_apps_channel');

  static Future<bool> openAppByPackageName(String packageName) async {
    try {
      if(Platform.isAndroid) {
        final result = await channel.invokeMethod(
          'openAppByPackageName',
          {'packageName': packageName}
        );
        return result == true;
      }
      return false;
    } catch(e) {
      print("Cannot oepning app, $e");
    }
    return false;
  }

  static Future<bool> openSystemApp(String action, Map<String, dynamic>? extras) async {
    try {
      final result = await channel.invokeMethod(
          'openSystemApp',
          {
            'action': action,
            if(extras != null) 'extras': extras
          }
      );
      return result ?? false;
    } on Exception catch (e) {
      print("Failed to open system app, $e");
      return false;
    }
  }

  static Future<bool> callNumber(String phoneNumber) async {
    try {
      final result = await channel.invokeMethod(
        'callNumber',
        {'phoneNumber': phoneNumber}
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to call number '$phoneNumber', $e");
      return false;
    }
  }
}