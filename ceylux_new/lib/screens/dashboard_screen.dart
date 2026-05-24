import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/stock_item.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Widget _itemEmoji(String emoji) => Container(
    width: 48, height: 48,
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
          width: 48, height: 48,
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
    return SingleChildScrollView(
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.2)),
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
                      final stock = stockSnap.data ?? [];
                      final orders = orderSnap.data ?? [];
                      final customers = custSnap.data ?? [];
                      final totalRevenue = orders.fold<int>(0, (a, b) => a + b.total);
                      final pendingOrders = orders.where((o) => o.status == 'Processing' || o.status == 'Pending').length;

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.45,
                        children: [
                          StatCard(label: 'Total Revenue', value: 'Rs. ${NumberFormat('#,###').format(totalRevenue)}', icon: Icons.wallet, accentColor: AppColors.gold),
                          StatCard(label: 'Stock Items', value: '${stock.length}', icon: Icons.inventory_2, accentColor: AppColors.accent),
                          StatCard(label: 'Customers', value: '${customers.length}', icon: Icons.group, accentColor: AppColors.success),
                          StatCard(label: 'Pending Orders', value: '$pendingOrders', icon: Icons.shopping_bag, accentColor: pendingOrders > 0 ? AppColors.warning : AppColors.success),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Low Stock Alerts
          StreamBuilder<List<StockItem>>(
            stream: svc.stockStream(),
            builder: (context, snap) {
              final lowItems = (snap.data ?? []).where((s) => s.isLowStock || s.isOutOfStock).toList();
              if (lowItems.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    text: 'Low Stock Alerts',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${lowItems.length}', style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...lowItems.take(3).map((item) => CeyluxCard(
                    child: Row(
                      children: [
                        _itemThumb(item),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isOutOfStock ? AppColors.danger.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: (item.isOutOfStock ? AppColors.danger : AppColors.warning).withOpacity(0.3)),
                          ),
                          child: Text(
                            item.isOutOfStock ? '⚠ Out' : '${item.totalQty} left',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.isOutOfStock ? AppColors.danger : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

          // Recent Orders
          const SectionTitle(text: 'Recent Orders'),
          StreamBuilder<List<AppOrder>>(
            stream: svc.ordersStream(),
            builder: (context, snap) {
              final orders = (snap.data ?? []).take(3).toList();
              if (orders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No orders yet',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }
              return Column(
                children: orders.map((o) => CeyluxCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.customerName,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${o.id} • ${o.date}',
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
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 12),

          // Top Customers
          const SectionTitle(text: 'Top Customers'),
          StreamBuilder<List<Customer>>(
            stream: svc.customersStream(),
            builder: (context, snap) {
              final customers = [...(snap.data ?? [])]
                ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
              if (customers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No clients yet',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }
              return Column(
                children: customers.take(3).map((c) {
                  final tier = Tiers.getTier(c.totalSpent);
                  return CeyluxCard(
                    child: Row(
                      children: [
                        UserAvatar(name: c.name, photoUrl: c.photoUrl, borderColor: tier.color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
            },
          ),
        ],
      ),
    );
  }
}