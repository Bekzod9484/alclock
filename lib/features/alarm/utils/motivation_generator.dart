import 'dart:math';

/// Generates random motivational messages for alarm notes
class MotivationGenerator {
  static const List<String> _motivations = [
    "Uyqudan oldin qat'iy qaror — tongda g'olib natija.",
    "Nafsga qarshi g'alaba — ertalabdan boshlanadi.",
    "Turing, hayot sizni kutmaydi.",
    "O'zingizni yengmasangiz, hech kim yenga olmaydi.",
    "Har tong — yangi jang, sizda kuch yetarli.",
    "Bugungi intizom — ertangi muvaffaqiyat.",
    "Yotoq qulay, lekin maqsad bundan ustun.",
    "Erta turuvchi — bir kun oldinda bo'ladi.",
    "Bu budilnik — sizning kuchingiz sinovi.",
    "Hech qanday bahona qabul qilinmaydi.",
  ];

  /// Returns a random motivational message
  static String randomMotivation() {
    final random = Random();
    final shuffled = List<String>.from(_motivations)..shuffle(random);
    return shuffled.first;
  }
}





