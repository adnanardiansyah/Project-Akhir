import 'package:flutter/material.dart';

import '../services/route_distance_service.dart';

// Tombol untuk memasukkan kunci pribadi OpenRouteService bagi sesi berjalan
class RouteApiKeyButton extends StatelessWidget {
  final RouteDistanceService service;

  const RouteApiKeyButton({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => IconButton(
        tooltip: service.hasPersonalApiKey
            ? 'Ubah kunci jarak'
            : 'Masukkan kunci jarak',
        icon: const Icon(Icons.key_rounded),
        onPressed: () => _showKeyDialog(context),
      ),
    );
  }

  // Kunci tidak disimpan di aplikasi atau dikirim ke repositori
  Future<void> _showKeyDialog(BuildContext context) async {
    final key = await showDialog<String>(
      context: context,
      builder: (context) =>
          _RouteApiKeyDialog(hasPersonalApiKey: service.hasPersonalApiKey),
    );
    if (key == null) return;
    if (key.isEmpty) {
      service.clearPersonalApiKey();
    } else {
      service.setPersonalApiKey(key);
    }
  }
}

// Dialog yang mengelola input key selama dialog terbuka
class _RouteApiKeyDialog extends StatefulWidget {
  final bool hasPersonalApiKey;

  const _RouteApiKeyDialog({required this.hasPersonalApiKey});

  @override
  State<_RouteApiKeyDialog> createState() => _RouteApiKeyDialogState();
}

class _RouteApiKeyDialogState extends State<_RouteApiKeyDialog> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Kunci jarak rute'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan kunci OpenRouteService milik Anda. '
              'Kunci hanya aktif selama sesi aplikasi ini.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'API key pribadi'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Masukkan API key Anda'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        if (widget.hasPersonalApiKey)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Hapus'),
          ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
