import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuoteService {
  static const String _quotesAssetPath = 'assets/quotes/islamic_quotes.json';
  static const String _shownQuotesKey = 'shown_quotes';
  static const String _lastQuoteDateKey = 'last_quote_date';
  
  List<String> _allQuotes = [];
  List<String> _shownQuotes = [];
  DateTime? _lastQuoteDate;

  Future<void> initialize() async {
    await _loadQuotes();
    await _loadShownQuotes();
  }

  Future<void> _loadQuotes() async {
    try {
      final String jsonString = await rootBundle.loadString(_quotesAssetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _allQuotes = List<String>.from(jsonData['quotes'] ?? []);
    } catch (e) {
      print('Error loading quotes: $e');
      // Fallback quotes (from requirements)
      _allQuotes = [
        "Har bir tong — yangi imkoniyat.",
        "Uyg'onish — Robbing seni yana bir kun bilan siyladi.",
        "Erta turish — baraka kaliti.",
        "Tonggi vaqt — duolar qabul bo'ladigan on.",
        "Yaxshi uyqu — kuchli imon bilan yashashga yordam beradi.",
      ];
    }
  }

  Future<void> _loadShownQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    _shownQuotes = prefs.getStringList(_shownQuotesKey) ?? [];
    
    final lastDateString = prefs.getString(_lastQuoteDateKey);
    if (lastDateString != null) {
      _lastQuoteDate = DateTime.parse(lastDateString);
    }
  }

  Future<void> _saveShownQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_shownQuotesKey, _shownQuotes);
    await prefs.setString(_lastQuoteDateKey, DateTime.now().toIso8601String());
  }

  bool _isNewDay() {
    if (_lastQuoteDate == null) return true;
    final now = DateTime.now();
    final lastDate = _lastQuoteDate!;
    return now.year != lastDate.year ||
        now.month != lastDate.month ||
        now.day != lastDate.day;
  }

  Future<String> getDailyQuote() async {
    await initialize();
    
    // If it's a new day, reset shown quotes if all have been shown
    if (_isNewDay()) {
      if (_shownQuotes.length >= _allQuotes.length) {
        _shownQuotes.clear();
      }
    }

    // Get available quotes (not shown today)
    final availableQuotes = _allQuotes
        .where((quote) => !_shownQuotes.contains(quote))
        .toList();

    // If no available quotes, reset and use all
    if (availableQuotes.isEmpty) {
      _shownQuotes.clear();
      availableQuotes.addAll(_allQuotes);
    }

    // Select random quote from available
    final random = DateTime.now().millisecondsSinceEpoch % availableQuotes.length;
    final selectedQuote = availableQuotes[random];

    // Mark as shown
    if (_isNewDay()) {
      _shownQuotes.clear();
    }
    _shownQuotes.add(selectedQuote);
    _lastQuoteDate = DateTime.now();
    await _saveShownQuotes();

    return selectedQuote;
  }
}

