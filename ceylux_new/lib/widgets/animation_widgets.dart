import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

// ── Loading Animation Widget ──────────────────────────────────────────────
class LoadingAnimation extends StatelessWidget {
  final String? message;
  final double size;
  
  const LoadingAnimation({
    super.key,
    this.message,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/Loading animation blue.json',
            height: size,
            width: size,
            repeat: true,
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Error Animation Widget ────────────────────────────────────────────────
class ErrorAnimation extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final double size;
  
  const ErrorAnimation({
    super.key,
    this.title = 'Oops! Error',
    this.message = 'Something went wrong. Please try again.',
    this.onRetry,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/404 Page Not Found.json',
            height: size,
            width: size,
            repeat: true,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0D4A82)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── No Data Animation Widget ──────────────────────────────────────────────
class NoDataAnimation extends StatelessWidget {
  final String message;
  final double size;
  final VoidCallback? onAction;
  final String? actionLabel;
  
  const NoDataAnimation({
    super.key,
    this.message = 'No data found',
    this.size = 150,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/No Data Found.json',
            height: size,
            width: size,
            repeat: true,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0D4A82)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Searching Animation Widget ────────────────────────────────────────────
class SearchingAnimation extends StatelessWidget {
  final double size;
  
  const SearchingAnimation({
    super.key,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animations/serching.json',
        height: size,
        width: size,
        repeat: true,
      ),
    );
  }
}

// ── Success Animation Widget ──────────────────────────────────────────────
class SuccessAnimation extends StatelessWidget {
  final String? message;
  final double size;
  final Duration duration;
  final VoidCallback? onComplete;
  
  const SuccessAnimation({
    super.key,
    this.message,
    this.size = 150,
    this.duration = const Duration(seconds: 2),
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    Future.delayed(duration, () {
      onComplete?.call();
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/Money.json',
            height: size,
            width: size,
            repeat: false,
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Assistant Bot Animation Widget ────────────────────────────────────────
class AssistantBotAnimation extends StatelessWidget {
  final String? message;
  final double size;
  
  const AssistantBotAnimation({
    super.key,
    this.message,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/Assistant-Bot.json',
            height: size,
            width: size,
            repeat: true,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                message!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
