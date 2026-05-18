import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
  );

 Widget _itemThumb(StockItem item) {
  if (item.photoUrl != null && item.photoUrl!.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
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
                      final lowStock = stock.where((s) => s.isLowStock || s.isOutOfStock).length;
                      final pendingOrders = orders.where((o) => o.status == 'Processing' || o.status == 'Pending').length;

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.4,
                        children: [
                          StatCard(label: 'Total Revenue', value: 'Rs. ${NumberFormat('#,###').format(totalRevenue)}', icon: '💰'),
                          StatCard(label: 'Stock Items', value: '${stock.length}', icon: '📦', accentColor: AppColors.accent),
                          StatCard(label: 'Customers', value: '${customers.length}', icon: '👥', accentColor: AppColors.success),
                          StatCard(label: 'Pending Orders', value: '$pendingOrders', icon: '🛍️', accentColor: pendingOrders > 0 ? AppColors.warning : AppColors.success),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),

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
                    text: '⚠️ Low Stock Alerts',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${lowItems.length}', style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  ...lowItems.take(3).map((item) => CeyluxCard(
                    child: Row(
                      children: [
                        _itemThumb(item), // ← image or emoji
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(item.sku, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isOutOfStock ? AppColors.danger.withOpacity(0.15) : AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: (item.isOutOfStock ? AppColors.danger : AppColors.warning).withOpacity(0.4)),
                          ),
                          child: Text(
                            item.isOutOfStock ? '⚠ Out' : '${item.totalQty} left',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: item.isOutOfStock ? AppColors.danger : AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
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
              if (orders.isEmpty) return const Center(child: Text('No orders yet', style: TextStyle(color: AppColors.muted)));
              return Column(
                children: orders.map((o) => CeyluxCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${o.id} • ${o.date}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Rs. ${NumberFormat('#,###').format(o.total)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldLight)),
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

          // Top Customers
          const SectionTitle(text: 'Top Customers'),
          StreamBuilder<List<Customer>>(
            stream: svc.customersStream(),
            builder: (context, snap) {
              final customers = [...(snap.data ?? [])]
                ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
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
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('${c.totalOrders} orders', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TierBadge(totalSpent: c.totalSpent),
                            const SizedBox(height: 4),
                            Text('Rs. ${NumberFormat('#,###').format(c.totalSpent)}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
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