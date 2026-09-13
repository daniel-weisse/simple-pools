// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Simple Pools';

  @override
  String get tagline => 'Ein klarer Weg aufs Podest.';

  @override
  String get home => 'Turniere';

  @override
  String get archive => 'Archiv';

  @override
  String get options => 'Einstellungen';

  @override
  String get newTournament => 'Neues Turnier starten';

  @override
  String get emptyTitle => 'Hier beginnt dein nächstes Turnier';

  @override
  String get emptyBody =>
      'Bring deine Fechter mit. Wir kümmern uns um Runden, Ranglisten und Direktausscheidung.';

  @override
  String get archiveEmpty => 'Keine archivierten Turniere';

  @override
  String get localOnly => 'Auf deinem Gerät · Offline bereit';

  @override
  String get rename => 'Umbenennen';

  @override
  String get archiveAction => 'Archivieren';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get delete => 'Endgültig löschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get name => 'Turniername';

  @override
  String get participants => 'Teilnehmer';

  @override
  String get participantName => 'Name des Fechters';

  @override
  String get hand => 'Hand';

  @override
  String get left => 'Links';

  @override
  String get right => 'Rechts';

  @override
  String get seed => 'Setzplatz (optional)';

  @override
  String get add => 'Fechter hinzufügen';

  @override
  String get poolSize => 'Maximale Rundengröße';

  @override
  String get create => 'Runden erstellen';

  @override
  String get setup => 'Turnier einrichten';

  @override
  String get setupHint =>
      'Füge 2-128 Fechter hinzu. Niedrigere Setzplätze stehen vorn. Die Gruppen werden ausgeglichen.';

  @override
  String get validation =>
      'Bitte prüfe die Eingaben. Namen sind erforderlich. Setzplätze müssen zwischen 1 und 9999 liegen.';

  @override
  String get minimum => 'Füge mindestens zwei Teilnehmer hinzu.';

  @override
  String get pools => 'Runden';

  @override
  String get rankings => 'Rangliste';

  @override
  String get bracket => 'Direktausscheidung';

  @override
  String get round => 'Runde';

  @override
  String get pool => 'Gruppe';

  @override
  String get bout => 'Gefecht';

  @override
  String get rest => 'Erholungspause vor diesem Gefecht';

  @override
  String get score => 'Ergebnis eintragen';

  @override
  String get scoreHint =>
      'Unterschiedliche ganze Zahlen von 0 bis 999 eingeben.';

  @override
  String get hitsFor => 'Gesetzte Treffer';

  @override
  String get hitsAgainst => 'Erhaltene Treffer';

  @override
  String get difference => 'Trefferdifferenz';

  @override
  String get wins => 'Siege';

  @override
  String get rank => 'Platz';

  @override
  String get fencer => 'Fechter';

  @override
  String get pending => 'Ausstehend';

  @override
  String get winner => 'Sieger';

  @override
  String get inProgress => 'Läuft';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get exportPdf => 'PDF exportieren';

  @override
  String get printPdf => 'Drucken / Vorschau';

  @override
  String get nextRound => 'Weitere Vorrunde';

  @override
  String get startBracket => 'Direktausscheidung starten';

  @override
  String get endPools => 'Mit Rundenrangliste beenden';

  @override
  String get resolveTies => 'Gleichstände auflösen';

  @override
  String get tiesHint =>
      'Lege die Reihenfolge jeder punktgleichen Gruppe fest oder lose sie aus. Setzplätze wurden bereits berücksichtigt.';

  @override
  String get randomize => 'Auslosen';

  @override
  String get applyOrder => 'Reihenfolge übernehmen';

  @override
  String get bracketSize => 'Größe der Direktausscheidung';

  @override
  String get bracketHint =>
      'Die Bestplatzierten erhalten Freilose. Bei einem kleineren Tableau scheiden die Letztplatzierten aus.';

  @override
  String get thirdPlace => 'Gefecht um Platz drei hinzufügen';

  @override
  String get bronze => 'Platz drei';

  @override
  String get bye => 'Freilos';

  @override
  String get finalRanking => 'Endplatzierung';

  @override
  String get correctionTitle => 'Abhängige Ergebnisse aktualisieren?';

  @override
  String get correctionBody =>
      'Die folgenden späteren Ergebnisse werden gelöscht, weil sich ihre Teilnehmer ändern. Betroffene Platzierungen und der Sieger bleiben bis zum Abschluss der Gefechte offen.';

  @override
  String get clearResults => 'Ergebnisse löschen und speichern';

  @override
  String get language => 'Sprache';

  @override
  String get backup => 'Sicherung & Übertragung';

  @override
  String get exportJson => 'Alle Turniere exportieren';

  @override
  String get importJson => 'Sicherung importieren';

  @override
  String get backupHint =>
      'Mit einer JSON-Sicherung kannst du deinen Verlauf wiederherstellen oder übertragen. Browserdaten können vom Browser oder in dessen Einstellungen gelöscht werden.';

  @override
  String get deleteAll => 'Gesamten Verlauf löschen';

  @override
  String get deleteAllHint =>
      'Alle Turniere auf diesem Gerät werden endgültig gelöscht.';

  @override
  String get deleteHint => 'Dieses Turnier wird endgültig gelöscht.';

  @override
  String get importTitle => 'Turniere importieren?';

  @override
  String get importHint =>
      'Die geprüfte Sicherung wird mit deinem Verlauf zusammengeführt. Turniere mit gleicher ID werden ersetzt.';

  @override
  String get success => 'Auf diesem Gerät gespeichert';

  @override
  String get error => 'Ein Fehler ist aufgetreten';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get close => 'Schließen';

  @override
  String get archiveHint =>
      'Turniere werden 30 Tage nach ihrer Erstellung automatisch archiviert.';

  @override
  String get roundPending =>
      'Warte auf die vorherige Runde und die Auflösung von Gleichständen.';

  @override
  String get finishHint =>
      'Dieses Turnier mit der kombinierten Rundenrangliste beenden?';

  @override
  String get menu => 'Menü';

  @override
  String get noBracket =>
      'Schließe die Runden ab und löse Gleichstände auf, um die Direktausscheidung zu starten.';

  @override
  String get poolProgress =>
      'Trage die Ergebnisse aller Gefechte für die Rangliste ein.';

  @override
  String get tied => 'Gleichstand';

  @override
  String get about => 'Für die Planche gemacht';

  @override
  String get aboutBody =>
      'Eine Offline-Turnierverwaltung für Fechter. Ohne Konto. Ohne Server.';

  @override
  String get count => 'Fechter';

  @override
  String get moveUp => 'Nach oben';

  @override
  String get moveDown => 'Nach unten';

  @override
  String get remove => 'Entfernen';

  @override
  String get ready => 'Bereit';

  @override
  String get exportTournament => 'Turniersicherung exportieren';

  @override
  String get importTournament => 'Turnier importieren';

  @override
  String get importTournamentHint =>
      'Dieses Turnier wird deinem Verlauf hinzugefügt. Ein vorhandenes Turnier mit derselben ID wird ersetzt.';

  @override
  String get singleTournamentRequired =>
      'Wähle eine Sicherung mit genau einem Turnier aus.';

  @override
  String get start => 'Starten';

  @override
  String get scoreCleared => 'Zu löschende spätere Ergebnisse';

  @override
  String get importCount => 'Turniere in der Sicherung';

  @override
  String get poolLimit => 'Es werden höchstens 20 Vorrunden unterstützt.';

  @override
  String get back => 'Zurück';

  @override
  String get storageError =>
      'Lokaler Speicher konnte nicht geöffnet werden. Erlaube die Speicherung von Websitedaten und versuche es erneut.';

  @override
  String get noResults => 'Noch keine Ergebnisse';

  @override
  String get result => 'Ergebnis';

  @override
  String get seedColumn => 'Setzplatz';

  @override
  String get finalResults => 'Endergebnisse';

  @override
  String eliminatedCount(int count) {
    return '$count Teilnehmer scheiden sofort aus';
  }
}
