import 'dart:math';

/// Universal motivational messages in Uzbek
/// These messages do NOT reference time of day, morning, night, sleep, or sunrise
class MotivationalMessages {
  static const List<String> _messages = [
    "Harakat – muvaffaqiyatning kaliti.",
    "Bugungi kichik qadam ertangi katta natijani yaratadi.",
    "Ishonch – barcha yutuqlarning asosi.",
    "Sabr va mehnat – muvaffaqiyatga olib boradigan yo'l.",
    "Har bir qadam sizni maqsadingizga yaqinlashtiradi.",
    "O'z-o'ziga ishonch – eng kuchli qurol.",
    "Imkoniyatlar har doim mavjud, faqat ko'rish kerak.",
    "Muvaffaqiyat – kichik qadamlarning yig'indisi.",
    "Har bir kuni yangi boshlanishdir.",
    "O'z maqsadingizga ishonch bilan intiling.",
    "Qiyinchiliklar – kuch va tajriba beradi.",
    "Har bir muvaffaqiyat kichik boshlanishdan keladi.",
    "O'z-o'ziga sodiqlik – eng muhim fazilat.",
    "Har bir kuni o'z imkoniyatlarini ochadi.",
    "Ishonch va mehnat – muvaffaqiyatning kaliti.",
    "Har bir qadam sizni yanada kuchliroq qiladi.",
    "Maqsadga intilish – hayotning ma'nosi.",
    "Har bir kuni yangi imkoniyatlar beradi.",
    "O'z-o'ziga ishonch – muvaffaqiyatning asosi.",
    "Sabr va mehnat – barcha yutuqlarning kaliti.",
    "Har bir qadam sizni maqsadingizga yaqinlashtiradi.",
    "Ishonch – barcha yutuqlarning asosi.",
    "Har bir kuni yangi boshlanishdir.",
    "O'z maqsadingizga ishonch bilan intiling.",
    "Qiyinchiliklar – kuch va tajriba beradi.",
    "Har bir muvaffaqiyat kichik boshlanishdan keladi.",
    "O'z-o'ziga sodiqlik – eng muhim fazilat.",
    "Har bir kuni o'z imkoniyatlarini ochadi.",
    "Ishonch va mehnat – muvaffaqiyatning kaliti.",
    "Har bir qadam sizni yanada kuchliroq qiladi.",
    "Maqsadga intilish – hayotning ma'nosi.",
    "Har bir kuni yangi imkoniyatlar beradi.",
    "O'z-o'ziga ishonch – muvaffaqiyatning asosi.",
    "Sabr va mehnat – barcha yutuqlarning kaliti.",
    "Har bir qadam sizni maqsadingizga yaqinlashtiradi.",
    "Ishonch – barcha yutuqlarning asosi.",
    "Har bir kuni yangi boshlanishdir.",
    "O'z maqsadingizga ishonch bilan intiling.",
    "Qiyinchiliklar – kuch va tajriba beradi.",
    "Har bir muvaffaqiyat kichik boshlanishdan keladi.",
    "O'z-o'ziga sodiqlik – eng muhim fazilat.",
    "Har bir kuni o'z imkoniyatlarini ochadi.",
    "Ishonch va mehnat – muvaffaqiyatning kaliti.",
    "Har bir qadam sizni yanada kuchliroq qiladi.",
    "Maqsadga intilish – hayotning ma'nosi.",
    "Har bir kuni yangi imkoniyatlar beradi.",
    "O'z-o'ziga ishonch – muvaffaqiyatning asosi.",
    "Sabr va mehnat – barcha yutuqlarning kaliti.",
    "Har bir qadam sizni maqsadingizga yaqinlashtiradi.",
    "Ishonch – barcha yutuqlarning asosi.",
    "Har bir kuni yangi boshlanishdir.",
    "O'z maqsadingizga ishonch bilan intiling.",
    "Qiyinchiliklar – kuch va tajriba beradi.",
    "Har bir muvaffaqiyat kichik boshlanishdan keladi.",
    "O'z-o'ziga sodiqlik – eng muhim fazilat.",
    "Har bir kuni o'z imkoniyatlarini ochadi.",
    "Ishonch va mehnat – muvaffaqiyatning kaliti.",
    "Har bir qadam sizni yanada kuchliroq qiladi.",
    "Maqsadga intilish – hayotning ma'nosi.",
    "Har bir kuni yangi imkoniyatlar beradi.",
    "O'z-o'ziga ishonch – muvaffaqiyatning asosi.",
  ];

  /// Get a random motivational message
  /// This is fully random - no time-based logic, no repetition detection
  static String getRandomMessage() {
    final random = Random();
    final index = random.nextInt(_messages.length);
    return _messages[index];
  }
}
