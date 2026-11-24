import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';
import '../utils/format_date_time.dart';
import '../utils/format_rupiah.dart';
import 'order_status_chip.dart';
import 'pressable_card.dart';
import 'restaurant_avatar.dart';

/// Ringkasan satu pesanan bergaya Emerald Premium untuk daftar pesanan.
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
    final createdAt = order.createdAt;
    final itemCount = order.items.fold(0, (count, item) => count + item.qty);

    return PressableCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RestaurantAvatar(
                restaurantId: order.restaurantId,
                size: 46,
                heroEnabled: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: EmeraldColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: EmeraldColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          createdAt == null ? 'Baru saja' : formatDateTime(createdAt),
                          style: text.bodySmall?.copyWith(
                            color: EmeraldColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: EmeraldColors.textSecondary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OrderStatusChip(status: order.status),
                    if (order.deliveryStatus != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: EmeraldColors.softGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.delivery_dining_rounded,
                              color: EmeraldColors.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.deliveryStatus!.label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: EmeraldColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$itemCount Menu',
                    style: text.bodySmall?.copyWith(
                      color: EmeraldColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    formatRupiah(order.total),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: EmeraldColors.primaryDark,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
