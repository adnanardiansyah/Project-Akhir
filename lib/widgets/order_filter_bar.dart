import 'package:flutter/material.dart';

import '../models/order.dart';

// Pencarian dan filter tahap pesanan yang dipakai panel admin dan restoran.
class OrderFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final OrderStatus? selectedStatus;
  final Map<OrderStatus, int> statusCounts;
  final int totalCount;
  final String searchHint;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<OrderStatus?> onStatusChanged;

  const OrderFilterBar({
    super.key,
    required this.controller,
    required this.query,
    required this.selectedStatus,
    required this.statusCounts,
    required this.totalCount,
    required this.searchHint,
    required this.onQueryChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          onChanged: onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: () {
                      controller.clear();
                      onQueryChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text('Semua ($totalCount)'),
                selected: selectedStatus == null,
                onSelected: (_) => onStatusChanged(null),
              ),
              for (final status in OrderStatus.values) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('${status.label} (${statusCounts[status] ?? 0})'),
                  selected: selectedStatus == status,
                  onSelected: (_) => onStatusChanged(status),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
