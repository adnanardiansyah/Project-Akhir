import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Membuat anak muncul pudar sambil naik sedikit, dengan jeda bertahap per urutan
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;

  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

// Mengatur pengendali animasi dan jeda mulai
class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  // Jeda per urutan dibatasi agar daftar panjang tetap cepat tampil
  static const _stepDelay = Duration(milliseconds: 55);
  static const _maxSteps = 8;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: motionMedium,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: motionCurve,
  );
  late final Animation<Offset> _offset = Tween(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(_curve);
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    final steps = widget.index.clamp(0, _maxSteps);
    _startTimer = Timer(_stepDelay * steps, _controller.forward);
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
