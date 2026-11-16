import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Kartu yang mengecil halus saat ditekan, memberi umpan balik sentuhan
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

// Menyimpan status ditekan untuk animasi skala
class _PressableCardState extends State<PressableCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap != null && _pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: motionShort,
      curve: motionCurve,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}
