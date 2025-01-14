import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  final String baseUrl = "https://yourdomain.com/api";

  // Fetch all products
  Future<List<dynamic>> fetchAllProducts() async {
    final response = await http.get(Uri.parse("$baseUrl/get_products.php"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch products");
    }
  }

  // Search products
  Future<List<dynamic>> searchProducts(String query) async {
    final response = await http.get(Uri.parse("$baseUrl/search_products.php?query=$query"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to search products");
    }
  }

  // Get app version
  Future<Map<String, dynamic>> getAppVersion() async {
    final response = await http.get(Uri.parse("$baseUrl/get_version.php"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch app version");
    }
  }
}
