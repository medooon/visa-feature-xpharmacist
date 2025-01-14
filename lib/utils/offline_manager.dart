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

  // Get the last fetch date
  static Future<DateTime?> getLastFetchDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastFetchKey);
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  // Set the number of offline skips
  static Future<void> setOfflineSkips(int skips) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_offlineSkipKey, skips);
  }

  // Get the remaining offline skips
  static Future<int> getOfflineSkips() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_offlineSkipKey) ?? _maxSkips;
  }

  // Decrement offline skips
  static Future<void> decrementOfflineSkips() async {
    final currentSkips = await getOfflineSkips();
    if (currentSkips > 0) {
      await setOfflineSkips(currentSkips - 1);
    }
  }

  // Reset offline skips to max value
  static Future<void> resetOfflineSkips() async {
    await setOfflineSkips(_maxSkips);
  }
}
