import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

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
    Locale('en'),
    Locale('ru'),
    Locale('uz')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'AlClock'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @alarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarm;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @addAlarm.
  ///
  /// In en, this message translates to:
  /// **'Add Alarm'**
  String get addAlarm;

  /// No description provided for @editAlarm.
  ///
  /// In en, this message translates to:
  /// **'Edit Alarm'**
  String get editAlarm;

  /// No description provided for @alarmSound.
  ///
  /// In en, this message translates to:
  /// **'Alarm Sound'**
  String get alarmSound;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String minutes(int count);

  /// No description provided for @gradualWake.
  ///
  /// In en, this message translates to:
  /// **'Gradual Wake'**
  String get gradualWake;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @autoMode.
  ///
  /// In en, this message translates to:
  /// **'Auto Mode'**
  String get autoMode;

  /// No description provided for @automaticallyDetectSleep.
  ///
  /// In en, this message translates to:
  /// **'Automatically detect sleep'**
  String get automaticallyDetectSleep;

  /// No description provided for @manualSleepStart.
  ///
  /// In en, this message translates to:
  /// **'Manual Sleep Start'**
  String get manualSleepStart;

  /// No description provided for @setSleepTimeManually.
  ///
  /// In en, this message translates to:
  /// **'Set sleep time manually'**
  String get setSleepTimeManually;

  /// No description provided for @manualWakeTime.
  ///
  /// In en, this message translates to:
  /// **'Manual Wake Time'**
  String get manualWakeTime;

  /// No description provided for @setWakeTimeManually.
  ///
  /// In en, this message translates to:
  /// **'Set wake time manually'**
  String get setWakeTimeManually;

  /// No description provided for @dailyMotivationalTips.
  ///
  /// In en, this message translates to:
  /// **'Daily Motivational Tips'**
  String get dailyMotivationalTips;

  /// No description provided for @emojiMode.
  ///
  /// In en, this message translates to:
  /// **'Emoji Mode'**
  String get emojiMode;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @alarmSettings.
  ///
  /// In en, this message translates to:
  /// **'Alarm Settings'**
  String get alarmSettings;

  /// No description provided for @sleepTrackingSettings.
  ///
  /// In en, this message translates to:
  /// **'Sleep Tracking Settings'**
  String get sleepTrackingSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @uzbek.
  ///
  /// In en, this message translates to:
  /// **'O\'zbek'**
  String get uzbek;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @wakeUp.
  ///
  /// In en, this message translates to:
  /// **'Wake up'**
  String get wakeUp;

  /// No description provided for @alarmRinging.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarmRinging;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @snoozeButton.
  ///
  /// In en, this message translates to:
  /// **'5 minutes later'**
  String get snoozeButton;

  /// No description provided for @weeklySleep.
  ///
  /// In en, this message translates to:
  /// **'Weekly Sleep'**
  String get weeklySleep;

  /// No description provided for @weeklySleepDuration.
  ///
  /// In en, this message translates to:
  /// **'Weekly sleep duration'**
  String get weeklySleepDuration;

  /// No description provided for @avgSleepDuration.
  ///
  /// In en, this message translates to:
  /// **'Weekly average sleep duration'**
  String get avgSleepDuration;

  /// No description provided for @avgBedtime.
  ///
  /// In en, this message translates to:
  /// **'Weekly average sleep time'**
  String get avgBedtime;

  /// No description provided for @avgWakeTime.
  ///
  /// In en, this message translates to:
  /// **'Weekly average wake time'**
  String get avgWakeTime;

  /// No description provided for @bestDay.
  ///
  /// In en, this message translates to:
  /// **'Best Day'**
  String get bestDay;

  /// No description provided for @worstDay.
  ///
  /// In en, this message translates to:
  /// **'Worst Day'**
  String get worstDay;

  /// No description provided for @tapBarToSeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap a bar to see details'**
  String get tapBarToSeeDetails;

  /// No description provided for @addManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Manual Entry'**
  String get addManualEntry;

  /// No description provided for @manualSleepEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Sleep Entry'**
  String get manualSleepEntry;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @sleepStart.
  ///
  /// In en, this message translates to:
  /// **'Sleep Start'**
  String get sleepStart;

  /// No description provided for @wakeTime.
  ///
  /// In en, this message translates to:
  /// **'Wake Time'**
  String get wakeTime;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @wentToSleep.
  ///
  /// In en, this message translates to:
  /// **'Went to sleep'**
  String get wentToSleep;

  /// No description provided for @fellAsleep.
  ///
  /// In en, this message translates to:
  /// **'Fell asleep'**
  String get fellAsleep;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @sleepRecordSaved.
  ///
  /// In en, this message translates to:
  /// **'Sleep record saved'**
  String get sleepRecordSaved;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving'**
  String get errorSaving;

  /// No description provided for @pleaseSelectBothTimes.
  ///
  /// In en, this message translates to:
  /// **'Please select both sleep start and wake times'**
  String get pleaseSelectBothTimes;

  /// No description provided for @pleaseSelectWakeTime.
  ///
  /// In en, this message translates to:
  /// **'Please select wake time'**
  String get pleaseSelectWakeTime;

  /// No description provided for @pleaseSelectSleepStart.
  ///
  /// In en, this message translates to:
  /// **'Please select sleep start time'**
  String get pleaseSelectSleepStart;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @todayIsAFreshStart.
  ///
  /// In en, this message translates to:
  /// **'{name}, today\'s a fresh start.'**
  String todayIsAFreshStart(String name);

  /// No description provided for @noAlarms.
  ///
  /// In en, this message translates to:
  /// **'No alarms'**
  String get noAlarms;

  /// No description provided for @addYourFirstAlarm.
  ///
  /// In en, this message translates to:
  /// **'Add your first alarm'**
  String get addYourFirstAlarm;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @once.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get once;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @editEstimatedSleepTime.
  ///
  /// In en, this message translates to:
  /// **'Edit estimated sleep time'**
  String get editEstimatedSleepTime;

  /// No description provided for @sleepAdvice.
  ///
  /// In en, this message translates to:
  /// **'Sleep Advice'**
  String get sleepAdvice;

  /// No description provided for @sleepAdviceVeryShort1.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration is very short. This is harmful to your health. Try to sleep earlier today.'**
  String get sleepAdviceVeryShort1;

  /// No description provided for @sleepAdviceVeryShort2.
  ///
  /// In en, this message translates to:
  /// **'The body doesn\'t have time to recover. Aim for 7–9 hours of sleep.'**
  String get sleepAdviceVeryShort2;

  /// No description provided for @sleepAdviceShort1.
  ///
  /// In en, this message translates to:
  /// **'Sleep is insufficient. Try to make at least 7 hours of sleep a habit.'**
  String get sleepAdviceShort1;

  /// No description provided for @sleepAdviceShort2.
  ///
  /// In en, this message translates to:
  /// **'Lack of sleep reduces concentration.'**
  String get sleepAdviceShort2;

  /// No description provided for @sleepAdviceModerate1.
  ///
  /// In en, this message translates to:
  /// **'Good, but a bit short. Ideal sleep is 7–9 hours.'**
  String get sleepAdviceModerate1;

  /// No description provided for @sleepAdviceModerate2.
  ///
  /// In en, this message translates to:
  /// **'Try to sleep earlier today.'**
  String get sleepAdviceModerate2;

  /// No description provided for @sleepAdviceGood1.
  ///
  /// In en, this message translates to:
  /// **'Great! Healthy sleep level.'**
  String get sleepAdviceGood1;

  /// No description provided for @sleepAdviceGood2.
  ///
  /// In en, this message translates to:
  /// **'Sleep norm is 7–9 hours — you\'re doing great!'**
  String get sleepAdviceGood2;

  /// No description provided for @sleepAdviceLong1.
  ///
  /// In en, this message translates to:
  /// **'Sleep is a bit too long. May put extra strain on the body.'**
  String get sleepAdviceLong1;

  /// No description provided for @sleepAdviceLong2.
  ///
  /// In en, this message translates to:
  /// **'More activity is recommended.'**
  String get sleepAdviceLong2;

  /// No description provided for @sleepAdviceVeryLong1.
  ///
  /// In en, this message translates to:
  /// **'Too much sleep. This may be a sign of fatigue or stress.'**
  String get sleepAdviceVeryLong1;

  /// No description provided for @sleepAdviceVeryLong2.
  ///
  /// In en, this message translates to:
  /// **'Try to keep sleep around 7–9 hours.'**
  String get sleepAdviceVeryLong2;

  /// No description provided for @weeklySleepAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Weekly Sleep Analysis'**
  String get weeklySleepAnalysis;

  /// No description provided for @motivationNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get motivationNote;

  /// No description provided for @motivationNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a note...'**
  String get motivationNoteHint;
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
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
