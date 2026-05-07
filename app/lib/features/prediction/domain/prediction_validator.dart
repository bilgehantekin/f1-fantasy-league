String? validatePredictionSave({required String? leagueId}) {
  if (leagueId == null || leagueId.trim().isEmpty) {
    return 'League context is required to save a prediction';
  }
  return null;
}
