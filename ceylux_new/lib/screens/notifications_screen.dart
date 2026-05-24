import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/stock_item.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<List<StockItem>>(
      stream: ApiService().stockStream(),
      builder: (context, snap) {
        final allItems = snap.data ?? [];
        final outItems = allItems.where((i) => i.isOutOfStock).toList();
        final lowItems = allItems.where((i) => i.isLowStock).toList();

        if (outItems.isEmpty && lowItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✅', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  'All stock levels are good!',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No alerts at the moment',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            if (outItems.isNotEmpty) ...[
              _AlertHeader(title: '🚫 Out of Stock', count: outItems.length, color: AppColors.danger),
              const SizedBox(height: 10),
              ...outItems.map((item) => _AlertCard(item: item, isOut: true)),
              const SizedBox(height: 20),
            ],
            if (lowItems.isNotEmpty) ...[
              _AlertHeader(title: '⚠️ Low Stock', count: lowItems.length, color: AppColors.warning),
              const SizedBox(height: 10),
              ...lowItems.map((item) => _AlertCard(item: item, isOut: false)),
            ],
          ],
        );
      },
    );

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (canPop) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          title: Text(
            'Notifications & Alerts',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border),
          ),
        ),
        body: body,
      );
    }

    return body;
  }
}

class _AlertHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _AlertHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final StockItem item;
  final bool isOut;
  const _AlertCard({required this.item, required this.isOut});

  @override
  Widget build(BuildContext context) {
    final color = isOut ? AppColors.danger : AppColors.warning;
    return CeyluxCard(
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: item.photoUrl != null && item.photoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(item.photoUrl!, fit: BoxFit.cover),
                )
              : Center(child: Text(item.emoji, style: const TextStyle(fontSize: 24))),
          ),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  isOut ? '⚠ OUT' : '${item.totalQty} left',
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Min: ${item.minQty}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
