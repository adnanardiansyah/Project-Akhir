import 'package:flutter/material.dart';

import '../controllers/cart_controller.dart';
import '../theme/app_theme.dart';
import '../utils/format_rupiah.dart';

// Bar keranjang melayang di bawah; muncul meluncur saat keranjang berisi
class CartBar extends StatelessWidget {
  final CartController cart;
  final VoidCallback onOpen;

  const CartBar({super.key, required this.cart, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final visible = !cart.isEmpty;
        return AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1.5),
          duration: motionMedium,
          curve: motionCurve,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: motionShort,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Material(
                color: scheme.primary,
                elevation: 6,
                shadowColor: scheme.primary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(cardRadius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(cardRadius),
                  onTap: visible ? onOpen : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_rounded,
                          color: scheme.onPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${cart.totalQuantity} item',
                            style: text.titleMedium?.copyWith(
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                        Text(
                          formatRupiah(cart.total),
                          style: text.titleMedium?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
