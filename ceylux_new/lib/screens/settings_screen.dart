import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../services/update_service.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'User';
  String _userRole = 'Store Manager';
  bool _checkingUpdate = false;
  late ThemeMode _currentThemeMode;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _currentThemeMode = themeNotifier.value;
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Ceylux Associate';
      _userRole = _userName.toLowerCase().contains('admin') ? 'Administrator' : 'Store Associate';
    });
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    setState(() {
      _currentThemeMode = mode;
      themeNotifier.value = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final updateInfo = await UpdateService().checkForUpdate();
    
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    if (updateInfo.hasUpdate && updateInfo.downloadUrl != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.card,
          title: Text(
            'New Update Available',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textColor),
          ),
          content: Text(
            'Version ${updateInfo.latestVersion} is ready to install.\n\nNotes:\n${updateInfo.changelog ?? "Bug fixes and performance improvements."}',
            style: GoogleFonts.plusJakartaSans(color: AppColors.muted, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.plusJakartaSans(color: AppColors.muted, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Update started in background...'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Update Now', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Your app is fully up-to-date!',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textColor),
        ),
        content: Text(
          'Are you sure you want to log out of your Ceylux Clothing account?',
          style: GoogleFonts.plusJakartaSans(color: AppColors.muted, height: 1.4, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Log Out', style: GoogleFonts.plusJakartaSans(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gorgeous Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF093961)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _userRole.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Mode Selector (Replaces App Configuration)
          Text(
            'APPEARANCE THEME',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.muted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          CeyluxCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildThemeSelectorItem(
                  mode: ThemeMode.system,
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                ),
                const SizedBox(width: 8),
                _buildThemeSelectorItem(
                  mode: ThemeMode.light,
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                ),
                const SizedBox(width: 8),
                _buildThemeSelectorItem(
                  mode: ThemeMode.dark,
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // System Section
          Text(
            'SYSTEM & DATABASE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.muted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          CeyluxCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsRow(
                  icon: Icons.cloud_done_rounded,
                  iconColor: AppColors.success,
                  title: 'Database Connector',
                  subtitle: 'MySQL API Server synced',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Text(
                      'ONLINE',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.success,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.border),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) {
                    final ver = snap.data?.version ?? '1.0.1';
                    final build = snap.data?.buildNumber ?? '2';
                    return _buildSettingsRow(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.steelBlue,
                      title: 'Build Version',
                      subtitle: 'Production Version',
                      trailing: Text(
                        'v$ver+$build',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: AppColors.border),
                _buildSettingsRow(
                  icon: Icons.system_update_rounded,
                  iconColor: AppColors.primary,
                  title: 'Check for Updates',
                  subtitle: 'Query latest app update release',
                  onTap: _checkingUpdate ? null : _checkUpdate,
                  trailing: _checkingUpdate
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account Actions
          Text(
            'ACCOUNT ACTIONS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.muted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          CeyluxCard(
            padding: EdgeInsets.zero,
            child: _buildSettingsRow(
              icon: Icons.logout_rounded,
              iconColor: AppColors.danger,
              title: 'Sign Out Account',
              subtitle: 'Disconnect and clear active credentials',
              onTap: _logout,
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelectorItem({
    required ThemeMode mode,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _currentThemeMode == mode;
    final bool isAppDark = AppColors.isDark;

    Color bg;
    Color border;
    Color contentColor;

    if (isSelected) {
      bg = AppColors.primary;
      border = AppColors.primary;
      contentColor = Colors.white;
    } else {
      bg = isAppDark ? const Color(0xFF1E293B) : const Color(0xFFF5F2EE);
      border = AppColors.border;
      contentColor = AppColors.textColor;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _changeTheme(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.5),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: contentColor, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: title.contains('Sign Out') ? AppColors.danger : AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
