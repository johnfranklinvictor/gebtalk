import 'package:flutter/material.dart';

/// GEBTALK TITAN III Design System — Color Foundation
/// 
/// World's #1 premium dark gamified palette — OLED blacks, neon accents,
/// XP tier system, cyber gradients, plasma glass, quantum effects.
class AppColors {
  // ═══════════════════════════════════════════════════════════════
  //  BRAND SIGNATURE COLORS
  // ═══════════════════════════════════════════════════════════════
  
  /// Primary plasma cyan — the signature GEBTALK energy color
  static const Color primary = Color(0xFF00FFD1);
  static const Color primaryLight = Color(0xFF5EFFF4);
  static const Color primaryDark = Color(0xFF00B392);
  
  /// Secondary neon accent — alerts, urgency, passion
  static const Color secondary = Color(0xFFFF2A6D);
  static const Color secondaryLight = Color(0xFFFF6B9D);
  
  /// Tertiary nebula purple — depth, mystery, premium
  static const Color nebulaPurple = Color(0xFF8B5CF6);
  static const Color nebulaLight = Color(0xFFa78bfa);
  
  // ═══════════════════════════════════════════════════════════════
  //  🎮 NEON GAMIFIED ACCENTS
  // ═══════════════════════════════════════════════════════════════
  
  /// Radioactive green — XP gains, positive events
  static const Color neonRadioactive = Color(0xFF39FF14);
  
  /// Plasma magenta — critical alerts, legendary items
  static const Color neonMagenta = Color(0xFFFF00FF);
  
  /// Hologram violet — UI overlays, scan effects
  static const Color neonViolet = Color(0xFF7B2FFF);
  
  /// Deep crimson — danger, urgent, destructive
  static const Color neonCrimson = Color(0xFFDC143C);
  
  /// Electric orange — warnings, fire effects
  static const Color neonOrange = Color(0xFFFF6600);
  
  /// Ice blue — freeze effects, cooldown states
  static const Color neonIce = Color(0xFF00D4FF);

  // ═══════════════════════════════════════════════════════════════
  //  🏆 XP / LEVEL TIER SYSTEM
  // ═══════════════════════════════════════════════════════════════
  
  /// Bronze — entry tier
  static const Color tierBronze = Color(0xFFCD7F32);
  static const Color tierBronzeGlow = Color(0xFFE8A54B);
  
  /// Silver — intermediate tier
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierSilverGlow = Color(0xFFE8E8E8);
  
  /// Gold — advanced tier
  static const Color tierGold = Color(0xFFFFD700);
  static const Color tierGoldGlow = Color(0xFFFFE55C);
  
  /// Diamond — elite tier
  static const Color tierDiamond = Color(0xFFB9F2FF);
  static const Color tierDiamondGlow = Color(0xFFE0F7FF);
  
  /// Mythic — legendary tier — animated rainbow shimmer
  static const Color tierMythic = Color(0xFFFF00FF);
  static const Color tierMythicAlt = Color(0xFF7B2FFF);

  // ═══════════════════════════════════════════════════════════════
  //  VOID & SURFACE SYSTEM (TRUE OLED)
  // ═══════════════════════════════════════════════════════════════
  
  /// The deepest void — OLED pure black app background
  static const Color background = Color(0xFF020408);
  
  /// Panel/card surface — barely lifted from void
  static const Color surface = Color(0xFF0A0D14);
  
  /// Elevated surface — modals, dropdowns
  static const Color surfaceElevated = Color(0xFF111620);
  
  /// Deep space variants
  static const Color deepSpaceBlack = Color(0xFF060A14);
  static const Color midnightNavy = Color(0xFF0D1117);
  
  /// Card surface with subtle blue undertone
  static const Color surfaceCard = Color(0xFF0E121B);
  
  /// Hover surface — slightly brighter on interaction
  static const Color surfaceHover = Color(0xFF151A26);
  
  /// Frosted surface for premium overlays
  static const Color surfaceFrosted = Color(0xFF1A1F2E);
  
  /// Ultra-elevated for floating elements
  static const Color surfaceFloat = Color(0xFF1C2235);

  // ═══════════════════════════════════════════════════════════════
  //  ROLE-SPECIFIC ACCENT SYSTEMS
  // ═══════════════════════════════════════════════════════════════
  
  /// CEO — Gold/Amber holographic empire
  static const Color ceoGold = Color(0xFFFFD700);
  static const Color ceoAmber = Color(0xFFFFA500);
  static const Color ceoGlow = Color(0xFFFFE55C);
  
  /// Manager — Electric blue command
  static const Color managerBlue = Color(0xFF3B82F6);
  static const Color managerCyan = Color(0xFF06B6D4);
  static const Color managerGlow = Color(0xFF60A5FA);
  
  /// Staff — Teal professional
  static const Color staffTeal = Color(0xFF14B8A6);
  static const Color staffGreen = Color(0xFF10B981);
  static const Color staffGlow = Color(0xFF2DD4BF);
  
  /// Customer — Crystal luxury
  static const Color customerCrystal = Color(0xFFF1F5F9);
  static const Color customerWarm = Color(0xFFFBBF24);
  static const Color customerGlow = Color(0xFFF8FAFC);
  
  // ═══════════════════════════════════════════════════════════════
  //  ENERGY & EMISSION COLORS
  // ═══════════════════════════════════════════════════════════════
  
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color safetyOrange = Color(0xFFE88F1B);
  static const Color tealGlow = Color(0xFF00FFD1);
  static const Color orangeGlow = Color(0xFFFF8C00);
  static const Color darkTeal = Color(0xFF08615B);
  
  /// Particle colors
  static const Color particleCyan = Color(0xFF00FFD1);
  static const Color particleBlue = Color(0xFF60A5FA);
  static const Color particlePurple = Color(0xFFA78BFA);
  static const Color particleGold = Color(0xFFFFD700);
  static const Color particleWhite = Color(0xFFE2E8F0);
  static const Color particleMagenta = Color(0xFFFF00FF);
  static const Color particleGreen = Color(0xFF39FF14);
  
  // ═══════════════════════════════════════════════════════════════
  //  ✨ ULTRA-PREMIUM ACCENT PALETTE
  // ═══════════════════════════════════════════════════════════════
  
  /// Frosted Pearl — premium light accent
  static const Color frostedPearl = Color(0xFFF0F4FF);
  
  /// Lunar Silver — metallic premium
  static const Color lunarSilver = Color(0xFFD1D5DB);
  
  /// Quantum Violet — deep premium accent
  static const Color quantumViolet = Color(0xFF6D28D9);
  
  /// Premium Gold — richer than tier gold
  static const Color premiumGold = Color(0xFFD4AF37);
  
  /// Diamond White — purest premium white
  static const Color diamondWhite = Color(0xFFF8FBFF);
  
  /// Stellar Blue — deep cosmos accent
  static const Color stellarBlue = Color(0xFF1E40AF);
  
  /// Aurora Green — vivid success
  static const Color auroraGreen = Color(0xFF059669);
  
  /// Rose Quartz — premium warm accent
  static const Color roseQuartz = Color(0xFFF472B6);
  
  // ═══════════════════════════════════════════════════════════════
  //  📊 STATUS SYSTEM COLORS
  // ═══════════════════════════════════════════════════════════════
  
  /// Online — vibrant green with energy
  static const Color statusOnline = Color(0xFF22C55E);
  static const Color statusOnlineGlow = Color(0xFF4ADE80);
  
  /// Away — warm amber
  static const Color statusAway = Color(0xFFF59E0B);
  static const Color statusAwayGlow = Color(0xFFFBBF24);
  
  /// Busy — urgent red
  static const Color statusBusy = Color(0xFFEF4444);
  static const Color statusBusyGlow = Color(0xFFF87171);
  
  /// Offline — muted grey
  static const Color statusOffline = Color(0xFF6B7280);
  static const Color statusOfflineGlow = Color(0xFF9CA3AF);
  
  /// Success / Warning / Error
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningAmber = Color(0xFFFBBF24);
  static const Color errorRed = Color(0xFFEF4444);
  
  // ═══════════════════════════════════════════════════════════════
  //  GLASSMORPHISM SYSTEM
  // ═══════════════════════════════════════════════════════════════
  
  /// Glass layers — increasing opacity for depth
  static const Color glassUltraLight = Color(0x08FFFFFF);  // 3%
  static const Color glassLight = Color(0x0DFFFFFF);       // 5%
  static const Color glassMedium = Color(0x1AFFFFFF);      // 10%
  static const Color glassHeavy = Color(0x33FFFFFF);       // 20%
  
  /// Glass borders
  static const Color glassBorderSubtle = Color(0x0DFFFFFF);   // 5%
  static const Color glassBorder = Color(0x1AFFFFFF);         // 10%
  static const Color glassBorderBright = Color(0x33FFFFFF);   // 20%
  
  /// Glass darks (for overlays)
  static const Color glassDark = Color(0x40000000);        // 25% black
  static const Color glassDarkHeavy = Color(0x80000000);   // 50% black
  
  // Legacy alias
  static const Color glassWhite = glassLight;
  
  /// 🎮 Gamified glass variants
  static const Color obsidianGlass = Color(0x20080010);     // deep purple-black
  static const Color chromeGlass = Color(0x15B0C4DE);       // reflective steel
  static const Color plasmaCoreGlass = Color(0x1800FFD1);    // energized cyan

  // ═══════════════════════════════════════════════════════════════
  //  TEXT SYSTEM
  // ═══════════════════════════════════════════════════════════════
  
  static const Color textMain = Color(0xFFF8FAFC);     // Pure white-ish
  static const Color softWhite = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);    // Slate 400
  static const Color textLight = Color(0xFF475569);    // Slate 600
  static const Color textDim = Color(0xFF334155);      // Slate 700
  
  // ═══════════════════════════════════════════════════════════════
  //  BORDERS & DIVIDERS
  // ═══════════════════════════════════════════════════════════════
  
  static const Color border = Color(0xFF1E293B);       // Slate 800
  static const Color borderLight = Color(0xFF0F172A);  // Slate 900
  static const Color borderGlow = Color(0xFF00FFD1);   // Primary for active borders
  
  // ═══════════════════════════════════════════════════════════════
  //  SIGNATURE GRADIENTS
  // ═══════════════════════════════════════════════════════════════
  
  /// Primary plasma gradient — buttons, active indicators
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00FFD1), Color(0xFF00B392)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Aurora gradient — premium backgrounds, hero elements
  static const LinearGradient auroraGradient = LinearGradient(
    colors: [Color(0xFF00FFD1), Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Nebula gradient — deep space backgrounds
  static const LinearGradient nebulaGradient = LinearGradient(
    colors: [Color(0xFF020408), Color(0xFF0A0D14), Color(0xFF14082A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Header gradient — screen headers
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF030508), Color(0xFF080A0F), Color(0xFF0E121B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Energy gradient — for send buttons, CTAs
  static const LinearGradient energyGradient = LinearGradient(
    colors: [Color(0xFF00FFD1), Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Fire gradient — for alerts, secondary actions
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF2A6D), Color(0xFFFF6B9D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// CEO gold gradient
  static const LinearGradient ceoGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// 🎮 Cyber pulse gradient — electric cyan to plasma magenta
  static const LinearGradient cyberPulseGradient = LinearGradient(
    colors: [Color(0xFF00FFD1), Color(0xFF00D4FF), Color(0xFFFF00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// 🎮 Void storm gradient — deep violet to crimson
  static const LinearGradient voidStormGradient = LinearGradient(
    colors: [Color(0xFF7B2FFF), Color(0xFF4C0082), Color(0xFFDC143C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// 🎮 Dragon breath gradient — orange to crimson to dark
  static const LinearGradient dragonBreathGradient = LinearGradient(
    colors: [Color(0xFFFF6600), Color(0xFFDC143C), Color(0xFF4A0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// 🎮 Mythic gradient — full rainbow premium
  static const LinearGradient mythicGradient = LinearGradient(
    colors: [
      Color(0xFFFF00FF), Color(0xFF7B2FFF), Color(0xFF00D4FF),
      Color(0xFF00FFD1), Color(0xFFFFD700), Color(0xFFFF6600),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Shimmer loading gradient
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFF0A0D14), Color(0xFF1A1F2E), Color(0xFF0A0D14)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
  
  /// Card background gradient
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF111620), Color(0xFF0A0D14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Glass panel gradient — for energy panels
  static const LinearGradient glassPanelGradient = LinearGradient(
    colors: [Color(0x0DFFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Quantum Shift gradient — premium animated-ready multi-stop
  static const LinearGradient quantumShiftGradient = LinearGradient(
    colors: [
      Color(0xFF00FFD1), Color(0xFF6D28D9), Color(0xFFFF2A6D),
      Color(0xFFFFD700), Color(0xFF00FFD1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Midnight Aurora gradient — deep premium sky effect
  static const LinearGradient midnightAuroraGradient = LinearGradient(
    colors: [
      Color(0xFF020408), Color(0xFF0D1B2A), Color(0xFF1B2838),
      Color(0xFF0A1628), Color(0xFF020408),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Stellar Flare gradient — radial-friendly burst
  static const LinearGradient stellarFlareGradient = LinearGradient(
    colors: [Color(0xFF00FFD1), Color(0xFF1E40AF), Color(0xFF6D28D9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Frosted Glass gradient — for premium card borders
  static const LinearGradient frostedBorderGradient = LinearGradient(
    colors: [
      Color(0x40FFFFFF), Color(0x10FFFFFF),
      Color(0x05FFFFFF), Color(0x20FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Premium Sent Message gradient
  static const LinearGradient sentMessageGradient = LinearGradient(
    colors: [Color(0xFF00B392), Color(0xFF009980)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Premium Received Message glass
  static const LinearGradient receivedMessageGradient = LinearGradient(
    colors: [Color(0xFF111620), Color(0xFF0E121B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════════
  //  DEEP INDIGO (legacy compatibility)
  // ═══════════════════════════════════════════════════════════════
  static const Color deepIndigo = Color(0xFF1E1B4B);

  // ═══════════════════════════════════════════════════════════════
  //  ROLE ACCENT HELPER
  // ═══════════════════════════════════════════════════════════════
  
  /// Returns the accent color for a given role
  static Color accentForRole(String role) {
    switch (role.toLowerCase()) {
      case 'ceo':
        return ceoGold;
      case 'manager':
        return managerBlue;
      case 'staff':
        return staffTeal;
      case 'customer':
        return customerWarm;
      default:
        return primary;
    }
  }
  
  /// Returns the glow color for a given role
  static Color glowForRole(String role) {
    switch (role.toLowerCase()) {
      case 'ceo':
        return ceoGlow;
      case 'manager':
        return managerGlow;
      case 'staff':
        return staffGlow;
      case 'customer':
        return customerGlow;
      default:
        return primaryLight;
    }
  }
  
  /// Returns the gradient for a given role
  static LinearGradient gradientForRole(String role) {
    switch (role.toLowerCase()) {
      case 'ceo':
        return ceoGradient;
      case 'manager':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'staff':
        return const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'customer':
        return const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return primaryGradient;
    }
  }
}
