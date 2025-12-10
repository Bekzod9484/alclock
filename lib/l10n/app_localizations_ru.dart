// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'AlClock';

  @override
  String get settings => 'Настройки';

  @override
  String get alarm => 'Будильник';

  @override
  String get statistics => 'Статистика';

  @override
  String get addAlarm => 'Добавить будильник';

  @override
  String get editAlarm => 'Редактировать будильник';

  @override
  String get alarmSound => 'Звук будильника';

  @override
  String get snooze => 'Отложить';

  @override
  String minutes(int count) {
    return '$count минут';
  }

  @override
  String get gradualWake => 'Постепенное пробуждение';

  @override
  String get vibration => 'Вибрация';

  @override
  String get volume => 'Громкость';

  @override
  String get autoMode => 'Автоматический режим';

  @override
  String get automaticallyDetectSleep => 'Автоматически определять сон';

  @override
  String get manualSleepStart => 'Ручное начало сна';

  @override
  String get setSleepTimeManually => 'Установить время сна вручную';

  @override
  String get manualWakeTime => 'Ручное время пробуждения';

  @override
  String get setWakeTimeManually => 'Установить время пробуждения вручную';

  @override
  String get dailyMotivationalTips => 'Ежедневные мотивационные советы';

  @override
  String get emojiMode => 'Режим эмодзи';

  @override
  String get name => 'Имя';

  @override
  String get userProfile => 'Профиль пользователя';

  @override
  String get alarmSettings => 'Настройки будильника';

  @override
  String get sleepTrackingSettings => 'Настройки отслеживания сна';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get uzbek => 'O\'zbek';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'English';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get repeat => 'Повтор';

  @override
  String get monday => 'Понедельник';

  @override
  String get tuesday => 'Вторник';

  @override
  String get wednesday => 'Среда';

  @override
  String get thursday => 'Четверг';

  @override
  String get friday => 'Пятница';

  @override
  String get saturday => 'Суббота';

  @override
  String get sunday => 'Воскресенье';

  @override
  String get wakeUp => 'Пробуждение';

  @override
  String get alarmRinging => 'Будильник';

  @override
  String get stop => 'Остановить';

  @override
  String get snoozeButton => 'Через 5 минут';

  @override
  String get weeklySleep => 'Еженедельный сон';

  @override
  String get weeklySleepDuration => 'Недельная продолжительность сна';

  @override
  String get avgSleepDuration => 'Средняя недельная продолжительность сна';

  @override
  String get avgBedtime => 'Среднее недельное время отхода ко сну';

  @override
  String get avgWakeTime => 'Среднее недельное время пробуждения';

  @override
  String get bestDay => 'Лучший день';

  @override
  String get worstDay => 'Худший день';

  @override
  String get tapBarToSeeDetails => 'Нажмите на столбец, чтобы увидеть детали';

  @override
  String get addManualEntry => 'Добавить вручную';

  @override
  String get manualSleepEntry => 'Ручной ввод сна';

  @override
  String get date => 'Дата';

  @override
  String get sleepStart => 'Начало сна';

  @override
  String get wakeTime => 'Время пробуждения';

  @override
  String get selectDate => 'Выберите дату';

  @override
  String get selectTime => 'Выберите время';

  @override
  String get notSet => 'Не установлено';

  @override
  String get wentToSleep => 'Ушел спать';

  @override
  String get fellAsleep => 'Ушел спать';

  @override
  String get quality => 'Качество';

  @override
  String get close => 'Закрыть';

  @override
  String get sleepRecordSaved => 'Запись сна сохранена';

  @override
  String get error => 'Ошибка';

  @override
  String get errorSaving => 'Ошибка при сохранении';

  @override
  String get pleaseSelectBothTimes => 'Пожалуйста, выберите оба времени';

  @override
  String get pleaseSelectWakeTime => 'Пожалуйста, выберите время пробуждения';

  @override
  String get pleaseSelectSleepStart => 'Пожалуйста, выберите время начала сна';

  @override
  String get goodMorning => 'Доброе утро';

  @override
  String get goodAfternoon => 'Добрый день';

  @override
  String get goodEvening => 'Добрый вечер';

  @override
  String todayIsAFreshStart(String name) {
    return '$name, сегодня новый старт.';
  }

  @override
  String get noAlarms => 'Нет будильников';

  @override
  String get addYourFirstAlarm => 'Добавьте первый будильник';

  @override
  String get enabled => 'Включено';

  @override
  String get disabled => 'Выключено';

  @override
  String get once => 'Один раз';

  @override
  String get everyDay => 'Каждый день';

  @override
  String get score => 'Оценка';

  @override
  String get editEstimatedSleepTime => 'Изменить предполагаемое время сна';

  @override
  String get sleepAdvice => 'Совет по сну';

  @override
  String get sleepAdviceVeryShort1 =>
      'Сон очень короткий. Это опасно для здоровья. Попробуйте лечь спать раньше сегодня.';

  @override
  String get sleepAdviceVeryShort2 =>
      'Организм не успевает восстановиться. Стремитесь к 7–9 часам сна.';

  @override
  String get sleepAdviceShort1 =>
      'Сон недостаточен. Постарайтесь сделать привычкой спать хотя бы 7 часов.';

  @override
  String get sleepAdviceShort2 => 'Недостаток сна снижает концентрацию.';

  @override
  String get sleepAdviceModerate1 =>
      'Хорошо, но немного мало. Идеальный сон — 7–9 часов.';

  @override
  String get sleepAdviceModerate2 => 'Попробуйте лечь спать раньше сегодня.';

  @override
  String get sleepAdviceGood1 => 'Отлично! Здоровый уровень сна.';

  @override
  String get sleepAdviceGood2 => 'Норма сна — 7–9 часов — у вас всё отлично!';

  @override
  String get sleepAdviceLong1 =>
      'Сон немного слишком долгий. Может дать лишнюю нагрузку на организм.';

  @override
  String get sleepAdviceLong2 => 'Рекомендуется больше активности.';

  @override
  String get sleepAdviceVeryLong1 =>
      'Слишком много сна. Это может быть признаком усталости или стресса.';

  @override
  String get sleepAdviceVeryLong2 =>
      'Постарайтесь держать сон около 7–9 часов.';

  @override
  String get weeklySleepAnalysis => 'Еженедельный анализ сна';

  @override
  String get motivationNote => 'Напоминание (необязательно)';

  @override
  String get motivationNoteHint => 'Введите напоминание...';
}
