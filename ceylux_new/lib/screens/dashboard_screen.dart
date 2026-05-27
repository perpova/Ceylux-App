import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/stock_item.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/animation_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  bool _isLowStockExpanded = true;
  bool _isRecentOrdersExpanded = true;
  bool _isTopCustomersExpanded = true;

  late ScrollController _scrollController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;
  double _lastScrollPosition = 0;
  bool _isScrollingDown = false;
  bool _isAtEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final currentPosition = _scrollController.offset;
    final isScrollingDown = currentPosition > _lastScrollPosition;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final isNearEnd = currentPosition >= maxScroll * 0.95;

    if (isScrollingDown && !_isScrollingDown) {
      // Started scrolling down
      _isScrollingDown = true;
      _rotationController.forward();
    } else if (!isScrollingDown && _isScrollingDown) {
      // Started scrolling up
      _isScrollingDown = false;
      _rotationController.reverse();
    }

    setState(() {
      _isAtEnd = isNearEnd;
    });

    _lastScrollPosition = currentPosition;
  }

  void _onArrowTap() {
    if (_isAtEnd) {
      // Scroll to top
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    } else {
      // Scroll to bottom
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _itemEmoji(String emoji) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
      );

  Widget _itemThumb(StockItem item) {
    if (item.photoUrl != null && item.photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          item.photoUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _itemEmoji(item.emoji),
        ),
      );
    }
    return _itemEmoji(item.emoji);
  }

  @override
  Widget build(BuildContext context) {
    final svc = ApiService();
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Elegant Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Overview',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Real-time Ceylux store insights',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.success.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live Sync',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Stats Grid
              StreamBuilder<List<StockItem>>(
                stream: svc.stockStream(),
                builder: (context, stockSnap) {
                  return StreamBuilder<List<AppOrder>>(
                    stream: svc.ordersStream(),
                    builder: (context, orderSnap) {
                      return StreamBuilder<List<Customer>>(
                        stream: svc.customersStream(),
                        builder: (context, custSnap) {
                          // Check for errors
                          if (stockSnap.hasError || orderSnap.hasError || custSnap.hasError) {
                            return SizedBox(
                              height: 250,
                              child: ErrorAnimation(
                                title: 'Network Error',
                                message: 'Failed to load dashboard data',
                                onRetry: () {},
                                size: 120,
                              ),
                            );
                          }

                          // Check for loading
                          if (!stockSnap.hasData || !orderSnap.hasData || !custSnap.hasData) {
                            return SizedBox(
                              height: 250,
                              child: const LoadingAnimation(
                                message: 'Loading dashboard...',
                                size: 120,
                              ),
                            );
                          }

                          final stock = stockSnap.data ?? [];
                          final orders = orderSnap.data ?? [];
                          final customers = custSnap.data ?? [];
                          final totalRevenue =
                              orders.fold<int>(0, (a, b) => a + b.total);
                          final pendingOrders = orders
                              .where((o) =>
                                  o.status == 'Processing' ||
                                  o.status == 'Pending')
                              .length;

                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.45,
                            children: [
                              StatCard(
                                  label: 'Total Revenue',
                                  value:
                                      'Rs. ${NumberFormat('#,###').format(totalRevenue)}',
                                  icon: Icons.wallet,
                                  accentColor: AppColors.gold),
                              StatCard(
                                  label: 'Stock Items',
                                  value: '${stock.length}',
                                  icon: Icons.inventory_2,
                                  accentColor: AppColors.accent),
                              StatCard(
                                  label: 'Customers',
                                  value: '${customers.length}',
                                  icon: Icons.group,
                                  accentColor: AppColors.success),
                              StatCard(
                                  label: 'Pending Orders',
                                  value: '$pendingOrders',
                                  icon: Icons.shopping_bag,
                                  accentColor: const Color(0xFF9333EA)),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Low Stock Alerts - Expandable
              StreamBuilder<List<StockItem>>(
                stream: svc.stockStream(),
                builder: (context, snap) {
                  // Error handling
                  if (snap.hasError) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      child: ErrorAnimation(
                        title: 'Network Error',
                        message: 'Failed to load stock alerts',
                        onRetry: () {},
                        size: 100,
                      ),
                    );
                  }

                  final lowItems = (snap.data ?? [])
                      .where((s) => s.isLowStock || s.isOutOfStock)
                      .toList();
                  if (lowItems.isEmpty) return const SizedBox.shrink();

                  final content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...lowItems.take(3).map((item) => CeyluxCard(
                            child: Row(
                              children: [
                                _itemThumb(item),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.sku,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.isOutOfStock
                                        ? AppColors.danger.withOpacity(0.12)
                                        : AppColors.warning.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: (item.isOutOfStock
                                                ? AppColors.danger
                                                : AppColors.warning)
                                            .withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    item.isOutOfStock
                                        ? '⚠ Out'
                                        : '${item.totalQty} left',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: item.isOutOfStock
                                          ? AppColors.danger
                                          : AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  );

                  return _buildExpandableSection(
                    title: 'Low Stock Alerts (${lowItems.length})',
                    isExpanded: _isLowStockExpanded,
                    onToggle: () => setState(
                        () => _isLowStockExpanded = !_isLowStockExpanded),
                    child: content,
                    emptyChild: null,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Recent Orders - Expandable
              StreamBuilder<List<AppOrder>>(
                stream: svc.ordersStream(),
                builder: (context, snap) {
                  // Error handling
                  if (snap.hasError) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      child: ErrorAnimation(
                        title: 'Network Error',
                        message: 'Failed to load recent orders',
                        onRetry: () {},
                        size: 100,
                      ),
                    );
                  }

                  final orders = (snap.data ?? []).take(3).toList();

                  final emptyWidget = Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No orders yet',
                        style: GoogleFonts.plusJakartaSans(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  );

                  final content = orders.isEmpty
                      ? null
                      : Column(
                          children: orders
                              .map((o) => CeyluxCard(
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
                                                o.customerName,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: AppColors.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${o.id} • ${o.date}',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  color: AppColors.muted,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Rs. ${NumberFormat('#,###').format(o.total)}',
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.goldDark,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            StatusBadge(status: o.status),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        );

                  return _buildExpandableSection(
                    title: 'Recent Orders',
                    isExpanded: _isRecentOrdersExpanded,
                    onToggle: () => setState(() =>
                        _isRecentOrdersExpanded = !_isRecentOrdersExpanded),
                    child: content,
                    emptyChild: emptyWidget,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Top Customers - Expandable
              StreamBuilder<List<Customer>>(
                stream: svc.customersStream(),
                builder: (context, snap) {
                  // Error handling
                  if (snap.hasError) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      child: ErrorAnimation(
                        title: 'Network Error',
                        message: 'Failed to load top customers',
                        onRetry: () {},
                        size: 100,
                      ),
                    );
                  }

                  final customers = [...(snap.data ?? [])]
                    ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

                  final emptyWidget = Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No clients yet',
                        style: GoogleFonts.plusJakartaSans(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  );

                  final content = customers.isEmpty
                      ? null
                      : Column(
                          children: customers.take(3).map((c) {
                            final tier = Tiers.getTier(c.totalSpent);
                            return CeyluxCard(
                              child: Row(
                                children: [
                                  UserAvatar(
                                      name: c.name,
                                      photoUrl: c.photoUrl,
                                      borderColor: tier.color),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${c.totalOrders} orders',
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
                                      TierBadge(totalSpent: c.totalSpent),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rs. ${NumberFormat('#,###').format(c.totalSpent)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );

                  return _buildExpandableSection(
                    title: 'Top Customers',
                    isExpanded: _isTopCustomersExpanded,
                    onToggle: () => setState(() =>
                        _isTopCustomersExpanded = !_isTopCustomersExpanded),
                    child: content,
                    emptyChild: emptyWidget,
                  );
                },
              ),
            ],
          ),
        ),
        // Floating Arrow Icon with Shimmer
        Positioned(
          bottom: 10,
          right: 20,
          child: GestureDetector(
            onTap: _onArrowTap,
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_rotationController, _shimmerController]),
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 3.14159265359,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.gold.withOpacity(
                              0.15 + _shimmerController.value * 0.15),
                          AppColors.gold.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.gold
                            .withOpacity(0.3 + _shimmerController.value * 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(
                              0.2 + _shimmerController.value * 0.2),
                          blurRadius: 8 + _shimmerController.value * 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.gold
                            .withOpacity(0.7 + _shimmerController.value * 0.3),
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget? child,
    required Widget? emptyChild,
  }) {
    final isEmpty = child == null;
    final displayChild = isEmpty ? emptyChild : child;

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
        if (isExpanded && displayChild != null)
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: displayChild,
            ),
          ),
      ],
    );
  }
}
