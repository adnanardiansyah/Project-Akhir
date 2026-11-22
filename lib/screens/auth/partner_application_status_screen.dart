import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/partner_application.dart';
import '../../services/app_services.dart';
import '../../widgets/logout_button.dart';
import 'partner_registration_screen.dart';

// Menampilkan hasil tinjauan pengajuan akun mitra.
class PartnerApplicationStatusScreen extends StatelessWidget {
  final AppUser user;
  final PartnerApplication application;
  final AppServices services;

  const PartnerApplicationStatusScreen({
    super.key,
    required this.user,
    required this.application,
    required this.services,
  });

  String get _partnerLabel => switch (application.type) {
    PartnerApplicationType.restaurant => 'mitra restoran',
    PartnerApplicationType.courier => 'kurir',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRejected =
        application.status == PartnerApplicationStatus.rejected;
    final isApproved =
        application.status == PartnerApplicationStatus.approved;
    final statusColor = isRejected
        ? scheme.error
        : isApproved
        ? scheme.primary
        : const Color(0xFFB45309);
    final statusIcon = isRejected
        ? Icons.mark_email_read_outlined
        : isApproved
        ? Icons.verified_outlined
        : Icons.hourglass_top_rounded;
    final statusTitle = isRejected
        ? 'Pengajuan perlu diperbaiki'
        : isApproved
        ? 'Pengajuan disetujui'
        : 'Pengajuan sedang ditinjau';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status pengajuan'),
        actions: [LogoutButton(authService: services.auth)],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(statusIcon, size: 54, color: statusColor),
                  const SizedBox(height: 16),
                  Text(
                    statusTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRejected
                        ? 'Periksa catatan admin lalu kirim ulang data yang benar.'
                        : isApproved
                        ? 'Pengajuan disetujui. Dashboard mitra sedang disiapkan.'
                        : 'Kami akan meninjau data pengajuan $_partnerLabel. '
                              'Role mitra aktif setelah admin menyetujuinya.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data pengajuan', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Jenis mitra', value: _partnerLabel),
                    _DetailRow(label: 'Nama', value: application.applicantName),
                    _DetailRow(label: 'Email', value: application.email),
                    _DetailRow(label: 'Telepon', value: application.phone),
                    if (application.type == PartnerApplicationType.restaurant) ...[
                      _DetailRow(
                        label: 'Restoran',
                        value: application.restaurantName ?? '-',
                      ),
                      _DetailRow(label: 'Alamat', value: application.address ?? '-'),
                    ],
                    if (isRejected &&
                        (application.rejectionReason?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Catatan admin',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(application.rejectionReason!),
                    ],
                  ],
                ),
              ),
            ),
            if (isRejected) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PartnerRegistrationScreen(
                      services: services,
                      applicant: user,
                      existingApplication: application,
                    ),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Perbaiki dan kirim ulang'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
