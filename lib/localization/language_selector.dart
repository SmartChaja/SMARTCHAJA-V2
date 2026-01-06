// lib/localization/language_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/localization/language_provider.dart';


class LanguageSelector extends ConsumerWidget { // Changed to ConsumerWidget
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the language state from Riverpod
    final languageState = ref.watch(languageProvider);
    final currentLanguageCode = languageState.currentLanguageCode;
    // Use the getter from LanguageState for the display name
    final currentLanguageName = languageState.currentLanguageName;

    // If not initialized, maybe show a placeholder or disable the button
    if (!languageState.isInitialized) {
      return const SizedBox(
        width: 100, // Give it some space
        height: kMinInteractiveDimension,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language),
          const SizedBox(width: 4),
          Text(currentLanguageName), // Display name from Riverpod state
        ],
      ),
      onSelected: (String languageCode) {
        // Call the method on the notifier to change the language
        ref.read(languageProvider.notifier).changeLanguage(languageCode);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'en',
          // Get display name using the LanguageState helper or define directly
          child: _buildLanguageItem('English', currentLanguageCode == 'en'),
        ),
        PopupMenuItem<String>(
          value: 'sw',
          child: _buildLanguageItem('Kiswahili', currentLanguageCode == 'sw'),
        ),
      ],
    );
  }

  Widget _buildLanguageItem(String title, bool isSelected) {
    return Row(
      children: [
        Text(title),
        const Spacer(),
        if (isSelected) const Icon(Icons.check, color: Colors.green),
      ],
    );
  }
}