import 'package:flutter/material.dart';

class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);

  static const Locale _enUS = Locale('en', 'US');

  static Locale _resolvedLocale(Locale locale) {
    return _enUS;
  }

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(_resolvedLocale(locale));
  }

  String get info => 'Info';
  String get history => 'Training history';
  String get exportData => 'Export data';
  String get importData => 'Import data';

  String get dataImported => 'Data imported';
  String get backupExported => 'Backup exported';

  String get backupReminderTitle => 'Backup reminder';
  String get notNow => 'Not now';
  String get backupNow => 'Backup now';

  String backupNoBackupMessage() =>
      'You have training data but no backup yet.\n\nDo you want to export a backup now?';

  String backupDaysMessage(int days) =>
      'It has been $days days since your last backup.\n\nDo you want to export a backup now?';

  String get noSessionsYet => 'No sessions yet.';
  String get noExercisesYet => 'No exercises yet.';
  String get newExercise => 'New exercise';

  String get edit => 'Edit';
  String get delete => 'Delete';

  String get deleteExerciseTitle => 'Delete exercise';
  String deleteExerciseConfirm(String name) =>
      'Are you sure you want to delete "$name"?\n\nAll sessions for this exercise will also be removed.';

  String get cancel => 'Cancel';

  String get editExerciseTitle => 'Edit exercise';
  String get newExerciseTitle => 'New exercise';
  String get exerciseNameLabel => 'Exercise name';

  String get save => 'Save';
  String get add => 'Add';

  String lastLine(String dateStr, int daysSince) =>
      'Last: $dateStr ($daysSince days ago)';

  String setsLine(String s1, String s2, String s3, {required bool ready}) {
    final extra = ready ? '\nReady to increase weight' : '';
    return 'S1: $s1 | S2: $s2 | S3: $s3$extra';
  }

  String get appName => 'Karos Strength Training';

  String get support => 'Support';

  String get couldNotOpenEmail => 'Could not open email client';

  String get infoBody =>
      'Log exercises and sessions, see your latest session per exercise, and export/import backups when needed.\n\n'
      'Use History for the full overview.';

  String get thankYouForSupport => 'Thank you for the support!';
  String get tipNotAvailable => 'Donations are not available right now.';
  String get tipTitle => 'Support the developer';
  String get tipCta9kr => 'Donate NOK 9';
  String get backupSectionTitle => 'Backup';

  String showingSessions(int visible, int total) =>
      'Showing $visible of $total sessions';

  String historyCardTitle(String exerciseName, String date) =>
      '$exerciseName \u2013 last: $date';

  // -----------------------------
  // Exercise detail / sessions
  // -----------------------------

  String get fullHistory => 'Full history';

  String get noPreviousSessionForExercise =>
      'No previous session for this exercise yet.';

  String lastSessionLabel(String date) => 'Last session: $date';

  String totalVolumeLabel(String kg) => 'Total volume: $kg kg';

  String setLine(int setIndex, String weightKg, String reps) =>
      'Set $setIndex: $weightKg kg x $reps reps';

  String editingBanner(String date) =>
      'You are editing a previous session from $date.\nSaving will overwrite this session.';

  String get progressionHint =>
      'Last time you hit 12 reps on all 3 sets.\nYou can increase the weight for this exercise.';

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

  String get kg => 'kg';
  String get repsLabel => 'reps';

  String exerciseHistoryTitle(String exerciseName) => 'History - $exerciseName';
}
