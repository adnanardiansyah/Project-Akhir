import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Tombol utama yang berganti mulus menjadi indikator memuat saat proses berjalan
class LoadingButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  // Null membuat tombol nonaktif, misalnya saat proses lain sedang berjalan
  final VoidCallback? onPressed;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.icon,
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
            : (icon == null
                  ? Text(label, key: const ValueKey('label'))
                  : Row(
                      key: const ValueKey('label-with-icon'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )),
      ),
    );
  }
}
