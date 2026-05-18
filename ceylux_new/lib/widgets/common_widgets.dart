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
          border: isOutlined ? Border.all(color: AppColors.primary) : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isOutlined ? null : [
            BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3)),
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
              fontWeight: FontWeight.w600,
              color: isOutlined ? AppColors.primary : Colors.white,
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
  final String icon;
  final Color? accentColor;

  const StatCard({super.key, required this.label, required this.value,
    required this.icon, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 3, decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, AppColors.primaryLight]),
                borderRadius: BorderRadius.circular(2),
              ), margin: const EdgeInsets.only(bottom: 10)),
              Text(value, style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: 0.8, fontWeight: FontWeight.w500)),
            ],
          ),
          Positioned(right: 0, top: 8, child: Text(icon, style: const TextStyle(fontSize: 22, color: Color(0x33125D9E)))),
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
      fontSize: size * 0.38, fontFamily: 'PlayfairDisplay'),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: GoogleFonts.playfairDisplay(fontSize: 22, color: AppColors.primary)),
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: padding ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
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
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}