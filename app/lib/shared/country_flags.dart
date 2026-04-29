// Race name → country flag emoji eşlemesi.

const _flags = <String, String>{
  'Australian Grand Prix': '🇦🇺',
  'Chinese Grand Prix': '🇨🇳',
  'Japanese Grand Prix': '🇯🇵',
  'Bahrain Grand Prix': '🇧🇭',
  'Saudi Arabian Grand Prix': '🇸🇦',
  'Miami Grand Prix': '🇺🇸',
  'Emilia Romagna Grand Prix': '🇮🇹',
  'Monaco Grand Prix': '🇲🇨',
  'Canadian Grand Prix': '🇨🇦',
  'Spanish Grand Prix': '🇪🇸',
  'Austrian Grand Prix': '🇦🇹',
  'British Grand Prix': '🇬🇧',
  'Hungarian Grand Prix': '🇭🇺',
  'Belgian Grand Prix': '🇧🇪',
  'Dutch Grand Prix': '🇳🇱',
  'Italian Grand Prix': '🇮🇹',
  'Azerbaijan Grand Prix': '🇦🇿',
  'Singapore Grand Prix': '🇸🇬',
  'United States Grand Prix': '🇺🇸',
  'Mexico City Grand Prix': '🇲🇽',
  'Sao Paulo Grand Prix': '🇧🇷',
  'São Paulo Grand Prix': '🇧🇷',
  'Las Vegas Grand Prix': '🇺🇸',
  'Qatar Grand Prix': '🇶🇦',
  'Abu Dhabi Grand Prix': '🇦🇪',
};

String flagFor(String raceName) => _flags[raceName] ?? '🏁';
