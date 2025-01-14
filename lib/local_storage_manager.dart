// lib/local_storage_manager.dart

import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


// lib/local_storage_manager.dart


class LocalStorageManager {
  static const String _boxName = 'encrypted_products';
  static Box? _box;
  static final _secureStorage = FlutterSecureStorage();
  static const _encryptionKeyKey = 'hive_encryption_key';

  // Initialize Hive
  static Future<void> initializeHive() async {
    await Hive.initFlutter();
    await openEncryptedBox();
  }

  // Generate or retrieve the encryption key
  static Future<Uint8List> getEncryptionKey() async {
    String? storedKey = await _secureStorage.read(key: _encryptionKeyKey);
    if (storedKey == null) {
      // Generate a new 256-bit key
      final key = Hive.generateSecureKey();
      // Store the key as a base64 string
      await _secureStorage.write(key: _encryptionKeyKey, value: base64UrlEncode(key));
      return key;
    } else {
      // Decode the stored base64 string back to bytes
      return base64Url.decode(storedKey);
    }
  }

  // Open an encrypted Hive box
  static Future<void> openEncryptedBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      final encryptionKey = await getEncryptionKey();
      _box = await Hive.openBox(
        _boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } else {
      _box = Hive.box(_boxName);
    }
  }
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




