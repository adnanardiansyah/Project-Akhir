import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'fade_slide_in.dart';
import 'skeleton_list.dart';
import 'state_message.dart';

// Daftar dari aliran data dengan tampilan memuat, galat, dan kosong yang beranimasi
class StreamListView<T> extends StatefulWidget {
  final Stream<List<T>> Function() streamFactory;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final IconData emptyIcon;
  final String emptyMessage;
  final String errorMessage;
  final Widget? header;
  // Ruang kosong di bawah daftar, misalnya agar tidak tertutup bar keranjang
  final double bottomPadding;
  // Berubah saat pengguna menarik daftar untuk meminta aliran baru
  final Object? refreshToken;

  const StreamListView({
    super.key,
    required this.streamFactory,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.errorMessage,
    this.header,
    this.bottomPadding = 32,
    this.refreshToken,
  });

  @override
  State<StreamListView<T>> createState() => _StreamListViewState<T>();
}

// Menyimpan aliran agar tidak dibuat ulang tiap build
class _StreamListViewState<T> extends State<StreamListView<T>> {
  late Stream<List<T>> _stream = widget.streamFactory();

  @override
  void didUpdateWidget(covariant StreamListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _stream = widget.streamFactory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: _stream,
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: motionMedium,
          switchInCurve: motionCurve,
          switchOutCurve: motionCurve,
          child: _buildContent(context, snapshot),
        );
      },
    );
  }

  // Memilih tampilan sesuai keadaan aliran; key berbeda memicu animasi pergantian
  Widget _buildContent(BuildContext context, AsyncSnapshot<List<T>> snapshot) {
    if (snapshot.hasError) {
      return StateMessage(
        key: const ValueKey('error'),
        icon: Icons.wifi_off_rounded,
        title: 'Gagal memuat',
        message: widget.errorMessage,
      );
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SkeletonList(key: ValueKey('loading'));
    }
    final items = snapshot.data ?? const [];
    if (items.isEmpty) {
      return StateMessage(
        key: const ValueKey('empty'),
        icon: widget.emptyIcon,
        title: widget.emptyMessage,
      );
    }
    final header = widget.header;
    final offset = header == null ? 0 : 1;
    return ListView.separated(
      key: const ValueKey('list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 8, 20, widget.bottomPadding),
      itemCount: items.length + offset,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (header != null && index == 0) {
          return FadeSlideIn(child: header);
        }
        return FadeSlideIn(
          index: index,
          child: widget.itemBuilder(context, items[index - offset]),
        );
      },
    );
  }
}
