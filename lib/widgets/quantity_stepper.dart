import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Tombol "Tambah" yang berubah menjadi pengatur jumlah (- n +) setelah menu dipilih
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: motionShort,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: quantity == 0
          ? FilledButton.tonalIcon(
              key: const ValueKey('add'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: onIncrement,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Tambah'),
            )
          : _Stepper(
              key: const ValueKey('stepper'),
              quantity: quantity,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
    );
  }
}

// Pengatur jumlah dengan angka yang beranimasi saat berubah
class _Stepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const _Stepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(fieldRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Kurangi',
            icon: Icon(Icons.remove_rounded, color: scheme.primary),
            onPressed: onDecrement,
          ),
          AnimatedSwitcher(
            duration: motionShort,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Text(
              '$quantity',
              key: ValueKey(quantity),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: scheme.primary),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Tambah',
            icon: Icon(Icons.add_rounded, color: scheme.primary),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}
