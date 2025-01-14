// lib/screens/product_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutterquiz/lib/product_service.dart';
import 'package:flutterquiz/lib/product_model.dart';

class GuessTheWordQuizScreen extends StatefulWidget {
  @override
  _GuessTheWordQuizScreenState createState() => _GuessTheWordQuizScreenState();
}

class _GuessTheWordQuizScreenState extends State<GuessTheWordQuizScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Load products: fetch from JSON if needed, else load locally
  Future<void> _loadProducts() async {
    try {
      bool shouldFetch = await ProductService.shouldFetchData();
      if (shouldFetch) {
        List<Product> fetchedProducts = await ProductService.fetchProductsFromJson();
        await ProductService.saveProductsLocally(fetchedProducts);
        setState(() {
          _products = fetchedProducts;
          _filteredProducts = fetchedProducts;
        });
      } else {
        List<Product> localProducts = await ProductService.getProductsFromLocal();
        setState(() {
          _products = localProducts;
          _filteredProducts = localProducts;
        });
      }
    } catch (e) {
      // Handle errors (e.g., show a snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter products based on search query
  void _filterProducts(String query) {
    List<Product> filtered = _products.where((product) {
      final lowerQuery = query.toLowerCase();
      return product.tradeName.toLowerCase().contains(lowerQuery) ||
          product.genericName.toLowerCase().contains(lowerQuery) ||
          product.pharmacology.toLowerCase().contains(lowerQuery) ||
          product.arabicName.toLowerCase().contains(lowerQuery) ||
          product.company.toLowerCase().contains(lowerQuery) ||
          product.route.toLowerCase().contains(lowerQuery);
    }).toList();

    setState(() {
      _searchQuery = query;
      _filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Macy Products'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Search Products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredProducts.isEmpty
              ? Center(child: Text('No products found'))
              : ListView.builder(
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return ListTile(
                      title: Text(product.tradeName),
                      subtitle: Text(product.genericName),
                      trailing: Text('\$${product.price.toStringAsFixed(2)}'),
                    );
                  },
                ),
    );
  }
}
