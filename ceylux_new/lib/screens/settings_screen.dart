import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/html_preview_widget.dart';
import '../widgets/profile_dialog.dart';
import '../services/update_service.dart';
import '../services/invoice_service.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import '../models/tier.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'User';
  String _userRole = 'Store Manager';
  String? _profileImagePath;
  bool _checkingUpdate = false;
  late ThemeMode _currentThemeMode;
  bool _isInvoiceExpanded = false;
  bool _isTierExpanded = false;

  final svc = ApiService();
  List<Tier> _tiers = [];
  bool _loadingTiers = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _currentThemeMode = themeNotifier.value;
    _loadTiers();
    // Listen to theme changes and rebuild in real-time
    themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        _currentThemeMode = themeNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _loadTiers() async {
    setState(() => _loadingTiers = true);
    try {
      final tiers = await svc.getTiers();
      if (mounted) {
        setState(() {
          _tiers = tiers;
          _loadingTiers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTiers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading tiers: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Ceylux Associate';
      _profileImagePath = prefs.getString('profileImagePath');
      _userRole = _userName.toLowerCase().contains('admin')
          ? 'Administrator'
          : 'Administrator';
    });
  }

  void _showAddTierDialog() {
    String name = '';
    String emoji = '';
    int minOrders = 5;
    int minSpent = 15000;
    double minRating = 2.0;
    int discount = 5;
    int priority = (_tiers.isEmpty
        ? 1
        : _tiers.map((t) => t.priority).reduce((a, b) => a > b ? a : b) + 1);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Text('Add New Tier',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.primary)),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name.isEmpty ? 'Tier Name' : name,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primary)),
                              Text('${discount}% OFF',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name & Emoji Fields
                  TextField(
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Tier Name',
                      hintText: 'e.g., Silver, Gold',
                      prefixIcon: const Icon(Icons.label),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: AppColors.bg,
                    ),
                    onChanged: (v) => setState(() => name = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Emoji',
                      hintText: '🥈 🥇 👑',
                      prefixIcon: const Icon(Icons.emoji_emotions),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: AppColors.bg,
                    ),
                    onChanged: (v) => setState(() => emoji = v),
                  ),
                  const SizedBox(height: 16),

                  // Sliders in Cards
                  _buildSliderCard(
                    icon: '',
                    label: 'Minimum Orders',
                    value: minOrders,
                    maxValue: 100,
                    divisions: 100,
                    onChanged: (v) => setState(() => minOrders = v.toInt()),
                  ),
                  const SizedBox(height: 12),

                  _buildSliderCard(
                    icon: '',
                    label: 'Minimum Spent',
                    value: minSpent,
                    maxValue: 500000,
                    divisions: 100,
                    onChanged: (v) => setState(() => minSpent = v.toInt()),
                    isCurrency: true,
                  ),
                  const SizedBox(height: 12),

                  _buildSliderCard(
                    icon: '',
                    label: 'Minimum Rating',
                    value: minRating,
                    maxValue: 5,
                    divisions: 50,
                    onChanged: (v) => setState(
                        () => minRating = double.parse(v.toStringAsFixed(1))),
                    isRating: true,
                  ),
                  const SizedBox(height: 12),

                  _buildSliderCard(
                    icon: '',
                    label: 'Discount Percentage',
                    value: discount,
                    maxValue: 50,
                    divisions: 50,
                    onChanged: (v) => setState(() => discount = v.toInt()),
                    showPercent: true,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.muted, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.isEmpty || emoji.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: const Text('Please enter tier name and emoji'),
                        backgroundColor: AppColors.danger,
                        duration: const Duration(seconds: 2)),
                  );
                  return;
                }
                try {
                  final newTier = Tier(
                    id: '',
                    name: name,
                    emoji: emoji,
                    minOrders: minOrders,
                    minSpent: minSpent,
                    minRating: minRating,
                    discountPercentage: discount,
                    priority: priority,
                  );
                  await svc.addTier(newTier);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadTiers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('✓ Tier "${name}" added successfully!'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.danger,
                          duration: const Duration(seconds: 3)),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Add Tier',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTierDialog(Tier tier) {
    String name = tier.name;
    String emoji = tier.emoji;
    int minOrders = tier.minOrders;
    int minSpent = tier.minSpent;
    double minRating = tier.minRating;
    int discount = tier.discountPercentage;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Text('${tier.emoji} ', style: const TextStyle(fontSize: 24)),
              Text('Edit Tier',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.primary)),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primary)),
                              Text('${discount}% OFF',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name & Emoji Fields
                  TextField(
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w600),
                    controller: TextEditingController(text: name),
                    decoration: InputDecoration(
                      labelText: 'Tier Name',
                      prefixIcon: const Icon(Icons.label),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: AppColors.bg,
                    ),
                    onChanged: (v) => setState(() => name = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w600),
                    controller: TextEditingController(text: emoji),
                    decoration: InputDecoration(
                      labelText: 'Emoji',
                      prefixIcon: const Icon(Icons.emoji_emotions),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: AppColors.bg,
                    ),
                    onChanged: (v) => setState(() => emoji = v),
                  ),
                  const SizedBox(height: 16),

                  // Sliders in Cards
                  _buildSliderCard(
                    icon: '🛍️',
                    label: 'Minimum Orders',
                    value: minOrders,
                    maxValue: 100,
                    divisions: 100,
                    onChanged: (v) => setState(() => minOrders = v.toInt()),
                  ),
                  const SizedBox(height: 12),

                  _buildSliderCard(
                    icon: '💰',
                    label: 'Minimum Spent',
                    value: minSpent,
                    maxValue: 500000,
                    divisions: 100,
                    onChanged: (v) => setState(() => minSpent = v.toInt()),
                    isCurrency: true,
                  ),
                  const SizedBox(height: 12),

                  _buildSliderCard(
                    icon: '⭐',
                    label: 'Minimum Rating',
                    value: minRating,
                    maxValue: 5,
                    divisions: 50,
                    onChanged: (v) => setState(
                        () => minRating = double.parse(v.toStringAsFixed(1))),
                    isRating: true,
                  ),
                  const SizedBox(height: 12),

                  _buildSliderCard(
                    icon: '🎁',
                    label: 'Discount Percentage',
                    value: discount,
                    maxValue: 50,
                    divisions: 50,
                    onChanged: (v) => setState(() => discount = v.toInt()),
                    showPercent: true,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.muted, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.isEmpty || emoji.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: const Text('Please enter tier name and emoji'),
                        backgroundColor: AppColors.danger,
                        duration: const Duration(seconds: 2)),
                  );
                  return;
                }
                try {
                  final updatedTier = tier.copyWith(
                    name: name,
                    emoji: emoji,
                    minOrders: minOrders,
                    minSpent: minSpent,
                    minRating: minRating,
                    discountPercentage: discount,
                  );
                  await svc.updateTier(tier.id, updatedTier);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadTiers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('✓ Tier "${name}" updated successfully!'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.danger,
                          duration: const Duration(seconds: 3)),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save Changes',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteTierDialog(Tier tier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Tier?',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: AppColors.danger)),
        content: Text(
            'Are you sure you want to delete ${tier.emoji} ${tier.name}?',
            style: GoogleFonts.plusJakartaSans(color: AppColors.textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await svc.deleteTier(tier.id);
                if (mounted) {
                  Navigator.pop(context);
                  _loadTiers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Tier deleted! ✓'),
                        backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.danger),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text('Delete',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.card,
          title: Text(
            'New Update Available',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: AppColors.textColor),
          ),
          content: Text(
            'Version ${updateInfo.latestVersion} is ready to install.\n\nNotes:\n${updateInfo.changelog ?? "Bug fixes and performance improvements."}',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.muted, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.muted, fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Update Now',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Your app is fully up-to-date!',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: AppColors.textColor),
        ),
        content: Text(
          'Are you sure you want to log out of your Ceylux Clothing account?',
          style: GoogleFonts.plusJakartaSans(
              color: AppColors.muted, height: 1.4, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Log Out',
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.danger, fontWeight: FontWeight.bold)),
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

  Future<void> _editInvoiceField(
      String fieldName, String key, String defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    final currentValue = prefs.getString(key) ?? defaultValue;
    final ctrl = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit $fieldName',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: AppColors.textColor),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: fieldName.contains('Footer') ? 3 : 1,
          style: GoogleFonts.plusJakartaSans(
              color: AppColors.textColor, fontSize: 13),
          decoration: InputDecoration(
            hintText: defaultValue,
            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gold),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              await prefs.setString(
                  key, ctrl.text.isEmpty ? defaultValue : ctrl.text);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$fieldName updated!',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600)),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text('Save',
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogoImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();

        // Check file size (max 2MB)
        if (bytes.length > 2 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File is too large. Max 2MB allowed.',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600)),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          return;
        }

        // Copy logo file to local app documents directory for persistence
        final docsDir = await getApplicationDocumentsDirectory();
        final fileName =
            'invoice_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final localFile = File('${docsDir.path}/$fileName');
        await file.copy(localFile.path);

        // Save logo path to shared preferences
        final prefs = await SharedPreferences.getInstance();
        final oldLogoPath = prefs.getString('invoice_logo_path');
        if (oldLogoPath != null && oldLogoPath.isNotEmpty) {
          try {
            final oldFile = File(oldLogoPath);
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          } catch (_) {}
        }
        await prefs.setString('invoice_logo_path', localFile.path);

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text('Logo uploaded successfully!',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600)),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading logo: $e',
                style:
                    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickTemplateFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['html', 'htm'],
        dialogTitle: 'Select Receipt Template',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        // Validate file exists and read it
        if (await file.exists()) {
          final content = await file.readAsString();

          // Basic validation - check if it contains HTML
          if (content.contains('html') || content.contains('{{')) {
            // Copy template file to local app documents directory for persistence
            final docsDir = await getApplicationDocumentsDirectory();
            final localFile =
                File('${docsDir.path}/uploaded_receipt_template.html');
            await file.copy(localFile.path);

            // Save template file path to shared preferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('receipt_template_path', localFile.path);

            if (mounted) {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'Template uploaded successfully!\nFile: ${result.files.single.name}',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Invalid template file. Must be HTML format with template variables.',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading template: $e',
                style:
                    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Preview HTML Receipt with Sample Data
  Future<void> _previewHTMLReceipt() async {
    try {
      // Create a sample order for preview
      final sampleOrder = AppOrder(
        dbId: 'sample-1',
        id: 'SAMPLE-001',
        customerId: 'cust-1',
        customerName: 'John Doe',
        customerAddress: 'Colombo, Sri Lanka',
        customerPhone: '+94 123 456 789',
        date: DateTime.now().toString().split(' ')[0],
        status: 'Processing',
        items: [
          OrderItem(name: 'Summer Dress', size: 'M', qty: 1, price: 3500),
          OrderItem(name: 'Cotton T-Shirt', size: 'L', qty: 2, price: 1500),
        ],
        total: 6000,
      );

      final html = await InvoiceService.getHTMLReceipt(sampleOrder);

      if (html == null || html.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Template not found. Please upload an HTML template first.',
                  style:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: Text('Preview Receipt',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.primary,
                elevation: 0,
              ),
              body: SingleChildScrollView(
                child: HTMLPreviewWidget(html: html, orderID: 'SAMPLE-001'),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error previewing template: $e',
                style:
                    GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showTemplateGuide() {
    const templateGuide = '''
HTML Receipt Template Guide
===========================

Use these variables in your HTML template. They will be replaced with actual order data:

• {{HEADER}} - Company name/header text
• {{CONTACT}} - Contact information
• {{FOOTER}} - Footer message
• {{INVOICE_ID}} - Order/Invoice ID
• {{DATE}} - Order date
• {{CUSTOMER_NAME}} - Customer name
• {{STATUS}} - Order status (Pending/Processing/Delivered)
• {{ITEMS}} - HTML table of items (auto-generated)
• {{SUBTOTAL}} - Subtotal amount
• {{DISCOUNT}} - Discount amount
• {{DISCOUNT_PERCENT}} - Discount percentage
• {{TOTAL}} - Total amount

Example Template:
================
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial; }
    .header { text-align: center; color: #C9A84C; }
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 8px; border: 1px solid #ddd; }
  </style>
</head>
<body>
  <div class="header">
    <h1>{{HEADER}}</h1>
    <p>{{CONTACT}}</p>
  </div>
  
  <p>Invoice: {{INVOICE_ID}}</p>
  <p>Customer: {{CUSTOMER_NAME}}</p>
  <p>Date: {{DATE}}</p>
  <p>Status: {{STATUS}}</p>
  
  <table>
    <tr><th>Item</th><th>Size</th><th>Qty</th><th>Price</th><th>Total</th></tr>
    {{ITEMS}}
  </table>
  
  <p>Subtotal: {{SUBTOTAL}}</p>
  <p>Discount: {{DISCOUNT}} ({{DISCOUNT_PERCENT}})</p>
  <h2>Total: {{TOTAL}}</h2>
  
  <footer>{{FOOTER}}</footer>
</body>
</html>

Save as HTML file and upload in settings to use custom template.
    ''';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Receipt Template Guide',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: AppColors.textColor),
        ),
        content: SingleChildScrollView(
          child: Text(
            templateGuide,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textColor,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gorgeous Profile Card
          GestureDetector(
            onTap: _showProfileDialog,
            child: Container(
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
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 1.5),
                      image: _profileImagePath != null &&
                              File(_profileImagePath!).existsSync()
                          ? DecorationImage(
                              image: FileImage(File(_profileImagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profileImagePath == null ||
                            !File(_profileImagePath!).existsSync()
                        ? Center(
                            child: Text(
                              _userName.isNotEmpty
                                  ? _userName[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
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

          // Loyalty Tier Thresholds - Expandable
          Text(
            'LOYALTY TIER CONFIGURATION',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.muted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _buildExpandableSection(
            title: 'MANAGE TIERS',
            isExpanded: _isTierExpanded,
            onToggle: () => setState(() => _isTierExpanded = !_isTierExpanded),
            child: CeyluxCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage your loyalty tiers',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tiers are saved to database',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddTierDialog,
                        icon: const Icon(Icons.add,
                            size: 16, color: Colors.white),
                        label: Text('Add Tier',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_loadingTiers)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    )
                  else if (_tiers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No tiers yet. Create your first tier!',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppColors.muted, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _tiers.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: AppColors.border, height: 12),
                      itemBuilder: (_, i) {
                        final tier = _tiers[i];
                        return GestureDetector(
                          onTap: () => _showEditTierDialog(tier),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(tier.emoji,
                                              style: TextStyle(fontSize: 20)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tier.name,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textColor,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.gold
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Text(
                                                        '${tier.discountPercentage}% OFF',
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors.gold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton(
                                      icon: Icon(Icons.more_vert,
                                          color: AppColors.primary, size: 20),
                                      color: AppColors.card,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side:
                                            BorderSide(color: AppColors.border),
                                      ),
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit,
                                                  size: 16,
                                                  color: AppColors.primary),
                                              const SizedBox(width: 8),
                                              Text('Edit',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    color: AppColors.textColor,
                                                    fontWeight: FontWeight.w600,
                                                  )),
                                            ],
                                          ),
                                          onTap: () => Future.delayed(
                                              Duration(milliseconds: 100),
                                              () => _showEditTierDialog(tier)),
                                        ),
                                        PopupMenuItem(
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete,
                                                  size: 16,
                                                  color: AppColors.danger),
                                              const SizedBox(width: 8),
                                              Text('Delete',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    color: AppColors.danger,
                                                    fontWeight: FontWeight.w600,
                                                  )),
                                            ],
                                          ),
                                          onTap: () => Future.delayed(
                                              Duration(milliseconds: 100),
                                              () =>
                                                  _showDeleteTierDialog(tier)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '📦 ${tier.minOrders} orders',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: AppColors.muted),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '💰 Rs.${NumberFormat('#,###').format(tier.minSpent)}',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '⭐ ${tier.minRating}/5',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: AppColors.muted),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Invoice Settings - Expandable
          _buildExpandableSection(
            title: 'INVOICE & RECEIPTS',
            isExpanded: _isInvoiceExpanded,
            onToggle: () =>
                setState(() => _isInvoiceExpanded = !_isInvoiceExpanded),
            child: CeyluxCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Upload
                  GestureDetector(
                    onTap: _pickLogoImage,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Logo for PDF',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textColor)),
                        const SizedBox(height: 8),
                        FutureBuilder<String?>(
                          future: SharedPreferences.getInstance()
                              .then((p) => p.getString('invoice_logo_path')),
                          builder: (_, snap) {
                            final logoPath = snap.data;
                            final hasLogo = logoPath != null &&
                                logoPath.isNotEmpty &&
                                File(logoPath).existsSync();

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  if (hasLogo)
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border:
                                            Border.all(color: AppColors.border),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.file(File(logoPath!),
                                            fit: BoxFit.cover),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.border.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(Icons.image_outlined,
                                          color: AppColors.muted, size: 20),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hasLogo
                                              ? 'Logo uploaded ✓'
                                              : 'Click to upload logo',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: hasLogo
                                                ? AppColors.success
                                                : AppColors.muted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'PNG or JPG (max 2MB)',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasLogo)
                                    GestureDetector(
                                      onTap: () async {
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        final path = prefs
                                            .getString('invoice_logo_path');
                                        if (path != null && path.isNotEmpty) {
                                          try {
                                            final file = File(path);
                                            if (await file.exists()) {
                                              await file.delete();
                                            }
                                          } catch (_) {}
                                        }
                                        await prefs.remove('invoice_logo_path');
                                        setState(() {});
                                      },
                                      child: Icon(Icons.close,
                                          size: 20, color: AppColors.danger),
                                    )
                                  else
                                    Icon(Icons.upload_file,
                                        size: 20, color: AppColors.gold),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 14),

                  // Receipt Template Upload
                  GestureDetector(
                    onTap: _pickTemplateFile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Receipt Template (HTML)',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textColor)),
                        const SizedBox(height: 8),
                        FutureBuilder<String?>(
                          future: SharedPreferences.getInstance().then(
                              (p) => p.getString('receipt_template_path')),
                          builder: (_, snap) {
                            final templatePath = snap.data;
                            final hasTemplate = templatePath != null &&
                                templatePath.isNotEmpty &&
                                File(templatePath).existsSync();

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (hasTemplate)
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Icon(Icons.code,
                                              color: AppColors.primary,
                                              size: 20),
                                        )
                                      else
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.border
                                                .withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Icon(Icons.file_present,
                                              color: AppColors.muted, size: 20),
                                        ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              hasTemplate
                                                  ? 'Template uploaded ✓'
                                                  : 'Click to upload template',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                color: hasTemplate
                                                    ? AppColors.success
                                                    : AppColors.muted,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              hasTemplate
                                                  ? templatePath!
                                                      .split('/')
                                                      .last
                                                  : 'HTML files only',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                color: AppColors.muted,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (hasTemplate)
                                        GestureDetector(
                                          onTap: () async {
                                            final prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            final path = prefs.getString(
                                                'receipt_template_path');
                                            if (path != null &&
                                                path.isNotEmpty) {
                                              try {
                                                final file = File(path);
                                                if (await file.exists()) {
                                                  await file.delete();
                                                }
                                              } catch (_) {}
                                            }
                                            await prefs.remove(
                                                'receipt_template_path');
                                            setState(() {});
                                          },
                                          child: Icon(Icons.close,
                                              size: 20,
                                              color: AppColors.danger),
                                        )
                                      else
                                        Icon(Icons.upload_file,
                                            size: 20, color: AppColors.gold),
                                    ],
                                  ),
                                  if (hasTemplate) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _previewHTMLReceipt,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                    color: AppColors.primary,
                                                    width: 0.5),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.preview,
                                                      size: 14,
                                                      color: AppColors.primary),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Preview',
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: _showTemplateGuide,
                                      child: Text(
                                        'View template guide',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _editInvoiceField('Invoice Header',
                        'invoice_header', 'CEYLUX Fashion Boutique'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice Header',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textColor)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<String?>(
                                  future: SharedPreferences.getInstance().then(
                                      (p) =>
                                          p.getString('invoice_header') ??
                                          'CEYLUX Fashion Boutique'),
                                  builder: (_, snap) => Text(
                                    snap.data ?? 'CEYLUX Fashion Boutique',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppColors.textColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Icon(Icons.edit,
                                  size: 16, color: AppColors.muted),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _editInvoiceField(
                        'Contact Info', 'invoice_contact', '+94 123 456 789'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contact Information',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textColor)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<String?>(
                                  future: SharedPreferences.getInstance().then(
                                      (p) =>
                                          p.getString('invoice_contact') ?? ''),
                                  builder: (_, snap) => Text(
                                    snap.data ?? 'No contact info set',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: snap.data?.isEmpty ?? true
                                          ? AppColors.muted
                                          : AppColors.textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Icon(Icons.edit,
                                  size: 16, color: AppColors.muted),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _editInvoiceField(
                        'Invoice Footer',
                        'invoice_footer',
                        'Thank you for shopping with CEYLUX!'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice Footer',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textColor)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<String?>(
                                  future: SharedPreferences.getInstance().then(
                                      (p) =>
                                          p.getString('invoice_footer') ??
                                          'Thank you for shopping with CEYLUX!'),
                                  builder: (_, snap) => Text(
                                    snap.data ??
                                        'Thank you for shopping with CEYLUX!',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppColors.textColor),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Icon(Icons.edit,
                                  size: 16, color: AppColors.muted),
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
          const SizedBox(height: 24),

          // System Section - Regular (non-expandable)
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.success.withOpacity(0.3)),
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
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account Actions - Regular (non-expandable)
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
                      color: title.contains('Sign Out')
                          ? AppColors.danger
                          : AppColors.textColor,
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

  Widget _buildTierThresholdEditor({
    required String tierName,
    required int ordersValue,
    required int spentValue,
    required double ratingValue,
    required int discountValue,
    required ValueChanged<int> onOrdersChanged,
    required ValueChanged<int> onSpentChanged,
    required ValueChanged<double> onRatingChanged,
    required ValueChanged<int> onDiscountChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tierName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Text(
                '$discountValue% OFF',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Orders threshold
        _buildThresholdInput(
          label: 'Minimum Orders',
          value: ordersValue.toString(),
          icon: Icons.shopping_cart_rounded,
          onChanged: (v) => onOrdersChanged(int.tryParse(v) ?? ordersValue),
        ),
        const SizedBox(height: 12),

        // Amount spent threshold
        _buildThresholdInput(
          label: 'Minimum Amount Spent (Rs.)',
          value: spentValue.toString(),
          icon: Icons.currency_rupee_rounded,
          onChanged: (v) => onSpentChanged(int.tryParse(v) ?? spentValue),
        ),
        const SizedBox(height: 12),

        // Rating threshold
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minimum Owner Rating',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: ratingValue,
                            min: 0.0,
                            max: 5.0,
                            divisions: 10,
                            activeColor: AppColors.gold,
                            inactiveColor: AppColors.border,
                            onChanged: onRatingChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${ratingValue.toStringAsFixed(1)}/5.0',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Discount percentage
        _buildThresholdInput(
          label: 'Discount Percentage (%)',
          value: discountValue.toString(),
          icon: Icons.local_offer_rounded,
          onChanged: (v) => onDiscountChanged(int.tryParse(v) ?? discountValue),
        ),
      ],
    );
  }

  Widget _buildThresholdInput({
    required String label,
    required String value,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: value),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintStyle:
                        GoogleFonts.plusJakartaSans(color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border(
                left: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: child,
          ),
      ],
    );
  }

  Widget _buildSliderCard({
    required String icon,
    required String label,
    required dynamic value,
    required double maxValue,
    required int divisions,
    required ValueChanged<double> onChanged,
    bool isCurrency = false,
    bool isRating = false,
    bool showPercent = false,
  }) {
    String displayValue;
    if (isCurrency) {
      displayValue = 'Rs. ${NumberFormat('#,###').format(value.toInt())}';
    } else if (isRating) {
      displayValue = '${value.toStringAsFixed(1)}/5.0';
    } else if (showPercent) {
      displayValue = '$value%';
    } else {
      displayValue = value.toString();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(label,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(displayValue,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: maxValue,
              divisions: divisions,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.border,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
