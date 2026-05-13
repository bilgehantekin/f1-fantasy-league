import 'package:flutter/widgets.dart';

/// Locale-aware uppercase. Turkish has dotted-İ / dotless-I rules; applying
/// them to English labels yields wrong output ("PREVİOUS RACE"). Pass a
/// [BuildContext] (or set [turkish] explicitly) so we only swap i→İ / ı→I
/// when the locale is actually Turkish.
String turkishUpper(String value, {BuildContext? context, bool? turkish}) {
  final isTurkish =
      turkish ?? (context != null &&
          Localizations.localeOf(context).languageCode == 'tr');
  if (!isTurkish) return value.toUpperCase();
  return value.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
}
