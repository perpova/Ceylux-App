import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  String? _error;

  final _siEmail = TextEditingController();
  final _siPass  = TextEditingController();
  bool _siObscure = true;

  final _suName  = TextEditingController();
  final _suEmail = TextEditingController();
  final _suPass  = TextEditingController();
  final _suPass2 = TextEditingController();
  bool _suObscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _error = null));
  }

  Future<void> _signin() async {
    if (_siEmail.text.isEmpty || _siPass.text.isEmpty) {
      setState(() => _error = 'Please enter your Email and Password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final r = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _siEmail.text.trim(), 'password': _siPass.text}),
      );
      final data = jsonDecode(r.body);
      if (r.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userName', data['user']['name']);
        await prefs.setString('userEmail', data['user']['email']);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _error = data['error'] ?? 'Sign in failed');
      }
    } catch (e) {
      setState(() => _error = 'Cannot connect to server. Is the API running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signup() async {
    if (_suName.text.isEmpty || _suEmail.text.isEmpty || _suPass.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (_suPass.text != _suPass2.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (_suPass.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final r = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': _suName.text.trim(), 'email': _suEmail.text.trim(), 'password': _suPass.text}),
      );
      final data = jsonDecode(r.body);
      if (r.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userName', data['user']['name']);
        await prefs.setString('userEmail', data['user']['email']);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _error = data['error'] ?? 'Sign up failed');
      }
    } catch (e) {
      setState(() => _error = 'Cannot connect to server. Is the API running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // Logo
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
              Text('CEYLUX', style: GoogleFonts.outfit(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 3)),
              Text('CLOTHING', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted, letterSpacing: 4, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              // Tab bar
              Container(
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.muted,
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                  dividerColor: Colors.transparent,
                  tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
                ),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: GoogleFonts.plusJakartaSans(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600))),
                  ]),
                ),

              // Forms
              SizedBox(
                height: 420,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── SIGN IN ──────────────────────────────────
                    Column(children: [
                      _field(
                        controller: _siEmail,
                        label: 'Email',
                        hint: 'you@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _siPass,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        obscure: _siObscure,
                        toggle: () => setState(() => _siObscure = !_siObscure),
                      ),
                      const SizedBox(height: 28),
                      _submitBtn('Sign In', _signin),
                    ]),

                    // ── SIGN UP ──────────────────────────────────
                    Column(children: [
                      _field(
                        controller: _suName,
                        label: 'Full Name',
                        hint: 'Nimal Perera',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _suEmail,
                        label: 'Email',
                        hint: 'you@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _suPass,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        obscure: _suObscure,
                        toggle: () => setState(() => _suObscure = !_suObscure),
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _suPass2,
                        label: 'Confirm Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        obscure: _suObscure,
                      ),
                      const SizedBox(height: 28),
                      _submitBtn('Create Account', _signup),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('© 2026 Ceylux Fashion Boutique',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10, color: AppColors.muted,
            letterSpacing: 1, fontWeight: FontWeight.bold,
          )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: TextStyle(color: AppColors.textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.muted),
            prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
            suffixIcon: toggle != null
              ? GestureDetector(
                  onTap: toggle,
                  child: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.muted, size: 20,
                  ))
              : null,
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _submitBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0D4A82)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(child: Text(label,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.bold))),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _siEmail.dispose(); _siPass.dispose();
    _suName.dispose(); _suEmail.dispose();
    _suPass.dispose(); _suPass2.dispose();
    super.dispose();
  }
}