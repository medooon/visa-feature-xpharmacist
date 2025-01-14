import 'package:shared_preferences/shared_preferences.dart';

class OfflineManager {
  static const String _lastFetchKey = 'lastFetchDate';
  static const String _offlineSkipKey = 'offlineSkips';
  static const int _maxSkips = 5;

  // Set the last fetch date
  static Future<void> setLastFetchDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_lastFetchKey, date.toIso8601String());
  }

  // Get
