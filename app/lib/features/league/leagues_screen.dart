import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'league_controller.dart';

class LeaguesScreen extends ConsumerWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagues = ref.watch(myLeaguesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liglerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Lige katıl',
            onPressed: () => _joinDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni lig',
            onPressed: () => _createDialog(context, ref),
          ),
        ],
      ),
      body: leagues.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
                child: Text('Henüz bir ligin yok. + ile birini oluştur.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final l = list[i];
              return Card(
                child: ListTile(
                  title: Text(l.name),
                  subtitle: Text('Kod: ${l.inviteCode}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/leagues/${l.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yeni lig'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Lig adı'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Oluştur')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      try {
        final id = await createLeague(ctrl.text.trim());
        ref.invalidate(myLeaguesProvider);
        if (context.mounted) context.push('/leagues/$id');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  Future<void> _joinDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lige katıl'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: '6 karakter davet kodu'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Katıl')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().length == 6) {
      try {
        final id = await joinLeagueByCode(ctrl.text.trim());
        ref.invalidate(myLeaguesProvider);
        if (context.mounted) context.push('/leagues/$id');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }
}
