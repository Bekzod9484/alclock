// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AlClock';

  @override
  String get settings => 'Settings';

  @override
  String get alarm => 'Alarm';

  @override
  String get statistics => 'Statistics';

  @override
  String get addAlarm => 'Add Alarm';

  @override
  String get editAlarm => 'Edit Alarm';

  @override
  String get alarmSound => 'Alarm Sound';

  @override
  String get snooze => 'Snooze';

  @override
  String minutes(int count) {
    return '$count minutes';
  }

  @override
  String get gradualWake => 'Gradual Wake';

  @override
  String get vibration => 'Vibration';

  @override
  String get volume => 'Volume';

  @override
  String get autoMode => 'Auto Mode';

  @override
  String get automaticallyDetectSleep => 'Automatically detect sleep';

  @override
  String get manualSleepStart => 'Manual Sleep Start';

  @override
  String get setSleepTimeManually => 'Set sleep time manually';

  @override
  String get manualWakeTime => 'Manual Wake Time';

  @override
  String get setWakeTimeManually => 'Set wake time manually';

  @override
  String get dailyMotivationalTips => 'Daily Motivational Tips';

  @override
  String get emojiMode => 'Emoji Mode';

  @override
  String get name => 'Name';

  @override
  String get userProfile => 'User Profile';

  @override
  String get alarmSettings => 'Alarm Settings';

  @override
  String get sleepTrackingSettings => 'Sleep Tracking Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get uzbek => 'O\'zbek';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'English';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get repeat => 'Repeat';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get wakeUp => 'Wake up';

  @override
  String get alarmRinging => 'Alarm';

  @override
  String get stop => 'Stop';

  @override
  String get snoozeButton => '5 minutes later';

  @override
  String get weeklySleep => 'Weekly Sleep';

  @override
  String get weeklySleepDuration => 'Weekly sleep duration';

  @override
  String get avgSleepDuration => 'Weekly average sleep duration';

  @override
  String get avgBedtime => 'Weekly average sleep time';

  @override
  String get avgWakeTime => 'Weekly average wake time';

  @override
  String get bestDay => 'Best Day';

  @override
  String get worstDay => 'Worst Day';

  @override
  String get tapBarToSeeDetails => 'Tap a bar to see details';

  @override
  String get addManualEntry => 'Add Manual Entry';

  @override
  String get manualSleepEntry => 'Manual Sleep Entry';

  @override
  String get date => 'Date';

  @override
  String get sleepStart => 'Sleep Start';

  @override
  String get wakeTime => 'Wake Time';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get notSet => 'Not set';

  @override
  String get wentToSleep => 'Went to sleep';

  @override
  String get fellAsleep => 'Fell asleep';

  @override
  String get quality => 'Quality';

  @override
  String get close => 'Close';

  @override
  String get sleepRecordSaved => 'Sleep record saved';

  @override
  String get error => 'Error';

  @override
  String get errorSaving => 'Error saving';

  @override
  String get pleaseSelectBothTimes =>
      'Please select both sleep start and wake times';

  @override
  String get pleaseSelectWakeTime => 'Please select wake time';

  @override
  String get pleaseSelectSleepStart => 'Please select sleep start time';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String todayIsAFreshStart(String name) {
    return '$name, today\'s a fresh start.';
  }

  @override
  String get noAlarms => 'No alarms';

  @override
  String get addYourFirstAlarm => 'Add your first alarm';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get once => 'Once';

  @override
  String get everyDay => 'Every day';

  @override
  String get score => 'Score';

  @override
  String get editEstimatedSleepTime => 'Edit estimated sleep time';

  @override
  String get sleepAdvice => 'Sleep Advice';

  @override
  String get sleepAdviceVeryShort1 =>
      'Sleep duration is very short. This is harmful to your health. Try to sleep earlier today.';

  @override
  String get sleepAdviceVeryShort2 =>
      'The body doesn\'t have time to recover. Aim for 7–9 hours of sleep.';

  @override
  String get sleepAdviceShort1 =>
      'Sleep is insufficient. Try to make at least 7 hours of sleep a habit.';

  @override
  String get sleepAdviceShort2 => 'Lack of sleep reduces concentration.';

  @override
  String get sleepAdviceModerate1 =>
      'Good, but a bit short. Ideal sleep is 7–9 hours.';

  @override
  String get sleepAdviceModerate2 => 'Try to sleep earlier today.';

  @override
  String get sleepAdviceGood1 => 'Great! Healthy sleep level.';

  @override
  String get sleepAdviceGood2 =>
      'Sleep norm is 7–9 hours — you\'re doing great!';

  @override
  String get sleepAdviceLong1 =>
      'Sleep is a bit too long. May put extra strain on the body.';

  @override
  String get sleepAdviceLong2 => 'More activity is recommended.';

  @override
  String get sleepAdviceVeryLong1 =>
      'Too much sleep. This may be a sign of fatigue or stress.';

  @override
  String get sleepAdviceVeryLong2 => 'Try to keep sleep around 7–9 hours.';

  @override
  String get weeklySleepAnalysis => 'Weekly Sleep Analysis';

  @override
  String get motivationNote => 'Note (optional)';

  @override
  String get motivationNoteHint => 'Enter a note...';
}
