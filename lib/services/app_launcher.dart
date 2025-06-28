import 'dart:io';

import 'package:flutter/services.dart';

class AppLauncher {
  static const channel = "open_apps_channel";

  static Future<bool> openAppByPackageName(String packageName) async {

    try {
      if(Platform.isAndroid) {
        const platform = MethodChannel(channel);
        final result = await platform.invokeMethod(
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
}