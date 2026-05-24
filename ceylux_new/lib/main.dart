import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ota_update/ota_update.dart';
import 'services/update_service.dart';
import 'utils/theme.dart';
import 'models/stock_item.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/notifications_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().seedInitialData();
  runApp(const CeyluxApp());
}

class CeyluxApp extends StatelessWidget {
  const CeyluxApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceylux CLOTHING',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const SplashGate(),
      routes: {'/home': (_) => const HomeShell()},
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
    // 1. Brief pause for branding animation feel
    await Future.delayed(const Duration(milliseconds: 800));

    // 2. Perform updater checks on Android devices
    if (Platform.isAndroid) {
      setState(() {
        _statusMessage = 'Checking for updates...';
      });

      final updateInfo = await UpdateService().checkForUpdate();

      if (updateInfo.hasUpdate && updateInfo.downloadUrl != null) {
        // Check if we should skip this update (already attempted or installed)
        final shouldSkip = await UpdateService().shouldSkipUpdate(updateInfo.latestVersion);
        if (shouldSkip) {
          // Skip to app if this update was already tried
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
        return; // Pause the splash flow and show the interactive update view
      }
    }

    // 3. Fall through to normal app entry if no updates or not Android
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

    // Mark this version as pending
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
        // onDone fires when the APK download is complete and the install
        // intent has been sent to Android's system installer.
        // We proceed to the app so the user isn't stuck — the installer
        // dialog will appear on top of the app automatically.
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
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
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
          // Background/Splash Brand Content
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _updateAvailable ? 0.25 : 1.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF0D4A82)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: const Center(child: Text('C', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(height: 16),
                  Text('CEYLUX', style: GoogleFonts.playfairDisplay(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 3)),
                  const SizedBox(height: 32),
                  if (!_updateAvailable && _checkingUpdate) ...[
                    const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Custom Glassmorphic Premium Update Card Overlay
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
                    // Header Section
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
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Version $_latestVersion is ready to install',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 16),

                    // Changelog Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "What's New:",
                        style: GoogleFonts.montserrat(
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
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: AppColors.textColor.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Progress Section vs Action Buttons
                    if (_isDownloading) ...[
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _statusMessage,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(_downloadProgress * 100).toInt()}%',
                                style: GoogleFonts.montserrat(
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
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Skip Now',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
                                style: GoogleFonts.montserrat(
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

  final _pages = const [
    DashboardScreen(), StockScreen(), OrdersScreen(),
    CustomersScreen(), NotificationsScreen(),
  ];

  final _navItems = const [
    {'icon': Icons.home_rounded,         'label': 'Home'},
    {'icon': Icons.inventory_2_rounded,  'label': 'Stock'},
    {'icon': Icons.shopping_bag_rounded, 'label': 'Orders'},
    {'icon': Icons.people_rounded,       'label': 'Clients'},
    {'icon': Icons.notifications_rounded,'label': 'Alerts'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('userName') ?? 'User');
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Logout?', style: TextStyle(color: AppColors.textColor)),
        content: const Text('Sign out of your account?', style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        shadowColor: AppColors.primary.withOpacity(0.1),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF0D4A82)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('C', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CEYLUX', style: GoogleFonts.playfairDisplay(fontSize: 22, color: AppColors.primary, letterSpacing: 1, fontWeight: FontWeight.bold)),
                Text('CLOTHING', style: GoogleFonts.montserrat(fontSize: 8, color: AppColors.muted, letterSpacing: 3, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              onPressed: () => setState(() => _tab = 4),
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
          // User avatar + logout
          GestureDetector(
            onTap: _logout,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: Center(child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  )),
                ),
                const SizedBox(width: 6),
                Text(
                  _userName.split(' ')[0],
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
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
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: const Border(top: BorderSide(color: AppColors.border)),
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
                      style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600,
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