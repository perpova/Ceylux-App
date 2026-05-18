import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      title: 'Ceylux Fashion',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const SplashGate(),
      routes: {'/home': (_) => const HomeShell()},
    );
  }
}

// ── Splash — token check ───────────────────────────────────────────────────
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeShell()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        ]),
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
        content: const Text('Sign out කරන්නද?', style: TextStyle(color: AppColors.muted)),
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
                Text('FASHION', style: GoogleFonts.montserrat(fontSize: 8, color: AppColors.muted, letterSpacing: 3, fontWeight: FontWeight.w500)),
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