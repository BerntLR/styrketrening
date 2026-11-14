import 'package:flutter/widgets.dart';

/// All user-facing texts in one place.
///
/// The app is English-only for now. Look texts up via [AppStrings.of] so a
/// second language can be added later without touching the pages.
class AppStrings {
  const AppStrings._();

  static AppStrings of(BuildContext context) => const AppStrings._();

  // -----------------------------
  // General
  // -----------------------------

  String get appName => 'Karos Strength Training';
  String get cancel => 'Cancel';
  String get delete => 'Delete';
  String get save => 'Save';
  String get add => 'Add';
  String get kg => 'kg';
  String get repsLabel => 'reps';

  String setLabel(int setIndex) => 'Set $setIndex';

  String setLine(int setIndex, String weightKg, int reps) =>
      'Set $setIndex: $weightKg kg x $reps reps';

  // -----------------------------
  // Exercise list
  // -----------------------------

  String get info => 'Info';
  String get noSessionsYet => 'No sessions yet.';
  String get noExercisesYet => 'No exercises yet.';
  String get newExercise => 'New exercise';

  String get deleteExerciseTitle => 'Delete exercise';
  String deleteExerciseConfirm(String name) =>
      'Are you sure you want to delete "$name"?\n\nAll sessions for this exercise will also be removed.';

  String get editExerciseTitle => 'Edit exercise';
  String get newExerciseTitle => 'New exercise';
  String get exerciseNameLabel => 'Exercise name';

  String lastLine(String dateStr, int daysSince) =>
      'Last: $dateStr ($daysSince days ago)';

  String setsLine(String s1, String s2, String s3) =>
      'S1: $s1 | S2: $s2 | S3: $s3';

  // -----------------------------
  // Exercise detail / sessions
  // -----------------------------

  String get fullHistory => 'Full history';

  String get noPreviousSessionForExercise =>
      'No previous session for this exercise yet.';

  String lastSessionLabel(String date) => 'Last session: $date';

  String totalVolumeLabel(String kg) => 'Total volume: $kg kg';

  String editingBanner(String date) =>
      'You are editing a previous session from $date.\nSaving will overwrite this session.';

  String get sessionSettings => 'Session settings';
  String get restTimeMinutes => 'Rest time (minutes)';
  String get minutes => 'Minutes';
  String get useRestTimer => 'Use rest timer';

  String restTimerTitle(int minutes) => 'Rest timer ($minutes min)';

  String timerRemainingSeconds(int seconds) => '$seconds sec';
  String timerReadyForSet(int setIndex) => 'Ready for set $setIndex';
  String get timerAllSetsDone => 'All sets done';
  String get startRest => 'Start rest';

  String get allSetsCompletedRememberSave =>
      'All sets completed. Remember to save the session.';

  String get sessionUpdated => 'Session updated';
  String get sessionSaved => 'Exercise completed and saved';

  String get saveChanges => 'Save changes';
  String get saveSession => 'Save session';
  String get discard => 'Discard';

  String get discardSessionTitle => 'Discard session';
  String get discardSessionBody =>
      'Do you want to discard this session without saving?';

  // -----------------------------
  // Exercise history
  // -----------------------------

  String exerciseHistoryTitle(String exerciseName) => 'History - $exerciseName';

  String get noSessionsForExercise =>
      'No sessions recorded yet for this exercise.';

  String get noSets => 'No sets';

  String sessionTitle(String date, String kg) => '$date – $kg kg';

  String get deleteSessionTitle => 'Delete session';
  String deleteSessionBody(String date, String kg) =>
      'Do you want to delete this session?\n\nDate: $date\nTotal volume: $kg kg';

  // -----------------------------
  // Info page
  // -----------------------------

  String get infoBody =>
      'Log exercises and sessions, see your latest session per exercise, and export/import backups when needed.';

  String get swipeHint => 'Swipe right to edit. Swipe left to delete.';

  String get backupSectionTitle => 'Backup';
  String get exportData => 'Export data';
  String get importData => 'Import data';
  String get dataImported => 'Data imported';
  String get backupExported => 'Backup exported';
  String get backupShareText => 'Exported training data backup.';

  String get linksTitle => 'Links';
  String get sendLetter => 'Send me a letter';
  String get website => 'Website';
  String get privacyPolicy => 'Privacy policy';
  String get support => 'Support';
  String get moreApps => 'More from BullPeak';
  String get couldNotOpenEmail => 'Could not open email client';
  String get couldNotOpenLink => 'Could not open link';

  String get tipTitle => 'Support the developer';
  String donateNok(int amount) => 'Donate NOK $amount';
  String get thankYouForSupport => 'Thank you for the support!';
  String get tipNotAvailable => 'Donations are not available right now.';
}
