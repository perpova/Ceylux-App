import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

class NetworkErrorHandler {
  static final NetworkErrorHandler _instance = NetworkErrorHandler._();
  factory NetworkErrorHandler() => _instance;
  NetworkErrorHandler._();

  late Connectivity _connectivity;
  BuildContext? _lastContext;
  OverlayEntry? _overlayEntry;
  bool _isConnected = true;

  void initialize(BuildContext context) {
    _lastContext = context;
    _connectivity = Connectivity();
    _connectivity.onConnectivityChanged.listen((result) {
      _handleConnectivityChange(result);
    });
  }

  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    final isConnected = result != ConnectivityResult.none;

    if (isConnected && !_isConnected) {
      _isConnected = true;
      _hideNoInternetOverlay();
    } else if (!isConnected && _isConnected) {
      _isConnected = false;
      if (_lastContext != null) {
        _showNoInternetOverlay(_lastContext!);
      }
    }
  }

  void _showNoInternetOverlay(BuildContext context) {
    _hideNoInternetOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => _NoInternetOverlay(),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideNoInternetOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void updateContext(BuildContext context) {
    _lastContext = context;
  }

  void dispose() {
    _hideNoInternetOverlay();
  }
}

// ── No Internet Overlay Widget ─────────────────────────────────────────────
class _NoInternetOverlay extends StatefulWidget {
  @override
  State<_NoInternetOverlay> createState() => _NoInternetOverlayState();
}

class _NoInternetOverlayState extends State<_NoInternetOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.18),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Top accent bar ──
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.danger.withValues(alpha: 0.0),
                            AppColors.danger,
                            AppColors.danger.withValues(alpha: 0.0),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Lottie animation ──
                          Lottie.asset(
                            'assets/animations/no internet.json',
                            width: 200,
                            height: 200,
                            repeat: true,
                            fit: BoxFit.contain,
                          ),

                          // ── Pulsing status badge ──
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (_, __) => Opacity(
                              opacity: _pulseAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.danger.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.danger,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'OFFLINE',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.danger,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ── Title ──
                          Text(
                            'No Internet Connection',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textColor,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Subtitle ──
                          Text(
                            'Please check your Wi-Fi or mobile data\nand try again.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.muted,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Info chip ──
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sync_rounded,
                                    color: AppColors.danger, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'App will automatically reconnect when\nnetwork is available.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

