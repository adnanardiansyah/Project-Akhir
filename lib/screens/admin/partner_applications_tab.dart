import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/partner_application.dart';
import '../../services/app_services.dart';
import '../../widgets/error_snack_bar.dart';

enum _ApplicationFilter { pending, all, approved, rejected }

extension on _ApplicationFilter {
  String get label => switch (this) {
    _ApplicationFilter.pending => 'Menunggu',
    _ApplicationFilter.all => 'Semua',
    _ApplicationFilter.approved => 'Disetujui',
    _ApplicationFilter.rejected => 'Ditolak',
  };

  PartnerApplicationStatus? get status => switch (this) {
    _ApplicationFilter.pending => PartnerApplicationStatus.pending,
    _ApplicationFilter.all => null,
    _ApplicationFilter.approved => PartnerApplicationStatus.approved,
    _ApplicationFilter.rejected => PartnerApplicationStatus.rejected,
  };
}

// Daftar dan tinjau pengajuan akun restoran atau kurir.
class PartnerApplicationsTab extends StatefulWidget {
  final AppUser user;
  final AppServices services;

  const PartnerApplicationsTab({
    super.key,
    required this.user,
    required this.services,
  });

  @override
  State<PartnerApplicationsTab> createState() => _PartnerApplicationsTabState();
}

class _PartnerApplicationsTabState extends State<PartnerApplicationsTab> {
  late final _applications = widget.services.admin.watchPartnerApplications();
  final _searchController = TextEditingController();
  _ApplicationFilter _filter = _ApplicationFilter.pending;
  String _query = '';
  String? _reviewingUid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _review(
    PartnerApplication application,
    PartnerApplicationStatus status,
  ) async {
    final decision = await _showReviewDialog(application, status);
    if (decision == null || !mounted) return;
    setState(() => _reviewingUid = application.applicantUid);
    try {
      await widget.services.admin.reviewPartnerApplication(
        application: application,
        status: status,
        adminUid: widget.user.uid,
        rejectionReason: decision.reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == PartnerApplicationStatus.approved
                  ? 'Pengajuan disetujui dan role mitra sudah diaktifkan.'
                  : 'Pengajuan ditolak. Pemohon dapat memperbaiki datanya.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          error is StateError
              ? error.message.toString()
              : 'Keputusan gagal disimpan. Periksa akses Firestore.',
        );
      }
    } finally {
      if (mounted) setState(() => _reviewingUid = null);
    }
  }

  Future<_ReviewDecision?> _showReviewDialog(
    PartnerApplication application,
    PartnerApplicationStatus status,
  ) async {
    final reasonController = TextEditingController();
    try {
      return await showDialog<_ReviewDecision>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            status == PartnerApplicationStatus.approved
                ? 'Setujui pengajuan?'
                : 'Tolak pengajuan?',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status == PartnerApplicationStatus.approved
                    ? application.type == PartnerApplicationType.restaurant
                          ? 'Akun restoran akan aktif. Data usaha masuk antrean tinjauan restoran sebelum tampil di katalog.'
                          : 'Akun akan mendapat akses dashboard kurir.'
                    : 'Pemohon dapat melihat catatan ini dan mengirim ulang datanya.',
              ),
              if (status == PartnerApplicationStatus.rejected) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLength: 300,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan untuk pemohon',
                    hintText: 'Jelaskan data yang perlu diperbaiki',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _ReviewDecision(reason: reasonController.text),
              ),
              child: Text(
                status == PartnerApplicationStatus.approved
                    ? 'Setujui'
                    : 'Tolak',
              ),
            ),
          ],
        ),
      );
    } finally {
      reasonController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PartnerApplication>>(
      stream: _applications,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Pengajuan mitra gagal dimuat. Pastikan Firestore Rules terbaru sudah diterapkan.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final applications = snapshot.data ?? const <PartnerApplication>[];
        final counts = {
          for (final status in PartnerApplicationStatus.values)
            status: applications
                .where((application) => application.status == status)
                .length,
        };
        final query = _query.trim().toLowerCase();
        final visible = applications.where((application) {
          final matchesStatus =
              _filter.status == null || application.status == _filter.status;
          final matchesQuery =
              query.isEmpty ||
              application.applicantName.toLowerCase().contains(query) ||
              application.email.toLowerCase().contains(query) ||
              (application.restaurantName?.toLowerCase().contains(query) ??
                  false) ||
              application.applicantUid.toLowerCase().contains(query);
          return matchesStatus && matchesQuery;
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Text(
              'Pengajuan mitra',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Setujui untuk mengaktifkan akun restoran atau kurir.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari nama, email, atau nama restoran',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in _ApplicationFilter.values) ...[
                    ChoiceChip(
                      label: Text(
                        filter.status == null
                            ? '${filter.label} (${applications.length})'
                            : '${filter.label} (${counts[filter.status] ?? 0})',
                      ),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (visible.isEmpty)
              _ApplicationEmpty(filter: _filter)
            else
              for (final application in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PartnerApplicationCard(
                    application: application,
                    isReviewing: _reviewingUid == application.applicantUid,
                    isDisabled: _reviewingUid != null,
                    onApprove: () =>
                        _review(application, PartnerApplicationStatus.approved),
                    onReject: () =>
                        _review(application, PartnerApplicationStatus.rejected),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _PartnerApplicationCard extends StatelessWidget {
  final PartnerApplication application;
  final bool isReviewing;
  final bool isDisabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PartnerApplicationCard({
    required this.application,
    required this.isReviewing,
    required this.isDisabled,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRestaurant = application.type == PartnerApplicationType.restaurant;
    final isPending = application.status == PartnerApplicationStatus.pending;
    final headline = isRestaurant
        ? application.restaurantName ?? 'Restoran'
        : application.applicantName;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(
                    isRestaurant
                        ? Icons.storefront_outlined
                        : Icons.delivery_dining_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        isRestaurant ? 'Mitra restoran' : 'Mitra kurir',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _ApplicationStatusBadge(status: application.status),
              ],
            ),
            const SizedBox(height: 14),
            _ApplicationDetail(
              icon: Icons.person_outline_rounded,
              value: application.applicantName,
            ),
            _ApplicationDetail(
              icon: Icons.mail_outline_rounded,
              value: application.email,
            ),
            _ApplicationDetail(
              icon: Icons.phone_outlined,
              value: application.phone,
            ),
            if (isRestaurant) ...[
              _ApplicationDetail(
                icon: Icons.location_on_outlined,
                value: application.address ?? '-',
              ),
              if (application.location case final location?)
                _ApplicationDetail(
                  icon: Icons.my_location_rounded,
                  value:
                      '${location.latitude.toStringAsFixed(5)}, '
                      '${location.longitude.toStringAsFixed(5)}',
                ),
            ],
            if (!isPending &&
                (application.rejectionReason?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 10),
              Text(
                'Catatan: ${application.rejectionReason}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isDisabled ? null : onReject,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isDisabled ? null : onApprove,
                      icon: isReviewing
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('Setujui'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApplicationDetail extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ApplicationDetail({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ApplicationStatusBadge extends StatelessWidget {
  final PartnerApplicationStatus status;

  const _ApplicationStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      PartnerApplicationStatus.pending => ('Menunggu', const Color(0xFFB45309)),
      PartnerApplicationStatus.approved => ('Disetujui', scheme.primary),
      PartnerApplicationStatus.rejected => ('Ditolak', scheme.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ApplicationEmpty extends StatelessWidget {
  final _ApplicationFilter filter;

  const _ApplicationEmpty({required this.filter});

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _ApplicationFilter.pending => 'Belum ada pengajuan yang menunggu.',
      _ApplicationFilter.all => 'Belum ada pengajuan mitra.',
      _ApplicationFilter.approved => 'Belum ada pengajuan yang disetujui.',
      _ApplicationFilter.rejected => 'Belum ada pengajuan yang ditolak.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ReviewDecision {
  final String reason;

  const _ReviewDecision({required this.reason});
}
