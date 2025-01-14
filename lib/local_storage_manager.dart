// lib/local_storage_manager.dart

import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LocalStorageManager {
  static const String _boxName = 'encrypted_products';
  static Box? _box;
// Add these methods to the LocalStorageManager class

static const String _offlineSkipKey = 'offlineSkips';
static const int _maxSkips = 5;

// Get remaining offline skips
static Future<int> getOfflineSkips() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_offlineSkipKey) ?? _maxSkips;
}

// Decrement offline skips
static Future<void> decrementOfflineSkips() async {
  final prefs = await SharedPreferences.getInstance();
  int currentSkips = prefs.getInt(_offlineSkipKey) ?? _maxSkips;
  if (currentSkips > 0) {
    await prefs.setInt(_offlineSkipKey, currentSkips - 1);
  }
}

// Reset offline skips
static Future<void> resetOfflineSkips() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_offlineSkipKey, _maxSkips);
}
  // Initialize Hive
  static Future<void> initializeHive() async {
    await Hive.initFlutter();
    await openEncryptedBox();
  }

  // Generate a 256-bit encryption key
  static Uint8List generateEncryptionKey() {
    // It's recommended to store this key securely.
    // For demonstration, we're generating it from a passphrase.
    // In production, consider more secure key management.
    final passphrase = 'your_secure_passphrase_here'; // Replace with a strong passphrase
    final key = sha256.convert(utf8.encode(passphrase)).bytes;
    return Uint8List.fromList(key);
  }

  // Open an encrypted Hive box
  static Future<void> openEncryptedBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      final encryptionKey = generateEncryptionKey();
      _box = await Hive.openBox(
        _boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } else {
      _box = Hive.box(_boxName);
    }
  }

  // Save data to the encrypted box
  static Future<void> saveData(String key, dynamic value) async {
    await _box?.put(key, value);
  }

  // Retrieve data from the encrypted box
  static dynamic getData(String key) {
    return _box?.get(key);
  }

  // Clear all data from the box
  static Future<void> clearData() async {
    await _box?.clear();
  }
}


// lib/local_storage_manager.dart




