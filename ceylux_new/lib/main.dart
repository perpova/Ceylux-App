import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ota_update/ota_update.dart';
import 'package:shimmer/shimmer.dart';
import 'services/update_service.dart';
import 'utils/theme.dart';
import 'models/stock_item.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_service.dart';
import 'widgets/profile_dialog.dart';

// Global theme notifier for reactively switching between System, Light, and Dark modes
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().seedInitialData();

  // Load saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode') ?? 'system';
  if (savedTheme == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else if (savedTheme == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else {
    themeNotifier.value = ThemeMode.system;
  }

  runApp(const CeyluxApp());
}

class CeyluxApp extends StatelessWidget {
  const CeyluxApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Ceylux CLOTHING',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          debugShowCheckedModeBanner: false,
          home: const SplashGate(),
          routes: {'/home': (_) => const HomeShell()},
        );
      },
    );
  }
}

// ── Splash — token check & In-App Update ────────────────────────────────────
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _checkingUpdate = true;
  bool _updateAvailable = false;
  String _latestVersion = '';
  String? _downloadUrl;
  String _changelog = '';
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = 'Initializing...';
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    // Show splash screen for at least 3.5 seconds
    await Future.delayed(const Duration(milliseconds: 3500));

    if (Platform.isAndroid) {
      setState(() {
        _statusMessage = 'Checking for updates...';
      });

      final updateInfo = await UpdateService().checkForUpdate();

      if (updateInfo.hasUpdate && updateInfo.downloadUrl != null) {
        final shouldSkip = await UpdateService().shouldSkipUpdate(updateInfo.latestVersion);
        if (shouldSkip) {
          _proceedToApp();
          return;
        }

        if (!mounted) return;
        setState(() {
          _checkingUpdate = false;
          _updateAvailable = true;
          _latestVersion = updateInfo.latestVersion;
          _downloadUrl = updateInfo.downloadUrl;
          _changelog = updateInfo.changelog ?? 'No release notes provided.';
        });
        return;
      }
    }

    _proceedToApp();
  }

  Future<void> _proceedToApp() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeShell()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  void _startUpdate() {
    if (_downloadUrl == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusMessage = 'Downloading update...';
    });

    UpdateService().markUpdateStarted(_latestVersion);
    UpdateService().incrementUpdateAttemptCount();

    _otaSubscription?.cancel();
    _otaSubscription = UpdateService().startOtaUpdate(_downloadUrl!).listen(
      (OtaEvent event) {
        if (!mounted) return;
        switch (event.status) {
          case OtaStatus.DOWNLOADING:
            final progress = (double.tryParse(event.value ?? '0') ?? 0.0) / 100.0;
            setState(() {
              _downloadProgress = progress;
              _statusMessage = 'Downloading update...';
            });
            break;
          case OtaStatus.INSTALLING:
            setState(() {
              _statusMessage = 'Installing update...';
            });
            break;
          case OtaStatus.ALREADY_RUNNING_ERROR:
            _showError('An update process is already running.');
            break;
          case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            _showError('Permission not granted to install packages.');
            break;
          case OtaStatus.DOWNLOAD_ERROR:
            _showError('Download error. Please check your internet connection.');
            break;
          case OtaStatus.CHECKSUM_ERROR:
            _showError('Integrity check failed. Please try again.');
            break;
          case OtaStatus.INTERNAL_ERROR:
            _showError('Internal installation error.');
            break;
          default:
            _showError('An unexpected error occurred during update.');
            break;
        }
      },
      onError: (err) {
        if (!mounted) return;
        _showError('Update failed: $err');
      },
      onDone: () async {
        if (!mounted) return;
        _proceedToApp();
      },
    );
  }

  void _showError(String message) {
    setState(() {
      _isDownloading = false;
      _statusMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Premium Loading Screen
          if (!_updateAvailable && _checkingUpdate)
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with Shimmer Effect
                    Shimmer.fromColors(
                        baseColor: AppColors.gold.withOpacity(0.3),
                        highlightColor: AppColors.gold.withOpacity(0.8),
                        period: const Duration(milliseconds: 2000),
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
                      period: const Duration(milliseconds: 2500),
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
                            'CLOTHING',
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
                    
                    // Glowing Circular Progress Indicator
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated rotating gradient border
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 2),
                            onEnd: () {},
                            builder: (context, value, child) {
                              return Transform.rotate(
                                angle: value * 6.28,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Inner circle
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bg.withOpacity(0.5),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          // Pulsing center
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(seconds: 1),
                            onEnd: () {},
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _statusMessage == 'Checking for updates...' ? '...' : '∞',
                                      style: GoogleFonts.outfit(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Status Text with Animation
                    Text(
                      _statusMessage,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Original UI for Update Available
          else if (_updateAvailable)
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 260, height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset('assets/images/ceylux_logo.png', fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('CEYLUX', style: GoogleFonts.outfit(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 3)),
                  ],
                ),
              ),
            ),

          if (_updateAvailable)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.system_update_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update Available',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Version $_latestVersion is ready to install',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "What's New:",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border.withOpacity(0.5)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _changelog,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textColor.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isDownloading) ...[
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _statusMessage,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(_downloadProgress * 100).toInt()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _downloadProgress,
                              backgroundColor: AppColors.border,
                              color: AppColors.primary,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _proceedToApp();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Skip Now',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _startUpdate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Update Now',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Home Shell ─────────────────────────────────────────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  String _userName = '';
  String? _profileImagePath;

  final _navItems = const [
    {'icon': Icons.home_rounded,         'label': 'Home'},
    {'icon': Icons.inventory_2_rounded,  'label': 'Stock'},
    {'icon': Icons.shopping_bag_rounded, 'label': 'Orders'},
    {'icon': Icons.people_rounded,       'label': 'Clients'},
    {'icon': Icons.settings_rounded,     'label': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _profileImagePath = prefs.getString('profileImagePath');
    });
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => ProfileDialog(
        userName: _userName,
        onProfileUpdated: () {
          _loadUser();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        shadowColor: AppColors.primary.withOpacity(0.1),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset('assets/images/ceylux_logo.png', width: 140, height: 44, fit: BoxFit.contain),
          ),
        ),
        actions: [
          Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
            StreamBuilder<List<StockItem>>(
              stream: ApiService().stockStream(),
              builder: (context, snap) {
                final low = (snap.data ?? []).where((i) => i.isLowStock || i.isOutOfStock).length;
                if (low == 0) return const SizedBox.shrink();
                return Positioned(top: 6, right: 6,
                  child: Container(width: 16, height: 16,
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    child: Center(child: Text('$low',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)))));
              },
            ),
          ]),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: GestureDetector(
              onTap: _showProfileDialog,
              child: Row(children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    image: _profileImagePath != null && File(_profileImagePath!).existsSync()
                        ? DecorationImage(
                            image: FileImage(File(_profileImagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profileImagePath == null || !File(_profileImagePath!).existsSync()
                      ? Center(
                          child: Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _userName.split(' ')[0],
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          DashboardScreen(),
          StockScreen(),
          OrdersScreen(),
          CustomersScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -3))],
        ),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final isActive = _tab == i;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_navItems[i]['icon'] as IconData,
                      color: isActive ? AppColors.primary : AppColors.muted, size: 22),
                    const SizedBox(height: 3),
                    Text(_navItems[i]['label'] as String,
                      style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.primary : AppColors.muted)),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 4 : 0, height: isActive ? 4 : 0,
                      decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                    ),
                  ]),
                ),
              ));
            }),
          ),
        )),
      ),
    );
  }
}