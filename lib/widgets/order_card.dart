import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utils/format_date_time.dart';
import '../utils/format_rupiah.dart';
import 'order_status_chip.dart';
import 'pressable_card.dart';
import 'restaurant_avatar.dart';

// Ringkasan satu pesanan untuk daftar; judul bisa nama resto atau nama pemesan
class OrderCard extends StatelessWidget {
  final FoodOrder order;
  final String title;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final createdAt = order.createdAt;
    final itemCount = order.items.fold(0, (count, item) => count + item.qty);
    return PressableCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RestaurantAvatar(
                restaurantId: order.restaurantId,
                size: 44,
                heroEnabled: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      createdAt == null
                          ? 'Baru saja'
                          : formatDateTime(createdAt),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status di baris bawah agar nama dan waktu tidak terpotong
          Row(
            children: [
              OrderStatusChip(status: order.status),
              const Spacer(),
              Text(
                '$itemCount item · ',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(formatRupiah(order.total), style: text.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}
