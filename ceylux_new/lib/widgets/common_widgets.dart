import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
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
      // Dark Mode Gradient Card Styles (Matching Dark Mode Screenshot)
      if (color == AppColors.primary || color == AppColors.accent) {
        // Blue Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF132035), Color(0xFF0B1422)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFF3B82F6).withOpacity(0.18);
        textColor = const Color(0xFF3B82F6);
        iconBgColor = const Color(0xFF3B82F6).withOpacity(0.1);
      } else if (color == AppColors.success) {
        // Green Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF11261C), Color(0xFF0A1811)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFF10B981).withOpacity(0.18);
        textColor = const Color(0xFF10B981);
        iconBgColor = const Color(0xFF10B981).withOpacity(0.1);
      } else if (color == AppColors.warning) {
        // Orange Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF2C1E15), Color(0xFF1B120C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFFF97316).withOpacity(0.18);
        textColor = const Color(0xFFF97316);
        iconBgColor = const Color(0xFFF97316).withOpacity(0.1);
      } else {
        // Gold/Yellow Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFF2A2315), Color(0xFF1A150C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFFF59E0B).withOpacity(0.18);
        textColor = const Color(0xFFF59E0B);
        iconBgColor = const Color(0xFFF59E0B).withOpacity(0.1);
      }
      labelColor = textColor.withOpacity(0.5);
    } else {
      // Light Mode Pastel Card Styles (Matching Light Mode Screenshot)
      if (color == AppColors.primary || color == AppColors.accent) {
        // Light Blue Pastel Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFFE2EAF3), Color(0xFFEEF3F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFF3B82F6).withOpacity(0.15);
        textColor = const Color(0xFF2563EB);
        iconBgColor = const Color(0xFF3B82F6).withOpacity(0.08);
      } else if (color == AppColors.success) {
        // Light Green Pastel Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFFE6F4EA), Color(0xFFF4FBF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFF10B981).withOpacity(0.15);
        textColor = const Color(0xFF059669);
        iconBgColor = const Color(0xFF10B981).withOpacity(0.08);
      } else if (color == AppColors.warning) {
        // Light Orange Pastel Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFFFFEDD5), Color(0xFFFFF8F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFFF97316).withOpacity(0.15);
        textColor = const Color(0xFFEA580C);
        iconBgColor = const Color(0xFFF97316).withOpacity(0.08);
      } else {
        // Light Gold/Yellow Pastel Gradient
        gradient = const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFFF59E0B).withOpacity(0.15);
        textColor = const Color(0xFFD97706);
        iconBgColor = const Color(0xFFF59E0B).withOpacity(0.08);
      }
      labelColor = textColor.withOpacity(0.6);
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

  const CeyluxCard({super.key, required this.child, this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
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