import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/order.dart';
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
              builder: (context, snap) {
                if (snap.hasError) {
                  return SizedBox(
                    height: 250,
                    child: ErrorAnimation(
                      title: 'Network Error',
                      message: 'Failed to load revenue data',
                      onRetry: () {},
                      size: 120,
                    ),
                  );
                }

                if (!snap.hasData) {
                  return SizedBox(
                    height: 250,
                    child: const LoadingAnimation(
                      message: 'Loading revenue data...',
                      size: 120,
                    ),
                  );
                }

                final orders = snap.data ?? [];
                final filteredOrders = orders.where((order) {
                  final orderDate = DateTime.parse(order.date);
                  return orderDate.isAfter(_startDate) &&
                      orderDate.isBefore(_endDate.add(const Duration(days: 1)));
                }).toList();

                final totalRevenue =
                    filteredOrders.fold<int>(0, (a, b) => a + b.total);
                final completedOrders = filteredOrders
                    .where((o) => o.status == 'Delivered')
                    .length;
                final pendingOrders = filteredOrders
                    .where((o) =>
                        o.status == 'Processing' || o.status == 'Pending')
                    .length;
                final avgOrderValue =
                    filteredOrders.isEmpty ? 0 : (totalRevenue ~/ filteredOrders.length);

                return Column(
                  children: [
                    // Main Revenue Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withOpacity(0.2),
                            AppColors.gold.withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Total Revenue',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rs. ${NumberFormat('#,###').format(totalRevenue)}',
                            style: GoogleFonts.outfit(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${filteredOrders.length} orders',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatBox(
                          label: 'Completed Orders',
                          value: '$completedOrders',
                          icon: Icons.check_circle,
                          color: AppColors.success,
                        ),
                        _StatBox(
                          label: 'Pending Orders',
                          value: '$pendingOrders',
                          icon: Icons.schedule,
                          color: const Color(0xFF9333EA),
                        ),
                        _StatBox(
                          label: 'Avg Order Value',
                          value: 'Rs. ${NumberFormat('#,###').format(avgOrderValue)}',
                          icon: Icons.trending_up,
                          color: AppColors.accent,
                        ),
                        _StatBox(
                          label: 'Total Orders',
                          value: '${filteredOrders.length}',
                          icon: Icons.shopping_bag,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Orders List
                    Text(
                      'Recent Orders',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (filteredOrders.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: AppColors.muted.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No orders in this period',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.muted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return CeyluxCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.customerName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${order.id} • ${order.date}',
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
                                  children: [
                                    Text(
                                      'Rs. ${NumberFormat('#,###').format(order.total)}',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.goldDark,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    StatusBadge(status: order.status),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
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
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
