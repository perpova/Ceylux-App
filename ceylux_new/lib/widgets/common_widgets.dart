import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import '../utils/theme.dart';

// ── Primary Button ─────────────────────────────────────────────────────────
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isSmall;
  final bool isOutlined;

  const GoldButton({super.key, required this.label, required this.onTap,
    this.icon, this.isSmall = false, this.isOutlined = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 18, vertical: isSmall ? 8 : 12),
        decoration: BoxDecoration(
          gradient: isOutlined ? null : const LinearGradient(
            colors: [AppColors.primary, Color(0xFF0D4A82)],
          ),
          border: isOutlined ? Border.all(color: AppColors.primary, width: 1.2) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isOutlined ? null : [
            BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isSmall ? 14 : 16, color: isOutlined ? AppColors.primary : Colors.white),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(
              fontSize: isSmall ? 11 : 13,
              fontWeight: FontWeight.bold,
              color: isOutlined ? AppColors.primary : Colors.white,
              letterSpacing: 0.3,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;

  const StatCard({super.key, required this.label, required this.value,
    this.icon, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final Color color = accentColor ?? AppColors.primary;
    final bool isDark = AppColors.isDark;
    
    late LinearGradient gradient;
    late Color borderColor;
    late Color textColor;
    late Color labelColor;
    late Color iconBgColor;

    if (isDark) {
      // Dark Mode VIBRANT Gradient Card Styles
      if (color == AppColors.primary || color == AppColors.accent) {
        // Vibrant Blue Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFF60A5FA).withOpacity(0.25);
        textColor = const Color(0xFF60A5FA);
        iconBgColor = const Color(0xFF60A5FA).withOpacity(0.15);
      } else if (color == AppColors.success) {
        // Vibrant Green Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF0F2F1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFF34D399).withOpacity(0.25);
        textColor = const Color(0xFF34D399);
        iconBgColor = const Color(0xFF34D399).withOpacity(0.15);
      } else if (color == AppColors.warning) {
        // Vibrant Orange Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFF3F1F0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFFFB923C).withOpacity(0.25);
        textColor = const Color(0xFFFB923C);
        iconBgColor = const Color(0xFFFB923C).withOpacity(0.15);
      } else if (color == AppColors.gold) {
        // Vibrant Gold/Yellow Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF78350F), Color(0xFF3C1D0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFFFCD34D).withOpacity(0.25);
        textColor = const Color(0xFFFCD34D);
        iconBgColor = const Color(0xFFFCD34D).withOpacity(0.15);
      } else {
        // Fallback Purple/Indigo Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF2E1065)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFFC084FC).withOpacity(0.25);
        textColor = const Color(0xFFC084FC);
        iconBgColor = const Color(0xFFC084FC).withOpacity(0.15);
      }
      labelColor = textColor.withOpacity(0.6);
    } else {
      // Light Mode VIBRANT Gradient Card Styles
      if (color == AppColors.primary || color == AppColors.accent) {
        // Vibrant Blue Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFFDEEAFF), Color(0xFFF0F5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFF3B82F6).withOpacity(0.2);
        textColor = const Color(0xFF1E40AF);
        iconBgColor = const Color(0xFF3B82F6).withOpacity(0.12);
      } else if (color == AppColors.success) {
        // Vibrant Green Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFFD1FAE5), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFF10B981).withOpacity(0.2);
        textColor = const Color(0xFF065F46);
        iconBgColor = const Color(0xFF10B981).withOpacity(0.12);
      } else if (color == AppColors.warning) {
        // Vibrant Orange Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFFFEDDD5), Color(0xFFFEF2F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFFF97316).withOpacity(0.2);
        textColor = const Color(0xFF7C2D12);
        iconBgColor = const Color(0xFFF97316).withOpacity(0.12);
      } else if (color == AppColors.gold) {
        // Vibrant Gold/Yellow Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFFFEF08A), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFFFBBF24).withOpacity(0.3);
        textColor = const Color(0xFFB45309);
        iconBgColor = const Color(0xFFFBBF24).withOpacity(0.15);
      } else {
        // Fallback Purple/Indigo Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFFA78BFA).withOpacity(0.3);
        textColor = const Color(0xFF6D28D9);
        iconBgColor = const Color(0xFFA78BFA).withOpacity(0.15);
      }
      labelColor = textColor.withOpacity(0.65);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: icon != null
                  ? Icon(
                      icon,
                      size: 18,
                      color: textColor,
                    )
                  : const SizedBox(width: 18, height: 18),
              ),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered': color = AppColors.success; break;
      case 'processing': color = AppColors.warning; break;
      default: color = AppColors.muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('● $status', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Tier Badge ────────────────────────────────────────────────────────────
class TierBadge extends StatelessWidget {
  final int totalSpent;
  const TierBadge({super.key, required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    final tier = Tiers.getTier(totalSpent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tier.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tier.color.withOpacity(0.4)),
      ),
      child: Text('${tier.badge} ${tier.label}',
        style: TextStyle(fontSize: 10, color: tier.color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── User Avatar ───────────────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  final Color? borderColor;

  const UserAvatar({super.key, required this.name, this.photoUrl,
    this.size = 40, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight.withOpacity(0.2),
        border: Border.all(color: borderColor ?? AppColors.border, width: 2),
      ),
      child: ClipOval(
        child: photoUrl != null
          ? CachedNetworkImage(imageUrl: photoUrl!, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _initial())
          : _initial(),
      ),
    );
  }

  Widget _initial() => Center(child: Text(
    name.isNotEmpty ? name[0].toUpperCase() : '?',
    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold,
      fontSize: size * 0.38, fontFamily: 'Outfit'),
  ));
}

// ── Section Title ─────────────────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle({super.key, required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: GoogleFonts.outfit(fontSize: 20, color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: -0.1)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Ceylux Card ───────────────────────────────────────────────────────────
class CeyluxCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final LinearGradient? gradient;

  const CeyluxCard({super.key, required this.child, this.onTap, this.padding, this.gradient});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? AppColors.card : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── Text Field ────────────────────────────────────────────────────────────
class GoldTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? hint;

  const GoldTextField({super.key, required this.label, required this.controller,
    this.keyboardType, this.maxLines = 1, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: AppColors.textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// ── Action Button with Loading Animation ──────────────────────────────────
class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final Color? buttonColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final bool isOutlined;
  final double fontSize;
  final double padding;
  // Backward compatibility
  final Color? color;

  const ActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.buttonColor,
    this.textColor,
    this.icon,
    this.width,
    this.isOutlined = false,
    this.fontSize = 12,
    this.padding = 11,
    this.color, // deprecated, use buttonColor instead
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = buttonColor ?? color ?? AppColors.gold;
    
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: padding, horizontal: 16),
        decoration: BoxDecoration(
          color: isOutlined 
              ? Colors.transparent 
              : bgColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isOutlined 
                ? bgColor.withOpacity(0.5) 
                : bgColor.withOpacity(0.3),
            width: isOutlined ? 1.5 : 1,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(bgColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: bgColor, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: bgColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Reusable Shimmer Loading Screen ────────────────────────────────────────
class ShimmerLoadingScreen extends StatelessWidget {
  final String? message;
  final Duration duration;

  const ShimmerLoadingScreen({
    super.key,
    this.message = 'Loading...',
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with Shimmer Effect
              Shimmer.fromColors(
                baseColor: AppColors.gold.withOpacity(0.3),
                highlightColor: AppColors.gold.withOpacity(0.8),
                period: duration,
                child: Container(
                  width: 280, height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 0),
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/images/ceylux_logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // CEYLUX Premium Text with Shimmer
              Shimmer.fromColors(
                baseColor: AppColors.gold.withOpacity(0.4),
                highlightColor: AppColors.gold.withOpacity(0.9),
                period: duration,
                child: Column(
                  children: [
                    Text(
                      'CEYLUX',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PREMIUM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold.withOpacity(0.7),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading Indicator
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
// ── Customer Rating Bar ────────────────────────────────────────────────────
class CustomerRatingBar extends StatelessWidget {
  final String label;
  final double percentage; // 0.0 to 100.0
  final String unit;
  final Color barColor;
  final VoidCallback? onTap;

  const CustomerRatingBar({
    super.key,
    required this.label,
    required this.percentage,
    required this.unit,
    required this.barColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: barColor.withOpacity(0.3), width: 0.8),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress Bar with gradient
            Container(
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.bg,
                border: Border.all(color: barColor.withOpacity(0.2)),
              ),
              child: Stack(
                children: [
                  // Background
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.bg,
                    ),
                  ),
                  // Progress fill
                  FractionallySizedBox(
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            barColor,
                            barColor.withOpacity(0.7),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  // Text overlay
                  Center(
                    child: Text(
                      unit,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: percentage > 50 ? Colors.white : AppColors.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}