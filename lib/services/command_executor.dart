import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'app_launcher.dart';
import 'system_service_launcher.dart';

class CommandExecutor {
  static Future<void> executeCommand(String action) async {
    print('🎯 Executing command: $action');

    try {
      // Load user's custom commands first
      final customCommands = await _loadCustomCommands();

      // Check if it's a custom command
      if (customCommands.containsKey(action)) {
        await _executeCustomCommand(customCommands[action]!);
        return;
      }

      // Default commands - case insensitive matching
      final normalizedAction = action.toLowerCase().trim();

      switch (normalizedAction) {
        case 'call dad':
          await _callContact('dad');
          break;
        case 'call mom':
          await _callContact('mom');
          break;
        case 'call police':
          await _makeEmergencyCall();
          break;
        case 'open google':
          await _openGoogle();
          break;
        case 'open siri':
          await _openAssistant();
          break;
        case 'send message':
          await _openMessaging();
          break;
        case 'open camera':
          await _openCamera();
          break;
        case 'play music':
          await _openMusicApp();
          break;
        case 'take screenshot':
          await _showScreenshotInstructions();
          break;
        case 'open calculator':
          await _openCalculator();
          break;
        default:
          print('❌ Unknown command: $action');
          await _errorFeedback();
          return;
      }

      // Success feedback
      await _successFeedback();
      print('✅ Command executed successfully: $action');

    } catch (e) {
      print('❌ Command execution failed: $e');
      await _errorFeedback();
    }
  }

  // Enhanced contact calling with saved names
  static Future<void> _callContact(String contactType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('contact_$contactType') ?? '';
      final contactName = prefs.getString('contact_${contactType}_name') ?? contactType;

      if (phoneNumber.isEmpty) {
        print('❌ No phone number configured for $contactName');
        await _errorFeedback();
        return;
      }

      await _makeCall(phoneNumber, contactName);
    } catch (e) {
      print('❌ Failed to call contact: $e');
      await _errorFeedback();
    }
  }

  // NATIVE KOTLIN CALLING - Uses your platform channel
  static Future<void> _makeCall(String phoneNumber, [String? contactName]) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanNumber.isEmpty) {
        print('❌ Invalid phone number: $phoneNumber');
        await _errorFeedback();
        return;
      }

      print('📞 Attempting NATIVE call to ${contactName ?? cleanNumber}: $cleanNumber');

      // Use your native Kotlin method for calling
      const platform = MethodChannel('open_apps_channel');

      try {
        final bool success = await platform.invokeMethod('callNumber', {
          'phoneNumber': cleanNumber,
        });

        if (success) {
          print('✅ NATIVE call initiated to ${contactName ?? cleanNumber}');
          await Vibration.vibrate(pattern: [0, 200, 100, 200]);
        } else {
          print('❌ Native call failed');
          await _errorFeedback();
        }
      } catch (e) {
        print('❌ Native call error: $e');
        await _errorFeedback();
      }
    } catch (e) {
      print('❌ Call failed: $e');
      await _errorFeedback();
    }
  }

  // Emergency call with special handling
  static Future<void> _makeEmergencyCall() async {
    try {
      print('🚨 Making NATIVE emergency call: 911');

      const platform = MethodChannel('open_apps_channel');

      try {
        final bool success = await platform.invokeMethod('callNumber', {
          'phoneNumber': '911',
        });

        if (success) {
          print('✅ NATIVE emergency call initiated');
          // Special emergency vibration pattern (longer, more urgent)
          await Vibration.vibrate(
            pattern: [0, 300, 100, 300, 100, 300, 100, 300],
          );
        } else {
          print('❌ Native emergency call failed');
          await _errorFeedback();
        }
      } catch (e) {
        print('❌ Native emergency call error: $e');
        await _errorFeedback();
      }
    } catch (e) {
      print('❌ Emergency call failed: $e');
      await _errorFeedback();
    }
  }

  // Open Google (actual Google website)
  static Future<void> _openGoogle() async {
    try {
      const googleUrl = 'https://www.google.com';
      print('🌐 Opening Google: $googleUrl');

      // Use your native browser opening method
      final bool success = await SystemServiceLauncher.openBrowser(googleUrl);

      if (success) {
        print('✅ Google opened successfully via native method');
      } else {
        print('❌ Native Google opening failed, trying fallback');
        await _openUrl(googleUrl);
      }
    } catch (e) {
      print('❌ Failed to open Google: $e');
      await _errorFeedback();
    }
  }

  // Open Google Assistant or Siri
  static Future<void> _openAssistant() async {
    try {
      if (Platform.isAndroid) {
        // Try to open Google Assistant via native method
        await _openUrl('https://assistant.google.com');
      } else if (Platform.isIOS) {
        await _openUrl('https://www.apple.com/siri/');
      } else {
        await _openUrl('https://assistant.google.com');
      }
    } catch (e) {
      print('❌ Failed to open assistant: $e');
      await _errorFeedback();
    }
  }

  // NATIVE messaging app opening
  static Future<void> _openMessaging() async {
    try {
      print('💬 Opening messaging app via native method...');

      // Use your native system app launcher
      const platform = MethodChannel('open_apps_channel');

      try {
        final bool success = await platform.invokeMethod('openSystemApp', {
          'action': 'android.intent.action.SENDTO',
          'uri': 'sms:',
        });

        if (success) {
          print('✅ NATIVE messaging app opened');
        } else {
          print('❌ Native messaging failed, trying fallback');
          // Fallback to basic SMS
          final Uri smsUri = Uri(scheme: 'sms');
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri);
            print('✅ Fallback messaging opened');
          } else {
            await _errorFeedback();
          }
        }
      } catch (e) {
        print('❌ Native messaging error: $e');
        await _errorFeedback();
      }
    } catch (e) {
      print('❌ Failed to open messaging: $e');
      await _errorFeedback();
    }
  }

  // NATIVE camera opening - THIS SHOULD WORK NOW!
  static Future<void> _openCamera() async {
    try {
      print('📸 Opening camera via NATIVE method...');

      // Use your existing native camera method
      final bool success = await SystemServiceLauncher.openCamera();

      if (success) {
        print('✅ NATIVE camera opened successfully!');
        return;
      } else {
        print('⚠️  Native camera method failed, trying alternatives...');
      }

      // Alternative: Try direct package name approach
      try {
        final bool packageSuccess = await AppLauncher.openAppByPackageName('com.samsung.android.camera');
        if (packageSuccess) {
          print('✅ Samsung Camera opened via package name');
          return;
        }
      } catch (e) {
        print('⚠️  Samsung Camera package failed: $e');
      }

      // Alternative: Try other camera packages
      final cameraPackages = [
        'com.android.camera',
        'com.android.camera2',
        'com.google.android.GoogleCamera',
      ];

      for (String packageName in cameraPackages) {
        try {
          final bool success = await AppLauncher.openAppByPackageName(packageName);
          if (success) {
            print('✅ Camera opened via $packageName');
            return;
          }
        } catch (e) {
          continue;
        }
      }

      print('❌ All camera methods failed');
      await _errorFeedback();

    } catch (e) {
      print('❌ Failed to open camera: $e');
      await _errorFeedback();
    }
  }

  // NATIVE music app opening - THIS SHOULD WORK NOW!
  static Future<void> _openMusicApp() async {
    try {
      print('🎵 Opening Samsung Music via NATIVE method...');

      // Method 1: Try Samsung Music directly
      try {
        final bool success = await AppLauncher.openAppByPackageName('com.samsung.android.music');
        if (success) {
          print('✅ Samsung Music opened successfully!');
          return;
        }
      } catch (e) {
        print('⚠️  Samsung Music package failed: $e');
      }

      // Method 2: Try alternative Samsung Music packages
      final samsungPackages = [
        'com.sec.android.app.music',
        'com.samsung.music',
      ];

      for (String packageName in samsungPackages) {
        try {
          final bool success = await AppLauncher.openAppByPackageName(packageName);
          if (success) {
            print('✅ Samsung Music opened via $packageName');
            return;
          }
        } catch (e) {
          continue;
        }
      }

      // Method 3: Try other music apps
      final musicPackages = [
        'com.spotify.music',
        'com.google.android.music',
        'com.google.android.apps.youtube.music',
        'com.amazon.mp3',
      ];

      for (String packageName in musicPackages) {
        try {
          final bool success = await AppLauncher.openAppByPackageName(packageName);
          if (success) {
            print('✅ Music app opened: $packageName');
            return;
          }
        } catch (e) {
          continue;
        }
      }

      // Method 4: Native system music intent
      try {
        const platform = MethodChannel('open_apps_channel');
        final bool success = await platform.invokeMethod('openSystemApp', {
          'action': 'android.intent.action.MUSIC_PLAYER',
        });

        if (success) {
          print('✅ Music player opened via native intent');
          return;
        }
      } catch (e) {
        print('⚠️  Native music intent failed: $e');
      }

      print('❌ All music methods failed');
      await _errorFeedback();

    } catch (e) {
      print('❌ Failed to open music app: $e');
      await _errorFeedback();
    }
  }

  // NATIVE calculator opening
  static Future<void> _openCalculator() async {
    try {
      print('🔢 Opening calculator via NATIVE method...');

      // Method 1: Try calculator packages directly
      final calculatorPackages = [
        'com.samsung.android.calculator',
        'com.google.android.calculator',
        'com.android.calculator2',
      ];

      for (String packageName in calculatorPackages) {
        try {
          final bool success = await AppLauncher.openAppByPackageName(packageName);
          if (success) {
            print('✅ Calculator opened: $packageName');
            return;
          }
        } catch (e) {
          continue;
        }
      }

      // Method 2: Fallback to web calculator
      await _openUrl('https://www.google.com/search?q=calculator');
      print('✅ Web calculator opened as fallback');

    } catch (e) {
      print('❌ Failed to open calculator: $e');
      await _errorFeedback();
    }
  }

  // Screenshot instructions
  static Future<void> _showScreenshotInstructions() async {
    try {
      print('📸 Screenshot Instructions:');

      if (Platform.isAndroid) {
        print('📱 Android: Press Power + Volume Down buttons simultaneously');
      } else if (Platform.isIOS) {
        print('📱 iOS: Press Power + Volume Up buttons simultaneously');
      }

      await Vibration.vibrate(pattern: [0, 100, 100, 100, 100, 100]);
      print('✅ Screenshot instructions provided');
    } catch (e) {
      print('❌ Failed to show screenshot instructions: $e');
      await _errorFeedback();
    }
  }

  // Enhanced URL opening
  static Future<void> _openUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      print('🌐 Opening URL: $url');

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ URL opened successfully');
      } else {
        print('❌ Cannot open URL: $url');
        await _errorFeedback();
      }
    } catch (e) {
      print('❌ Failed to open URL: $e');
      await _errorFeedback();
    }
  }

  // Load custom commands from preferences
  static Future<Map<String, Map<String, dynamic>>> _loadCustomCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commandsJson = prefs.getString('asl_commands') ?? '{}';
      final commandsMap = jsonDecode(commandsJson) as Map<String, dynamic>;

      return commandsMap.map((key, value) =>
          MapEntry(key, Map<String, dynamic>.from(value)));
    } catch (e) {
      print('❌ Failed to load custom commands: $e');
      return {};
    }
  }

  // Execute custom command
  static Future<void> _executeCustomCommand(Map<String, dynamic> command) async {
    try {
      final commandType = command['type'] ?? 'url';
      final target = command['target'] ?? '';

      if (target.isEmpty) {
        print('❌ Custom command has no target');
        await _errorFeedback();
        return;
      }

      switch (commandType) {
        case 'url':
          await _openUrl(target);
          break;
        case 'app':
        // Use native app opening
          final bool success = await AppLauncher.openAppByPackageName(target);
          if (!success) {
            await _errorFeedback();
          }
          break;
        case 'call':
          await _makeCall(target, 'Custom Contact');
          break;
        default:
          print('❌ Unknown custom command type: $commandType');
          await _errorFeedback();
      }
    } catch (e) {
      print('❌ Custom command failed: $e');
      await _errorFeedback();
    }
  }

  // Feedback methods
  static Future<void> _successFeedback() async {
    try {
      await Vibration.vibrate(pattern: [0, 100, 50, 100]);
    } catch (e) {
      print('❌ Success vibration failed: $e');
    }
  }

  static Future<void> _errorFeedback() async {
    try {
      await Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
    } catch (e) {
      print('❌ Error vibration failed: $e');
    }
  }
}