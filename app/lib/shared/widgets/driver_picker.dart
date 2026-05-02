import 'package:flutter/material.dart';

import '../models.dart';
import 'driver_chip.dart';

Future<Driver?> showDriverPicker(
  BuildContext context, {
  required List<Driver> drivers,
  required String title,
  Driver? selected,
  Set<String>? excludeIds,
}) {
  return showModalBottomSheet<Driver>(
    context: context,
    backgroundColor: const Color(0xFF15151E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _DriverPickerSheet(
      drivers: drivers,
      title: title,
      selectedId: selected?.id,
      excludeIds: excludeIds ?? const {},
    ),
  );
}

class _DriverPickerSheet extends StatelessWidget {
  final List<Driver> drivers;
  final String title;
  final String? selectedId;
  final Set<String> excludeIds;
  const _DriverPickerSheet({
    required this.drivers,
    required this.title,
    required this.selectedId,
    required this.excludeIds,
  });

  @override
  Widget build(BuildContext context) {
    // Group by team code
    final groups = <String, List<Driver>>{};
    for (final d in drivers) {
      final key = d.teamCode ?? 'OTHER';
      groups.putIfAbsent(key, () => []).add(d);
    }
    final teamKeys = groups.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: teamKeys.length,
              itemBuilder: (_, i) {
                final key = teamKeys[i];
                final list = groups[key]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          list.first.teamName ?? key,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final d in list)
                            _PickerItem(
                              driver: d,
                              selected: d.id == selectedId,
                              disabled: excludeIds.contains(d.id),
                              onTap: () => Navigator.pop(context, d),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerItem extends StatelessWidget {
  final Driver driver;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;
  const _PickerItem({
    required this.driver,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.35 : 1.0,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: DriverChip(driver: driver, selected: selected),
      ),
    );
  }
}
