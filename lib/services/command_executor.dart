import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'dart:convert';
import 'dart:io';

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

  // Enhanced call method with contact name
  static Future<void> _makeCall(String phoneNumber, [String? contactName]) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanNumber.isEmpty) {
        print('❌ Invalid phone number: $phoneNumber');
        await _errorFeedback();
        return;
      }

      final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
      print('📞 Attempting to call ${contactName ?? cleanNumber}: $cleanNumber');

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        print('✅ Call initiated to ${contactName ?? cleanNumber}');

        // Special vibration for calls
        await Vibration.vibrate(pattern: [0, 200, 100, 200]);
      } else {
        print('❌ Cannot make calls on this device');
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
      final Uri phoneUri = Uri(scheme: 'tel', path: '911');
      print('🚨 Making emergency call: 911');

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);

        // Special emergency vibration pattern (longer, more urgent)
        await Vibration.vibrate(
          pattern: [0, 300, 100, 300, 100, 300, 100, 300],
        );
        print('✅ Emergency call initiated');
      } else {
        print('❌ Cannot make emergency calls on this device');
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
    try {
      // Try to open camera via intent
      if (Platform.isAndroid) {
        final Uri cameraUri = Uri.parse('intent://media.android.intent.action.IMAGE_CAPTURE#Intent;scheme=camera;end');

        if (await canLaunchUrl(cameraUri)) {
          await launchUrl(cameraUri);
          print('✅ Camera opened');
          return;
        }
      }

      // Fallback: Try generic camera apps
      final cameraApps = [
        'android-app://com.android.camera',
        'android-app://com.samsung.android.camera',
        'android-app://com.google.android.GoogleCamera',
      ];

      bool opened = false;
      for (String appUri in cameraApps) {
        try {
          final Uri uri = Uri.parse(appUri);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            opened = true;
            print('✅ Camera app opened');
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (!opened) {
        print('❌ No camera app available');
        await _errorFeedback();
      }
    } catch (e) {
      print('❌ Failed to open camera: $e');
      await _errorFeedback();
    }
  }

  // Enhanced music app opening (simplified)
  static Future<void> _openMusicApp() async {
    try {
      // Try popular music streaming services
      final musicUrls = [
        // 'https://open.spotify.com',        // Spotify Web
        'https://music.youtube.com',       // YouTube Music
        'https://music.amazon.com',        // Amazon Music
        'https://music.apple.com',         // Apple Music
      ];

      // Try to open Spotify first (most common)
      final Uri spotifyUri = Uri.parse(musicUrls[0]);

      if (await canLaunchUrl(spotifyUri)) {
        await launchUrl(
          spotifyUri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ Music service opened');
      } else {
        await _errorFeedback();
      }
    } catch (e) {
      print('❌ Failed to open music app: $e');
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