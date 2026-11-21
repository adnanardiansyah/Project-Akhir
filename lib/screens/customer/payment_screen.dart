import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/payment_method.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_rupiah.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/restaurant_avatar.dart';

// Layar pembayaran simulasi: pilih metode, lihat total, lalu bayar
class PaymentScreen extends StatefulWidget {
  final FoodOrder order;
  final AppServices services;

  const PaymentScreen({super.key, required this.order, required this.services});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

// Menyimpan metode terpilih, tanda sedang membayar, dan hasil bayar
class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod? _selected;
  bool _isPaying = false;
  bool _isPaid = false;

  // Mengirim pembayaran; galat aturan status ditampilkan apa adanya
  Future<void> _pay() async {
    final method = _selected;
    if (method == null || _isPaying) return;
    setState(() => _isPaying = true);
    try {
      await widget.services.orders.payOrder(widget.order.id, method);
      if (mounted) setState(() => _isPaid = true);
    } on StateError catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Pembayaran gagal. Periksa koneksi atau akses Firestore.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: AnimatedSwitcher(
        duration: motionMedium,
        switchInCurve: motionCurve,
        child: _isPaid
            ? _PaymentSuccess(
                key: const ValueKey('paid'),
                total: widget.order.total,
                method: _selected!,
                onDone: () => Navigator.of(context).pop(),
              )
            : _buildForm(context),
      ),
    );
  }

  // Ringkasan pesanan, pilihan metode, dan tombol bayar
  Widget _buildForm(BuildContext context) {
    final order = widget.order;
    return Column(
      key: const ValueKey('form'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const FadeSlideIn(child: _SimulationNotice()),
              const SizedBox(height: 16),
              FadeSlideIn(index: 1, child: _OrderSummary(order: order)),
              const SizedBox(height: 24),
              FadeSlideIn(
                index: 2,
                child: Text(
                  'Pilih metode pembayaran',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              for (final (index, method) in PaymentMethod.values.indexed) ...[
                FadeSlideIn(
                  index: index + 3,
                  child: _MethodTile(
                    method: method,
                    selected: _selected == method,
                    onTap: _isPaying
                        ? null
                        : () => setState(() => _selected = method),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LoadingButton(
                label: 'Bayar ${formatRupiah(order.total)}',
                isLoading: _isPaying,
                onPressed: _selected == null ? null : _pay,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Penanda bahwa pembayaran hanya simulasi (K3)
class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(fieldRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pembayaran simulasi — tidak ada uang sungguhan yang dipotong.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// Ringkasan resto, jumlah item, dan total yang harus dibayar
class _OrderSummary extends StatelessWidget {
  final FoodOrder order;

  const _OrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final itemCount = order.items.fold(0, (count, item) => count + item.qty);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            RestaurantAvatar(
              restaurantId: order.restaurantId,
              size: 48,
              heroEnabled: false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.restaurantName, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '$itemCount item',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatRupiah(order.total),
              style: text.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kartu satu metode bayar; tepi dan tanda centang beranimasi saat dipilih
class _MethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: motionShort,
      curve: motionCurve,
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: selected
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.6),
          width: selected ? 1.8 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(method.icon, color: scheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(method.label, style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        method.description,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: motionShort,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    key: ValueKey(selected),
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Tampilan berhasil: centang yang membesar memantul, total, dan metode
class _PaymentSuccess extends StatelessWidget {
  final int total;
  final PaymentMethod method;
  final VoidCallback onDone;

  const _PaymentSuccess({
    super.key,
    required this.total,
    required this.method,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: successGreen.withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 72,
                  color: successGreen,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              index: 2,
              child: Column(
                children: [
                  Text('Pembayaran berhasil', style: text.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    '${formatRupiah(total)} lewat ${method.label}',
                    style: text.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: onDone,
                    child: const Text('Kembali ke pesanan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
