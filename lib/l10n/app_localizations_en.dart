// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Simple Pools';

  @override
  String get tagline => 'A clear path to the podium.';

  @override
  String get home => 'Tournaments';

  @override
  String get archive => 'Archive';

  @override
  String get options => 'Options';

  @override
  String get newTournament => 'Start new tournament';

  @override
  String get emptyTitle => 'Your next tournament starts here';

  @override
  String get emptyBody =>
      'Bring your fencers. We’ll take care of the pools, rankings, and bracket.';

  @override
  String get archiveEmpty => 'No archived tournaments';

  @override
  String get localOnly => 'On your device · Ready offline';

  @override
  String get rename => 'Rename';

  @override
  String get archiveAction => 'Archive';

  @override
  String get restore => 'Restore';

  @override
  String get delete => 'Delete permanently';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get name => 'Tournament name';

  @override
  String get participants => 'Participants';

  @override
  String get participantName => 'Fencer’s name';

  @override
  String get hand => 'Hand';

  @override
  String get left => 'Left';

  @override
  String get right => 'Right';

  @override
  String get seed => 'Pre-seed (optional)';

  @override
  String get add => 'Add fencer';

  @override
  String get poolSize => 'Maximum pool size';

  @override
  String get create => 'Create pools';

  @override
  String get setup => 'Set up your tournament';

  @override
  String get setupHint =>
      'Add 2-128 fencers. Lower pre-seeds rank first. Pools are balanced automatically.';

  @override
  String get validation =>
      'Check the fields. Names are required. Seeds must be 1-9999.';

  @override
  String get minimum => 'Add at least two participants.';

  @override
  String get pools => 'Pools';

  @override
  String get rankings => 'Rankings';

  @override
  String get bracket => 'Knockout';

  @override
  String get round => 'Round';

  @override
  String get pool => 'Pool';

  @override
  String get bout => 'Bout';

  @override
  String get rest => 'Rest break before this bout';

  @override
  String get score => 'Enter result';

  @override
  String get scoreHint => 'Enter different whole numbers from 0 to 999.';

  @override
  String get hitsFor => 'Hits for';

  @override
  String get hitsAgainst => 'Hits against';

  @override
  String get difference => 'Difference';

  @override
  String get wins => 'Wins';

  @override
  String get rank => 'Rank';

  @override
  String get fencer => 'Fencer';

  @override
  String get pending => 'Pending';

  @override
  String get winner => 'Winner';

  @override
  String get inProgress => 'In progress';

  @override
  String get completed => 'Completed';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get printPdf => 'Print / preview';

  @override
  String get nextRound => 'Another pool round';

  @override
  String get startBracket => 'Start knockout';

  @override
  String get endPools => 'Finish with pool ranking';

  @override
  String get resolveTies => 'Resolve ties';

  @override
  String get tiesHint =>
      'Choose an order for each tied group, or shuffle it. Pre-seeds have already been applied.';

  @override
  String get randomize => 'Shuffle';

  @override
  String get applyOrder => 'Use this order';

  @override
  String get bracketSize => 'Knockout size';

  @override
  String get bracketHint =>
      'Top seeds receive byes in an incomplete bracket. Choosing a smaller bracket eliminates the lowest ranks.';

  @override
  String get thirdPlace => 'Add third-place bout';

  @override
  String get bronze => 'Third place';

  @override
  String get bye => 'Bye';

  @override
  String get finalRanking => 'Final standings';

  @override
  String get correctionTitle => 'Update dependent results?';

  @override
  String get correctionBody =>
      'The following later results will be cleared because their participants change. Affected rankings and the winner will be pending until those bouts are completed.';

  @override
  String get clearResults => 'Clear results and save';

  @override
  String get language => 'Language';

  @override
  String get backup => 'Backup & transfer';

  @override
  String get exportJson => 'Export all tournaments';

  @override
  String get importJson => 'Import a backup';

  @override
  String get backupHint =>
      'Keep a JSON backup to restore or transfer your history. Browser data can be cleared by your browser or its settings.';

  @override
  String get deleteAll => 'Delete all history';

  @override
  String get deleteAllHint =>
      'This permanently deletes all tournaments on this device.';

  @override
  String get deleteHint => 'This tournament will be permanently deleted.';

  @override
  String get importTitle => 'Import tournaments?';

  @override
  String get importHint =>
      'The validated backup will be merged into your history. Tournaments with matching IDs will be replaced.';

  @override
  String get success => 'Saved on this device';

  @override
  String get error => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get archiveHint =>
      'Tournaments are automatically archived 30 days after creation.';

  @override
  String get roundPending =>
      'Waiting for the previous round and tie resolution.';

  @override
  String get finishHint =>
      'Finish this tournament using the combined pool ranking?';

  @override
  String get menu => 'Menu';

  @override
  String get noBracket =>
      'Complete the pools and resolve ties to start a knockout.';

  @override
  String get poolProgress => 'Enter each bout result to build the ranking.';

  @override
  String get tied => 'Tied';

  @override
  String get about => 'Made for the piste';

  @override
  String get aboutBody =>
      'An offline fencing tournament organizer. No account. No server.';

  @override
  String get count => 'fencers';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get remove => 'Remove';

  @override
  String get ready => 'Ready';

  @override
  String get exportTournament => 'Export tournament backup';

  @override
  String get importTournament => 'Import tournament';

  @override
  String get importTournamentHint =>
      'This tournament will be added to your history. An existing tournament with the same ID will be replaced.';

  @override
  String get singleTournamentRequired =>
      'Choose a backup containing exactly one tournament.';

  @override
  String get start => 'Start';

  @override
  String get scoreCleared => 'Later results to clear';

  @override
  String get importCount => 'Tournaments in backup';

  @override
  String get poolLimit => 'A maximum of 20 pool rounds is supported.';

  @override
  String get back => 'Back';

  @override
  String get storageError =>
      'Could not open local storage. Check that site storage is enabled, then retry.';

  @override
  String get noResults => 'No results yet';

  @override
  String get result => 'Result';

  @override
  String get seedColumn => 'Pre-seed';

  @override
  String get finalResults => 'Final results';

  @override
  String eliminatedCount(int count) {
    return '$count participants eliminated immediately';
  }
}
