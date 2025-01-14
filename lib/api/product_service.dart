import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import '../utils/offline_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProductService {
  final String baseUrl = "https://egysau.moazpharmacy.com/api"; // Replace with your actual domain

  // Fetch all products from API and save to local database
  Future<void> fetchAndSaveProducts() async {
    final response = await http.get(Uri.parse("$baseUrl/get_products.php"));
    if (response.statusCode == 200) {
      List<dynamic> products = json.decode(response.body);
      // Ensure each product is a Map<String, dynamic>
      List<Map<String, dynamic>> productList = products.cast<Map<String, dynamic>>();
      await DatabaseHelper.instance.insertProducts(productList);
      // Update last fetch date and reset skips
      await OfflineManager.setLastFetchDate(DateTime.now());
      await OfflineManager.resetOfflineSkips();
    } else {
      throw Exception("Failed to fetch products from API");
    }
  }

  // Search products locally
  Future<List<Map<String, dynamic>>> searchLocalProducts(String query) async {
    return await DatabaseHelper.instance.searchProducts(query);
  }

  // Get all products locally
  Future<List<Map<String, dynamic>>> getAllLocalProducts() async {
    return await DatabaseHelper.instance.getAllProducts();
  }

  // Check internet connection
  Future<bool> checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Check app version
  Future<Map<String, dynamic>> getAppVersion() async {
    final response = await http.get(Uri.parse("$baseUrl/get_version.php"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch app version");
    }
  }

  // Compare app version
  Future<bool> isAppUpdated() async {
    final versionInfo = await getAppVersion();
    // Use package_info_plus to get current version
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // Determine platform-specific latest version
    String latestVersion;
    if (packageInfo.packageName.contains("android")) {
      latestVersion = versionInfo["latest_version_android"];
    } else {
      latestVersion = versionInfo["latest_version_ios"];
    }

    return currentVersion == latestVersion;
  }

  // Clear local database
  Future<void> clearLocalDatabase() async {
    await DatabaseHelper.instance.clearDatabase();
  }
}

