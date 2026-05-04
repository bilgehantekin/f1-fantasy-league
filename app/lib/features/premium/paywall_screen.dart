import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_messages.dart';
import '../../core/navigation.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../profile/profile_controller.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _toggle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // DEV: gerçek RevenueCat / Stripe yerine mock RPC.
      // Production'da: purchases_flutter ile Purchases.purchasePackage(...) çağrılır.
      await supabase.rpc('dev_toggle_premium');
      ref.invalidate(profileProvider);
      if (mounted) safeBack(context);
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).asData?.value;
    final isPremium = profile?.isPremium ?? false;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('GRIDCALL PREMIUM')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.f1Red,
                  AppColors.f1Red.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(
                  'GridCall Premium',
                  style: tt.displayMedium?.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tahminlerini bir üst seviyeye taşı',
                  style: tt.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Feature(
            icon: '📊',
            title: 'Detaylı Sezon Analitiği',
            description:
                'Yarış başına trend grafiği, kategori bazlı derinlik analizi',
          ),
          _Feature(
            icon: '🏎️',
            title: 'Tüm Sürücü İstatistikleri',
            description: 'Her sürücü için isabet oranı, takıma göre kıyaslama',
          ),
          _Feature(
            icon: '🎨',
            title: 'Özel Lig Rozetleri',
            description:
                'Liginde kendine özel rozet tasarla ve haftalık ödüller belirle',
          ),
          _Feature(
            icon: '⚡',
            title: 'Erken Joker Erişimi',
            description: 'Joker sorularını herkesten 24 saat önce gör',
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.liveRed),
              ),
            ),
          if (isPremium)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lockGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.lockGreen.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.lockGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Premium üyeliğin aktif',
                      style: tt.titleMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            FilledButton(
              onPressed: _busy ? null : _toggle,
              child: Text(_busy ? '...' : 'PREMIUM\'A YÜKSELT (DEV MOCK)'),
            ),
          const SizedBox(height: 12),
          if (isPremium)
            OutlinedButton(
              onPressed: _busy ? null : _toggle,
              child: const Text('Premium\'u kapat (dev)'),
            ),
          const SizedBox(height: 16),
          Text(
            'Bu dev modda mock toggle. Production\'da RevenueCat (iOS/Android) veya Stripe (web) entegre edilecek.',
            style: tt.bodySmall?.copyWith(color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.titleMedium),
                Text(
                  description,
                  style: tt.bodySmall?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
