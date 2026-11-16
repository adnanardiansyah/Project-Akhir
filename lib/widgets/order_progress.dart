import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';

// Langkah yang ditampilkan di garis progres pesanan
const List<(OrderStatus, String)> _steps = [
  (OrderStatus.pending, 'Dipesan'),
  (OrderStatus.confirmed, 'Dikonfirmasi'),
  (OrderStatus.paid, 'Dibayar'),
];

// Garis progres Dipesan -> Dikonfirmasi -> Dibayar yang beranimasi saat status naik
class OrderProgress extends StatelessWidget {
  final OrderStatus status;

  const OrderProgress({super.key, required this.status});

  // Urutan langkah yang sudah dicapai; pesanan batal tidak punya progres
  int get _reachedIndex => switch (status) {
    OrderStatus.pending => 0,
    OrderStatus.confirmed => 1,
    OrderStatus.paid => 2,
    OrderStatus.cancelled => -1,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (status == OrderStatus.cancelled) {
      return Row(
        children: [
          Icon(Icons.cancel_rounded, color: scheme.error),
          const SizedBox(width: 8),
          Text(
            'Pesanan dibatalkan',
            style: text.titleSmall?.copyWith(color: scheme.error),
          ),
        ],
      );
    }
    return Row(
      children: [
        for (final (index, (_, label)) in _steps.indexed) ...[
          if (index > 0)
            Expanded(
              child: AnimatedContainer(
                duration: motionMedium,
                curve: motionCurve,
                height: 3,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: index <= _reachedIndex
                      ? scheme.primary
                      : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          _StepDot(label: label, reached: index <= _reachedIndex),
        ],
      ],
    );
  }
}

// Satu titik langkah dengan label; terisi warna utama bila sudah dicapai
class _StepDot extends StatelessWidget {
  final String label;
  final bool reached;

  const _StepDot({required this.label, required this.reached});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: motionMedium,
          curve: motionCurve,
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? scheme.primary : scheme.surfaceContainerHighest,
          ),
          child: AnimatedSwitcher(
            duration: motionShort,
            child: reached
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('done'),
                    size: 16,
                    color: scheme.onPrimary,
                  )
                : const SizedBox.shrink(key: ValueKey('todo')),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: reached ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
