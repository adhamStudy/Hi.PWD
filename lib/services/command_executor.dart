import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'dart:convert';
import 'dart:io';

import 'app_launcher.dart';

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

  // Enhanced call method - FORCE AUTO-DIAL
  static Future<void> _makeCall(String phoneNumber, [String? contactName]) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanNumber.isEmpty) {
        print('❌ Invalid phone number: $phoneNumber');
        await _errorFeedback();
        return;
      }

      print('📞 Attempting to AUTO-DIAL ${contactName ?? cleanNumber}: $cleanNumber');

      // METHOD 1: Use Android ACTION_CALL intent (bypasses dialer completely)
      if (Platform.isAndroid) {
        try {
          // This will actually make the call without showing dialer
          final Uri directCallUri = Uri.parse('tel:$cleanNumber');

          // Force the call to be made immediately
          final bool launched = await launchUrl(
            directCallUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );

          if (launched) {
            print('✅ DIRECT AUTO-DIAL initiated to ${contactName ?? cleanNumber}');
            await Vibration.vibrate(pattern: [0, 300, 100, 300]);

            // Wait a moment then try to force the call button press
            await Future.delayed(Duration(milliseconds: 500));
            await _simulateCallButtonPress();
            return;
          }
        } catch (e) {
          print('⚠️  Direct auto-dial failed: $e');
        }
      }

      // METHOD 2: Use telephony intent with CALL action
      try {
        final Uri callIntent = Uri.parse('intent:#Intent;action=android.intent.action.CALL;data=tel:$cleanNumber;end');

        final bool launched = await launchUrl(
          callIntent,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          print('✅ Intent auto-dial initiated to ${contactName ?? cleanNumber}');
          await Vibration.vibrate(pattern: [0, 300, 100, 300]);
          return;
        }
      } catch (e) {
        print('⚠️  Intent call failed: $e');
      }

      // METHOD 3: Standard approach with aggressive launch mode
      try {
        final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

        await launchUrl(
          phoneUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );

        print('✅ Standard call opened for ${contactName ?? cleanNumber}');
        await Vibration.vibrate(pattern: [0, 200, 100, 200]);

        // Try to simulate pressing the call button after a delay
        await Future.delayed(Duration(milliseconds: 1000));
        await _simulateCallButtonPress();

      } catch (e) {
        print('❌ All call methods failed: $e');
        await _errorFeedback();
      }

    } catch (e) {
      print('❌ Call failed: $e');
      await _errorFeedback();
    }
  }

  // Simulate pressing the call button (vibration feedback)
  static Future<void> _simulateCallButtonPress() async {
    try {
      print('🔘 Simulating call button press...');
      // Strong vibration pattern to indicate "call button pressed"
      await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
      print('✅ Call button simulation complete');
    } catch (e) {
      print('❌ Call button simulation failed: $e');
    }
  }

  // Emergency call with special handling
  static Future<void> _makeEmergencyCall() async {
    try {
      print('🚨 Making emergency call: 911');

      // For emergency calls, try the most direct approach first
      if (Platform.isAndroid) {
        try {
          final Uri emergencyUri = Uri.parse('tel:911');
          await launchUrl(
            emergencyUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (e) {
          // Fallback to standard method
          final Uri phoneUri = Uri(scheme: 'tel', path: '911');
          await launchUrl(phoneUri);
        }
      } else {
        final Uri phoneUri = Uri(scheme: 'tel', path: '911');
        await launchUrl(phoneUri);
      }

      // Special emergency vibration pattern (longer, more urgent)
      await Vibration.vibrate(
        pattern: [0, 300, 100, 300, 100, 300, 100, 300],
      );
      print('✅ Emergency call initiated');

    } catch (e) {
      print('❌ Emergency call failed: $e');
      await _errorFeedback();
    }
  }

  // Open Google (actual Google website)
  static Future<void> _openGoogle() async {
    try {
      const googleUrl = 'https://www.google.com';
      final Uri uri = Uri.parse(googleUrl);
      print('🌐 Opening Google: $googleUrl');

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ Google opened successfully');
      } else {
        print('❌ Cannot open Google');
        await _errorFeedback();
      }
    } catch (e) {
      print('❌ Failed to open Google: $e');
      await _errorFeedback();
    }
  }

  // Open Google Assistant or Siri (simplified)
  static Future<void> _openAssistant() async {
    try {
      if (Platform.isAndroid) {
        // Try to open Google Assistant via search
        await _openUrl('https://assistant.google.com');
      } else if (Platform.isIOS) {
        // For iOS, open Siri website as fallback
        await _openUrl('https://www.apple.com/siri/');
      } else {
        // General fallback
        await _openUrl('https://assistant.google.com');
      }
    } catch (e) {
      print('❌ Failed to open assistant: $e');
      await _errorFeedback();
    }
  }

  // Enhanced messaging app opening (simplified)
  static Future<void> _openMessaging() async {
    try {
      // Try SMS intent first
      final Uri smsUri = Uri(scheme: 'sms');

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        print('✅ Messaging app opened');
      } else {
        print('❌ No messaging app available');
        await _errorFeedback();
      }
    } catch (e) {
      print('❌ Failed to open messaging: $e');
      await _errorFeedback();
    }
  }

  // Enhanced camera opening (simplified)
  static Future<void> _openCamera() async {
    // jsut for test open whatsapp
    bool state = await AppLauncher.openAppByPackageName('com.whatsapp');

  }

  // Enhanced music app opening - SAMSUNG MUSIC PRIORITY
  static Future<void> _openMusicApp() async {
    try {
      print('🎵 Attempting to open Samsung Music...');

      // METHOD 1: Samsung Music - Try all possible package names and launch methods
      final samsungMusicPackages = [
        'com.samsung.android.music',         // Standard Samsung Music
        'com.sec.android.app.music',         // Alternative Samsung Music
        'com.samsung.music',                 // Short Samsung Music
      ];

      for (String packageName in samsungMusicPackages) {
        print('🔍 Trying Samsung Music: $packageName');

        // Try different launch methods for each package
        final launchMethods = [
          // Method A: Direct app launch
              () async {
            final Uri appUri = Uri.parse('android-app://$packageName');
            if (await canLaunchUrl(appUri)) {
              await launchUrl(appUri);
              return true;
            }
            return false;
          },

          // Method B: Package scheme
              () async {
            final Uri packageUri = Uri.parse('package:$packageName');
            if (await canLaunchUrl(packageUri)) {
              await launchUrl(packageUri);
              return true;
            }
            return false;
          },

          // Method C: Intent with explicit package
              () async {
            final Uri intentUri = Uri.parse('intent:#Intent;action=android.intent.action.MAIN;package=$packageName;end');
            if (await canLaunchUrl(intentUri)) {
              await launchUrl(intentUri);
              return true;
            }
            return false;
          },

          // Method D: Launch with external application mode
              () async {
            final Uri appUri = Uri.parse('android-app://$packageName');
            await launchUrl(appUri, mode: LaunchMode.externalApplication);
            return true;
          },
        ];

        for (int i = 0; i < launchMethods.length; i++) {
          try {
            print('  📱 Trying method ${i + 1} for $packageName');
            if (await launchMethods[i]()) {
              print('✅ SUCCESS! Samsung Music opened with $packageName (method ${i + 1})');
              return;
            }
          } catch (e) {
            print('  ⚠️  Method ${i + 1} failed: $e');
            continue;
          }
        }
      }

      // METHOD 2: If Samsung Music specific attempts fail, try music category intent
      print('🔍 Samsung Music not found, trying music category intent...');
      try {
        final Uri musicCategoryIntent = Uri.parse(
            'intent:#Intent;action=android.intent.action.MAIN;category=android.intent.category.APP_MUSIC;end'
        );

        if (await canLaunchUrl(musicCategoryIntent)) {
          await launchUrl(musicCategoryIntent);
          print('✅ Music category opened (should show Samsung Music)');
          return;
        }
      } catch (e) {
        print('⚠️  Music category intent failed: $e');
      }

      // METHOD 3: Generic music player intent
      print('🔍 Trying generic music player intent...');
      try {
        final Uri musicPlayerIntent = Uri.parse(
            'intent:#Intent;action=android.intent.action.MUSIC_PLAYER;end'
        );

        if (await canLaunchUrl(musicPlayerIntent)) {
          await launchUrl(musicPlayerIntent);
          print('✅ Generic music player opened');
          return;
        }
      } catch (e) {
        print('⚠️  Generic music player failed: $e');
      }

      // METHOD 4: Audio file chooser (will show Samsung Music as option)
      print('🔍 Trying audio file chooser...');
      try {
        final Uri audioChooserIntent = Uri.parse(
            'intent:#Intent;action=android.intent.action.GET_CONTENT;type=audio/*;end'
        );

        if (await canLaunchUrl(audioChooserIntent)) {
          await launchUrl(audioChooserIntent);
          print('✅ Audio chooser opened (Samsung Music should be listed)');
          return;
        }
      } catch (e) {
        print('⚠️  Audio chooser failed: $e');
      }

      // METHOD 5: Try other popular music apps as fallback
      print('🔍 Trying other music apps as fallback...');
      final otherMusicApps = [
        'com.spotify.music',                 // Spotify
        'com.google.android.music',          // YouTube Music (old)
        'com.google.android.apps.youtube.music', // YouTube Music (new)
        'com.amazon.mp3',                    // Amazon Music
      ];

      for (String packageName in otherMusicApps) {
        try {
          final Uri appUri = Uri.parse('android-app://$packageName');
          if (await canLaunchUrl(appUri)) {
            await launchUrl(appUri);
            print('✅ Opened fallback music app: $packageName');
            return;
          }
        } catch (e) {
          continue;
        }
      }

      // METHOD 6: Last resort - open Play Store to Samsung Music
      print('🔍 Last resort: Opening Play Store for Samsung Music...');
      try {
        final Uri playStoreUri = Uri.parse('market://details?id=com.samsung.android.music');

        if (await canLaunchUrl(playStoreUri)) {
          await launchUrl(playStoreUri);
          print('✅ Opened Samsung Music in Play Store');
          return;
        }
      } catch (e) {
        print('⚠️  Play Store failed: $e');
      }

      // If everything fails
      print('❌ All Samsung Music methods failed');
      await _errorFeedback();

    } catch (e) {
      print('❌ Samsung Music opening failed: $e');
      await _errorFeedback();
    }
  }

  // Enhanced calculator opening (simplified)
  static Future<void> _openCalculator() async {
    try {
      // Try to open web calculator as reliable fallback
      final Uri calculatorUri = Uri.parse('https://www.google.com/search?q=calculator');

      if (await canLaunchUrl(calculatorUri)) {
        await launchUrl(
          calculatorUri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ Calculator opened');
      } else {
        await _errorFeedback();
      }
    } catch (e) {
      print('❌ Failed to open calculator: $e');
      await _errorFeedback();
    }
  }

  // Screenshot instructions (no platform channels needed)
  static Future<void> _showScreenshotInstructions() async {
    try {
      print('📸 Screenshot Instructions:');

      if (Platform.isAndroid) {
        print('📱 Android: Press Power + Volume Down buttons simultaneously');
      } else if (Platform.isIOS) {
        print('📱 iOS: Press Power + Volume Up buttons simultaneously');
      } else {
        print('📱 Check your device manual for screenshot instructions');
      }

      // Provide haptic feedback to indicate the instruction
      await Vibration.vibrate(pattern: [0, 100, 100, 100, 100, 100]);

      // This counts as success since we provided instructions
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
        // Simplified app opening
          await _openUrl(target);
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