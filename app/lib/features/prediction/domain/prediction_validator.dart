enum PredictionSaveError { missingLeagueContext }

PredictionSaveError? validatePredictionSave({required String? leagueId}) {
  if (leagueId == null || leagueId.trim().isEmpty) {
    return PredictionSaveError.missingLeagueContext;
  }
  return null;
}
