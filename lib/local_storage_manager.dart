// lib/local_storage_manager.dart

import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class LocalStorageManager {
  static const String _boxName = 'encrypted_products';
  static Box? _box;

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
