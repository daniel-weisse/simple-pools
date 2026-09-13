import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Simple Pools'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'A clear path to the podium.'**
  String get tagline;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get home;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @newTournament.
  ///
  /// In en, this message translates to:
  /// **'Start new tournament'**
  String get newTournament;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your next tournament starts here'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Bring your fencers. We’ll take care of the pools, rankings, and bracket.'**
  String get emptyBody;

  /// No description provided for @archiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No archived tournaments'**
  String get archiveEmpty;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'On your device · Ready offline'**
  String get localOnly;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @archiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveAction;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Tournament name'**
  String get name;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @participantName.
  ///
  /// In en, this message translates to:
  /// **'Fencer’s name'**
  String get participantName;

  /// No description provided for @hand.
  ///
  /// In en, this message translates to:
  /// **'Hand'**
  String get hand;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @seed.
  ///
  /// In en, this message translates to:
  /// **'Pre-seed (optional)'**
  String get seed;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add fencer'**
  String get add;

  /// No description provided for @poolSize.
  ///
  /// In en, this message translates to:
  /// **'Maximum pool size'**
  String get poolSize;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create pools'**
  String get create;

  /// No description provided for @setup.
  ///
  /// In en, this message translates to:
  /// **'Set up your tournament'**
  String get setup;

  /// No description provided for @setupHint.
  ///
  /// In en, this message translates to:
  /// **'Add 2-128 fencers. Lower pre-seeds rank first. Pools are balanced automatically.'**
  String get setupHint;

  /// No description provided for @validation.
  ///
  /// In en, this message translates to:
  /// **'Check the fields. Names are required. Seeds must be 1-9999.'**
  String get validation;

  /// No description provided for @minimum.
  ///
  /// In en, this message translates to:
  /// **'Add at least two participants.'**
  String get minimum;

  /// No description provided for @pools.
  ///
  /// In en, this message translates to:
  /// **'Pools'**
  String get pools;

  /// No description provided for @rankings.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get rankings;

  /// No description provided for @bracket.
  ///
  /// In en, this message translates to:
  /// **'Knockout'**
  String get bracket;

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get round;

  /// No description provided for @pool.
  ///
  /// In en, this message translates to:
  /// **'Pool'**
  String get pool;

  /// No description provided for @bout.
  ///
  /// In en, this message translates to:
  /// **'Bout'**
  String get bout;

  /// No description provided for @rest.
  ///
  /// In en, this message translates to:
  /// **'Rest break before this bout'**
  String get rest;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Enter result'**
  String get score;

  /// No description provided for @scoreHint.
  ///
  /// In en, this message translates to:
  /// **'Enter different whole numbers from 0 to 999.'**
  String get scoreHint;

  /// No description provided for @hitsFor.
  ///
  /// In en, this message translates to:
  /// **'Hits for'**
  String get hitsFor;

  /// No description provided for @hitsAgainst.
  ///
  /// In en, this message translates to:
  /// **'Hits against'**
  String get hitsAgainst;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @fencer.
  ///
  /// In en, this message translates to:
  /// **'Fencer'**
  String get fencer;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @printPdf.
  ///
  /// In en, this message translates to:
  /// **'Print / preview'**
  String get printPdf;

  /// No description provided for @nextRound.
  ///
  /// In en, this message translates to:
  /// **'Another pool round'**
  String get nextRound;

  /// No description provided for @startBracket.
  ///
  /// In en, this message translates to:
  /// **'Start knockout'**
  String get startBracket;

  /// No description provided for @endPools.
  ///
  /// In en, this message translates to:
  /// **'Finish with pool ranking'**
  String get endPools;

  /// No description provided for @resolveTies.
  ///
  /// In en, this message translates to:
  /// **'Resolve ties'**
  String get resolveTies;

  /// No description provided for @tiesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an order for each tied group, or shuffle it. Pre-seeds have already been applied.'**
  String get tiesHint;

  /// No description provided for @randomize.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get randomize;

  /// No description provided for @applyOrder.
  ///
  /// In en, this message translates to:
  /// **'Use this order'**
  String get applyOrder;

  /// No description provided for @bracketSize.
  ///
  /// In en, this message translates to:
  /// **'Knockout size'**
  String get bracketSize;

  /// No description provided for @bracketHint.
  ///
  /// In en, this message translates to:
  /// **'Top seeds receive byes in an incomplete bracket. Choosing a smaller bracket eliminates the lowest ranks.'**
  String get bracketHint;

  /// No description provided for @thirdPlace.
  ///
  /// In en, this message translates to:
  /// **'Add third-place bout'**
  String get thirdPlace;

  /// No description provided for @bronze.
  ///
  /// In en, this message translates to:
  /// **'Third place'**
  String get bronze;

  /// No description provided for @bye.
  ///
  /// In en, this message translates to:
  /// **'Bye'**
  String get bye;

  /// No description provided for @finalRanking.
  ///
  /// In en, this message translates to:
  /// **'Final standings'**
  String get finalRanking;

  /// No description provided for @correctionTitle.
  ///
  /// In en, this message translates to:
  /// **'Update dependent results?'**
  String get correctionTitle;

  /// No description provided for @correctionBody.
  ///
  /// In en, this message translates to:
  /// **'The following later results will be cleared because their participants change. Affected rankings and the winner will be pending until those bouts are completed.'**
  String get correctionBody;

  /// No description provided for @clearResults.
  ///
  /// In en, this message translates to:
  /// **'Clear results and save'**
  String get clearResults;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup & transfer'**
  String get backup;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'Export all tournaments'**
  String get exportJson;

  /// No description provided for @importJson.
  ///
  /// In en, this message translates to:
  /// **'Import a backup'**
  String get importJson;

  /// No description provided for @backupHint.
  ///
  /// In en, this message translates to:
  /// **'Keep a JSON backup to restore or transfer your history. Browser data can be cleared by your browser or its settings.'**
  String get backupHint;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all history'**
  String get deleteAll;

  /// No description provided for @deleteAllHint.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes all tournaments on this device.'**
  String get deleteAllHint;

  /// No description provided for @deleteHint.
  ///
  /// In en, this message translates to:
  /// **'This tournament will be permanently deleted.'**
  String get deleteHint;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import tournaments?'**
  String get importTitle;

  /// No description provided for @importHint.
  ///
  /// In en, this message translates to:
  /// **'The validated backup will be merged into your history. Tournaments with matching IDs will be replaced.'**
  String get importHint;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @archiveHint.
  ///
  /// In en, this message translates to:
  /// **'Tournaments are automatically archived 30 days after creation.'**
  String get archiveHint;

  /// No description provided for @roundPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the previous round and tie resolution.'**
  String get roundPending;

  /// No description provided for @finishHint.
  ///
  /// In en, this message translates to:
  /// **'Finish this tournament using the combined pool ranking?'**
  String get finishHint;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @noBracket.
  ///
  /// In en, this message translates to:
  /// **'Complete the pools and resolve ties to start a knockout.'**
  String get noBracket;

  /// No description provided for @poolProgress.
  ///
  /// In en, this message translates to:
  /// **'Enter each bout result to build the ranking.'**
  String get poolProgress;

  /// No description provided for @tied.
  ///
  /// In en, this message translates to:
  /// **'Tied'**
  String get tied;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'Made for the piste'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'An offline fencing tournament organizer. No account. No server.'**
  String get aboutBody;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'fencers'**
  String get count;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @exportTournament.
  ///
  /// In en, this message translates to:
  /// **'Export tournament backup'**
  String get exportTournament;

  /// No description provided for @importTournament.
  ///
  /// In en, this message translates to:
  /// **'Import tournament'**
  String get importTournament;

  /// No description provided for @importTournamentHint.
  ///
  /// In en, this message translates to:
  /// **'This tournament will be added to your history. An existing tournament with the same ID will be replaced.'**
  String get importTournamentHint;

  /// No description provided for @singleTournamentRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a backup containing exactly one tournament.'**
  String get singleTournamentRequired;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @scoreCleared.
  ///
  /// In en, this message translates to:
  /// **'Later results to clear'**
  String get scoreCleared;

  /// No description provided for @importCount.
  ///
  /// In en, this message translates to:
  /// **'Tournaments in backup'**
  String get importCount;

  /// No description provided for @poolLimit.
  ///
  /// In en, this message translates to:
  /// **'A maximum of 20 pool rounds is supported.'**
  String get poolLimit;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @storageError.
  ///
  /// In en, this message translates to:
  /// **'Could not open local storage. Check that site storage is enabled, then retry.'**
  String get storageError;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get noResults;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @seedColumn.
  ///
  /// In en, this message translates to:
  /// **'Pre-seed'**
  String get seedColumn;

  /// No description provided for @finalResults.
  ///
  /// In en, this message translates to:
  /// **'Final results'**
  String get finalResults;

  /// No description provided for @eliminatedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} participants eliminated immediately'**
  String eliminatedCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
