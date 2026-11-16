import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Tombol utama yang berganti mulus menjadi indikator memuat saat proses berjalan
class LoadingButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const LoadingButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: motionShort,
        child: isLoading
            ? const SizedBox.square(
                key: ValueKey('loading'),
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Text(label, key: const ValueKey('label')),
      ),
    );
  }
}
