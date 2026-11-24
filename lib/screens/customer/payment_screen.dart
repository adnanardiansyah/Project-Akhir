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

/// Layar Pembayaran Simulasi dengan Konsep Emerald Premium.
class PaymentScreen extends StatefulWidget {
  final FoodOrder order;
  final AppServices services;

  const PaymentScreen({super.key, required this.order, required this.services});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod? _selected;
  bool _isPaying = false;
  bool _isDone = false;
  bool _isCod = false;

  // COD hanya dipilih sekarang; uang diterima kurir saat pesanan tiba
  Future<void> _confirm() async {
    final method = _selected;
    if (method == null || _isPaying) return;
    setState(() => _isPaying = true);
    try {
      if (method == PaymentMethod.cod) {
        await widget.services.orders.chooseCodPayment(widget.order.id);
      } else {
        await widget.services.orders.payOrder(widget.order.id, method);
      }
      if (mounted) {
        setState(() {
          _isCod = method == PaymentMethod.cod;
          _isDone = true;
        });
      }
    } on StateError catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
          context,
          method == PaymentMethod.cod
              ? 'Metode COD gagal disimpan. Periksa koneksi atau akses Firestore.'
              : 'Pembayaran gagal. Periksa koneksi atau akses Firestore.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmeraldColors.background,
      appBar: AppBar(
        title: const Text('Pembayaran'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: AnimatedSwitcher(
        duration: motionMedium,
        switchInCurve: motionCurve,
        child: _isDone
            ? _PaymentSuccess(
                key: const ValueKey('done'),
                total: widget.order.total,
                method: _selected!,
                isCod: _isCod,
                onDone: () => Navigator.of(context).pop(),
              )
            : _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final order = widget.order;
    return Column(
      key: const ValueKey('form'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const FadeSlideIn(child: _SimulationNotice()),
              const SizedBox(height: 16),
              FadeSlideIn(index: 1, child: _OrderSummary(order: order)),
              const SizedBox(height: 24),
              FadeSlideIn(
                index: 2,
                child: Text(
                  'Pilih Metode Pembayaran',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: EmeraldColors.textPrimary,
                  ),
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
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: EmeraldColors.border)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: LoadingButton(
              label: _selected == PaymentMethod.cod
                  ? 'Pilih COD ${formatRupiah(order.total)}'
                  : 'Konfirmasi Bayar ${formatRupiah(order.total)}',
              icon: _selected == PaymentMethod.cod
                  ? Icons.money_rounded
                  : Icons.lock_outline_rounded,
              isLoading: _isPaying,
              onPressed: _selected == null ? null : _confirm,
            ),
          ),
        ),
      ],
    );
  }
}

class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EmeraldColors.softGreenLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmeraldColors.accent.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: EmeraldColors.primary,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mode Simulasi Aman — Transaksi tidak memotong saldo/uang sungguhan.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EmeraldColors.primaryDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final FoodOrder order;

  const _OrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final itemCount = order.items.fold(0, (count, item) => count + item.qty);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EmeraldColors.border),
      ),
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
                Text(
                  order.restaurantName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: EmeraldColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$itemCount Menu Makanan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: EmeraldColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatRupiah(order.total),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: EmeraldColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

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
    return AnimatedContainer(
      duration: motionShort,
      curve: motionCurve,
      decoration: BoxDecoration(
        color: selected ? EmeraldColors.softGreenLight : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? EmeraldColors.primary : EmeraldColors.border,
          width: selected ? 1.8 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? EmeraldColors.softGreen
                        : EmeraldColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    method.icon,
                    color: selected
                        ? EmeraldColors.primary
                        : EmeraldColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: EmeraldColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        method.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: EmeraldColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? EmeraldColors.primary
                      : EmeraldColors.border,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentSuccess extends StatelessWidget {
  final int total;
  final PaymentMethod method;
  final bool isCod;
  final VoidCallback onDone;

  const _PaymentSuccess({
    super.key,
    required this.total,
    required this.method,
    required this.isCod,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
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
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: EmeraldColors.softGreen,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 68,
                  color: EmeraldColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              index: 2,
              child: Column(
                children: [
                  Text(
                    isCod ? 'Metode COD Dipilih' : 'Pembayaran Sukses!',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: EmeraldColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCod
                        ? 'Siapkan ${formatRupiah(total)} tunai. Bayar langsung ke kurir saat pesanan tiba.'
                        : 'Total ${formatRupiah(total)} telah terbayar menggunakan ${method.label}. Resto akan segera memproses pesananmu.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: EmeraldColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: onDone,
                    child: const Text('Kembali ke Detail Pesanan'),
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
