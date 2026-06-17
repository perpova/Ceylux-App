import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import '../models/stock_item.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/animation_widgets.dart';

class RevenueDetailsScreen extends StatefulWidget {
  const RevenueDetailsScreen({super.key});

  @override
  State<RevenueDetailsScreen> createState() => _RevenueDetailsScreenState();
}

class _RevenueDetailsScreenState extends State<RevenueDetailsScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _filterType = 'currentMonth'; // currentMonth, custom, specific

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  void _setCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _filterType = 'currentMonth';
      _selectedMonth = now.month;
      _selectedYear = now.year;
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
  }

  void _setSpecificMonth(int month, int year) {
    setState(() {
      _filterType = 'specific';
      _selectedMonth = month;
      _selectedYear = year;
      _startDate = DateTime(year, month, 1);
      _endDate = DateTime(year, month + 1, 0);
    });
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.gold,
              secondary: AppColors.accent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterType = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = ApiService();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text(
          'Revenue Details',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterButton(
                    label: 'This Month',
                    isActive: _filterType == 'currentMonth',
                    onTap: _setCurrentMonth,
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    label: 'Custom Range',
                    isActive: _filterType == 'custom',
                    onTap: _showDateRangePicker,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Month/Year Selector
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 24,
                itemBuilder: (context, index) {
                  final date = DateTime.now().subtract(Duration(days: index * 30));
                  final month = date.month;
                  final year = date.year;
                  final isSelected =
                      _selectedMonth == month && _selectedYear == year;

                  return GestureDetector(
                    onTap: () => _setSpecificMonth(month, year),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM').format(date),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textColor,
                            ),
                          ),
                          Text(
                            '$year',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Revenue Data
            StreamBuilder<List<AppOrder>>(
              stream: svc.ordersStream(),
              builder: (context, ordersSnap) {
                return StreamBuilder<List<StockItem>>(
                  stream: svc.stockStream(),
                  builder: (context, stockSnap) {
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: svc.paymentsStream(),
                      builder: (context, paymentsSnap) {
                        if (ordersSnap.hasError || stockSnap.hasError || paymentsSnap.hasError) {
                          return SizedBox(
                            height: 250,
                            child: ErrorAnimation(
                              title: 'Network Error',
                              message: 'Failed to load financial data',
                              onRetry: () {},
                              size: 120,
                            ),
                          );
                        }

                        if (!ordersSnap.hasData || !stockSnap.hasData || !paymentsSnap.hasData) {
                          return SizedBox(
                            height: 250,
                            child: const LoadingAnimation(
                              message: 'Loading financial analysis...',
                              size: 120,
                            ),
                          );
                        }

                        final orders = ordersSnap.data ?? [];
                        final stock = stockSnap.data ?? [];
                        final payments = paymentsSnap.data ?? [];

                        // Filter orders by date range
                        final filteredOrders = orders.where((order) {
                          final orderDate = DateTime.parse(order.date);
                          return !orderDate.isBefore(_startDate) && !orderDate.isAfter(_endDate);
                        }).toList();

                        final nonCancelledOrders = filteredOrders
                            .where((o) => o.status.toLowerCase() != 'cancelled' && o.status.toLowerCase() != 'canceled')
                            .toList();

                        // 1. Total Revenue
                        final totalRevenue = nonCancelledOrders.fold<int>(0, (a, b) => a + b.total);

                        // 2. Total Profit & Product Breakdown
                        double totalProfit = 0.0;
                        final productStats = <String, Map<String, dynamic>>{};

                        for (final order in nonCancelledOrders) {
                          final itemsSum = order.items.fold<int>(0, (sum, item) => sum + item.total);
                          final double discountRatio = itemsSum > 0 ? (order.total / itemsSum) : 1.0;
                          double orderCost = 0.0;

                          for (final item in order.items) {
                            final stockItem = stock.firstWhere(
                              (s) => s.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
                              orElse: () => StockItem(
                                id: '', name: item.name, category: '', sku: '', minQty: 0,
                                price: item.price, cost: 0, emoji: '👕', sizes: {}
                              )
                            );
                            
                            final double itemRevenue = item.total * discountRatio;
                            final double itemCost = (stockItem.cost * item.qty).toDouble();
                            final double itemProfit = itemRevenue - itemCost;
                            orderCost += itemCost;

                            productStats.update(
                              item.name,
                              (existing) => {
                                'qty': existing['qty'] + item.qty,
                                'profit': existing['profit'] + itemProfit,
                                'emoji': stockItem.emoji,
                                'photoUrl': stockItem.photoUrl,
                              },
                              ifAbsent: () => {
                                'qty': item.qty,
                                'profit': itemProfit,
                                'emoji': stockItem.emoji,
                                'photoUrl': stockItem.photoUrl,
                              },
                            );
                          }

                          final double orderProfit = order.total - orderCost;
                          totalProfit += orderProfit;
                        }

                        // 3. Outstanding Credit Balance
                        final creditAndCodOrders = filteredOrders.where((order) {
                          final isCreditOrCod = order.paymentMethodName == 'Credit' ||
                                                order.paymentMethodName == 'Cash on Delivery (C.O.D.)';
                          final isNotCancelled = order.status.toLowerCase() != 'cancelled' &&
                                                 order.status.toLowerCase() != 'canceled';
                          final isUnpaid = !order.isPaid;
                          return isCreditOrCod && isNotCancelled && isUnpaid;
                        }).toList();
                        final outstandingCredit = creditAndCodOrders.fold<int>(0, (sum, order) => sum + order.total);

                        // 4. Received Money
                        final immediatePaidOrders = filteredOrders.where((order) {
                          final isImmediate = order.paymentMethodName != 'Credit' &&
                                              order.paymentMethodName != 'Cash on Delivery (C.O.D.)';
                          final isNotCancelled = order.status.toLowerCase() != 'cancelled' &&
                                                 order.status.toLowerCase() != 'canceled';
                          return isImmediate && isNotCancelled;
                        }).toList();
                        final immediatePaidAmount = immediatePaidOrders.fold<int>(0, (sum, order) => sum + order.total);

                        final filteredPayments = payments.where((p) {
                          try {
                            final dateStr = p['payment_date'] ?? p['created_at'] ?? '';
                            if (dateStr.length >= 10) {
                              final pDate = DateTime.parse(dateStr.substring(0, 10));
                              return !pDate.isBefore(_startDate) && !pDate.isAfter(_endDate);
                            }
                          } catch (_) {}
                          return false;
                        }).toList();

                        final creditCollections = filteredPayments.fold<double>(0.0, (sum, p) {
                          final amt = double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;
                          return sum + amt;
                        });

                        final double totalReceivedMoney = immediatePaidAmount + creditCollections;

                        // Sort products by quantity sold
                        final sortedProducts = productStats.entries.toList()
                          ..sort((a, b) => b.value['qty'].compareTo(a.value['qty']));

                        final hasProducts = sortedProducts.isNotEmpty;
                        final mostSellingProduct = hasProducts ? sortedProducts.first : null;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // REDESIGNED STATS GRID
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.4,
                              children: [
                                _PremiumStatCard(
                                  label: 'Total Revenue',
                                  value: 'Rs. ${NumberFormat('#,###').format(totalRevenue)}',
                                  icon: Icons.wallet,
                                  color: AppColors.gold,
                                  gradientColors: [AppColors.gold.withOpacity(0.15), AppColors.gold.withOpacity(0.02)],
                                ),
                                _PremiumStatCard(
                                  label: 'Net Profit',
                                  value: 'Rs. ${NumberFormat('#,###').format(totalProfit.round())}',
                                  icon: Icons.show_chart,
                                  color: AppColors.success,
                                  gradientColors: [AppColors.success.withOpacity(0.15), AppColors.success.withOpacity(0.02)],
                                  subtitle: totalRevenue > 0
                                      ? '${((totalProfit / totalRevenue) * 100).toStringAsFixed(1)}% margin'
                                      : null,
                                ),
                                _PremiumStatCard(
                                  label: 'Received Money',
                                  value: 'Rs. ${NumberFormat('#,###').format(totalReceivedMoney.round())}',
                                  icon: Icons.monetization_on,
                                  color: const Color(0xFF10B981), // Emerald
                                  gradientColors: [const Color(0xFF10B981).withOpacity(0.15), const Color(0xFF10B981).withOpacity(0.02)],
                                  subtitle: 'Immediate + Collections',
                                ),
                                _PremiumStatCard(
                                  label: 'Outstanding Credit',
                                  value: 'Rs. ${NumberFormat('#,###').format(outstandingCredit)}',
                                  icon: Icons.pending_actions,
                                  color: AppColors.danger,
                                  gradientColors: [AppColors.danger.withOpacity(0.15), AppColors.danger.withOpacity(0.02)],
                                  subtitle: 'Unpaid Credit & COD',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // MOST SELLING PRODUCT
                            if (mostSellingProduct != null) ...[
                              Text(
                                'Most Selling Product',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _MostSellingProductCard(
                                name: mostSellingProduct.key,
                                qty: mostSellingProduct.value['qty'],
                                profit: mostSellingProduct.value['profit'],
                                emoji: mostSellingProduct.value['emoji'],
                                photoUrl: mostSellingProduct.value['photoUrl'],
                              ),
                              const SizedBox(height: 24),
                            ],

                            // PRODUCT BREAKDOWN LIST
                            Text(
                              'Product Sales & Profit Breakdown',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (!hasProducts)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      size: 48,
                                      color: AppColors.muted.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No sales data in this period',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.muted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sortedProducts.length,
                                itemBuilder: (context, index) {
                                  final item = sortedProducts[index];
                                  final name = item.key;
                                  final qty = item.value['qty'];
                                  final profit = item.value['profit'];
                                  final emoji = item.value['emoji'];
                                  final photoUrl = item.value['photoUrl'];

                                  return _ProductBreakdownCard(
                                    name: name,
                                    qty: qty,
                                    profit: profit,
                                    emoji: emoji,
                                    photoUrl: photoUrl,
                                  );
                                },
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.gold : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.gold : AppColors.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppColors.textColor,
          ),
        ),
      ),
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final String? subtitle;

  const _PremiumStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradientColors,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MostSellingProductCard extends StatelessWidget {
  final String name;
  final int qty;
  final double profit;
  final String emoji;
  final String? photoUrl;

  const _MostSellingProductCard({
    required this.name,
    required this.qty,
    required this.profit,
    required this.emoji,
    this.photoUrl,
  });

  Widget _itemThumb() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          photoUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _itemEmoji(),
        ),
      );
    }
    return _itemEmoji();
  }

  Widget _itemEmoji() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
      );

  @override
  Widget build(BuildContext context) {
    final profitText = 'Rs. ${NumberFormat('#,###').format(profit.round())}';
    final bool isDark = AppColors.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2E220F), AppColors.card]
              : [const Color(0xFFFFF9F0), AppColors.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _itemThumb(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: AppColors.gold, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            'Best Seller',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.goldDark,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$qty units sold',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$profitText profit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: profit >= 0 ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductBreakdownCard extends StatelessWidget {
  final String name;
  final int qty;
  final double profit;
  final String emoji;
  final String? photoUrl;

  const _ProductBreakdownCard({
    required this.name,
    required this.qty,
    required this.profit,
    required this.emoji,
    this.photoUrl,
  });

  Widget _itemThumb() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          photoUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _itemEmoji(),
        ),
      );
    }
    return _itemEmoji();
  }

  Widget _itemEmoji() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
      );

  @override
  Widget build(BuildContext context) {
    final profitText = 'Rs. ${NumberFormat('#,###').format(profit.round())}';

    return CeyluxCard(
      child: Row(
        children: [
          _itemThumb(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$qty sold',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profitText,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: profit >= 0 ? AppColors.success : AppColors.danger,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Profit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: AppColors.muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
