import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/partner_application.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../utils/form_validators.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/password_field.dart';

// Form pendaftaran akun mitra restoran dan kurir.
class PartnerRegistrationScreen extends StatefulWidget {
  final AppServices services;
  final AppUser? applicant;
  final PartnerApplication? existingApplication;

  const PartnerRegistrationScreen({
    super.key,
    required this.services,
    this.applicant,
    this.existingApplication,
  });

  @override
  State<PartnerRegistrationScreen> createState() =>
      _PartnerRegistrationScreenState();
}

class _PartnerRegistrationScreenState extends State<PartnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _restaurantController = TextEditingController();
  final _addressController = TextEditingController();
  late PartnerApplicationType _type;
  GeoPoint? _restaurantLocation;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  String? _locationError;

  bool get _isAuthenticated => widget.applicant != null;
  bool get _isReapplying => widget.existingApplication != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingApplication;
    _type = existing?.type ?? PartnerApplicationType.restaurant;
    _nameController.text = existing?.applicantName ?? '';
    _emailController.text =
        existing?.email ?? widget.services.auth.currentEmail ?? '';
    _phoneController.text = existing?.phone ?? '';
    _restaurantController.text = existing?.restaurantName ?? '';
    _addressController.text = existing?.address ?? '';
    _restaurantLocation = existing?.location;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    _restaurantController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Mengambil titik GPS perangkat sebagai lokasi restoran.
  Future<void> _useCurrentLocation() async {
    if (_isLoadingLocation) return;
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });
    final result = await widget.services.location.refreshCurrentLocation();
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = false;
      _restaurantLocation = result.location;
      _locationError = result.location == null
          ? _locationIssueMessage(result.issue)
          : null;
    });
  }

  String _locationIssueMessage(LocationIssue? issue) => switch (issue) {
    LocationIssue.serviceDisabled => 'Aktifkan GPS perangkat terlebih dahulu.',
    LocationIssue.permissionDenied => 'Izin lokasi belum diberikan.',
    LocationIssue.permissionDeniedForever =>
      'Izinkan akses lokasi melalui Pengaturan perangkat.',
    LocationIssue.unavailable || null => 'Lokasi perangkat tidak terbaca.',
  };

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 15) {
      return 'Masukkan nomor telepon yang valid';
    }
    return null;
  }

  // Menyimpan pendaftaran baru atau pengajuan ulang.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == PartnerApplicationType.restaurant &&
        _restaurantLocation == null) {
      showErrorSnackBar(context, 'Tentukan lokasi restoran dari perangkat.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isReapplying) {
        await widget.services.partnerApplications.resubmit(
          uid: widget.applicant!.uid,
          type: _type,
          applicantName: _nameController.text,
          phone: _phoneController.text,
          restaurantName: _restaurantController.text,
          address: _addressController.text,
          location: _restaurantLocation,
        );
      } else if (_isAuthenticated) {
        await widget.services.partnerApplications.submitForCurrentCustomer(
          type: _type,
          phone: _phoneController.text,
          restaurantName: _restaurantController.text,
          address: _addressController.text,
          location: _restaurantLocation,
        );
      } else {
        await widget.services.auth.registerPartnerApplicant(
          type: _type,
          displayName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phone: _phoneController.text,
          restaurantName: _restaurantController.text,
          address: _addressController.text,
          location: _restaurantLocation,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, errorMessageFor(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pendaftaran mitra')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              FadeSlideIn(
                child: AuthHeader(
                  title: _isReapplying
                      ? 'Perbaiki pengajuan'
                      : 'Bergabung sebagai mitra',
                  subtitle: _isReapplying
                      ? 'Perbarui data pengajuan untuk ditinjau kembali.'
                      : 'Pilih jenis mitra. Admin akan meninjau pengajuanmu.',
                ),
              ),
              const SizedBox(height: 24),
              if (_isReapplying) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: validateDisplayName,
                ),
                const SizedBox(height: 14),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.mail_outline_rounded),
                    title: const Text('Email akun'),
                    subtitle: Text(widget.services.auth.currentEmail ?? ''),
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (_isAuthenticated) ...[
                _AccountSummary(
                  name: widget.applicant!.displayName,
                  email: widget.services.auth.currentEmail ?? '',
                ),
                const SizedBox(height: 20),
              ] else ...[
                FadeSlideIn(
                  index: 1,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: validateDisplayName,
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 2,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: validateEmail,
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 3,
                  child: PasswordField(
                    controller: _passwordController,
                    label: 'Kata sandi',
                    textInputAction: TextInputAction.next,
                    validator: validatePassword,
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 4,
                  child: PasswordField(
                    controller: _confirmController,
                    label: 'Ulangi kata sandi',
                    textInputAction: TextInputAction.next,
                    validator: (value) => validatePasswordConfirmation(
                      value,
                      _passwordController.text,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              FadeSlideIn(
                index: 5,
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor telepon aktif',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: 'Contoh: 08xxxxxxxxxx',
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: _validatePhone,
                ),
              ),
              const SizedBox(height: 22),
              Text('Jenis mitra', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              SegmentedButton<PartnerApplicationType>(
                segments: const [
                  ButtonSegment(
                    value: PartnerApplicationType.restaurant,
                    icon: Icon(Icons.storefront_outlined),
                    label: Text('Restoran'),
                  ),
                  ButtonSegment(
                    value: PartnerApplicationType.courier,
                    icon: Icon(Icons.delivery_dining_rounded),
                    label: Text('Kurir'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: _isReapplying || _isLoading
                    ? null
                    : (selection) => setState(() => _type = selection.first),
              ),
              if (_type == PartnerApplicationType.restaurant) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _restaurantController,
                  decoration: const InputDecoration(
                    labelText: 'Nama restoran',
                    prefixIcon: Icon(Icons.restaurant_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Nama restoran wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat restoran',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 3,
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Alamat restoran wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _isLoading || _isLoadingLocation
                      ? null
                      : _useCurrentLocation,
                  icon: _isLoadingLocation
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(
                    _restaurantLocation == null
                        ? 'Gunakan lokasi restoran saat ini'
                        : 'Perbarui lokasi restoran',
                  ),
                ),
                if (_restaurantLocation case final location?) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Titik restoran: ${location.latitude.toStringAsFixed(5)}, '
                    '${location.longitude.toStringAsFixed(5)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (_locationError case final message?) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _type == PartnerApplicationType.restaurant
                            ? 'Role restoran aktif setelah admin menyetujui pengajuan. Listing ditinjau terpisah sebelum tampil di katalog.'
                            : 'Role kurir aktif setelah admin menyetujui pengajuan.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                label: _isReapplying ? 'Kirim ulang pengajuan' : 'Kirim pengajuan',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  final String name;
  final String email;

  const _AccountSummary({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(Icons.person_outline_rounded, color: scheme.primary),
        ),
        title: Text(name),
        subtitle: Text(email),
      ),
    );
  }
}
