import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary      = Color(0xFF125D9E);
  static const Color primaryLight = Color(0xFF77B9ED);
  static const Color gold         = Color(0xFFD4AF37);
  static const Color goldLight    = Color(0xFFE8C95A);
  static const Color goldDark     = Color(0xFFB8920A);
  static const Color steelBlue    = Color(0xFF87A9C2);
  static const Color bg           = Color(0xFFF5F2EE);
  static const Color card         = Color(0xFFFFFFFF);
  static const Color cardHover    = Color(0xFFEEF4FB);
  static const Color border       = Color(0xFFD0E4F5);
  static const Color textColor    = Color(0xFF1A2E42);
  static const Color muted        = Color(0xFF6B8BAA);
  static const Color success      = Color(0xFF2E7D5E);
  static const Color danger       = Color(0xFFB03A2E);
  static const Color warning      = Color(0xFFB8860B);
  static const Color accent       = Color(0xFF125D9E);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.card,
      background: AppColors.bg,
    ),
    textTheme: GoogleFonts.montserratTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge:   GoogleFonts.playfairDisplay(color: AppColors.primary),
      displayMedium:  GoogleFonts.playfairDisplay(color: AppColors.primary),
      displaySmall:   GoogleFonts.playfairDisplay(color: AppColors.primary),
      headlineLarge:  GoogleFonts.playfairDisplay(color: AppColors.primary),
      headlineMedium: GoogleFonts.playfairDisplay(color: AppColors.primary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.textColor,
      elevation: 0,
      shadowColor: Color(0x1A125D9E),
      iconTheme: IconThemeData(color: AppColors.primary),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.card,
      elevation: 1,
      shadowColor: Color(0x1A125D9E),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
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

const List<String> allSizes  = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
const List<String> kidsSizes = ['2Y', '4Y', '6Y', '8Y', '10Y', '12Y'];