import 'package:url_launcher/url_launcher.dart';

class LegalLinks {
  static final privacy = Uri.parse('https://gridcall.app/privacy');
  static final terms = Uri.parse('https://gridcall.app/terms');

  const LegalLinks._();
}

Future<void> openExternalLink(Uri uri) async {
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    throw 'Could not open link: $uri';
  }
}
