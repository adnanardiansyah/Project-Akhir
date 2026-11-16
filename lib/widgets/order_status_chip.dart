import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';

// Label status pesanan berwarna; warna dan teks berganti halus saat status berubah
class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusChip({super.key, required this.status});

  // Warna khas tiap status
  Color _colorFor(ColorScheme scheme) => switch (status) {
    OrderStatus.pending => const Color(0xFFB45309),
    OrderStatus.confirmed => const Color(0xFF2F7FE0),
    OrderStatus.paid => successGreen,
    OrderStatus.cancelled => scheme.error,
  };

  IconData get _icon => switch (status) {
    OrderStatus.pending => Icons.schedule_rounded,
    OrderStatus.confirmed => Icons.thumb_up_alt_rounded,
    OrderStatus.paid => Icons.check_circle_rounded,
    OrderStatus.cancelled => Icons.cancel_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(Theme.of(context).colorScheme);
    return AnimatedContainer(
      duration: motionMedium,
      curve: motionCurve,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedSwitcher(
        duration: motionShort,
        child: Row(
          key: ValueKey(status),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
