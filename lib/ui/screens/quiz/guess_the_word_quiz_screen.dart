import 'package:flutter/material.dart';
import '../api/product_service.dart';
import '../utils/offline_manager.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final ProductService productService = ProductService();

  List<dynamic> products = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    checkAndFetchData();
  }

  Future<void> checkAndFetchData() async {
    setState(() => isLoading = true);

    try {
      // Check if it's time to fetch new data
      final shouldFetch = await shouldFetchNewData();

      if (shouldFetch) {
        final isOnline = await productService.checkInternetConnection();

        if (isOnline) {
          // Fetch new data
          products = await productService.fetchAllProducts();
          await afterSuccessfulFetch();
        } else {
          // Handle offline mode with skips
          await handleOfflineAccess();
        }
      } else {
        print("Data is up-to-date. Loading local data...");
        products = await productService.loadLocalData(); // Load data from local storage
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> searchProducts(String query) async {
    setState(() => isLoading = true);

    try {
      if (query.isEmpty) {
        products = await productService.loadLocalData(); // Load all data
      } else {
        products = await productService.searchLocalData(query); // Search in local data
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Products")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: searchProducts,
            ),
          ),
          if (isLoading)
            Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (products.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  "No products found",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    title: Text(product['trade_name']),
                    subtitle: Text(product['generic_name']),
                    trailing: Text("\$${product['price']}"),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

