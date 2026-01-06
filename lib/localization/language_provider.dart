// lib/localization/language_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_locale.dart'; 

const String _riverpodLanguagePreferenceKey = 'selectedLanguageRiverpod'; 
// State for our language
class LanguageState {
  final String currentLanguageCode;
  final FlutterLocalization localizationInstance;
  final bool isInitialized;

  LanguageState({
    required this.currentLanguageCode,
    required this.localizationInstance,
    this.isInitialized = false,
  });

  String get currentLanguageName {
    switch (currentLanguageCode) {
      case 'en':
        return 'English';
      case 'sw':
        return 'Kiswahili';
      default:
        return localizationInstance.getLanguageName(languageCode: currentLanguageCode);
    }
  }

  LanguageState copyWith({
    String? currentLanguageCode,
    FlutterLocalization? localizationInstance,
    bool? isInitialized,
  }) {
    return LanguageState(
      currentLanguageCode: currentLanguageCode ?? this.currentLanguageCode,
      localizationInstance: localizationInstance ?? this.localizationInstance,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// Notifier for our language state
class LanguageNotifier extends StateNotifier<LanguageState> {
  final FlutterLocalization _localization = FlutterLocalization.instance;

  LanguageNotifier()
      : super(LanguageState(
          currentLanguageCode: 'en', // Default before async init
          localizationInstance: FlutterLocalization.instance,
          isInitialized: false,
        )) {
    _initialize();
  }

  Future<void> _initialize() async {
    // ensureInitialized for the flutter_localization package itself
    // is now called in main.dart BEFORE this provider is even created.

    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_riverpodLanguagePreferenceKey) ?? 'en';

    _localization.init(
      mapLocales: [
        const MapLocale('en', AppLocale.en, fontFamily: 'MuseoSans'), // Use AppLocale.en
        const MapLocale('sw', AppLocale.sw, fontFamily: 'MuseoSans'), // Use AppLocale.sw
      ],
      initLanguageCode: savedLanguage,
    );

    state = state.copyWith(
      currentLanguageCode: savedLanguage,
      isInitialized: true,
    );

    _localization.onTranslatedLanguage = (Locale? locale) {
      if (locale != null && locale.languageCode != state.currentLanguageCode) {
        _saveLanguagePreference(locale.languageCode);
        state = state.copyWith(currentLanguageCode: locale.languageCode);
      }
    };
  }

  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != state.currentLanguageCode && state.isInitialized) {
      _localization.translate(languageCode);
      // onTranslatedLanguage callback will update state and save preference
    }
  }

  Future<void> _saveLanguagePreference(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_riverpodLanguagePreferenceKey, languageCode);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>(
  (ref) => LanguageNotifier(),
  name: 'languageProvider',
);
