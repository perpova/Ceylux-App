import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/stock_item.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/animation_widgets.dart';

class StockScreen extends StatefulWidget {
  final String? initialSearchQuery;
  const StockScreen({super.key, this.initialSearchQuery});
  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _filter = 'All';
  String _search = '';
  DateTime _selectedMonth = DateTime.now();
  final svc = ApiService();
  late TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _search = widget.initialSearchQuery ?? '';
    _searchCtrl = TextEditingController(text: _search);
  }

  @override
  void didUpdateWidget(covariant StockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSearchQuery != oldWidget.initialSearchQuery) {
      setState(() {
        _search = widget.initialSearchQuery ?? '';
        _searchCtrl.text = _search;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  DateTime get _currentMonthStart => DateTime(_selectedMonth.year, _selectedMonth.month, 1);
  DateTime get _currentMonthEnd => DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
  
  DateTime get _lastMonthStart {
    final m = _selectedMonth.month - 1 == 0 ? DateTime(_selectedMonth.year - 1, 12, 1) : DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    return m;
  }
  
  DateTime get _lastMonthEnd {
    final m = _selectedMonth.month - 1 == 0 ? DateTime(_selectedMonth.year - 1, 12, 31, 23, 59, 59) : DateTime(_selectedMonth.year, _selectedMonth.month, 0, 23, 59, 59);
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(children: [
                    Icon(Icons.search, color: AppColors.muted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textColor, fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none, 
                        hintText: 'Search by name or SKU...', 
                        hintStyle: TextStyle(color: AppColors.muted),
                        suffixIcon: _search.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                },
                                child: Icon(Icons.close_rounded,
                                    color: AppColors.muted, size: 18),
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    )),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              GoldButton(label: 'Add', onTap: () => _showForm(context, null), isSmall: true, icon: Icons.add),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Current Month', 'Last Month'].map((filter) => GestureDetector(
                      onTap: () => setState(() => _filter = filter),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _filter == filter ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _filter == filter ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(filter, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _filter == filter ? AppColors.primary : AppColors.muted)),
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showMonthPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<StockItem>>(
            stream: svc.stockStream(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const LoadingAnimation(message: 'Loading inventory...');
              }
              if (snap.hasError) {
                return ErrorAnimation(
                  title: 'Failed to Load Stock',
                  message: snap.error.toString(),
                  onRetry: () {},
                );
              }
              final items = (snap.data ?? []).where((item) {
                // Month filter based on _selectedMonth
                bool matchMonth = true;
                if (_filter == 'Current Month') {
                  // Filter by current selected month
                  matchMonth = item.createdAt.year == _selectedMonth.year &&
                      item.createdAt.month == _selectedMonth.month;
                } else if (_filter == 'Last Month') {
                  // Filter by last month
                  matchMonth = item.createdAt.year == _lastMonthStart.year &&
                      item.createdAt.month == _lastMonthStart.month;
                }
                // If 'All', matchMonth stays true
                
                final matchSearch = item.name.toLowerCase().contains(_search.toLowerCase()) || item.sku.toLowerCase().contains(_search.toLowerCase());
                return matchMonth && matchSearch;
              }).toList();

              if (items.isEmpty) {
                return NoDataAnimation(
                  message: _search.isNotEmpty 
                      ? 'No items found for "$_search"'
                      : 'No stock items yet',
                  actionLabel: 'Add Item',
                  onAction: () => _showForm(context, null),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: items.length,
                itemBuilder: (context, i) => _StockCard(item: items[i], onTap: () => _showForm(context, items[i])),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MonthYearPicker(
        initialMonth: _selectedMonth,
        onChanged: (newMonth) => setState(() => _selectedMonth = newMonth),
        onDone: () {
          setState(() => _filter = 'Current Month');
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showForm(BuildContext context, StockItem? item) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _StockFormSheet(item: item),
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockItem item;
  final VoidCallback onTap;
  const _StockCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = item.totalQty;
    Color sc = total == 0 ? AppColors.danger : total < item.minQty ? AppColors.warning : AppColors.success;
    String sl = total == 0 ? '⚠ Out' : total < item.minQty ? '$total Low' : '$total In Stock';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 6, offset: Offset(0, 2))]),
        child: Row(
          children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: item.photoUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.network(item.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(item.emoji, style: const TextStyle(fontSize: 28)))))
                : Center(child: Text(item.emoji, style: const TextStyle(fontSize: 28)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textColor)),
              const SizedBox(height: 2),
              Row(children: [
                Text(item.sku, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                _catTag(item.category),
              ]),
              const SizedBox(height: 3),
              Text(item.sizes.entries.where((e) => !e.key.contains('_') && e.value > 0).map((e) => '${e.key}:${e.value}').join('  '),
                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Rs. ${NumberFormat('#,###').format(item.price)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.discount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.warning.withOpacity(0.4))),
                      child: Text('${item.discount}% OFF', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppColors.warning, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: sc.withOpacity(0.4))),
                    child: Text(sl, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: sc, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _catTag(String cat) {
    final colors = {'Men': AppColors.primary, 'Women': Color(0xFFE91E8C), 'Kids': Color(0xFF2E7D5E)};
    final c = colors[cat] ?? AppColors.muted;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(cat, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: c, fontWeight: FontWeight.bold)));
  }
}

class _StockFormSheet extends StatefulWidget {
  final StockItem? item;
  const _StockFormSheet({this.item});
  @override
  State<_StockFormSheet> createState() => _StockFormSheetState();
}

class _StockFormSheetState extends State<_StockFormSheet> {
  final _name   = TextEditingController();
  final _sku    = TextEditingController();
  final _price  = TextEditingController();
  final _cost   = TextEditingController();
  final _discount = TextEditingController();
  final _minQty = TextEditingController();
  final _colorController = TextEditingController();
  String _category = 'Men';
  String _emoji = '👕';
  Map<String, int> _sizes = {};
  List<String> _colors = ['Black', 'Red', 'Orange', 'Yellow'];
  final List<String> _targetSizes = ['M', 'L', 'XL', '2XL'];
  List<String> _addSuggestions = [];
  static const List<String> _commonColors = [
    'Black', 'Blue', 'Brown', 'Beige', 'Bronze', 'Burgundy', 'Red', 'Orange', 'Yellow',
    'Green', 'Grey', 'Gold', 'Silver', 'White', 'Purple', 'Pink', 'Peach', 'Navy',
    'Maroon', 'Magenta', 'Mint', 'Olive', 'Teal', 'Turquoise', 'Violet', 'Lavender',
    'Khaki', 'Charcoal', 'Coral', 'Cream', 'Cyan', 'Mustard', 'Indigo', 'Plum'
  ];
  File? _photo;
  String? _existingPhotoUrl;
  DateTime _createdAt = DateTime.now();
  bool _saving = false;
  final svc = ApiService();

  bool get _isEdit => widget.item != null;
  final _emojis = ['👔','👕','👗','👘','👖','👚','🧥','🧣','👒','👠','👟','🧤'];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final it = widget.item!;
      _name.text = it.name; _sku.text = it.sku;
      _price.text = it.price.toString(); _cost.text = it.cost.toString();
      _discount.text = it.discount.toString();
      _minQty.text = it.minQty.toString();
      _category = it.category; _emoji = it.emoji;
      _sizes = Map.from(it.sizes); _existingPhotoUrl = it.photoUrl;
      _createdAt = it.createdAt;

      final colorsSet = <String>{};
      for (final key in _sizes.keys) {
        if (key.contains('_')) {
          colorsSet.add(key.split('_')[0]);
        }
      }

      if (colorsSet.isEmpty) {
        _colors = ['Black', 'Red', 'Orange', 'Yellow'];
        final tempSizes = <String, int>{};
        for (final c in _colors) {
          for (final sz in _targetSizes) {
            tempSizes['${c}_$sz'] = (c == 'Black') ? (_sizes[sz] ?? 0) : 0;
          }
        }
        for (final entry in _sizes.entries) {
          if (!entry.key.contains('_') && !_targetSizes.contains(entry.key)) {
            tempSizes['Black_${entry.key}'] = entry.value;
          }
        }
        _sizes = tempSizes;
      } else {
        final defaultOrder = ['Black', 'Red', 'Orange', 'Yellow'];
        final parsedColors = colorsSet.toList();
        parsedColors.sort((a, b) {
          final idxA = defaultOrder.indexOf(a);
          final idxB = defaultOrder.indexOf(b);
          if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
          if (idxA != -1) return -1;
          if (idxB != -1) return 1;
          return a.compareTo(b);
        });
        _colors = parsedColors;
      }

      for (final c in _colors) {
        for (final sz in _targetSizes) {
          _sizes['${c}_$sz'] ??= 0;
        }
      }
    } else {
      _name.text = 'Ceylux oversized Tee - ';
      _colors = ['Black', 'Red', 'Orange', 'Yellow'];
      for (final c in _colors) {
        for (final sz in _targetSizes) {
          _sizes['${c}_$sz'] = 0;
        }
      }
      _generateSkuCode();
    }
  }

  Future<void> _generateSkuCode() async {
    try {
      final now = DateTime.now();
      final yearStr = DateFormat('yy').format(now);
      final monthStr = DateFormat('MM').format(now);
      final prefix = 'CLX$yearStr$monthStr';
      
      final list = await svc.getStock();
      
      int maxNum = 0;
      final regex = RegExp('^CLX$yearStr$monthStr(\\d{3})\$');
      
      for (final item in list) {
        final match = regex.firstMatch(item.sku);
        if (match != null) {
          final numStr = match.group(1)!;
          final numVal = int.tryParse(numStr) ?? 0;
          if (numVal > maxNum) {
            maxNum = numVal;
          }
        }
      }
      
      final nextNum = maxNum + 1;
      final nextNumStr = nextNum.toString().padLeft(3, '0');
      
      if (mounted) {
        setState(() {
          _sku.text = '$prefix$nextNumStr';
        });
      }
    } catch (e) {
      print('❌ Failed to auto-generate SKU: $e');
    }
  }


  void _onCategoryChange(String cat) {
    setState(() {
      _category = cat;
    });
  }

  void _updateAddSuggestions(String input) {
    if (input.trim().isEmpty) {
      setState(() => _addSuggestions = []);
      return;
    }
    final lowercaseInput = input.toLowerCase();
    setState(() {
      _addSuggestions = _commonColors
          .where((c) => c.toLowerCase().startsWith(lowercaseInput) && !_colors.any((existing) => existing.toLowerCase() == c.toLowerCase()))
          .toList();
    });
  }

  Future<void> _pickPhoto() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context, backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)), margin: EdgeInsets.only(bottom: 16)),
        Row(children: [
          Expanded(child: _srcBtn('📷', 'Camera', ImageSource.camera)),
          const SizedBox(width: 12),
          Expanded(child: _srcBtn('🖼️', 'Gallery', ImageSource.gallery)),
        ]),
      ])),
    );
    if (src == null) return;
    final picked = await ImagePicker().pickImage(source: src, imageQuality: 80);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Widget _srcBtn(String icon, String label, ImageSource src) => GestureDetector(
    onTap: () => Navigator.pop(context, src),
    child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(children: [Text(icon, style: TextStyle(fontSize: 28)), SizedBox(height: 4), Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textColor))])),
  );

  Future<void> _save() async {
    if (_name.text.isEmpty || _price.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Price required!')));
      return;
    }
    setState(() => _saving = true);
    try {
      String? photoUrl = _existingPhotoUrl;
      if (_photo != null) photoUrl = await svc.uploadPhoto(_photo!, 'stock');

      // Compute aggregated size totals for backward compatibility
      final finalSizes = Map<String, int>.from(_sizes);
      for (final sz in _targetSizes) {
        int total = 0;
        for (final color in _colors) {
          total += _sizes['${color}_$sz'] ?? 0;
        }
        finalSizes[sz] = total;
      }

      final item = StockItem(
        id: _isEdit ? widget.item!.id : '',
        name: _name.text, category: _category, sku: _sku.text,
        minQty: int.tryParse(_minQty.text) ?? 15,
        price: int.tryParse(_price.text) ?? 0,
        cost: int.tryParse(_cost.text) ?? 0,
        discount: int.tryParse(_discount.text) ?? 0,
        emoji: _emoji, photoUrl: photoUrl, sizes: finalSizes,
        createdAt: _createdAt,
      );

      if (_isEdit) { await svc.updateStockItem(item); } else { await svc.addStockItem(item); }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Item updated ✓' : 'Item added ✓'),
          backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete Item?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textColor)),
      content: Text('${widget.item!.name} delete කරන්නද?', style: GoogleFonts.plusJakartaSans(color: AppColors.muted)),
      actions: [
        ActionButton(onTap: () => Navigator.pop(context, false), label: 'Cancel', isOutlined: true, buttonColor: AppColors.muted),
        const SizedBox(width: 8),
        ActionButton(onTap: () => Navigator.pop(context, true), label: 'Delete', buttonColor: AppColors.danger),
      ],
    ));
    if (ok != true) return;
    await svc.deleteStockItem(widget.item!.id);
    if (mounted) Navigator.pop(context);
  }

  void _showQuantityDialog(String color, String sz, int currentQty) async {
    final controller = TextEditingController(text: currentQty == 0 ? '' : currentQty.toString());
    final newQty = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Enter Quantity for $color ($sz)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textColor, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.plusJakartaSans(color: AppColors.textColor),
          decoration: InputDecoration(
            hintText: 'e.g. 10',
            hintStyle: TextStyle(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          ActionButton(
            onTap: () => Navigator.pop(context),
            label: 'Cancel',
            isOutlined: true,
            buttonColor: AppColors.muted,
          ),
          const SizedBox(width: 8),
          ActionButton(
            onTap: () {
              final parsed = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context, parsed.clamp(0, 999));
            },
            label: 'OK',
            buttonColor: AppColors.primary,
          ),
        ],
      ),
    );

    if (newQty != null) {
      setState(() => _sizes['${color}_$sz'] = newQty);
    }
  }

  void _showColorActions(String color) {
    final renameController = TextEditingController(text: color);
    List<String> suggestions = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Color: $color', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textColor, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: renameController,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textColor),
                decoration: InputDecoration(
                  labelText: 'Color Name',
                  labelStyle: TextStyle(color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  final trimmed = val.trim();
                  if (trimmed.isEmpty) {
                    dialogSetState(() => suggestions = []);
                  } else {
                    final lowercase = trimmed.toLowerCase();
                    dialogSetState(() {
                      suggestions = _commonColors
                          .where((c) => c.toLowerCase().startsWith(lowercase) && c.toLowerCase() != color.toLowerCase())
                          .toList();
                    });
                  }
                },
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: suggestions.take(5).map((sugg) => GestureDetector(
                    onTap: () {
                      renameController.text = sugg;
                      dialogSetState(() => suggestions = []);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.isDark ? Colors.blueGrey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.isDark ? AppColors.border : Colors.grey[300]!),
                      ),
                      child: Text(
                        sugg,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
          actions: [
            ActionButton(
              onTap: () {
                if (_colors.length <= 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot delete the only remaining color.'))
                  );
                  return;
                }
                setState(() {
                  _colors.remove(color);
                  for (final sz in _targetSizes) {
                    _sizes.remove('${color}_$sz');
                  }
                });
                Navigator.pop(context);
              },
              label: 'Delete',
              isOutlined: true,
              buttonColor: AppColors.danger,
            ),
            const SizedBox(width: 8),
            ActionButton(
              onTap: () => Navigator.pop(context),
              label: 'Cancel',
              isOutlined: true,
              buttonColor: AppColors.muted,
            ),
            const SizedBox(width: 8),
            ActionButton(
              onTap: () {
                final newName = renameController.text.trim();
                if (newName.isNotEmpty && newName != color) {
                  if (_colors.contains(newName)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Color already exists.'))
                    );
                    return;
                  }
                  setState(() {
                    final index = _colors.indexOf(color);
                    if (index != -1) {
                      _colors[index] = newName;
                      for (final sz in _targetSizes) {
                        _sizes['${newName}_$sz'] = _sizes['${color}_$sz'] ?? 0;
                        _sizes.remove('${color}_$sz');
                      }
                    }
                  });
                }
                Navigator.pop(context);
              },
              label: 'Save',
              buttonColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)), margin: EdgeInsets.only(bottom: 16))),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_isEdit ? 'Edit Item' : 'Add New Item', style: GoogleFonts.outfit(fontSize: 20, color: AppColors.primary, fontWeight: FontWeight.bold)),
          if (_isEdit) GestureDetector(onTap: _delete, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('Delete', style: GoogleFonts.plusJakartaSans(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)))),
        ]),
        const SizedBox(height: 20),

        // Photo + Emoji
        Row(children: [
          GestureDetector(onTap: _pickPhoto, child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary, width: 1.5)),
            child: _photo != null
              ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(_photo!, fit: BoxFit.cover))
              : _existingPhotoUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.network(_existingPhotoUrl!, fit: BoxFit.cover))
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 24),
                    Text('Photo', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold))]),
          )),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('EMOJI', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: _emojis.map((e) => GestureDetector(
              onTap: () => setState(() => _emoji = e),
              child: Container(width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _emoji == e ? AppColors.primary.withOpacity(0.1) : AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _emoji == e ? AppColors.primary : AppColors.border)),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 18)))),
            )).toList()),
          ])),
        ]),
        const SizedBox(height: 16),

        GoldTextField(label: 'Item Name *', controller: _name, hint: 'e.g. Silk Kurta - Navy'),
        GoldTextField(label: 'SKU Code', controller: _sku, hint: 'e.g. MK-001'),

        // Date Added (Read-only for edit)
        if (_isEdit)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Text('Date Added', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(_createdAt),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textColor, fontWeight: FontWeight.w600),
                    ),
                    Icon(Icons.calendar_today, color: AppColors.muted, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        // Category
        Text('CATEGORY', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(children: ['Men', 'Women', 'Kids'].map((cat) => Expanded(child: GestureDetector(
          onTap: () => _onCategoryChange(cat),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _category == cat ? AppColors.primary.withOpacity(0.1) : AppColors.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _category == cat ? AppColors.primary : AppColors.border)),
            child: Text(cat, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: _category == cat ? AppColors.primary : AppColors.muted))),
        ))).toList()),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: GoldTextField(label: 'Selling Price (Rs.) *', controller: _price, keyboardType: TextInputType.number, hint: '4500')),
          const SizedBox(width: 12),
          Expanded(child: GoldTextField(label: 'Cost Price (Rs.)', controller: _cost, keyboardType: TextInputType.number, hint: '2800')),
        ]),
        const SizedBox(height: 8),
        
        // Discount and Min Stock in one row
        Row(children: [
          Expanded(child: GoldTextField(label: 'Discount %', controller: _discount, keyboardType: TextInputType.number, hint: '0')),
          const SizedBox(width: 12),
          Expanded(child: GoldTextField(label: 'Min Stock Alert', controller: _minQty, keyboardType: TextInputType.number, hint: '15')),
        ]),
        const SizedBox(height: 16),

        // Sizes
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('SIZE INVENTORY', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.bold)),
          Text('Total: ${_sizes.entries.where((e) => e.key.contains('_')).fold(0, (a, b) => a + b.value)}',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),

        Table(
          border: TableBorder.all(color: Colors.black87, width: 1),
          columnWidths: const {
            0: FlexColumnWidth(1.2), // Color column
            1: FlexColumnWidth(1),   // M
            2: FlexColumnWidth(1),   // L
            3: FlexColumnWidth(1),   // XL
            4: FlexColumnWidth(1),   // 2XL
          },
          children: [
            // Header Row
            TableRow(
              children: [
                TableCell(child: Container(height: 40, color: Colors.white, alignment: Alignment.center)),
                _buildHeaderCell('M'),
                _buildHeaderCell('L'),
                _buildHeaderCell('XL'),
                _buildHeaderCell('2XL'),
              ],
            ),
            // Data Rows
            ..._colors.map((color) {
              return TableRow(
                children: [
                  // Color row header
                  TableCell(
                    child: GestureDetector(
                      onTap: () => _showColorActions(color),
                      child: Container(
                        height: 45,
                        color: color == 'Black' ? Colors.white : Colors.white,
                        alignment: Alignment.center,
                        child: Text(
                          color,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Size cells
                  ..._targetSizes.map((sz) {
                    final qty = _sizes['${color}_$sz'] ?? 0;
                    return TableCell(
                      child: GestureDetector(
                        onTap: () => _showQuantityDialog(color, sz, qty),
                        child: Container(
                          height: 45,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Text(
                            qty == 0 ? '' : '$qty',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 16),

        // Add Color Input Field
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _colorController,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textColor, fontSize: 13),
                  onChanged: _updateAddSuggestions,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Add new color...',
                    hintStyle: TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final newColor = _colorController.text.trim();
                if (newColor.isNotEmpty) {
                  if (_colors.any((c) => c.toLowerCase() == newColor.toLowerCase())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Color already exists!'))
                    );
                    return;
                  }
                  setState(() {
                    _colors.add(newColor);
                    for (final sz in _targetSizes) {
                      _sizes['${newColor}_$sz'] = 0;
                    }
                    _colorController.clear();
                    _addSuggestions = [];
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Add Color',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_addSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _addSuggestions.take(6).map((suggestion) => GestureDetector(
              onTap: () {
                setState(() {
                  _colorController.text = suggestion;
                  _addSuggestions = [];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.isDark ? Colors.blueGrey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.isDark ? AppColors.border : Colors.grey[300]!),
                ),
                child: Text(
                  suggestion,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
        const SizedBox(height: 20),

        _saving
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SizedBox(width: double.infinity, child: GoldButton(label: _isEdit ? 'Save Changes' : 'Add Item', onTap: _save)),
        const SizedBox(height: 8),
      ])),
    );
  }

  Widget _buildHeaderCell(String label) {
    return TableCell(
      child: Container(
        height: 40,
        color: Colors.white,
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _price.dispose();
    _cost.dispose();
    _discount.dispose();
    _minQty.dispose();
    _colorController.dispose();
    super.dispose();
  }
}

class _MonthYearPicker extends StatefulWidget {
  final DateTime initialMonth;
  final Function(DateTime) onChanged;
  final VoidCallback onDone;

  const _MonthYearPicker({required this.initialMonth, required this.onChanged, required this.onDone});

  @override
  State<_MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<_MonthYearPicker> {
  late DateTime _selected;
  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear - 5 + i);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 16)),
                Text('Select Month & Year', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor)),
                const SizedBox(height: 24),
                
                // Month and Year Selectors
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MONTH', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButton<int>(
                              value: _selected.month,
                              isExpanded: true,
                              underline: Container(),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              items: List.generate(12, (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(_months[i], style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textColor, fontWeight: FontWeight.bold)),
                              )),
                              onChanged: (month) {
                                if (month != null) {
                                  setState(() => _selected = DateTime(_selected.year, month));
                                  widget.onChanged(_selected);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YEAR', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted, letterSpacing: 1, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButton<int>(
                              value: _selected.year,
                              isExpanded: true,
                              underline: Container(),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              items: years.map((year) => DropdownMenuItem(
                                value: year,
                                child: Text('$year', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textColor, fontWeight: FontWeight.bold)),
                              )).toList(),
                              onChanged: (year) {
                                if (year != null) {
                                  setState(() => _selected = DateTime(year, _selected.month));
                                  widget.onChanged(_selected);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('MMMM yyyy').format(_selected),
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: 'Done',
                    onTap: widget.onDone,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
