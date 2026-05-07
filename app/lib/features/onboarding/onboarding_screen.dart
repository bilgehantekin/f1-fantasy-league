import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_messages.dart';
import '../../core/notifications.dart';
import '../../core/theme.dart';
import '../calendar/calendar_controller.dart';
import '../profile/profile_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _username = TextEditingController();
  bool _remindersEnabled = true;
  bool _onlyMissing = true;
  int _hoursBeforeLock = 1;
  bool _busy = false;
  String? _error;
  String? _usernameError;
  bool _seededUsername = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final username = _username.text.trim();
    final validationError = _validateUsername(username);
    if (validationError != null) {
      setState(() {
        _usernameError = validationError;
        _error = null;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _usernameError = null;
    });
    try {
      final reminderPrefs = ReminderPreferences(
        enabled: _remindersEnabled,
        hoursBeforeLock: _hoursBeforeLock,
        onlyMissingPrediction: _onlyMissing,
      );
      if (_remindersEnabled) {
        final granted = await NotificationService.instance.requestPermissions();
        if (!granted) {
          await reminderPrefs.copyWith(enabled: false).save();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Bildirim izni verilmedi. Hatırlatmaları daha sonra ayarlardan açabilirsin.',
                ),
              ),
            );
          }
        } else {
          await reminderPrefs.save();
        }
      } else {
        await reminderPrefs.save();
      }

      await completeOnboarding(username: username);

      ref.invalidate(profileProvider);
      final races = await ref.read(racesProvider.future);
      await NotificationService.instance.scheduleForRaces(races);

      if (!mounted) return;
      context.go('/calendar');
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateUsername(String username) {
    if (username.isEmpty) return 'Kullanıcı adı gerekli.';
    if (username.length < 3) return 'En az 3 karakter gir.';
    if (username.length > 16) return 'En fazla 16 karakter gir.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).asData?.value;
    if (!_seededUsername &&
        _username.text.isEmpty &&
        profile?.username.isNotEmpty == true) {
      _seededUsername = true;
      _username.text = profile!.username;
    }

    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            const Text(
              'GRIDCALL',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Arkadaşlarınla özel lig kur, yarıştan önce tahminini yap, sonuçlar açıklanınca puanını karşılaştır.',
              style: TextStyle(fontSize: 15, color: Color(0xB3FFFFFF)),
            ),
            const SizedBox(height: 28),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StepTitle(number: '01', label: 'NASIL OYNANIR?'),
                  const SizedBox(height: 12),
                  Text(
                    'Her yarış haftası basit: ligine katıl, tahminini süre bitmeden kaydet, sonuçlar açıklanınca sıralamadaki yerini gör.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _HowItWorksCard(
                    number: '1',
                    icon: Icons.groups_outlined,
                    title: 'Lig kur veya davet koduyla katıl',
                    text:
                        'Arkadaşlarınla aynı ligde yarış. Kendi ligini oluştur ya da gelen kodla hemen katıl.',
                  ),
                  const SizedBox(height: 12),
                  const _HowItWorksCard(
                    number: '2',
                    icon: Icons.edit_road_outlined,
                    title: 'Süre bitmeden tahminini yap',
                    text:
                        'Podyum, pole, DNF ve güvenlik aracı gibi tahminlerini seç.',
                  ),
                  const SizedBox(height: 12),
                  const _HowItWorksCard(
                    number: '3',
                    icon: Icons.leaderboard_outlined,
                    title: 'Sonuçlar gelince puanını gör',
                    text:
                        'Skorların hesaplanır, lig sıralaması güncellenir ve haftalık paylaşım kartın hazır olur.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StepTitle(number: '02', label: 'PROFİL'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _username,
                    onChanged: (_) {
                      if (_usernameError != null) {
                        setState(() => _usernameError = null);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı adı',
                      helperText: 'Bu ad liglerde arkadaşlarına görünür.',
                    ).copyWith(errorText: _usernameError),
                    maxLength: 16,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StepTitle(number: '03', label: 'HATIRLATICILAR'),
                  const SizedBox(height: 8),
                  Text(
                    'Tahmin yapmayı unutmaman için yarış tahminleri kapanmadan önce bildirim gönderebiliriz.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _remindersEnabled,
                    onChanged: (v) => setState(() => _remindersEnabled = v),
                    title: const Text('Tahmin hatırlatmaları'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_remindersEnabled) ...[
                    const SizedBox(height: 4),
                    Text(
                      'HATIRLATMA ZAMANI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1 saat')),
                        ButtonSegment(value: 6, label: Text('6 saat')),
                      ],
                      selected: {_hoursBeforeLock},
                      onSelectionChanged: (v) =>
                          setState(() => _hoursBeforeLock = v.first),
                    ),
                    CheckboxListTile(
                      value: _onlyMissing,
                      onChanged: (v) =>
                          setState(() => _onlyMissing = v ?? true),
                      title: const Text('Sadece tahmin yapmadıysam'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                  Text(
                    'Bu tercihi daha sonra bildirim ayarlarından değiştirebilirsin.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.liveRed),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _finish,
              child: Text(_busy ? 'HAZIRLANIYOR...' : 'BAŞLA'),
            ),
            const SizedBox(height: 20),
            Text(
              'GridCall, Formula 1, FIA, takım veya sürücülerle bağlantısı olmayan, '
              'bağımsız bir hayran uygulamasıdır. Tüm marka ve logolar ilgili sahiplerine aittir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.surfaceHi),
    ),
    child: child,
  );
}

class _HowItWorksCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String text;

  const _HowItWorksCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.f1Red.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 21, color: AppColors.f1Red),
            ),
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.f1Red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.64),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StepTitle extends StatelessWidget {
  final String number;
  final String label;

  const _StepTitle({required this.number, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.f1Red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    ],
  );
}
