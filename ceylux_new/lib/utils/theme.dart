import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Global theme notifier for reactively switching between System, Light, and Dark modes
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

class AppColors {
  // Dynamically resolve whether dark mode is currently active
  static bool get isDark {
    try {
      final mode = themeNotifier.value;
      if (mode == ThemeMode.dark) return true;
      if (mode == ThemeMode.light) return false;
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    } catch (_) {
      return false;
    }
  }

  // Dynamic color getters that resolve based on theme mode
  static Color get bg => isDark ? const Color(0xFF0B1320) : const Color(0xFFF1F5F9);
  static Color get card => isDark ? const Color(0xFF111C2D) : const Color(0xFFFFFFFF);
  static Color get border => isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  static Color get textColor => isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1A2E42);
  static Color get muted => isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B8BAA);

  // App accent colors
  static const Color primary      = Color(0xFF125D9E);
  static const Color primaryLight = Color(0xFF77B9ED);
  static const Color gold         = Color(0xFFD4AF37);
  static const Color goldLight    = Color(0xFFE8C95A);
  static const Color goldDark     = Color(0xFFB8920A);
  static const Color steelBlue    = Color(0xFF87A9C2);
  static const Color cardHover    = Color(0xFFEEF4FB);
  static const Color success      = Color(0xFF2E7D5E);
  static const Color danger       = Color(0xFFB03A2E);
  static const Color warning      = Color(0xFFB8860B);
  static const Color accent       = Color(0xFF125D9E);
}

class AppTheme {
  // Compatibility getter
  static ThemeData get dark => lightTheme;

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    cardColor: const Color(0xFFFFFFFF),
    dividerColor: const Color(0xFFE2E8F0),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFF1F5F9),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge:   GoogleFonts.outfit(color: AppColors.primary),
      displayMedium:  GoogleFonts.outfit(color: AppColors.primary),
      displaySmall:   GoogleFonts.outfit(color: AppColors.primary),
      headlineLarge:  GoogleFonts.outfit(color: AppColors.primary),
      headlineMedium: GoogleFonts.outfit(color: AppColors.primary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF1A2E42),
      elevation: 0,
      shadowColor: Color(0x1A125D9E),
      iconTheme: IconThemeData(color: AppColors.primary),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFFFFFFFF),
      elevation: 1,
      shadowColor: Color(0x1A125D9E),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFF6B8BAA),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B1320),
    cardColor: const Color(0xFF111C2D),
    dividerColor: const Color(0xFF1E293B),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: Color(0xFF111C2D),
      background: Color(0xFF0B1320),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge:   GoogleFonts.outfit(color: AppColors.primaryLight),
      displayMedium:  GoogleFonts.outfit(color: AppColors.primaryLight),
      displaySmall:   GoogleFonts.outfit(color: AppColors.primaryLight),
      headlineLarge:  GoogleFonts.outfit(color: AppColors.primaryLight),
      headlineMedium: GoogleFonts.outfit(color: AppColors.primaryLight),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Color(0xFFF3F4F6),
      elevation: 0,
      shadowColor: Color(0x1A000000),
      iconTheme: IconThemeData(color: AppColors.primaryLight),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E293B),
      elevation: 1,
      shadowColor: Color(0x1A000000),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E293B),
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: Color(0xFF94A3B8),
    ),
  );
}

class CustomerTier {
  final String label;
  final int minSpent;
  final int maxSpent;
  final int discount;
  final Color color;
  final String badge;

  const CustomerTier({required this.label, required this.minSpent,
    required this.maxSpent, required this.discount,
    required this.color, required this.badge});
}

class Tiers {
  static const bronze   = CustomerTier(label: 'Bronze',   minSpent: 0,      maxSpent: 24999,     discount: 0,  color: Color(0xFFCD7F32), badge: '🥉');
  static const silver   = CustomerTier(label: 'Silver',   minSpent: 25000,  maxSpent: 49999,     discount: 5,  color: Color(0xFF87A9C2), badge: '🥈');
  static const gold     = CustomerTier(label: 'Gold',     minSpent: 50000,  maxSpent: 99999,     discount: 10, color: Color(0xFFD4AF37), badge: '🥇');
  static const platinum = CustomerTier(label: 'Platinum', minSpent: 100000, maxSpent: 999999999, discount: 15, color: Color(0xFF125D9E), badge: '💎');

  static CustomerTier getTier(int spent) {
    if (spent >= 100000) return platinum;
    if (spent >= 50000)  return gold;
    if (spent >= 25000)  return silver;
    return bronze;
  }
}

// Loyalty Tier Helper - Calculates discount based on 3 metrics
class LoyaltyTierHelper {
  static int calculateDiscount({
    required int totalOrders,
    required int totalSpent,
    required double ownerRating,
    required int tierOneOrders,
    required int tierOneSpent,
    required double tierOneRating,
    required int tierOneDiscount,
    required int tierTwoOrders,
    required int tierTwoSpent,
    required double tierTwoRating,
    required int tierTwoDiscount,
    required int tierThreeOrders,
    required int tierThreeSpent,
    required double tierThreeRating,
    required int tierThreeDiscount,
  }) {
    // Check Tier 3 (Highest)
    if (totalOrders >= tierThreeOrders &&
        totalSpent >= tierThreeSpent &&
        ownerRating >= tierThreeRating) {
      return tierThreeDiscount;
    }

    // Check Tier 2
    if (totalOrders >= tierTwoOrders &&
        totalSpent >= tierTwoSpent &&
        ownerRating >= tierTwoRating) {
      return tierTwoDiscount;
    }

    // Check Tier 1
    if (totalOrders >= tierOneOrders &&
        totalSpent >= tierOneSpent &&
        ownerRating >= tierOneRating) {
      return tierOneDiscount;
    }

    // No tier
    return 0;
  }

  // Get tier name
  static String getTierName({
    required int totalOrders,
    required int totalSpent,
    required double ownerRating,
    required int tierOneOrders,
    required int tierOneSpent,
    required double tierOneRating,
    required int tierOneDiscount,
    required int tierTwoOrders,
    required int tierTwoSpent,
    required double tierTwoRating,
    required int tierTwoDiscount,
    required int tierThreeOrders,
    required int tierThreeSpent,
    required double tierThreeRating,
    required int tierThreeDiscount,
  }) {
    int discount = calculateDiscount(
      totalOrders: totalOrders,
      totalSpent: totalSpent,
      ownerRating: ownerRating,
      tierOneOrders: tierOneOrders,
      tierOneSpent: tierOneSpent,
      tierOneRating: tierOneRating,
      tierOneDiscount: tierOneDiscount,
      tierTwoOrders: tierTwoOrders,
      tierTwoSpent: tierTwoSpent,
      tierTwoRating: tierTwoRating,
      tierTwoDiscount: tierTwoDiscount,
      tierThreeOrders: tierThreeOrders,
      tierThreeSpent: tierThreeSpent,
      tierThreeRating: tierThreeRating,
      tierThreeDiscount: tierThreeDiscount,
    );

    switch (discount) {
      case int d when d >= tierThreeDiscount:
        return '💎 Platinum';
      case int d when d >= tierTwoDiscount:
        return '🥇 Gold';
      case int d when d >= tierOneDiscount:
        return '🥈 Silver';
      default:
        return '🥉 Bronze';
    }
  }
}

const List<String> allSizes  = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
const List<String> kidsSizes = ['2Y', '4Y', '6Y', '8Y', '10Y', '12Y'];