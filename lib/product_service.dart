// lib/services/product_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutterquiz/lib/product_model.dart';
import 'package:flutterquiz/lib/local_storage_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  static const String _jsonUrl = 'https://egypt.moazpharmacy.com/products.json'; // Replace with your actual URL
  static const String _lastFetchKey = 'lastFetchDate';
  static const int _fetchIntervalDays = 30;

  // Fetch products from the JSON file
  static Future<List<Product>> fetchProductsFromJson() async {
    final response = await http.get(Uri.parse(_jsonUrl));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<Product> products = data.map((json) => Product.fromJson(json)).toList();
      return products;
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Save products to local encrypted storage
  static Future<void> saveProductsLocally(List<Product> products) async {
    List<Map<String, dynamic>> productMaps = products.map((product) => product.toJson()).toList();
    String jsonString = json.encode(productMaps);
    await LocalStorageManager.saveData('products', jsonString);
    await updateLastFetchDate();
  }

  // Retrieve products from local storage
  static Future<List<Product>> getProductsFromLocal() async {
    String? jsonString = LocalStorageManager.getData('products');
    if (jsonString != null) {
      List<dynamic> data = json.decode(jsonString);
      List<Product> products = data.map((json) => Product.fromJson(json)).toList();
      return products;
    } else {
      return [];
    }
  }

  // Check if data should be fetched based on the last fetch date
  static Future<bool> shouldFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastFetchDateStr = prefs.getString(_lastFetchKey);
    if (lastFetchDateStr == null) {
      return true; // Never fetched before
    }

    DateTime lastFetchDate = DateTime.parse(lastFetchDateStr);
    DateTime currentDate = DateTime.now();

    return currentDate.difference(lastFetchDate).inDays >= _fetchIntervalDays;
  }

  // Update the last fetch date to now
  static Future<void> updateLastFetchDate() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_lastFetchKey, DateTime.now().toIso8601String());
  }
}
