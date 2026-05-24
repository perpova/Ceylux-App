import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/invoice_service.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../models/stock_item.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'All';
  final svc = ApiService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Pending', 'Processing', 'Delivered'].map((s) => GestureDetector(
                    onTap: () => setState(() => _filter = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _filter == s ? AppColors.gold.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _filter == s ? AppColors.gold : AppColors.border),
                      ),
                      child: Text(s, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: _filter == s ? AppColors.gold : AppColors.muted,
                      )),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showNewOrderSheet(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A6B).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1A3A6B).withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 16, color: Color(0xFF1A3A6B)),
                      SizedBox(width: 6),
                      Text('New Order', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A3A6B),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AppOrder>>(
            stream: svc.ordersStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppColors.gold));
              }
              final orders = (snap.data ?? [])
                  .where((o) => _filter == 'All' || o.status == _filter)
                  .toList();
              if (orders.isEmpty) {
                return Center(child: Text('No orders', style: TextStyle(color: AppColors.muted)));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                itemCount: orders.length,
                itemBuilder: (context, i) {
                  final o = orders[i];
                  return CeyluxCard(
                    onTap: () => _showOrderDetail(context, o),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('${o.id} • ${o.date}', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              const SizedBox(height: 4),
                              Text('${o.items.length} item(s)', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Rs. ${NumberFormat('#,###').format(o.total)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldLight)),
                            const SizedBox(height: 6),
                            StatusBadge(status: o.status),
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

  void _showOrderDetail(BuildContext context, AppOrder o) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(order: o),
    );
  }

  void _showNewOrderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const _NewOrderSheet(),
    );
  }
}

// ── Order Detail ─────────────────────────────────────────────────────────────
class _OrderDetailSheet extends StatelessWidget {
  final AppOrder order;
  const _OrderDetailSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final svc = ApiService();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            margin: const EdgeInsets.only(bottom: 16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.id, style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 18, color: AppColors.textColor)),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Row(children: [
            Text(order.customerName, style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(width: 8),
            Text('•', style: TextStyle(color: AppColors.border)),
            const SizedBox(width: 8),
            Text(order.date, style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('Size: ${item.size} × ${item.qty}', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Text('Rs. ${NumberFormat('#,###').format(item.subtotal)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
              Text('Rs. ${NumberFormat('#,###').format(order.total)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.goldLight)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: ['Pending', 'Processing', 'Delivered'].map((s) => Expanded(
              child: GestureDetector(
                onTap: () async {
                  await svc.updateOrderStatus(order.id, s);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: order.status == s ? AppColors.gold.withOpacity(0.2) : AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: order.status == s ? AppColors.gold : AppColors.border),
                  ),
                  child: Text(s, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: order.status == s ? AppColors.gold : AppColors.muted)),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              final msg = Uri.encodeComponent(
                '🛍️ CEYLUX Fashion Boutique\n\nOrder: ${order.id}\n'
                '${order.items.map((i) => '• ${i.name} [${i.size}] x${i.qty} — Rs. ${NumberFormat('#,###').format(i.subtotal)}').join('\n')}'
                '\n\n💰 Total: Rs. ${NumberFormat('#,###').format(order.total)}\n\nThank you! 🙏'
              );
              launchUrl(Uri.parse('https://wa.me/?text=$msg'));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF25D366).withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💬', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text('Share via WhatsApp', style: TextStyle(
                    color: Color(0xFF25D366), fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => InvoiceService.shareInvoice(order),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1A3A6B).withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF1A3A6B), size: 18),
                  SizedBox(width: 8),
                  Text('Download Invoice PDF', style: TextStyle(
                    color: Color(0xFF1A3A6B), fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── New Order Sheet ───────────────────────────────────────────────────────────
class _NewOrderSheet extends StatefulWidget {
  const _NewOrderSheet();
  @override
  State<_NewOrderSheet> createState() => _NewOrderSheetState();
}

class _NewOrderSheetState extends State<_NewOrderSheet> {
  String? _selCustId;
  String? _selCustName;
  List<Customer> _customers = [];
  final List<Map<String, dynamic>> _items = [];
  final _discountCtrl = TextEditingController();
  int _manualDiscount = 0;
  final svc = ApiService();

  int get _subtotal => _items.fold<int>(0, (a, b) => a + (b['qty'] as int) * (b['price'] as int));
  int get _discountAmt => (_subtotal * _manualDiscount / 100).round();
  int get _total => _subtotal - _discountAmt;

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selCustId == null || _items.isEmpty) return;
    final now = DateTime.now();
    final orderId = 'ORD-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final o = AppOrder(
      id: orderId,
      customerId: _selCustId!,
      customerName: _selCustName ?? '',
      items: _items.map((i) => OrderItem(
        name: i['name'], qty: i['qty'], price: i['price'], size: i['size'],
      )).toList(),
      total: _total,
      status: 'Pending',
      date: DateFormat('yyyy-MM-dd').format(now),
    );
    await svc.addOrder(o);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + bottomPadding + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              margin: const EdgeInsets.only(bottom: 16)),
            Text('New Order', style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 18, color: AppColors.textColor)),
            const SizedBox(height: 16),

            Text('SELECT CUSTOMER', style: TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: 1)),
            const SizedBox(height: 8),
            StreamBuilder<List<Customer>>(
              stream: svc.customersStream(),
              builder: (context, snap) {
                _customers = snap.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _selCustId,
                  dropdownColor: AppColors.card,
                  style: TextStyle(color: AppColors.textColor, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true, fillColor: AppColors.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.gold)),
                  ),
                  hint: Text('Choose customer', style: TextStyle(color: AppColors.muted)),
                  items: _customers.map((c) => DropdownMenuItem<String>(
                    value: c.id, child: Text(c.name),
                  )).toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    final cust = _customers.firstWhere((c) => c.id == id);
                    setState(() {
                      _selCustId = id;
                      _selCustName = cust.name;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            Text('ADD ITEMS', style: TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: 1)),
            const SizedBox(height: 8),
            StreamBuilder<List<StockItem>>(
              stream: svc.stockStream(),
              builder: (context, snap) {
                final stock = snap.data ?? [];
                return _ItemAdder(stock: stock, onAdd: (item) => setState(() => _items.add(item)));
              },
            ),

            if (_items.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item['name']} [${item['size']}] x${item['qty']}',
                        style: const TextStyle(fontSize: 12))),
                    Text('Rs. ${NumberFormat('#,###').format((item['qty'] as int) * (item['price'] as int))}',
                        style: TextStyle(fontSize: 12, color: AppColors.goldLight, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _items.remove(item)),
                      child: Icon(Icons.close, size: 16, color: AppColors.danger),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),

              // ── Discount Section ──────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DISCOUNT', style: TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppColors.textColor, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(color: AppColors.muted),
                              filled: true,
                              fillColor: AppColors.card,
                              suffixText: '%',
                              suffixStyle: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.gold),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (v) {
                              final val = int.tryParse(v) ?? 0;
                              setState(() => _manualDiscount = val.clamp(0, 100));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...[5, 10, 15].map((p) => GestureDetector(
                          onTap: () {
                            // toggle: same % tap කළොත් clear වෙනවා
                            if (_manualDiscount == p) {
                              _discountCtrl.clear();
                              setState(() => _manualDiscount = 0);
                            } else {
                              _discountCtrl.text = '$p';
                              setState(() => _manualDiscount = p);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: _manualDiscount == p ? AppColors.gold.withOpacity(0.15) : AppColors.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _manualDiscount == p ? AppColors.gold : AppColors.border,
                              ),
                            ),
                            child: Text('$p%', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: _manualDiscount == p ? AppColors.gold : AppColors.muted,
                            )),
                          ),
                        )),
                      ],
                    ),
                    if (_manualDiscount > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('🎁 $_manualDiscount% discount applied',
                              style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('− Rs. ${NumberFormat('#,###').format(_discountAmt)}',
                              style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // ─────────────────────────────────────────────

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Text('Rs. ${NumberFormat('#,###').format(_total)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.goldLight)),
                ],
              ),
              const SizedBox(height: 16),
              GoldButton(
                label: 'Confirm & Create Order',
                onTap: _selCustId != null && _items.isNotEmpty ? _submit : () {},
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Item Adder ────────────────────────────────────────────────────────────────
class _ItemAdder extends StatefulWidget {
  final List<StockItem> stock;
  final Function(Map<String, dynamic>) onAdd;
  const _ItemAdder({required this.stock, required this.onAdd});
  @override
  State<_ItemAdder> createState() => _ItemAdderState();
}

class _ItemAdderState extends State<_ItemAdder> {
  String? _selId;
  String _size = '';
  int _qty = 1;

  StockItem? get _sel => _selId == null ? null : widget.stock.where((s) => s.id == _selId).firstOrNull;
  List<String> get _sizes => _sel == null
      ? []
      : (_sel!.category == 'Kids' ? kidsSizes : allSizes)
          .where((s) => (_sel!.sizes[s] ?? 0) > 0)
          .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selId,
          dropdownColor: AppColors.card,
          style: TextStyle(color: AppColors.textColor, fontSize: 13),
          decoration: InputDecoration(
            filled: true, fillColor: AppColors.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.gold)),
          ),
          hint: Text('Select item', style: TextStyle(color: AppColors.muted)),
          items: widget.stock.map((s) => DropdownMenuItem<String>(
            value: s.id,
            child: Text('${s.name} — Rs. ${s.price}'),
          )).toList(),
          onChanged: (id) => setState(() { _selId = id; _size = ''; _qty = 1; }),
        ),
        if (_sel != null && _sizes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _size.isNotEmpty ? _size : null,
                  dropdownColor: AppColors.card,
                  style: TextStyle(color: AppColors.textColor, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true, fillColor: AppColors.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.gold)),
                  ),
                  hint: Text('Size', style: TextStyle(color: AppColors.muted)),
                  items: _sizes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (s) => setState(() => _size = s ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: AppColors.muted),
                    onPressed: () => setState(() => _qty = (_qty - 1).clamp(1, 99)),
                  ),
                  Text('$_qty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textColor)),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: AppColors.gold),
                    onPressed: () => setState(() => _qty++),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          GoldButton(
            label: '+ Add Item',
            onTap: () {
              if (_sel != null && _size.isNotEmpty) {
                widget.onAdd({'name': _sel!.name, 'qty': _qty, 'price': _sel!.price, 'size': _size});
                setState(() { _selId = null; _size = ''; _qty = 1; });
              }
            },
            isOutlined: true,
          ),
        ],
      ],
    );
  }
}
