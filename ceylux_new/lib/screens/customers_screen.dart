import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/customer.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

// Rating helpers
class _RatingInfo {
  final String label;
  final String emoji;
  final Color color;
  const _RatingInfo(this.label, this.emoji, this.color);
}

const _ratings = [
  _RatingInfo('Unrated',       '—',  AppColors.muted),
  _RatingInfo('Poor',          '😞', AppColors.danger),
  _RatingInfo('Below Average', '😐', Color(0xFFE07020)),
  _RatingInfo('Average',       '🙂', AppColors.warning),
  _RatingInfo('Good',          '😊', Color(0xFF2E9E6E)),
  _RatingInfo('Excellent',     '🌟', AppColors.primary),
];

_RatingInfo _ratingInfo(double r) => r <= 0 ? _ratings[0] : _ratings[r.clamp(1,5).toInt()];

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _search = '';
  String _filterTier = 'All';
  String _filterRating = 'All';
  final svc = ApiService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search + Add
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(children: [
                  const Icon(Icons.search, color: AppColors.muted, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    style: const TextStyle(color: AppColors.textColor, fontSize: 14),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Search customers...', hintStyle: TextStyle(color: AppColors.muted)),
                    onChanged: (v) => setState(() => _search = v),
                  )),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            GoldButton(label: '+ Add', onTap: () => _showAddSheet(context), isSmall: true, icon: Icons.person_add),
          ]),
        ),

        // Filter tabs — Tier
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TIER', style: GoogleFonts.montserrat(fontSize: 9, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: ['All', '🥉 Bronze', '🥈 Silver', '🥇 Gold', '💎 Platinum'].map((t) {
                final active = _filterTier == t;
                return GestureDetector(
                  onTap: () => setState(() => _filterTier = t),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.muted)),
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 8),
            Text('OWNER RATING', style: GoogleFonts.montserrat(fontSize: 9, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: ['All', '😞 Poor', '😐 Below Avg', '🙂 Average', '😊 Good', '🌟 Excellent'].map((r) {
                final active = _filterRating == r;
                return GestureDetector(
                  onTap: () => setState(() => _filterRating = r),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(r, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.muted)),
                  ),
                );
              }).toList()),
            ),
          ]),
        ),

        const SizedBox(height: 10),

        // List
        Expanded(
          child: StreamBuilder<List<Customer>>(
            stream: svc.customersStream(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

              var customers = snap.data ?? [];

              // Search filter
              if (_search.isNotEmpty) {
                customers = customers.where((c) =>
                  c.name.toLowerCase().contains(_search.toLowerCase()) ||
                  c.phone.contains(_search) ||
                  c.email.toLowerCase().contains(_search.toLowerCase())
                ).toList();
              }

              // Tier filter
              if (_filterTier != 'All') {
                final tierName = _filterTier.split(' ').last;
                customers = customers.where((c) => Tiers.getTier(c.totalSpent).label == tierName).toList();
              }

              // Rating filter
              if (_filterRating != 'All') {
                final ratingLabel = _filterRating.split(' ').sublist(1).join(' ');
                customers = customers.where((c) => _ratingInfo(c.ownerRating).label == ratingLabel).toList();
              }

              if (customers.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('👥', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No customers found', style: GoogleFonts.playfairDisplay(fontSize: 18, color: AppColors.muted)),
                ]));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: customers.length,
                itemBuilder: (context, i) {
                  final c = customers[i];
                  final tier = Tiers.getTier(c.totalSpent);
                  final ri = _ratingInfo(c.ownerRating);
                  return CeyluxCard(
                    onTap: () => _showDetail(context, c),
                    child: Row(children: [
                      Stack(children: [
                        UserAvatar(name: c.name, photoUrl: c.photoUrl, size: 50, borderColor: tier.color),
                        if (c.ownerRating > 0)
                          Positioned(bottom: 0, right: 0,
                            child: Container(width: 18, height: 18,
                              decoration: BoxDecoration(color: ri.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                              child: Center(child: Text('${c.ownerRating.toInt()}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white))))),
                      ]),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textColor)),
                        const SizedBox(height: 2),
                        Text(c.phone, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        const SizedBox(height: 5),
                        // Mini rating bar
                        _MiniRatingBar(rating: c.ownerRating),
                      ])),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        TierBadge(totalSpent: c.totalSpent),
                        const SizedBox(height: 4),
                        Text('Rs. ${NumberFormat('#,###').format(c.totalSpent)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      ]),
                    ]),
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
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _CustomerDetailSheet(customer: c),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const _AddCustomerSheet(),
    );
  }
}

//  Mini Rating Bar (list view) 
class _MiniRatingBar extends StatelessWidget {
  final double rating;
  const _MiniRatingBar({required this.rating});

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return Text('Not rated', style: GoogleFonts.montserrat(fontSize: 9, color: AppColors.muted));
    final ri = _ratingInfo(rating);
    return Row(children: [
      ...List.generate(5, (i) => Container(
        width: 18, height: 6,
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          color: i < rating ? ri.color : AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      )),
      const SizedBox(width: 6),
      Text('${ri.emoji} ${ri.label}', style: GoogleFonts.montserrat(fontSize: 9, color: ri.color, fontWeight: FontWeight.w600)),
    ]);
  }
}

//  Customer Detail Sheet 
class _CustomerDetailSheet extends StatefulWidget {
  final Customer customer;
  const _CustomerDetailSheet({required this.customer});
  @override
  State<_CustomerDetailSheet> createState() => _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends State<_CustomerDetailSheet> {
  bool _uploading = false;
  bool _editingNote = false;
  late double _ownerRating;
  late TextEditingController _noteCtrl;
  final svc = ApiService();

  @override
  void initState() {
    super.initState();
    _ownerRating = widget.customer.ownerRating;
    _noteCtrl = TextEditingController(text: widget.customer.ownerNote);
  }

  Future<void> _saveNote() async {
    await svc.updateCustomer(widget.customer.copyWith(ownerRating: _ownerRating, ownerNote: _noteCtrl.text));
    if (mounted) {
      setState(() => _editingNote = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved ✓'), backgroundColor: AppColors.success, duration: Duration(seconds: 1)));
    }
  }

  Future<void> _setRating(double r) async {
    setState(() => _ownerRating = r);
    await svc.updateCustomer(widget.customer.copyWith(ownerRating: r, ownerNote: _noteCtrl.text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rating saved: ${_ratingInfo(r).emoji} ${_ratingInfo(r).label}'), backgroundColor: AppColors.success, duration: const Duration(seconds: 1)));
  }

  Future<void> _changePhoto() async {
    final source = await _pickSource();
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await svc.uploadPhoto(File(picked.path), 'customers');
      await svc.updateCustomer(widget.customer.copyWith(photoUrl: url));
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated ✓'), backgroundColor: AppColors.success)); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger));
    } finally { if (mounted) setState(() => _uploading = false); }
  }

  Future<ImageSource?> _pickSource() => showModalBottomSheet<ImageSource>(
    context: context, backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 16)),
      Row(children: [
        Expanded(child: _srcBtn('📷', 'Camera', ImageSource.camera)),
        const SizedBox(width: 12),
        Expanded(child: _srcBtn('🖼️', 'Gallery', ImageSource.gallery)),
      ]),
    ])),
  );

  Widget _srcBtn(String icon, String label, ImageSource src) => GestureDetector(
    onTap: () => Navigator.pop(context, src),
    child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(children: [Text(icon, style: const TextStyle(fontSize: 28)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textColor))])),
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final tier = Tiers.getTier(c.totalSpent);
    final ri = _ratingInfo(_ownerRating);

    return Container(
      decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(child: Column(children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 16))),

        // Photo + name
        Stack(alignment: Alignment.center, children: [
          UserAvatar(name: c.name, photoUrl: c.photoUrl, size: 80, borderColor: tier.color),
          if (_uploading) Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.6)), child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
          Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _uploading ? null : _changePhoto,
            child: Container(width: 26, height: 26, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 14, color: Colors.white)))),
        ]),
        const SizedBox(height: 8),
        Text(c.name, style: GoogleFonts.playfairDisplay(fontSize: 20, color: AppColors.primary)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TierBadge(totalSpent: c.totalSpent),
          const SizedBox(width: 8),
          if (_ownerRating > 0) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: ri.color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: ri.color.withOpacity(0.4))),
            child: Text('${ri.emoji} ${ri.label}', style: TextStyle(fontSize: 10, color: ri.color, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 16),

        // OWNER RATING 
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.12)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.lock_outline, size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Owner Rating', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('Private', style: GoogleFonts.montserrat(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 14),

            // Rating bars — 1 to 5
            Row(children: List.generate(5, (i) {
              final val = (i + 1).toDouble();
              final active = _ownerRating >= val;
              final info = _ratings[i + 1];
              return Expanded(child: GestureDetector(
                onTap: () => _setRating(val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 5),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? info.color.withOpacity(0.15) : AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: active ? info.color : AppColors.border, width: active ? 1.5 : 1),
                    boxShadow: active ? [BoxShadow(color: info.color.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))] : null,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${i + 1}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: active ? info.color : AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(info.emoji, style: const TextStyle(fontSize: 14)),
                  ]),
                ),
              ));
            })),
            const SizedBox(height: 10),

            // Rating label line
            Center(child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(_ownerRating),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: ri.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _ownerRating <= 0 ? '— Tap a number to rate —' : '${ri.emoji}  ${ri.label} Customer',
                  style: GoogleFonts.montserrat(fontSize: 12, color: _ownerRating <= 0 ? AppColors.muted : ri.color, fontWeight: FontWeight.w600),
                ),
              ),
            )),
            const SizedBox(height: 14),

            // Progress bar
            Row(children: List.generate(5, (i) {
              final active = i < _ownerRating;
              final info = _ratings[i + 1];
              return Expanded(child: Container(
                height: 5,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: active ? info.color : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ));
            })),
            const SizedBox(height: 14),

            // Private note
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Private Note', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textColor)),
              GestureDetector(
                onTap: () => setState(() => _editingNote = !_editingNote),
                child: Text(_editingNote ? 'Cancel' : '✏️ Edit', style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.primary))),
            ]),
            const SizedBox(height: 8),
            if (_editingNote) ...[
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Always pays on time, prefers silk...',
                  hintStyle: const TextStyle(color: AppColors.muted, fontSize: 12),
                  filled: true, fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 8),
              GoldButton(label: 'Save Note', onTap: _saveNote, isSmall: true),
            ] else Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Text(
                _noteCtrl.text.isEmpty ? 'No notes yet. Tap Edit to add.' : _noteCtrl.text,
                style: TextStyle(fontSize: 12, color: _noteCtrl.text.isEmpty ? AppColors.muted : AppColors.textColor, fontStyle: _noteCtrl.text.isEmpty ? FontStyle.italic : FontStyle.normal),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        //  TIER PROGRESS
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Loyalty Tier', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textColor)),
            const SizedBox(height: 12),
            _TierProgressBar(totalSpent: c.totalSpent),
          ]),
        ),
        const SizedBox(height: 14),

        // CONTACT INFO 
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _infoRow('📞', c.phone),
            if (c.email.isNotEmpty) ...[const Divider(color: AppColors.border, height: 16), _infoRow('📧', c.email)],
            if (c.address.isNotEmpty) ...[const Divider(color: AppColors.border, height: 16), _infoRow('📍', c.address)],
          ]),
        ),
        const SizedBox(height: 14),

        //  STATS 
        Row(children: [
          Expanded(child: _statBox('Orders', '${c.totalOrders}')),
          const SizedBox(width: 10),
          Expanded(child: _statBox('Total Spent', 'Rs. ${NumberFormat('#,###').format(c.totalSpent)}')),
          const SizedBox(width: 10),
          Expanded(child: _statBox('Discount', '${Tiers.getTier(c.totalSpent).discount}%')),
        ]),
        const SizedBox(height: 8),
      ])),
    );
  }

  Widget _infoRow(String icon, String text) => Row(children: [
    Text(icon, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 10),
    Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textColor))),
  ]);

  Widget _statBox(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12), textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
    ]),
  );

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }
}

// Tier Progress Bar 
class _TierProgressBar extends StatelessWidget {
  final int totalSpent;
  const _TierProgressBar({required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    final tiers = [Tiers.bronze, Tiers.silver, Tiers.gold, Tiers.platinum];
    final current = Tiers.getTier(totalSpent);
    final currentIdx = tiers.indexWhere((t) => t.label == current.label);

    return Column(children: [
      Row(children: tiers.asMap().entries.map((e) {
        final idx = e.key;
        final t = e.value;
        final isPast = idx <= currentIdx;
        final isCurrent = idx == currentIdx;
        return Expanded(child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Column(children: [
            AnimatedContainer(duration: const Duration(milliseconds: 300),
              height: isCurrent ? 10 : 6,
              decoration: BoxDecoration(color: isPast ? t.color : AppColors.border, borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 6),
            Text(t.badge, style: const TextStyle(fontSize: 16)),
            Text(t.label, style: TextStyle(fontSize: 9, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? t.color : AppColors.muted)),
            if (isCurrent) Container(width: 4, height: 4, decoration: BoxDecoration(color: t.color, shape: BoxShape.circle), margin: const EdgeInsets.only(top: 3)),
          ]),
        ));
      }).toList()),
      const SizedBox(height: 10),
      if (current.label != 'Platinum') Builder(builder: (_) {
        final next = tiers[currentIdx + 1];
        final needed = next.minSpent - totalSpent;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: next.color.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: next.color.withOpacity(0.2))),
          child: Text('Rs. ${NumberFormat('#,###').format(needed)} more → ${next.label} ${next.badge} (${next.discount}% discount)',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 11, color: next.color, fontWeight: FontWeight.w600)),
        );
      }) else Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text('🏆 Top tier reached! 15% discount on all orders', textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}

// Add Customer Sheet 
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
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _phone.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      String? photoUrl;
      if (_photo != null) photoUrl = await svc.uploadPhoto(_photo!, 'customers');
      await svc.addCustomer(Customer(
        id: '', name: _name.text, phone: _phone.text,
        email: _email.text, address: _address.text,
        totalOrders: 0, totalSpent: 0, photoUrl: photoUrl,
        ownerRating: 0, ownerNote: '',
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(child: Column(children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 16)),
        Text('Add Customer', style: GoogleFonts.playfairDisplay(fontSize: 18, color: AppColors.primary)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _pickPhoto,
          child: Container(width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.bg, border: Border.all(color: AppColors.primary, width: 2)),
            child: _photo != null
              ? ClipOval(child: Image.file(_photo!, fit: BoxFit.cover))
              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 24),
                  Text('Photo', style: TextStyle(fontSize: 10, color: AppColors.muted))])),
        ),
        const SizedBox(height: 20),
        GoldTextField(label: 'Name *', controller: _name, hint: 'Full name'),
        GoldTextField(label: 'Phone *', controller: _phone, keyboardType: TextInputType.phone, hint: '07X XXX XXXX'),
        GoldTextField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress, hint: 'email@example.com'),
        GoldTextField(label: 'Address', controller: _address, maxLines: 2, hint: 'Street, City'),
        _saving ? const CircularProgressIndicator(color: AppColors.primary) : GoldButton(label: 'Add Customer', onTap: _save),
      ])),
    );
  }

  @override
  void dispose() { _name.dispose(); _phone.dispose(); _email.dispose(); _address.dispose(); super.dispose(); }
}