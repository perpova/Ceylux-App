import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/invoice_service.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../models/stock_item.dart';
import '../models/tier.dart';
import '../models/delivery_method.dart';
import '../models/payment_method.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/animation_widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'All';
  String _sortBy = 'Recent';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final svc = ApiService();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AppOrder> _applySearchAndSort(List<AppOrder> orders) {
    // Apply status filter
    var filtered = _filter == 'All'
        ? orders
        : orders.where((o) => o.status == _filter).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((o) =>
              o.customerName.toLowerCase().contains(query) ||
              o.id.toLowerCase().contains(query) ||
              o.date.contains(query))
          .toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Recent':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'High to Low':
        filtered.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'Low to High':
        filtered.sort((a, b) => a.total.compareTo(b.total));
        break;
      case 'Customer (A-Z)':
        filtered.sort((a, b) => a.customerName.compareTo(b.customerName));
        break;
      case 'Customer (Z-A)':
        filtered.sort((a, b) => b.customerName.compareTo(a.customerName));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final btnColor = isDark ? AppColors.primaryLight : const Color(0xFF1A3A6B);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search Bar ──────────────────────────────────────────────
              TextFormField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: AppColors.textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by customer name, order ID, or date...',
                  hintStyle: TextStyle(color: AppColors.muted, fontSize: 12),
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.muted, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(Icons.close_rounded,
                              color: AppColors.muted, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.gold, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),

              // ── Status Filter & Sort ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Pending', 'Processing', 'Delivered']
                            .map((s) => GestureDetector(
                                  onTap: () => setState(() => _filter = s),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _filter == s
                                          ? AppColors.gold.withOpacity(0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: _filter == s
                                              ? AppColors.gold
                                              : AppColors.border),
                                    ),
                                    child: Text(s,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _filter == s
                                              ? AppColors.gold
                                              : AppColors.muted,
                                        )),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    onSelected: (v) => setState(() => _sortBy = v),
                    color: AppColors.card,
                    position: PopupMenuPosition.over,
                    itemBuilder: (BuildContext context) {
                      return [
                        'Recent',
                        'Oldest',
                        'High to Low',
                        'Low to High',
                        'Customer (A-Z)',
                        'Customer (Z-A)'
                      ]
                          .map((s) => PopupMenuItem<String>(
                                value: s,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_sortBy == s)
                                      Icon(Icons.check,
                                          size: 16, color: AppColors.gold)
                                    else
                                      const SizedBox(width: 16),
                                    const SizedBox(width: 8),
                                    Text(s,
                                        style: TextStyle(
                                          color: _sortBy == s
                                              ? AppColors.gold
                                              : AppColors.textColor,
                                          fontWeight: _sortBy == s
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        )),
                                  ],
                                ),
                              ))
                          .toList();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(Icons.sort, color: AppColors.muted, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── New Order Button ────────────────────────────────────────
              ActionButton(
                label: 'New Order',
                icon: Icons.add,
                buttonColor: btnColor,
                width: double.infinity,
                onTap: () => _showNewOrderSheet(context),
                padding: 13,
                fontSize: 13,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AppOrder>>(
            stream: svc.ordersStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const LoadingAnimation(message: 'Loading orders...');
              }
              if (snap.hasError) {
                return ErrorAnimation(
                  title: 'Failed to Load Orders',
                  message: snap.error.toString(),
                  onRetry: () {},
                );
              }
              final orders = _applySearchAndSort(snap.data ?? []);
              if (orders.isEmpty) {
                return NoDataAnimation(
                  message: _searchQuery.isNotEmpty 
                      ? 'No orders found for "$_searchQuery"'
                      : 'No orders yet',
                  actionLabel: _searchQuery.isNotEmpty ? 'Clear Search' : null,
                  onAction: _searchQuery.isNotEmpty
                      ? () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        }
                      : null,
                );
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
                              Text(o.customerName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textColor)),
                              const SizedBox(height: 2),
                              Text('${o.id} • ${o.date}',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.muted)),
                              const SizedBox(height: 4),
                              Text('${o.items.length} item(s)',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Rs. ${NumberFormat('#,###').format(o.total)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gold)),
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
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(order: o),
    );
  }

  void _showNewOrderSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _NewOrderScreen()),
    );
  }
}

// ── Order Detail ─────────────────────────────────────────────────────────────
class _OrderDetailSheet extends StatefulWidget {
  final AppOrder order;
  const _OrderDetailSheet({required this.order});

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  late List<OrderItem> _editableItems;
  late Map<int, TextEditingController> _qtyControllers;
  late Map<int, TextEditingController> _priceControllers;
  late Map<int, TextEditingController> _discountControllers;
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  // Delivery method fields
  String? _selectedDeliveryMethodId;
  String? _selectedDeliveryMethodName;
  File? _paymentProofImage;
  List<DeliveryMethod> _deliveryMethods = [];
  bool _loadingDeliveryMethods = false;
  bool _uploadingProof = false;

  // Payment method fields
  String? _selectedPaymentMethodId;
  String? _selectedPaymentMethodName;
  List<PaymentMethod> _paymentMethods = [];
  bool _loadingPaymentMethods = false;

  final svc = ApiService();

  @override
  void initState() {
    super.initState();
    _editableItems = List.from(widget.order.items);
    _initializeControllers();
    _selectedDeliveryMethodId = widget.order.deliveryMethodId;
    _selectedDeliveryMethodName = widget.order.deliveryMethodName;
    _selectedPaymentMethodId = widget.order.paymentMethodId;
    _selectedPaymentMethodName = widget.order.paymentMethodName;
    _loadDeliveryMethods();
    _loadPaymentMethods();
  }

  Future<void> _loadDeliveryMethods() async {
    setState(() => _loadingDeliveryMethods = true);
    try {
      final methods = await svc.getDeliveryMethods();
      if (mounted) {
        setState(() {
          _deliveryMethods = methods;
          _loadingDeliveryMethods = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDeliveryMethods = false);
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _loadingPaymentMethods = true);
    try {
      final methods = await svc.getPaymentMethods();
      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _loadingPaymentMethods = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPaymentMethods = false);
    }
  }

  Future<void> _pickPaymentProof() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _paymentProofImage = File(picked.path));
    }
  }

  Future<void> _saveDeliveryMethod() async {
    if (_selectedDeliveryMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a delivery method'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _uploadingProof = true);
    try {
      String? proofUrl = widget.order.paymentProofUrl;
      if (_paymentProofImage != null) {
        proofUrl = await svc.uploadPaymentProof(_paymentProofImage!);
      }

      final updatedOrder = widget.order.copyWith(
        deliveryMethodId: _selectedDeliveryMethodId,
        deliveryMethodName: _selectedDeliveryMethodName,
        paymentProofUrl: proofUrl,
        paymentMethodId: _selectedPaymentMethodId,
        paymentMethodName: _selectedPaymentMethodName,
      );

      await svc.updateOrder(widget.order.dbId, updatedOrder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text('Payment & Delivery details saved ✓'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingProof = false);
    }
  }

  Widget _buildProofSelectionWidget() {
    if (_paymentProofImage != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _paymentProofImage!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _paymentProofImage = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    } else if (widget.order.paymentProofUrl != null &&
        widget.order.paymentProofUrl!.isNotEmpty) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.order.paymentProofUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Existing Proof',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tap to replace',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 32,
              color: AppColors.muted,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload Payment Proof (Optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Bank transfer screenshot, cheque photo, etc.',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _initializeControllers() {
    _qtyControllers = {};
    _priceControllers = {};
    _discountControllers = {};
    for (int i = 0; i < _editableItems.length; i++) {
      _qtyControllers[i] =
          TextEditingController(text: _editableItems[i].qty.toString());
      _priceControllers[i] =
          TextEditingController(text: _editableItems[i].price.toString());
      _discountControllers[i] =
          TextEditingController(text: _editableItems[i].discount.toString());
    }
  }

  @override
  void dispose() {
    _qtyControllers.values.forEach((c) => c.dispose());
    _priceControllers.values.forEach((c) => c.dispose());
    _discountControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _deleteOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title:
            Text('Delete Order?', style: TextStyle(color: AppColors.textColor)),
        content: Text('Are you sure you want to permanently delete this order?',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        final svc = ApiService();
        await svc.deleteOrder(widget.order.dbId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.delete, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  const Text('Order deleted successfully'),
                ],
              ),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  void _removeItem(int index) {
    if (index >= 0 && index < _editableItems.length) {
      // Dispose the controllers for the removed item
      _qtyControllers[index]?.dispose();
      _priceControllers[index]?.dispose();
      _discountControllers[index]?.dispose();

      // Remove the item
      _editableItems.removeAt(index);

      // Rebuild controllers to match new indices
      _rebuildControllers();
    }
  }

  void _rebuildControllers() {
    // Clear all old controllers
    _qtyControllers.values.forEach((c) => c.dispose());
    _priceControllers.values.forEach((c) => c.dispose());
    _discountControllers.values.forEach((c) => c.dispose());

    // Reinitialize with current items
    _initializeControllers();
  }

  void _updateEditableItem(int index) {
    final qty = int.tryParse(_qtyControllers[index]?.text ?? '0') ?? 0;
    final price = int.tryParse(_priceControllers[index]?.text ?? '0') ?? 0;
    final discount =
        int.tryParse(_discountControllers[index]?.text ?? '0') ?? 0;

    if (index < _editableItems.length) {
      _editableItems[index] = OrderItem(
        name: _editableItems[index].name,
        qty: qty,
        price: price,
        size: _editableItems[index].size,
        discount: discount,
      );
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      // Update all items from controllers
      for (int i = 0; i < _editableItems.length; i++) {
        _updateEditableItem(i);
      }

      final svc = ApiService();
      // Calculate new total with discount
      int subtotal = 0;
      for (var item in _editableItems) {
        subtotal += item.subtotal;
      }
      int itemDiscounts = 0;
      for (var item in _editableItems) {
        itemDiscounts += (item.subtotal * item.discount ~/ 100);
      }
      // Apply bill discount percentage to the amount after item discounts
      int billDiscountAmount =
          ((subtotal - itemDiscounts) * widget.order.discountPercentage ~/ 100);
      // Apply loyalty discount to the amount after item and bill discounts
      int afterBillDiscount = subtotal - itemDiscounts - billDiscountAmount;
      int loyaltyDiscountAmount = (afterBillDiscount * widget.order.loyaltyDiscount ~/ 100);
      int newTotal = subtotal - itemDiscounts - billDiscountAmount - loyaltyDiscountAmount;

      final updatedOrder = AppOrder(
        dbId: widget.order.dbId,
        id: widget.order.id,
        customerId: widget.order.customerId,
        customerName: widget.order.customerName,
        customerAddress: widget.order.customerAddress,
        customerPhone: widget.order.customerPhone,
        items: _editableItems,
        total: newTotal,
        status: widget.order.status,
        date: widget.order.date,
        discountPercentage: widget.order.discountPercentage,
        loyaltyDiscount: widget.order.loyaltyDiscount,
        deliveryMethodId: widget.order.deliveryMethodId,
        deliveryMethodName: widget.order.deliveryMethodName,
        paymentProofUrl: widget.order.paymentProofUrl,
        deliveryNotes: widget.order.deliveryNotes,
        paymentMethodId: widget.order.paymentMethodId,
        paymentMethodName: widget.order.paymentMethodName,
      );

      await svc.updateOrder(widget.order.dbId, updatedOrder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text('Order updated successfully ✓'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
        // Close the sheet to refresh with updated data
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int get _totalSubtotal =>
      _editableItems.fold<int>(0, (sum, item) => sum + item.subtotal);
  int get _totalItemDiscounts => _editableItems.fold<int>(
      0, (sum, item) => sum + (item.subtotal * item.discount ~/ 100));
  int get _billDiscountAmount => ((_totalSubtotal - _totalItemDiscounts) *
      widget.order.discountPercentage ~/
      100);
  int get _afterBillDiscount =>
      _totalSubtotal - _totalItemDiscounts - _billDiscountAmount;
  int get _loyaltyDiscountAmount =>
      (_afterBillDiscount * widget.order.loyaltyDiscount ~/ 100);
  int get _totalAmount =>
      _totalSubtotal - _totalItemDiscounts - _billDiscountAmount - _loyaltyDiscountAmount;

  @override
  Widget build(BuildContext context) {
    final svc = ApiService();
    final isDark = AppColors.isDark;
    final btnColor = isDark ? AppColors.primaryLight : const Color(0xFF1A3A6B);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back,
                      size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.order.id,
                    style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 18,
                        color: AppColors.textColor)),
                Row(
                  children: [
                    StatusBadge(status: widget.order.status),
                    const SizedBox(width: 8),
                    if (!_isEditMode) ...[
                      GestureDetector(
                        onTap: () {
                          // Reset controllers when entering edit mode
                          _editableItems = List.from(widget.order.items);
                          _initializeControllers();
                          setState(() => _isEditMode = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.gold.withOpacity(0.3)),
                          ),
                          child:
                              Icon(Icons.edit, color: AppColors.gold, size: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _deleteOrder,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.danger.withOpacity(0.3)),
                          ),
                          child: Icon(Icons.delete_outline,
                              color: AppColors.danger, size: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(children: [
              Text(widget.order.customerName,
                  style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: AppColors.border)),
              const SizedBox(width: 8),
              Text(widget.order.date,
                  style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                  color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: _editableItems.asMap().entries.map((entry) {
                  int idx = entry.key;
                  OrderItem item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: _isEditMode
                        ? Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textColor)),
                                        Text('Size: ${item.size}',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _removeItem(idx)),
                                    child: Icon(Icons.delete,
                                        color: AppColors.danger, size: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Qty',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.muted)),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: AppColors.border),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textColor),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            controller: _qtyControllers[idx],
                                            onChanged: (v) =>
                                                _updateEditableItem(idx),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Price',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.muted)),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: AppColors.border),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textColor),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            controller: _priceControllers[idx],
                                            onChanged: (v) =>
                                                _updateEditableItem(idx),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Discount %',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.muted)),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: AppColors.border),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textColor),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            controller:
                                                _discountControllers[idx],
                                            onChanged: (v) =>
                                                _updateEditableItem(idx),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                  'Subtotal: Rs. ${NumberFormat('#,###').format(_editableItems[idx].subtotal)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                      fontStyle: FontStyle.italic)),
                              const SizedBox(height: 8),
                              if (idx < _editableItems.length - 1)
                                Divider(color: AppColors.border, height: 16),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textColor)),
                                    Text('Size: ${item.size} × ${item.qty}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.muted)),
                                  ],
                                ),
                              ),
                              Text(
                                  'Rs. ${NumberFormat('#,###').format(item.subtotal)}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textColor)),
                            ],
                          ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w600)),
                Text('Rs. ${NumberFormat('#,###').format(_totalSubtotal)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor)),
              ],
            ),
            if (_totalItemDiscounts > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Item Discounts',
                      style: TextStyle(fontSize: 12, color: AppColors.danger)),
                  Text(
                      '−Rs. ${NumberFormat('#,###').format(_totalItemDiscounts)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            if (widget.order.discountPercentage > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bill Discount (${widget.order.discountPercentage}%)',
                      style: TextStyle(fontSize: 12, color: AppColors.danger)),
                  Text(
                      '−Rs. ${NumberFormat('#,###').format(_billDiscountAmount)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            if (widget.order.loyaltyDiscount > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Loyalty Discount (${widget.order.loyaltyDiscount}%)',
                      style: TextStyle(fontSize: 12, color: AppColors.danger)),
                  Text(
                      '−Rs. ${NumberFormat('#,###').format(_loyaltyDiscountAmount)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 13,
                        color: AppColors.gold)),
                Text('Rs. ${NumberFormat('#,###').format(_totalAmount)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.gold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditMode)
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      label: 'Cancel',
                      onTap: () {
                        // Reset to original items and exit edit mode
                        _editableItems = List.from(widget.order.items);
                        _initializeControllers();
                        setState(() => _isEditMode = false);
                      },
                      isOutlined: true,
                      buttonColor: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ActionButton(
                      label: 'Save Changes',
                      onTap: _saveChanges,
                      isLoading: _isSaving,
                      buttonColor: AppColors.gold,
                      padding: 12,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: ['Pending', 'Processing', 'Delivered']
                    .map((s) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionButton(
                              label: s,
                              onTap: () async {
                                final sStatus = s;
                                if (widget.order.status != sStatus) {
                                  svc.updateOrderStatus(widget.order.dbId, sStatus).then((_) {
                                    InvoiceService.sendStatusUpdateEmail(widget.order, sStatus);
                                  }).catchError((err) {
                                    print('❌ Failed to update order status: $err');
                                  });
                                }
                                if (context.mounted) Navigator.pop(context);
                              },
                              buttonColor: widget.order.status == s
                                  ? AppColors.gold
                                  : AppColors.muted,
                              isOutlined: widget.order.status != s,
                              fontSize: 11,
                              padding: 10,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 12),
            StreamBuilder<List<Customer>>(
              stream: svc.customersStream(),
              builder: (context, snap) {
                final customers = snap.data ?? [];
                final customer = customers.firstWhere(
                  (c) => c.id == widget.order.customerId,
                  orElse: () => Customer(
                      id: '',
                      name: '',
                      phone: '',
                      email: '',
                      address: '',
                      totalOrders: 0,
                      totalSpent: 0),
                );
                final phone = customer.phone.trim();

                return Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        label: 'WhatsApp',
                        icon: Icons.chat,
                        buttonColor: const Color(0xFF25D366),
                        onTap: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            useRootNavigator: true,
                            builder: (_) => AlertDialog(
                              backgroundColor: AppColors.card,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                      color: const Color(0xFF25D366)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Preparing Invoice...',
                                    style: TextStyle(
                                      color: AppColors.textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Creating PDF and preparing for WhatsApp',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );

                          try {
                            String formattedPhone = phone;
                            if (formattedPhone.isNotEmpty) {
                              formattedPhone =
                                  formattedPhone.replaceAll(RegExp(r'\D'), '');
                              if (formattedPhone.startsWith('0') &&
                                  formattedPhone.length == 10) {
                                formattedPhone =
                                    '94${formattedPhone.substring(1)}';
                              } else if (!formattedPhone.startsWith('94') &&
                                  formattedPhone.length == 9) {
                                formattedPhone = '94$formattedPhone';
                              }
                            }

                            await InvoiceService.shareInvoice(widget.order,
                                phone: formattedPhone);

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error,
                                          color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Error: $e',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ActionButton(
                        label: 'PDF',
                        icon: Icons.picture_as_pdf,
                        buttonColor: AppColors.gold,
                        onTap: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            useRootNavigator: true,
                            builder: (_) => AlertDialog(
                              backgroundColor: AppColors.card,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                      color: AppColors.gold),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Generating Receipt...',
                                    style: TextStyle(
                                      color: AppColors.textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Creating PDF and saving to downloads',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );

                          try {
                            await InvoiceService.downloadInvoice(widget.order);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.download_done,
                                          color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'PDF downloaded!',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11),
                                            ),
                                            Text(
                                              'Check Downloads folder',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.white70),
                                            ),
                                          ],
                                        ),
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
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error,
                                          color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Failed: $e',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
            // ── Delivery & Payment Info Display (View Mode) ──
            if (!_isEditMode) ...[
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),
              Text(
                'DELIVERY & PAYMENT INFO',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: AppColors.muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.isDark
                        ? [
                            AppColors.card,
                            AppColors.card.withOpacity(0.8),
                          ]
                        : [
                            const Color(0xFFF8FAFC),
                            const Color(0xFFF1F5F9),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delivery method row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_shipping_outlined,
                            size: 18,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DELIVERY METHOD',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedDeliveryMethodName ?? 'Not selected',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.border.withOpacity(0.5), height: 1),
                    const SizedBox(height: 16),
                    // Payment method row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.payment_outlined,
                            size: 18,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PAYMENT METHOD',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.muted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedPaymentMethodName ?? 'Not selected',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Payment proof image section
                    if (widget.order.paymentProofUrl != null &&
                        widget.order.paymentProofUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Divider(color: AppColors.border.withOpacity(0.5), height: 1),
                      const SizedBox(height: 16),
                      Text(
                        'PAYMENT PROOF',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          // Show zoomable interactive full-screen image dialog
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.black.withOpacity(0.95),
                              insetPadding: EdgeInsets.zero,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      maxScale: 4.0,
                                      child: Image.network(
                                        widget.order.paymentProofUrl!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 40,
                                    right: 20,
                                    child: IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.network(
                                  widget.order.paymentProofUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      color: AppColors.bg,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, st) =>
                                      Container(
                                    height: 200,
                                    color: AppColors.bg,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_not_supported_outlined,
                                              color: AppColors.muted,
                                              size: 32),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Could not load payment proof image',
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Semi-transparent overlay to indicate click action
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                    color: Colors.black.withOpacity(0.6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.zoom_in,
                                          color: Colors.white.withOpacity(0.9),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Tap to view full size',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── UPDATE DELIVERY & PAYMENT SECTION (EDIT MODE) ──
            if (!_isEditMode && widget.order.status != 'Delivered') ...[
              Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),
              Text(
                'UPDATE DELIVERY & PAYMENT',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: AppColors.muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delivery Method Selection
                    Text(
                      'DELIVERY METHOD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingDeliveryMethods)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
                        ),
                      )
                    else if (_deliveryMethods.isEmpty)
                      Text(
                        'No delivery methods available',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDeliveryMethodId,
                            isExpanded: true,
                            dropdownColor: AppColors.card,
                            style: TextStyle(color: AppColors.textColor, fontSize: 13, fontWeight: FontWeight.w500),
                            hint: Text('Select Delivery Method',
                                style: TextStyle(color: AppColors.muted, fontSize: 13)),
                            items: _deliveryMethods
                                .map((method) => DropdownMenuItem<String>(
                                      value: method.id,
                                      child: Text('${method.emoji} ${method.name}'),
                                    ))
                                .toList(),
                            onChanged: (id) {
                              if (id != null) {
                                final method = _deliveryMethods.firstWhere((m) => m.id == id);
                                setState(() {
                                  _selectedDeliveryMethodId = id;
                                  _selectedDeliveryMethodName = method.name;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Payment Method Selection
                    Text(
                      'PAYMENT METHOD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingPaymentMethods)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
                        ),
                      )
                    else if (_paymentMethods.isEmpty)
                      Text(
                        'No payment methods available',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPaymentMethodId,
                            isExpanded: true,
                            dropdownColor: AppColors.card,
                            style: TextStyle(color: AppColors.textColor, fontSize: 13, fontWeight: FontWeight.w500),
                            hint: Text('Select Payment Method',
                                style: TextStyle(color: AppColors.muted, fontSize: 13)),
                            items: _paymentMethods
                                .map((method) => DropdownMenuItem<String>(
                                      value: method.id,
                                      child: Text('${method.emoji} ${method.name}'),
                                    ))
                                .toList(),
                            onChanged: (id) {
                              if (id != null) {
                                final method = _paymentMethods.firstWhere((m) => m.id == id);
                                setState(() {
                                  _selectedPaymentMethodId = id;
                                  _selectedPaymentMethodName = method.name;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Payment Proof Selection (Optional)
                    Text(
                      'PAYMENT PROOF (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickPaymentProof,
                      child: _buildProofSelectionWidget(),
                    ),
                    const SizedBox(height: 20),

                    // Action Button to Save Details
                    ActionButton(
                      label: 'Save Payment & Delivery Details',
                      onTap: _saveDeliveryMethod,
                      isLoading: _uploadingProof,
                      buttonColor: AppColors.primary,
                      padding: 12,
                      fontSize: 13,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ── New Order Screen (Full Screen) ─────────────────────────────────────────────
class _NewOrderScreen extends StatefulWidget {
  const _NewOrderScreen();
  @override
  State<_NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<_NewOrderScreen> {
  String? _selCustId;
  String? _selCustName;
  String? _selCustAddress;
  String? _selCustPhone;
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  String _customerSearch = '';
  final _customerSearchCtrl = TextEditingController();

  String _itemSearch = '';
  final _itemSearchCtrl = TextEditingController();
  List<StockItem> _stock = [];
  List<StockItem> _filteredStock = [];

  // Selected items with per-item settings
  final List<Map<String, dynamic>> _selectedItems = [];

  int _overallDiscount = 0;
  final _overallDiscountCtrl = TextEditingController();
  
  int _loyaltyDiscount = 0;
  final _loyaltyDiscountCtrl = TextEditingController();

  List<Tier> _tiers = [];
  final svc = ApiService();

  // Delivery method fields
  String? _selectedDeliveryMethodId;
  String? _selectedDeliveryMethodName;
  File? _paymentProofImage;
  List<DeliveryMethod> _deliveryMethods = [];
  bool _loadingDeliveryMethods = false;
  bool _uploadingProof = false;

  // Payment method fields
  String? _selectedPaymentMethodId;
  String? _selectedPaymentMethodName;
  List<PaymentMethod> _paymentMethods = [];
  bool _loadingPaymentMethods = false;

  @override
  void initState() {
    super.initState();
    _loadTiers();
    _loadDeliveryMethods();
    _loadPaymentMethods();
  }

  Future<void> _loadTiers() async {
    try {
      final tiers = await svc.getTiers();
      if (mounted) {
        setState(() => _tiers = tiers);
      }
    } catch (_) {}
  }

  Future<void> _loadDeliveryMethods() async {
    setState(() => _loadingDeliveryMethods = true);
    try {
      final methods = await svc.getDeliveryMethods();
      if (mounted) {
        setState(() {
          _deliveryMethods = methods;
          _loadingDeliveryMethods = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDeliveryMethods = false);
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _loadingPaymentMethods = true);
    try {
      final methods = await svc.getPaymentMethods();
      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _loadingPaymentMethods = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPaymentMethods = false);
    }
  }

  Future<void> _pickPaymentProof() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _paymentProofImage = File(picked.path));
    }
  }

  Widget _buildProofSelectionWidget() {
    if (_paymentProofImage != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _paymentProofImage!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _paymentProofImage = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 32,
              color: AppColors.muted,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload Payment Proof (Optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Bank transfer screenshot, cheque photo, etc.',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }
  }

  int _getCustomerLoyaltyDiscount(Customer c) {
    if (_tiers.isEmpty) return 0;
    final sortedTiers = List<Tier>.from(_tiers)
      ..sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
    for (final tier in sortedTiers) {
      if (c.totalOrders >= tier.minOrders &&
          c.totalSpent >= tier.minSpent &&
          c.ownerRating >= tier.minRating) {
        return tier.discountPercentage;
      }
    }
    return 0;
  }

  @override
  void dispose() {
    _customerSearchCtrl.dispose();
    _itemSearchCtrl.dispose();
    _overallDiscountCtrl.dispose();
    _loyaltyDiscountCtrl.dispose();
    super.dispose();
  }

  void _updateCustomerFilter(String query) {
    setState(() {
      _customerSearch = query.toLowerCase();
      if (_customerSearch.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers
            .where((c) =>
                c.name.toLowerCase().contains(_customerSearch) ||
                c.phone.contains(_customerSearch))
            .toList();
      }
    });
  }

  void _updateItemFilter(String query) {
    setState(() {
      _itemSearch = query.toLowerCase();
      if (_itemSearch.isEmpty) {
        _filteredStock = _stock;
      } else {
        _filteredStock = _stock
            .where((item) =>
                item.name.toLowerCase().contains(_itemSearch) ||
                item.category.toLowerCase().contains(_itemSearch) ||
                item.sku.toLowerCase().contains(_itemSearch))
            .toList();
      }
    });
  }

  void _selectCustomer(Customer customer) {
    final loyaltyDisc = _getCustomerLoyaltyDiscount(customer);
    setState(() {
      _selCustId = customer.id;
      _selCustName = customer.name;
      _selCustAddress = customer.address;
      _selCustPhone = customer.phone;
      _loyaltyDiscount = loyaltyDisc;
      _loyaltyDiscountCtrl.text = '$loyaltyDisc';
      _customerSearchCtrl.clear();
      _customerSearch = '';
      _filteredCustomers = _customers;
    });
  }

  void _clearCustomer() {
    setState(() {
      _selCustId = null;
      _selCustName = null;
      _selCustAddress = null;
      _selCustPhone = null;
      _loyaltyDiscount = 0;
      _loyaltyDiscountCtrl.clear();
      _customerSearchCtrl.clear();
      _customerSearch = '';
      _filteredCustomers = _customers;
    });
  }

  void _addItem(StockItem item, String size, int qty, int price) {
    setState(() {
      _selectedItems.add({
        'item': item,
        'size': size,
        'qty': qty,
        'price': price,
        'discount': item.discount, // Use discount from stock item
      });
      _itemSearchCtrl.clear();
      _itemSearch = '';
      _filteredStock = _stock;
    });
  }

  void _removeItem(int index) {
    setState(() => _selectedItems.removeAt(index));
  }

  void _updateItem(int index, {int? qty, int? price, int? discount}) {
    setState(() {
      if (qty != null) _selectedItems[index]['qty'] = qty;
      if (price != null) _selectedItems[index]['price'] = price;
      if (discount != null) _selectedItems[index]['discount'] = discount;
    });
  }

  void _showItemSettings(int index) {
    final item = _selectedItems[index];
    showDialog(
      context: context,
      builder: (context) => _ItemSettingsDialog(
        item: item,
        selectedItems: _selectedItems,
        onSave: (qty, price, discount) {
          _updateItem(index, qty: qty, price: price, discount: discount);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAddCustomerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCustomerSheet(onCustomerAdded: (customer) {
        // Auto-select the newly added customer in real-time
        setState(() {
          _selCustId = customer.id;
          _selCustName = customer.name;
          _selCustPhone = customer.phone;
          _selCustAddress = customer.address;
          _customerSearchCtrl.clear();
          _customerSearch = '';
          // Add to customers list if not already there
          if (!_customers.any((c) => c.id == customer.id)) {
            _customers.add(customer);
            _filteredCustomers = _customers;
          }
        });
      }),
    );
  }

  int _getItemSubtotal(Map<String, dynamic> item) =>
      (item['qty'] as int) * (item['price'] as int);
  int _getItemDiscount(Map<String, dynamic> item) =>
      _getItemSubtotal(item) * (item['discount'] as int) ~/ 100;
  int _getItemTotal(Map<String, dynamic> item) =>
      _getItemSubtotal(item) - _getItemDiscount(item);

  int get _totalSubtotal =>
      _selectedItems.fold<int>(0, (a, b) => a + _getItemSubtotal(b));
  int get _totalItemDiscounts =>
      _selectedItems.fold<int>(0, (a, b) => a + _getItemDiscount(b));
  int get _overallDiscountAmt =>
      ((_totalSubtotal - _totalItemDiscounts) * _overallDiscount ~/ 100);
  int get _afterBillDiscount =>
      _totalSubtotal - _totalItemDiscounts - _overallDiscountAmt;
  int get _loyaltyDiscountAmt =>
      (_afterBillDiscount * _loyaltyDiscount ~/ 100);
  int get _grandTotal =>
      _totalSubtotal - _totalItemDiscounts - _overallDiscountAmt - _loyaltyDiscountAmt;

  // Group items by item ID (same item, different sizes)
  Map<String, List<Map<String, dynamic>>> _groupItemsByName() {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (int i = 0; i < _selectedItems.length; i++) {
      final item = _selectedItems[i];
      final key = item['item'].id;
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add({...item, '_index': i});
    }
    return groups;
  }

  Future<void> _submitOrder() async {
    if (_selCustId == null || _selectedItems.isEmpty) return;

    setState(() => _uploadingProof = true);

    try {
      String? proofUrl;
      if (_paymentProofImage != null) {
        proofUrl = await svc.uploadPaymentProof(_paymentProofImage!);
      }

      final now = DateTime.now();
      final orderId = 'ORD-${now.millisecondsSinceEpoch.toString().substring(7)}';
      final o = AppOrder(
        dbId: '',
        id: orderId,
        customerId: _selCustId!,
        customerName: _selCustName ?? '',
        customerAddress: _selCustAddress,
        customerPhone: _selCustPhone,
        items: _selectedItems
            .map((i) => OrderItem(
                  name: i['item'].name,
                  qty: i['qty'],
                  price: i['price'],
                  size: i['size'],
                  discount: i['discount'] ?? 0,
                ))
            .toList(),
        total: _grandTotal,
        status: 'Pending',
        date: DateFormat('yyyy-MM-dd').format(now),
        discountPercentage: _overallDiscount,
        loyaltyDiscount: _loyaltyDiscount,
        deliveryMethodId: _selectedDeliveryMethodId,
        deliveryMethodName: _selectedDeliveryMethodName,
        paymentMethodId: _selectedPaymentMethodId,
        paymentMethodName: _selectedPaymentMethodName,
        paymentProofUrl: proofUrl,
      );
      print('DEBUG: Creating order with discountPercentage: $_overallDiscount, loyaltyDiscount: $_loyaltyDiscount');
      print('DEBUG: Order toMap: ${o.toMap()}');
      await svc.addOrder(o);

      // Fetch updated customer details asynchronously to check and notify of loyalty status progress
      try {
        svc.getCustomers().then((updatedCustomers) {
          final updatedCustomer = updatedCustomers.where((c) => c.id == _selCustId).firstOrNull;
          if (updatedCustomer != null && updatedCustomer.email.trim().isNotEmpty) {
            svc.getTiers().then((tiers) {
              if (tiers.isNotEmpty) {
                final sortedTiers = List<Tier>.from(tiers)
                  ..sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
                
                Tier? earnedTier;
                for (final tier in sortedTiers) {
                  if (updatedCustomer.totalOrders >= tier.minOrders &&
                      updatedCustomer.totalSpent >= tier.minSpent &&
                      updatedCustomer.ownerRating >= tier.minRating) {
                    earnedTier = tier;
                    break;
                  }
                }

                if (earnedTier != null) {
                  // Trigger Loyalty congrats email asynchronously
                  InvoiceService.sendLoyaltyEmail(updatedCustomer, earnedTier);
                }
              }
            });
          }
        }).catchError((err) {
          print('❌ Failed fetching updated customer for loyalty check: $err');
        });
      } catch (e) {
        print('❌ Failed checking loyalty tier achievement: $e');
      }

      // Automatically trigger initial invoice email asynchronously
      InvoiceService.sendInitialInvoiceEmail(o);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Failed to create order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingProof = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text('Create New Order',
            style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 20,
                color: AppColors.textColor)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Customer>>(
        stream: svc.customersStream(),
        builder: (context, custSnap) {
          _customers = custSnap.data ?? [];
          if (_filteredCustomers.isEmpty && _customerSearch.isEmpty) {
            _filteredCustomers = _customers;
          }

          return StreamBuilder<List<StockItem>>(
            stream: svc.stockStream(),
            builder: (context, stockSnap) {
              _stock = stockSnap.data ?? [];
              if (_filteredStock.isEmpty && _itemSearch.isEmpty) {
                _filteredStock = _stock;
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Customer Section ────────────────────────────────
                    Container(
                      color: AppColors.card,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CUSTOMER',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          if (_selCustId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.gold.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Selected',
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: AppColors.muted)),
                                        Text(_selCustName ?? '',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.gold)),
                                        const SizedBox(height: 6),
                                        if (_selCustPhone != null &&
                                            _selCustPhone!.isNotEmpty)
                                          Text(_selCustPhone!,
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.muted)),
                                        if (_selCustAddress != null &&
                                            _selCustAddress!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(_selCustAddress!,
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.muted,
                                                  height: 1.3),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _clearCustomer,
                                    child: Icon(Icons.close,
                                        color: AppColors.gold),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _customerSearchCtrl,
                                        onChanged: _updateCustomerFilter,
                                        style: TextStyle(
                                            color: AppColors.textColor,
                                            fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'Search customer...',
                                          hintStyle: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12),
                                          prefixIcon: Icon(Icons.search,
                                              color: AppColors.muted, size: 18),
                                          suffixIcon: _customerSearch.isNotEmpty
                                              ? GestureDetector(
                                                  onTap: () {
                                                    _customerSearchCtrl.clear();
                                                    _updateCustomerFilter('');
                                                  },
                                                  child: Icon(
                                                      Icons.close_rounded,
                                                      color: AppColors.muted,
                                                      size: 18),
                                                )
                                              : null,
                                          filled: true,
                                          fillColor: AppColors.bg,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                                color: AppColors.border),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                                color: AppColors.border),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                                color: AppColors.gold),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.gold
                                                .withOpacity(0.3)),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () =>
                                              _showAddCustomerSheet(context),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Icon(Icons.person_add,
                                                color: AppColors.gold,
                                                size: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_customers.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    constraints:
                                        const BoxConstraints(maxHeight: 200),
                                    decoration: BoxDecoration(
                                      color: AppColors.bg,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _filteredCustomers.length,
                                      itemBuilder: (context, i) {
                                        final c = _filteredCustomers[i];
                                        return GestureDetector(
                                          onTap: () => _selectCustomer(c),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              border: i <
                                                      _filteredCustomers
                                                              .length -
                                                          1
                                                  ? Border(
                                                      bottom: BorderSide(
                                                          color: AppColors
                                                              .border
                                                              .withOpacity(
                                                                  0.5)))
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(c.name,
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: AppColors
                                                                  .textColor)),
                                                      Text(c.phone,
                                                          style: TextStyle(
                                                              fontSize: 10,
                                                              color: AppColors
                                                                  .muted)),
                                                    ],
                                                  ),
                                                ),
                                                Icon(Icons.arrow_forward,
                                                    color: AppColors.muted,
                                                    size: 16),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ] else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    child: Text(
                                        'No customers found. Add one using the + button!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.muted,
                                            fontStyle: FontStyle.italic)),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Items Section ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ADD ITEMS',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),

                          // Item Search
                          TextField(
                            controller: _itemSearchCtrl,
                            onChanged: _updateItemFilter,
                            style: TextStyle(
                                color: AppColors.textColor, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search items...',
                              hintStyle: TextStyle(
                                  color: AppColors.muted, fontSize: 12),
                              prefixIcon: Icon(Icons.search,
                                  color: AppColors.muted, size: 18),
                              suffixIcon: _itemSearch.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _itemSearchCtrl.clear();
                                        _updateItemFilter('');
                                      },
                                      child: Icon(Icons.close_rounded,
                                          color: AppColors.muted, size: 18),
                                    )
                                  : null,
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
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Items Grid/List
                          Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: _filteredStock.isEmpty
                                ? Center(
                                    child: Text('No items found',
                                        style:
                                            TextStyle(color: AppColors.muted)),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _filteredStock.length,
                                    itemBuilder: (context, i) {
                                      final item = _filteredStock[i];
                                      final hasStock = item.totalQty > 0;
                                      return GestureDetector(
                                        onTap: hasStock
                                            ? () => _showAddItemDialog(item)
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: hasStock
                                                ? Colors.transparent
                                                : AppColors.danger
                                                    .withOpacity(0.05),
                                            border: i <
                                                    _filteredStock.length - 1
                                                ? Border(
                                                    bottom: BorderSide(
                                                        color: AppColors.border
                                                            .withOpacity(0.5)))
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(item.emoji,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        16)),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(item.name,
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: AppColors.textColor)),
                                                              Text(
                                                                  'Rs. ${item.price}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      color: AppColors
                                                                          .gold,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600)),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                        'Stock: ${item.totalQty}',
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            color: item
                                                                    .isOutOfStock
                                                                ? AppColors
                                                                    .danger
                                                                : AppColors
                                                                    .muted)),
                                                  ],
                                                ),
                                              ),
                                              if (hasStock)
                                                Icon(Icons.add_circle_outline,
                                                    color: AppColors.gold)
                                              else
                                                Icon(Icons.block,
                                                    color: AppColors.danger),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Selected Items Section ────────────────────────────
                    if (_selectedItems.isNotEmpty)
                      Container(
                        color: AppColors.card,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'SELECTED ITEMS (${_groupItemsByName().length} ${_groupItemsByName().length == 1 ? 'item' : 'items'})',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.muted,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ..._groupItemsByName().entries.map((groupEntry) {
                              final itemGroup = groupEntry.value;
                              final firstItem = itemGroup.first;
                              final stockItem = firstItem['item'] as StockItem;

                              // Calculate total for entire group
                              int groupSubtotal = 0;
                              int groupDiscount = 0;
                              for (var item in itemGroup) {
                                groupSubtotal += _getItemSubtotal(item);
                                groupDiscount += _getItemDiscount(item);
                              }
                              int groupTotal = groupSubtotal - groupDiscount;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Item name and emoji
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(stockItem.emoji,
                                                style: const TextStyle(
                                                    fontSize: 16)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(stockItem.name,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors
                                                          .textColor)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // List of sizes and quantities
                                    ...itemGroup.asMap().entries.map((entry) {
                                      final sizeIdx = entry.key;
                                      final item = entry.value;
                                      final originalIdx = item['_index'] as int;

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      '${item['size']} • Qty: ${item['qty']} • Rs. ${item['price']}',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              AppColors.muted,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                      'Subtotal: Rs. ${_getItemSubtotal(item)}',
                                                      style: TextStyle(
                                                          fontSize: 9,
                                                          color:
                                                              AppColors.muted)),
                                                  if (item['discount'] > 0) ...[
                                                    const SizedBox(height: 1),
                                                    Text(
                                                        'Discount: −Rs. ${_getItemDiscount(item)} (${item['discount']}%)',
                                                        style: TextStyle(
                                                            fontSize: 9,
                                                            color: AppColors
                                                                .danger)),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () =>
                                                      _showItemSettings(
                                                          originalIdx),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.gold
                                                          .withOpacity(0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Icon(Icons.edit,
                                                        size: 12,
                                                        color: AppColors.gold),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                GestureDetector(
                                                  onTap: () =>
                                                      _removeItem(originalIdx),
                                                  child: Icon(Icons.close,
                                                      color: AppColors.danger,
                                                      size: 16),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),

                                    const SizedBox(height: 10),
                                    Divider(color: AppColors.border, height: 1),
                                    const SizedBox(height: 10),

                                    // Group totals
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Subtotal: Rs. $groupSubtotal',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.muted)),
                                            if (groupDiscount > 0) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                  'Discount: −Rs. $groupDiscount',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.danger)),
                                            ],
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.gold.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text('Total: Rs. $groupTotal',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.gold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Discount Section ────────────────────────────────
                    if (_selectedItems.isNotEmpty)
                      Container(
                        color: AppColors.card,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BILL DISCOUNT',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.muted,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _overallDiscountCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                        color: AppColors.textColor,
                                        fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle:
                                          TextStyle(color: AppColors.muted),
                                      filled: true,
                                      fillColor: AppColors.bg,
                                      suffixText: '%',
                                      suffixStyle: TextStyle(
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.bold),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide:
                                            BorderSide(color: AppColors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide:
                                            BorderSide(color: AppColors.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide:
                                            BorderSide(color: AppColors.gold),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                    ),
                                    onChanged: (v) {
                                      final val = int.tryParse(v) ?? 0;
                                      setState(() =>
                                          _overallDiscount = val.clamp(0, 100));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ...[5, 10, 15]
                                    .map((p) => GestureDetector(
                                          onTap: () {
                                            if (_overallDiscount == p) {
                                              _overallDiscountCtrl.clear();
                                              setState(
                                                  () => _overallDiscount = 0);
                                            } else {
                                              _overallDiscountCtrl.text = '$p';
                                              setState(
                                                  () => _overallDiscount = p);
                                            }
                                          },
                                          child: Container(
                                            margin:
                                                const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: _overallDiscount == p
                                                  ? AppColors.gold
                                                      .withOpacity(0.15)
                                                  : AppColors.bg,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _overallDiscount == p
                                                    ? AppColors.gold
                                                    : AppColors.border,
                                              ),
                                            ),
                                            child: Text('$p%',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: _overallDiscount == p
                                                      ? AppColors.gold
                                                      : AppColors.muted,
                                                )),
                                          ),
                                        ))
                                    .toList(),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Loyalty Discount Section ────────────────────────
                    if (_selectedItems.isNotEmpty)
                      Container(
                        color: AppColors.card,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LOYALTY DISCOUNT',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.muted,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _loyaltyDiscountCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                        color: AppColors.textColor,
                                        fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle:
                                          TextStyle(color: AppColors.muted),
                                      filled: true,
                                      fillColor: AppColors.bg,
                                      suffixText: '%',
                                      suffixStyle: TextStyle(
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.bold),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide:
                                            BorderSide(color: AppColors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide:
                                            BorderSide(color: AppColors.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide:
                                            BorderSide(color: AppColors.gold),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                    ),
                                    onChanged: (v) {
                                      final val = int.tryParse(v) ?? 0;
                                      setState(() =>
                                          _loyaltyDiscount = val.clamp(0, 100));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ...[5, 10, 15]
                                    .map((p) => GestureDetector(
                                          onTap: () {
                                            if (_loyaltyDiscount == p) {
                                              _loyaltyDiscountCtrl.clear();
                                              setState(
                                                  () => _loyaltyDiscount = 0);
                                            } else {
                                              _loyaltyDiscountCtrl.text = '$p';
                                              setState(
                                                  () => _loyaltyDiscount = p);
                                            }
                                          },
                                          child: Container(
                                            margin:
                                                const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: _loyaltyDiscount == p
                                                  ? AppColors.gold
                                                      .withOpacity(0.15)
                                                  : AppColors.bg,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _loyaltyDiscount == p
                                                    ? AppColors.gold
                                                    : AppColors.border,
                                              ),
                                            ),
                                            child: Text('$p%',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: _loyaltyDiscount == p
                                                      ? AppColors.gold
                                                      : AppColors.muted,
                                                )),
                                          ),
                                        ))
                                    .toList(),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Total Section ───────────────────────────────────
                    if (_selectedItems.isNotEmpty)
                      Container(
                        color: AppColors.card,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal',
                                    style: TextStyle(
                                        color: AppColors.muted, fontSize: 12)),
                                Text('Rs. ${_totalSubtotal}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textColor)),
                              ],
                            ),
                            if (_totalItemDiscounts > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Item Discounts',
                                      style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12)),
                                  Text('−Rs. ${_totalItemDiscounts}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.danger)),
                                ],
                              ),
                            ],
                            if (_overallDiscount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Bill Discount ($_overallDiscount%)',
                                      style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12)),
                                  Text('−Rs. ${_overallDiscountAmt}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.danger)),
                                ],
                              ),
                            ],
                            if (_loyaltyDiscount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Loyalty Discount ($_loyaltyDiscount%)',
                                      style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12)),
                                  Text('−Rs. ${_loyaltyDiscountAmt}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.danger)),
                                ],
                              ),
                            ],
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('GRAND TOTAL',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        fontSize: 13,
                                        color: AppColors.textColor)),
                                Text('Rs. ${_grandTotal}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppColors.goldLight)),
                              ],
                            ),
                             // ── Delivery & Payment Selection ──
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('DELIVERY & PAYMENT',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 12),
                            
                            // Delivery Method Dropdown
                            _loadingDeliveryMethods
                                ? const Center(child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(color: AppColors.gold),
                                  ))
                                : Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.bg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedDeliveryMethodId,
                                        isExpanded: true,
                                        dropdownColor: AppColors.card,
                                        style: TextStyle(color: AppColors.textColor),
                                        hint: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text('Select Delivery Method',
                                              style: TextStyle(color: AppColors.muted, fontSize: 13)),
                                        ),
                                        items: _deliveryMethods
                                            .map((dm) => DropdownMenuItem(
                                                  value: dm.id,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: Text(dm.name,
                                                        style: TextStyle(color: AppColors.textColor, fontSize: 13)),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (id) {
                                          if (id != null) {
                                            final dm = _deliveryMethods.firstWhere((element) => element.id == id);
                                            setState(() {
                                              _selectedDeliveryMethodId = id;
                                              _selectedDeliveryMethodName = dm.name;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 12),

                            // Payment Method Dropdown
                            _loadingPaymentMethods
                                ? const Center(child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(color: AppColors.gold),
                                  ))
                                : Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.bg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedPaymentMethodId,
                                        isExpanded: true,
                                        dropdownColor: AppColors.card,
                                        style: TextStyle(color: AppColors.textColor),
                                        hint: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text('Select Payment Method',
                                              style: TextStyle(color: AppColors.muted, fontSize: 13)),
                                        ),
                                        items: _paymentMethods
                                            .map((pm) => DropdownMenuItem(
                                                  value: pm.id,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: Text(pm.name,
                                                        style: TextStyle(color: AppColors.textColor, fontSize: 13)),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (id) {
                                          if (id != null) {
                                            final pm = _paymentMethods.firstWhere((element) => element.id == id);
                                            setState(() {
                                              _selectedPaymentMethodId = id;
                                              _selectedPaymentMethodName = pm.name;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 12),

                            // Payment Proof Selection Card
                            GestureDetector(
                              onTap: _paymentProofImage == null ? _pickPaymentProof : null,
                              child: _buildProofSelectionWidget(),
                            ),

                            const SizedBox(height: 16),
                            _uploadingProof
                                ? const Center(child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(color: AppColors.gold),
                                  ))
                                : GoldButton(
                                    label: 'Create Order',
                                    onTap: _selCustId != null &&
                                            _selectedItems.isNotEmpty
                                        ? _submitOrder
                                        : () {},
                                  ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddItemDialog(StockItem item) {
    String selectedSize = '';
    int qty = 1;
    int price = item.price;
    final sizeList = item.category == 'Kids' ? kidsSizes : allSizes;
    
    // Filter available sizes based on total stock minus what is already in the cart
    final availableSizes = sizeList.where((s) {
      final alreadyInCart = _selectedItems
          .where((cartItem) => cartItem['item'].id == item.id && cartItem['size'] == s)
          .fold<int>(0, (sum, cartItem) => sum + (cartItem['qty'] as int));
      return (item.sizes[s] ?? 0) - alreadyInCart > 0;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.emoji} ${item.name}',
                        style: TextStyle(
                            color: AppColors.textColor, fontSize: 16)),
                    Text('Price: Rs. $price',
                        style: TextStyle(color: AppColors.gold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Size Selection
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: selectedSize.isEmpty ? null : selectedSize,
                    isExpanded: true,
                    underline: Container(),
                    dropdownColor: AppColors.card,
                    style: TextStyle(color: AppColors.textColor),
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Select Size',
                          style: TextStyle(color: AppColors.muted)),
                    ),
                    items: availableSizes
                        .map((s) {
                          final alreadyInCart = _selectedItems
                              .where((cartItem) => cartItem['item'].id == item.id && cartItem['size'] == s)
                              .fold<int>(0, (sum, cartItem) => sum + (cartItem['qty'] as int));
                          final remaining = (item.sizes[s] ?? 0) - alreadyInCart;
                          
                          return DropdownMenuItem(
                            value: s,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                  '$s ($remaining available)',
                                  style: TextStyle(
                                      color: AppColors.textColor)),
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (s) => setState(() {
                      selectedSize = s ?? '';
                      qty = 1;
                    }),
                  ),
                ),
                const SizedBox(height: 12),

                // Quantity
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quantity:',
                          style: TextStyle(
                              color: AppColors.textColor,
                              fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove,
                                color: AppColors.muted, size: 18),
                            onPressed: () =>
                                setState(() => qty = (qty - 1).clamp(1, 99)),
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                          SizedBox(
                            width: 40,
                            child: Text('$qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gold)),
                          ),
                          IconButton(
                            icon: Icon(Icons.add,
                                color: AppColors.gold, size: 18),
                            onPressed: selectedSize.isEmpty
                                ? null
                                : () {
                                    final alreadyInCart = _selectedItems
                                        .where((cartItem) => cartItem['item'].id == item.id && cartItem['size'] == selectedSize)
                                        .fold<int>(0, (sum, cartItem) => sum + (cartItem['qty'] as int));
                                    final maxQty = (item.sizes[selectedSize] ?? 0) - alreadyInCart;
                                    if (qty < maxQty) {
                                      setState(() => qty++);
                                    }
                                  },
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Price (editable)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: AppColors.textColor),
                    decoration: InputDecoration(
                      hintText: 'Price',
                      hintStyle: TextStyle(color: AppColors.muted),
                      border: InputBorder.none,
                      prefixText: 'Rs. ',
                      prefixStyle: TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.bold),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    controller: TextEditingController(text: '$price'),
                    onChanged: (v) =>
                        setState(() => price = int.tryParse(v) ?? item.price),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ActionButton(
              label: 'Cancel',
              onTap: () => Navigator.pop(context),
              isOutlined: true,
              buttonColor: AppColors.muted,
            ),
            const SizedBox(width: 8),
            ActionButton(
              label: 'Add',
              onTap: selectedSize.isEmpty
                  ? () {}
                  : () {
                      _addItem(item, selectedSize, qty, price);
                      Navigator.pop(context);
                    },
              buttonColor:
                  selectedSize.isEmpty ? AppColors.muted : AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item Settings Dialog ──────────────────────────────────────────────────────
class _ItemSettingsDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> selectedItems;
  final Function(int, int, int) onSave;
  const _ItemSettingsDialog({required this.item, required this.selectedItems, required this.onSave});
  @override
  State<_ItemSettingsDialog> createState() => _ItemSettingsDialogState();
}

class _ItemSettingsDialogState extends State<_ItemSettingsDialog> {
  late int _qty;
  late int _price;
  late int _discount;

  @override
  void initState() {
    super.initState();
    _qty = widget.item['qty'];
    _price = widget.item['price'];
    _discount = widget.item['discount'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title:
          Text('Item Settings', style: TextStyle(color: AppColors.textColor)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item Info
            Container(
              padding: const EdgeInsets.all(12),
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
                      Text(widget.item['item'].emoji,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.item['item'].name,
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: AppColors.textColor)),
                            Text('Size: ${widget.item['size']}',
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quantity
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QUANTITY',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline,
                            color: AppColors.muted),
                        onPressed: () =>
                            setState(() => _qty = (_qty - 1).clamp(1, 99)),
                      ),
                      Text('$_qty',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold)),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline,
                            color: AppColors.gold),
                        onPressed: () {
                          // Find total stock of this item and size
                          final totalStock = widget.item['item'].sizes[widget.item['size']] ?? 0;
                          // Sum up what other items in the cart are using
                          final alreadyInCartOther = widget.selectedItems
                              .where((cartItem) => cartItem != widget.item && cartItem['item'].id == widget.item['item'].id && cartItem['size'] == widget.item['size'])
                              .fold<int>(0, (sum, cartItem) => sum + (cartItem['qty'] as int));
                          final maxQty = totalStock - alreadyInCartOther;
                          if (_qty < maxQty) {
                            setState(() => _qty++);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Price
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PRICE',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      prefixText: 'Rs. ',
                      prefixStyle: TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.bold),
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    controller: TextEditingController(text: '$_price'),
                    onChanged: (v) => setState(
                        () => _price = int.tryParse(v) ?? widget.item['price']),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Discount
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ITEM DISCOUNT',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                              color: AppColors.textColor, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.card,
                            suffixText: '%',
                            suffixStyle: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold),
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
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          controller: TextEditingController(text: '$_discount'),
                          onChanged: (v) =>
                              setState(() => _discount = int.tryParse(v) ?? 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...[5, 10, 15]
                          .map((p) => GestureDetector(
                                onTap: () => setState(
                                    () => _discount = _discount == p ? 0 : p),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _discount == p
                                        ? AppColors.gold.withOpacity(0.15)
                                        : AppColors.card,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _discount == p
                                          ? AppColors.gold
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text('$p%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _discount == p
                                            ? AppColors.gold
                                            : AppColors.muted,
                                      )),
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ActionButton(
          label: 'Cancel',
          onTap: () => Navigator.pop(context),
          isOutlined: true,
          buttonColor: AppColors.muted,
        ),
        const SizedBox(width: 8),
        ActionButton(
          label: 'Save',
          onTap: () => widget.onSave(_qty, _price, _discount),
          buttonColor: AppColors.gold,
        ),
      ],
    );
  }
}

// ── Add Customer Sheet ──────────────────────────────────────────────────────

class _AddCustomerSheet extends StatefulWidget {
  final Function(Customer customer) onCustomerAdded;
  const _AddCustomerSheet({required this.onCustomerAdded});

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
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _phone.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Name and Phone are required'),
            backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      String? photoUrl;
      if (_photo != null)
        photoUrl = await svc.uploadPhoto(_photo!, 'customers');
      final newCustomer = Customer(
        id: '',
        name: _name.text,
        phone: _phone.text,
        email: _email.text,
        address: _address.text,
        totalOrders: 0,
        totalSpent: 0,
        photoUrl: photoUrl,
        ownerRating: 0,
        ownerNote: '',
      );
      await svc.addCustomer(newCustomer);

      // Wait a moment for the database to update, then get the fresh customer list
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Customer added successfully ✓'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 1)),
        );

        // Get the newly added customer from the updated list
        final updatedCustomers = await svc.getCustomers();
        final addedCustomer = updatedCustomers.firstWhere(
          (c) => c.phone == _phone.text && c.name == _name.text,
          orElse: () => newCustomer,
        );

        // Send Welcome email asynchronously
        InvoiceService.sendWelcomeEmail(addedCustomer);

        widget.onCustomerAdded(addedCustomer);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
              margin: EdgeInsets.only(bottom: 16),
            ),
            Text(
              'Add Customer',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bg,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: _photo != null
                    ? ClipOval(child: Image.file(_photo!, fit: BoxFit.cover))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              color: AppColors.gold, size: 24),
                          Text('Photo',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            GoldTextField(
                label: 'Name *', controller: _name, hint: 'Full name'),
            GoldTextField(
                label: 'Phone *',
                controller: _phone,
                keyboardType: TextInputType.phone,
                hint: '07X XXX XXXX'),
            GoldTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                hint: 'email@example.com'),
            GoldTextField(
                label: 'Address',
                controller: _address,
                maxLines: 2,
                hint: 'Street, City'),
            const SizedBox(height: 16),
            _saving
                ? CircularProgressIndicator(color: AppColors.gold)
                : GoldButton(label: 'Add Customer', onTap: _save),
          ],
        ),
      ),
    );
  }
}
