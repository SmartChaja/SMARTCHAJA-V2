import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'SellPoint';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Pagination
  static const int defaultPageSize = 10;

  // Asset Paths
  static const String imagePath = 'assets/images/';
  static const String iconPath = 'assets/icons/';

  static const String defaultCurrency = 'TZS';
}

class AppGradients {
  static const LinearGradient calmingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE0EAFC),
      Color(0xFFCFDEF3),
    ],
  );

  static const LinearGradient defaultGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2C3E50), // Dark blue-gray
      Color(0xFF3498DB), // Blue
    ],
  );
  static const LinearGradient deepDarkBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F2027), // Midnight dark blue
      Color(0xFF203A43), // Deep steel blue
      Color(0xFF2C5364), // Slightly brighter deep blue
    ],
  );
  static const LinearGradient deepBlueModern = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF111827), // Deep dark base
      Color(0xFF1F2937), // Slightly lighter intermediary (optional smoothness)
      Color(0xFF3498DB), // Accent sky blue
    ],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9B59B6), // Purple
      Color(0xFF8E44AD), // Dark purple
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E88E5), // Primary blue
      Color(0xFF1565C0), // Darker blue
    ],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF26A69A), // Teal
      Color(0xFF00897B), // Darker teal
    ],
  );

  static const LinearGradient lightToDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF7F9FB), // Light Background
      Color(0xFFDDE6ED), // Light Gray
    ],
  );

  static const LinearGradient darkBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D47A1), // Navy Blue
      Color(0xFF1976D2), // Lighter Royal Blue
    ],
  );

  static const LinearGradient warmSunset = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFFFF9A8B), // Soft pink
      Color(0xFFFF6A88), // Vibrant coral
      Color(0xFFFF99AC), // Light rose
    ],
  );

  static const LinearGradient frostyGlass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFe0eafc), // Frost blue
      Color(0xFFcfdef3),
      Color(0xFFcfd9df),
    ],
  );

  static const LinearGradient grayscaleFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFEEEEEE),
      Color(0xFFCCCCCC),
      Color(0xFF999999),
    ],
  );

  static const LinearGradient emeraldGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00C853), // Vivid Green
      Color(0xFF43A047), // Slightly darker
    ],
  );

  static const LinearGradient crimsonRed = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFFB71C1C), // Dark red
      Color(0xFFE53935), // Bright red
    ],
  );
}

class AppColors {
  // 💡 Brand Colors
  static const Color primaryColor = Color(0xFF059669);
  static const Color primaryLightColor = Color(0xFF64B5F6);
  static const Color primaryDarkColor = Color(0xFF1565C0);
  static const Color primaryAppBarColor = Color(0xFF0D1B4C);

  // 🖋️ Text Colors (Light Theme)
  static const Color primaryTextColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color disabledTextColor = Color(0xFFBDBDBD);

  // 🖋️ Text Colors (Dark Theme)
  static const Color primaryTextColorDark = Color(0xFFF5F5F5); // White-ish
  static const Color secondaryTextColorDark =
      Color(0xFFB0BEC5); // Light blue-gray
  static const Color disabledTextColorDark =
      Color(0xFF888888); // Gray for dark mode

  // ❌ Error Colors
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color errorLightColor = Color(0xFFEF5350);
  static const Color errorDarkColor = Color(0xFFC62828);

  // ✅ Success Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color successLightColor = Color(0xFF66BB6A);
  static const Color successDarkColor = Color(0xFF388E3C);

  // ⚠️ Warning Colors
  static const Color warningColor = Color(0xFFFFA726);
  static const Color warningLightColor = Color(0xFFFFB74D);
  static const Color warningDarkColor = Color(0xFFF57C00);

  // 🧱 Background and Surface Colors (Light)
  static const Color backgroundColor = Color.fromARGB(255, 230, 230, 230);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // 🌑 Background and Surface Colors (Dark)
  static const Color backgroundColorDark = Color(0xFF121212); // True dark
  static const Color surfaceColorDark = Color(0xFF1E1E1E); // Card dark
  static const Color dividerColorDark = Color(0xFF2C2C2C); // Border dark
}

class AppSpacing {
  // Basic spacing units
  static const double xs = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;

  // Specific spacing
  static const double buttonPadding = medium;
  static const double sectionPadding = large;
  static const double cardPadding = medium;
}

class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.0,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.2,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// Add these constants for consistent border radius values
class AppBorderRadius {
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 12.0;
  static const double xl = 16.0;
  static const double xxl = 50.0;
}

// NEWLY ADDED or MODIFIED SECTION for Shadows
class AppShadows {
  static final BoxShadow xs = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 4,
    offset: const Offset(0, 1),
  );

  static final BoxShadow sm = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 6,
    offset: const Offset(0, 2),
  );

  static final BoxShadow md = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );

  // ADDED 'lg' (large) shadow definition
  static final BoxShadow lg = BoxShadow(
    color: Colors.black.withOpacity(0.12), // Slightly more opacity
    blurRadius: 16, // More blur
    spreadRadius: 2, // A bit of spread
    offset: const Offset(0, 6), // Larger offset
  );

  static final BoxShadow xl = BoxShadow(
    color: Colors.black.withOpacity(0.15),
    blurRadius: 24,
    spreadRadius: 4,
    offset: const Offset(0, 8),
  );

  // Example of a more subtle shadow
  static final BoxShadow subtle = BoxShadow(
    color: Colors.grey.withOpacity(0.08),
    blurRadius: 5,
    offset: const Offset(0, 1),
  );

  // Example of a shadow for focused/active elements
  static final BoxShadow focused = BoxShadow(
    color: AppColors.primaryColor.withOpacity(0.25), // Using your primary color
    blurRadius: 12,
    spreadRadius: 1,
    offset: const Offset(0, 4),
  );
}
