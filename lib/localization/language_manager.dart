// lib/localization/language_manager.dart
import 'package:flutter_localization/flutter_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_locale.dart';

class LanguageManager {
  static final FlutterLocalization localization = FlutterLocalization.instance;
  static const String _languagePreferenceKey = 'selectedLanguage';

  // Initialize localization
  static Future<void> init() async {
    await localization.ensureInitialized();
    
    // Load saved language preference
    final savedLanguage = await getSavedLanguage();
    
    localization.init(
      mapLocales: [
        const MapLocale('en', AppLocale.en, fontFamily: 'MuseoSans'),
        const MapLocale('sw', AppLocale.sw, fontFamily: 'MuseoSans'),
        // Add more languages as needed
      ],
      initLanguageCode: savedLanguage,
    );
  }

  // Change language
  static Future<void> changeLanguage(String languageCode) async {
    await saveLanguage(languageCode);
    localization.translate(languageCode);
  }

  // Save language preference to SharedPreferences
  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePreferenceKey, languageCode);
  }

  // Get saved language from SharedPreferences
  static Future<String> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languagePreferenceKey) ?? 'en'; 
  }

  // Get language name for display
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'sw':
        return 'Kiswahili';
      default:
        return 'Unknown';
    }
  }
}
