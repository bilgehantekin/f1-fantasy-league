import 'package:url_launcher/url_launcher.dart';

class LegalLinks {
  static final privacy = Uri.parse('https://pitwall.app/privacy');
  static final terms = Uri.parse('https://pitwall.app/terms');

  const LegalLinks._();
}

Future<void> openExternalLink(Uri uri) async {
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    throw 'Bağlantı açılamadı: $uri';
  }
}
