import 'package:flutter/widgets.dart';

/// All user-facing texts in one place.
///
/// English is the default. Norwegian is used when the device language is
/// Norwegian (nb, nn or no). Look texts up via [AppStrings.of].
class AppStrings {
  const AppStrings._(this._no);

  final bool _no;

  static const english = AppStrings._(false);
  static const norwegian = AppStrings._(true);

  static bool isNorwegian(Locale locale) =>
      const {'nb', 'nn', 'no'}.contains(locale.languageCode);

  static AppStrings of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    return locale != null && isNorwegian(locale) ? norwegian : english;
  }

  String _t(String en, String no) => _no ? no : en;

  // -----------------------------
  // General
  // -----------------------------

  String get appName => 'Karos Strength Training';
  String get cancel => _t('Cancel', 'Avbryt');
  String get delete => _t('Delete', 'Slett');
  String get save => _t('Save', 'Lagre');
  String get add => _t('Add', 'Legg til');
  String get kg => 'kg';
  String get repsLabel => _t('reps', 'reps');

  String setLabel(int setIndex) => _t('Set $setIndex', 'Sett $setIndex');

  String setLine(int setIndex, String weightKg, int reps) => _t(
        'Set $setIndex: $weightKg kg x $reps reps',
        'Sett $setIndex: $weightKg kg x $reps reps',
      );

  // -----------------------------
  // Exercise list
  // -----------------------------

  String get info => 'Info';
  String get noSessionsYet => _t('No sessions yet.', 'Ingen økter ennå.');
  String get noExercisesYet => _t('No exercises yet.', 'Ingen øvelser ennå.');
  String get newExercise => _t('New exercise', 'Ny øvelse');

  String get deleteExerciseTitle => _t('Delete exercise', 'Slett øvelse');
  String deleteExerciseConfirm(String name) => _t(
        'Are you sure you want to delete "$name"?\n\nAll sessions for this exercise will also be removed.',
        'Er du sikker på at du vil slette «$name»?\n\nAlle økter for denne øvelsen blir også slettet.',
      );

  String get editExerciseTitle => _t('Edit exercise', 'Rediger øvelse');
  String get newExerciseTitle => _t('New exercise', 'Ny øvelse');
  String get exerciseNameLabel => _t('Exercise name', 'Navn på øvelse');

  String lastLine(String dateStr, int daysSince) => switch (daysSince) {
        0 => _t('Last: $dateStr (today)', 'Sist: $dateStr (i dag)'),
        1 => _t('Last: $dateStr (yesterday)', 'Sist: $dateStr (i går)'),
        _ => _t(
            'Last: $dateStr ($daysSince days ago)',
            'Sist: $dateStr ($daysSince dager siden)',
          ),
      };

  String setsLine(String s1, String s2, String s3) =>
      'S1: $s1 | S2: $s2 | S3: $s3';

  // -----------------------------
  // Exercise detail / sessions
  // -----------------------------

  String get fullHistory => _t('Full history', 'Hele historikken');

  String get noPreviousSessionForExercise => _t(
        'No previous session for this exercise yet.',
        'Ingen tidligere økt for denne øvelsen ennå.',
      );

  String lastSessionLabel(String date) =>
      _t('Last session: $date', 'Siste økt: $date');

  String totalVolumeLabel(String kg) =>
      _t('Total volume: $kg kg', 'Totalt volum: $kg kg');

  String editingBanner(String date) => _t(
        'You are editing a previous session from $date.\nSaving will overwrite this session.',
        'Du redigerer en tidligere økt fra $date.\nNår du lagrer, blir denne økten overskrevet.',
      );

  String get sessionSettings => _t('Session settings', 'Innstillinger for økten');
  String get restTimeMinutes => _t('Rest time (minutes)', 'Pause (minutter)');
  String get minutes => _t('Minutes', 'Minutter');
  String get useRestTimer => _t('Use rest timer', 'Bruk pausetimer');

  String restTimerTitle(int minutes) =>
      _t('Rest timer ($minutes min)', 'Pausetimer ($minutes min)');

  String timerRemainingSeconds(int seconds) =>
      _t('$seconds sec', '$seconds sek');
  String timerReadyForSet(int setIndex) =>
      _t('Ready for set $setIndex', 'Klar for sett $setIndex');
  String get timerAllSetsDone => _t('All sets done', 'Alle sett er ferdige');
  String get startRest => _t('Start rest', 'Start pause');

  String get allSetsCompletedRememberSave => _t(
        'All sets completed. Remember to save the session.',
        'Alle sett er fullført. Husk å lagre økten.',
      );

  String get sessionUpdated => _t('Session updated', 'Økten er oppdatert');
  String get sessionSaved =>
      _t('Exercise completed and saved', 'Øvelsen er fullført og lagret');

  String get saveChanges => _t('Save changes', 'Lagre endringer');
  String get saveSession => _t('Save session', 'Lagre økten');
  String get discard => _t('Discard', 'Forkast');

  String get discardSessionTitle => _t('Discard session', 'Forkast økten');
  String get discardSessionBody => _t(
        'Do you want to discard this session without saving?',
        'Vil du forkaste denne økten uten å lagre?',
      );

  // -----------------------------
  // Exercise history
  // -----------------------------

  String exerciseHistoryTitle(String exerciseName) =>
      _t('History - $exerciseName', 'Historikk - $exerciseName');

  String get noSessionsForExercise => _t(
        'No sessions recorded yet for this exercise.',
        'Ingen økter registrert for denne øvelsen ennå.',
      );

  String get noSets => _t('No sets', 'Ingen sett');

  String sessionTitle(String date, String kg) => '$date – $kg kg';

  String get deleteSessionTitle => _t('Delete session', 'Slett økt');
  String deleteSessionBody(String date, String kg) => _t(
        'Do you want to delete this session?\n\nDate: $date\nTotal volume: $kg kg',
        'Vil du slette denne økten?\n\nDato: $date\nTotalt volum: $kg kg',
      );

  // -----------------------------
  // Info page
  // -----------------------------

  String get infoBody => _t(
        'Log exercises and sessions, see your latest session per exercise, and export/import backups when needed.',
        'Logg øvelser og økter, se siste økt for hver øvelse, og eksporter eller importer backup ved behov.',
      );

  String get swipeHint => _t(
        'Swipe right to edit. Swipe left to delete.',
        'Sveip til høyre for å redigere. Sveip til venstre for å slette.',
      );

  String get backupSectionTitle => 'Backup';
  String get exportData => _t('Export data', 'Eksporter data');
  String get importData => _t('Import data', 'Importer data');
  String get dataImported => _t('Data imported', 'Data er importert');
  String get importFailed => _t(
        'No valid backup was found. Nothing was changed.',
        'Fant ingen gyldig backup. Ingenting ble endret.',
      );
  String get backupExported => _t('Backup exported', 'Backup er eksportert');
  String get backupShareText =>
      _t('Exported training data backup.', 'Backup av treningsdata.');

  String get linksTitle => _t('Links', 'Lenker');
  String get sendLetter => _t('Send me a letter', 'Send meg et brev');
  String get website => _t('Website', 'Nettside');
  String get privacyPolicy => _t('Privacy policy', 'Personvern');
  String get support => _t('Support', 'Brukerstøtte');
  String get moreApps => _t('More from BullPeak', 'Mer fra BullPeak');
  String get couldNotOpenEmail =>
      _t('Could not open email client', 'Kunne ikke åpne e-postprogrammet');
  String get couldNotOpenLink =>
      _t('Could not open link', 'Kunne ikke åpne lenken');

  String get tipTitle => _t('Support the developer', 'Støtt utvikleren');
  String donateNok(int amount) => _t('Donate NOK $amount', 'Gi $amount kr');
  String get thankYouForSupport =>
      _t('Thank you for the support!', 'Takk for støtten!');
  String get tipNotAvailable => _t(
        'Donations are not available right now.',
        'Gaver er ikke tilgjengelige akkurat nå.',
      );
}
