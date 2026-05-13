import 'package:url_launcher/url_launcher.dart';

class LegalLinks {
  static final privacy = Uri.parse(
    'https://absorbing-muenster-0a7.notion.site/GridCall-Privacy-Policy-0092d80b8b344f19a917891dbc61bf9a',
  );
  static final terms = Uri.parse(
    'https://absorbing-muenster-0a7.notion.site/GridCall-Terms-of-Use-c03dc22dd514406db030141cfbd6b0a0',
  );

  const LegalLinks._();
}

Future<void> openExternalLink(Uri uri) async {
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    throw 'Could not open link: $uri';
  }
}
