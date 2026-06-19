import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF00FFD1);      // Neon Cyan/Teal
  static const Color primaryLight = Color(0xFF5EFFF4);  // Lighter Neon
  static const Color primaryDark = Color(0xFF00B392);   // Deeper Neon
  static const Color secondary = Color(0xFFFF2A5F);    // Neon Pink/Red
  static const Color secondaryLight = Color(0xFFFF6B90); // Warm Neon Pink
  static const Color background = Color(0xFF0A0C10);   // Deep Void
  static const Color surface = Color(0xFF12161F);      // Vault Surface
  
  
  // Gamified Theme Colors
  static const Color deepSpaceBlack = Color(0xFF0A0F1F);
  static const Color midnightNavy = Color(0xFF111827);
  static const Color darkTeal = Color(0xFF08615B);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color safetyOrange = Color(0xFFE88F1B);
  static const Color softWhite = Color(0xFFF8FAFC);

  // Accent Shades
  static const Color tealGlow = Color(0xFF00FFD1);     // Bright teal for glows
  static const Color orangeGlow = Color(0xFFFF8C00);   // Bright orange for glows
  static const Color deepIndigo = Color(0xFF1E1B4B);   // Deep indigo accent
  
  // Glassmorphism
  static const Color glassWhite = Color(0x0DFFFFFF); // 5% white
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white
  static const Color glassDark = Color(0x40000000); // 25% black

  // Neutral Text (Inverted for Dark Theme)
  static const Color textMain = Color(0xFFF8FAFC);     // Slate 50 (White)
  static const Color textMuted = Color(0xFF94A3B8);    // Slate 400 (Grey)
  static const Color textLight = Color(0xFF475569);    // Slate 600 (Darker Grey)
  
  // Borders & Dividers
  static const Color border = Color(0xFF1E293B);       // Slate 800
  static const Color borderLight = Color(0xFF0F172A);  // Slate 900
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00FFD1), Color(0xFF00B392)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF05070A), Color(0xFF0A0C10), Color(0xFF12161F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF2A5F), Color(0xFFFF6B90)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF1E293B)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1F2E), Color(0xFF12161F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
