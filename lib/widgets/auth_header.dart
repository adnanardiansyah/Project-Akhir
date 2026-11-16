import 'package:flutter/material.dart';

import 'brand_mark.dart';

// Kepala layar masuk dan daftar: logo, judul, dan keterangan
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(),
        const SizedBox(height: 28),
        Text(title, style: text.headlineMedium),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
