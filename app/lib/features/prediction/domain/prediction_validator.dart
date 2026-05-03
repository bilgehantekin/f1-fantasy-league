String? validatePredictionSave({required String? leagueId}) {
  if (leagueId == null || leagueId.trim().isEmpty) {
    return 'Tahmin kaydetmek için lig bağlamı gerekli';
  }
  return null;
}
