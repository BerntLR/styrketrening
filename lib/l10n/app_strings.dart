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

  String get appName => 'Karos Strength';
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

  String get sessionSettings =>
      _t('Session settings', 'Innstillinger for økten');
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
  String get restOverTitle => _t('Rest is over', 'Pausen er ferdig');
  String get startRest => _t('Start rest', 'Start pause');

  String get allSetsCompletedRememberSave => _t(
    'All sets completed. Remember to save the session.',
    'Alle sett er fullført. Husk å lagre økten.',
  );

  String invalidSet(int setIndex) => _t(
    'Set $setIndex: weight and reps must be numbers.',
    'Sett $setIndex: vekt og reps må være tall.',
  );

  String get noSetsEntered => _t(
    'Fill in at least one set before saving.',
    'Fyll inn minst ett sett før du lagrer.',
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
    'Log your strength training: add exercises, fill in weight and reps for up to three sets, and use the rest timer between sets. Your last session is shown at the top, so you know what to beat.',
    'Logg styrketreningen: legg til øvelser, fyll inn vekt og reps for opptil tre sett, og bruk pausetimeren mellom settene. Siste økt vises øverst, så du vet hva du skal slå.',
  );

  String get swipeHint => _t(
    'Swipe right to edit. Swipe left to delete.',
    'Sveip til høyre for å redigere. Sveip til venstre for å slette.',
  );

  // Karo standard texts (see _karo_standard/04_tekster.md).
  String get backupTitle => _t('Backup', 'Sikkerhetskopi');
  String get exportData => _t('Export data', 'Eksporter data');
  String get importData => _t('Import data', 'Importer data');
  String get importConfirm => _t(
    'This replaces all data in the app. Continue?',
    'Dette erstatter alle data i appen. Fortsette?',
  );
  String get importFailed => _t(
    'The file could not be read. Nothing was changed.',
    'Fila kunne ikke leses. Ingenting ble endret.',
  );
  String get importDone => _t('Data imported.', 'Data importert.');
  String get backupExported =>
      _t('Backup saved.', 'Sikkerhetskopien er lagret.');
  String get edit => _t('Edit', 'Rediger');

  String get couldNotExport => _t(
    'The backup could not be saved.',
    'Sikkerhetskopien kunne ikke lagres.',
  );
  String get restTimerHint => _t(
    'The rest timer alerts you when the rest is over, also when the screen is locked.',
    'Pausetimeren varsler når pausen er ferdig, også når skjermen er låst.',
  );

  String get linksTitle => _t('Links', 'Lenker');
  String get sendLetter => _t('Send me a letter', 'Send meg et brev');
  String get website => _t('Website', 'Nettside');
  String get privacyPolicy => _t('Privacy policy', 'Personvern');
  String get support => _t('Support', 'Brukerstøtte');
  String get moreApps => _t('More from BullPeak', 'Mer fra BullPeak');
  String get couldNotOpenLink =>
      _t('Could not open the link.', 'Kunne ikke åpne lenken.');
  String get couldNotOpenEmail =>
      _t('Could not open e-mail.', 'Kunne ikke åpne e-post.');

  String get tipTitle => _t('Support the developer', 'Støtt utvikleren');
  String donateNok(int amount) => _t('Donate NOK $amount', 'Doner $amount kr');
  String get thankYouForSupport =>
      _t('Thank you for your support!', 'Tusen takk for støtten!');
  String get tipNotAvailable => _t(
    'Tips are not available right now.',
    'Tips er ikke tilgjengelig akkurat nå.',
  );
}
