import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/customer.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _search = '';
  final svc = ApiService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(children: [
                    const Icon(Icons.search, color: AppColors.muted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: AppColors.textColor, fontSize: 14),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search customers...',
                          hintStyle: TextStyle(color: AppColors.muted),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              GoldButton(
                label: '+ Add',
                onTap: () => _showAddSheet(context),
                isSmall: true,
                icon: Icons.person_add,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Customer>>(
            stream: svc.customersStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold));
              }
              final customers = (snap.data ?? []).where((c) =>
                c.name.toLowerCase().contains(_search.toLowerCase()) ||
                c.phone.contains(_search) ||
                c.email.toLowerCase().contains(_search.toLowerCase())
              ).toList();

              if (customers.isEmpty) {
                return const Center(
                  child: Text('No customers found', style: TextStyle(color: AppColors.muted)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: customers.length,
                itemBuilder: (context, i) {
                  final c = customers[i];
                  final tier = Tiers.getTier(c.totalSpent);
                  return CeyluxCard(
                    onTap: () => _showDetail(context, c),
                    child: Row(
                      children: [
                        UserAvatar(name: c.name, photoUrl: c.photoUrl, size: 48, borderColor: tier.color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(c.phone, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TierBadge(totalSpent: c.totalSpent),
                            const SizedBox(height: 4),
                            Text(
                              'Rs. ${NumberFormat('#,###').format(c.totalSpent)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, Customer c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerDetailSheet(customer: c),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddCustomerSheet(),
    );
  }
}

// ── Customer Detail Sheet ─────────────────────────────────────────────────────
class _CustomerDetailSheet extends StatefulWidget {
  final Customer customer;
  const _CustomerDetailSheet({required this.customer});
  @override
  State<_CustomerDetailSheet> createState() => _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends State<_CustomerDetailSheet> {
  bool _uploading = false;
  final svc = ApiService();

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final source = await _pickSource();
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final url = await svc.uploadPhoto(File(picked.path), 'customers');
      await svc.updateCustomer(widget.customer.copyWith(photoUrl: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated ✓'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<ImageSource?> _pickSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              margin: const EdgeInsets.only(bottom: 16),
            ),
            const Text('Select Photo', style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 16, color: AppColors.textColor)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        children: [
                          Text('📷', style: TextStyle(fontSize: 32)),
                          SizedBox(height: 8),
                          Text('Camera', style: TextStyle(fontSize: 13, color: AppColors.textColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        children: [
                          Text('🖼️', style: TextStyle(fontSize: 32)),
                          SizedBox(height: 8),
                          Text('Gallery', style: TextStyle(fontSize: 13, color: AppColors.textColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final tier = Tiers.getTier(c.totalSpent);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            margin: const EdgeInsets.only(bottom: 20),
          ),

          // Profile Photo with edit button
          Stack(
            alignment: Alignment.center,
            children: [
              UserAvatar(name: c.name, photoUrl: c.photoUrl, size: 80, borderColor: tier.color),
              if (_uploading)
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
                  ),
                ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _uploading ? null : _changePhoto,
                  child: Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: AppColors.bg),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _uploading ? null : _changePhoto,
            child: const Text(
              'Change Photo',
              style: TextStyle(fontSize: 11, color: AppColors.gold),
            ),
          ),
          const SizedBox(height: 12),

          Text(c.name, style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 20, color: AppColors.textColor)),
          const SizedBox(height: 4),
          TierBadge(totalSpent: c.totalSpent),
          const SizedBox(height: 16),

          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _infoRow('📞', c.phone),
                if (c.email.isNotEmpty) ...[
                  const Divider(color: AppColors.border, height: 16),
                  _infoRow('📧', c.email),
                ],
                if (c.address.isNotEmpty) ...[
                  const Divider(color: AppColors.border, height: 16),
                  _infoRow('📍', c.address),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Stats
          Row(
            children: [
              Expanded(child: _statBox('Orders', '${c.totalOrders}')),
              const SizedBox(width: 10),
              Expanded(child: _statBox('Total Spent', 'Rs. ${NumberFormat('#,###').format(c.totalSpent)}')),
              const SizedBox(width: 10),
              Expanded(child: _statBox('Discount', '${tier.discount}%')),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(String icon, String text) => Row(
    children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textColor))),
    ],
  );

  Widget _statBox(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
    child: Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldLight, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ],
    ),
  );
}

// ── Add Customer Sheet ────────────────────────────────────────────────────────
class _AddCustomerSheet extends StatefulWidget {
  const _AddCustomerSheet();
  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  File? _photo;
  bool _saving = false;
  final svc = ApiService();

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _phone.text.isEmpty) return;
    setState(() => _saving = true);

    try {
      String? photoUrl;
      if (_photo != null) {
        photoUrl = await svc.uploadPhoto(_photo!, 'customers');
      }

      await svc.addCustomer(Customer(
        id: '',
        name: _name.text,
        phone: _phone.text,
        email: _email.text,
        address: _address.text,
        totalOrders: 0,
        totalSpent: 0,
        photoUrl: photoUrl,
      ));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              margin: const EdgeInsets.only(bottom: 16),
            ),
            const Text('Add Customer', style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 18, color: AppColors.textColor)),
            const SizedBox(height: 20),

            // Photo picker
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bg,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: _photo != null
                  ? ClipOval(child: Image.file(_photo!, fit: BoxFit.cover))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('📷', style: TextStyle(fontSize: 28)),
                        Text('Photo', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 20),

            GoldTextField(label: 'Name *', controller: _name, hint: 'Full name'),
            GoldTextField(label: 'Phone *', controller: _phone, keyboardType: TextInputType.phone, hint: '07X XXX XXXX'),
            GoldTextField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress, hint: 'email@example.com'),
            GoldTextField(label: 'Address', controller: _address, maxLines: 2, hint: 'Street, City'),

            _saving
              ? const CircularProgressIndicator(color: AppColors.gold)
              : GoldButton(label: 'Add Customer', onTap: _save),
          ],
        ),
      ),
    );
  }
}
