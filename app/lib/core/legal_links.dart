import 'package:url_launcher/url_launcher.dart';

class LegalLinks {
  static final privacy = Uri.parse(
    'https://github.com/bilgehantekin/f1-fantasy-league/blob/main/docs/privacy-policy.md',
  );
  static final terms = Uri.parse(
    'https://github.com/bilgehantekin/f1-fantasy-league/blob/main/docs/terms-of-service.md',
  );

  const LegalLinks._();
}

Future<void> openExternalLink(Uri uri) async {
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    throw 'Could not open link: $uri';
  }
}
