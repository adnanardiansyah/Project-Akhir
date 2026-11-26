import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/payment_method.dart';
import '../theme/app_theme.dart';
import '../utils/format_date_time.dart';
import '../utils/format_rupiah.dart';

class PaymentReceipt extends StatefulWidget {
  final FoodOrder order;
  final PaymentMethod method;
  final bool isCod;
  final DateTime? paidAt;

  const PaymentReceipt({
    super.key,
    required this.order,
    required this.method,
    required this.isCod,
    this.paidAt,
  });

  @override
  State<PaymentReceipt> createState() => _PaymentReceiptState();
}

class _PaymentReceiptState extends State<PaymentReceipt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );
  late final CurvedAnimation _reveal = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
  );
  late final CurvedAnimation _strike = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
  );
  late final CurvedAnimation _stamp = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 0.9, curve: Curves.elasticOut),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.14),
    end: Offset.zero,
  ).animate(_reveal);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _strike.dispose();
    _stamp.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _reveal,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: EmeraldColors.border),
            boxShadow: emeraldCardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: EmeraldColors.softGreenLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: EmeraldColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isCod ? 'Struk Pesanan' : 'Struk Pembayaran',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: EmeraldColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bukti transaksi simulasi',
                            style: const TextStyle(
                              fontSize: 11,
                              color: EmeraldColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ReceiptStatus(isCod: widget.isCod),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _ReceiptRow(label: 'No. Pesanan', value: '#${widget.order.id}'),
                const SizedBox(height: 10),
                _ReceiptRow(
                  label: 'Restoran',
                  value: widget.order.restaurantName,
                ),
                const SizedBox(height: 10),
                _ReceiptRow(label: 'Metode', value: widget.method.label),
                const SizedBox(height: 10),
                _ReceiptRow(
                  label: 'Waktu',
                  value: widget.paidAt == null
                      ? 'Menunggu pembayaran'
                      : formatDateTime(widget.paidAt!),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                ...widget.order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.qty}x ${item.name}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: EmeraldColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatRupiah(item.price * item.qty),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: EmeraldColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: EmeraldColors.textPrimary,
                        ),
                      ),
                    ),
                    FittedBox(
                      child: Text(
                        formatRupiah(widget.order.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: EmeraldColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _PaymentStamp(
                  strike: _strike,
                  stamp: _stamp,
                  isCod: widget.isCod,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: EmeraldColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: EmeraldColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptStatus extends StatelessWidget {
  final bool isCod;

  const _ReceiptStatus({required this.isCod});

  @override
  Widget build(BuildContext context) {
    final color = isCod ? EmeraldColors.warning : EmeraldColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isCod ? 'COD' : 'LUNAS',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _PaymentStamp extends StatelessWidget {
  final Animation<double> strike;
  final Animation<double> stamp;
  final bool isCod;

  const _PaymentStamp({
    required this.strike,
    required this.stamp,
    required this.isCod,
  });

  @override
  Widget build(BuildContext context) {
    if (isCod) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: EmeraldColors.softGreenLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 16,
              color: EmeraldColors.warning,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Bayar tunai ke kurir saat pesanan tiba',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: EmeraldColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'BELUM DIBAYAR',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: EmeraldColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
          AnimatedBuilder(
            animation: strike,
            builder: (context, _) => Align(
              alignment: Alignment.center,
              child: Container(
                width: 170 * strike.value,
                height: 2,
                decoration: BoxDecoration(
                  color: EmeraldColors.success.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: stamp,
            builder: (context, _) => Transform.scale(
              scale: stamp.value.clamp(0.0, 1.05),
              child: Transform.rotate(
                angle: -0.12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: EmeraldColors.success, width: 3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'LUNAS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: EmeraldColors.success,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
