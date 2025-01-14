import 'package:flutter/material.dart';
import 'package:flutterquiz/ui/api/product_service.dart';
import 'package:flutterquiz/utils/offline_manager.dart';
import 'package:url_launcher/url_launcher.dart'; // For redirecting to app store
import 'package:package_info_plus/package_info_plus.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final ProductService productService = ProductService();

  List<Map<String, dynamic>> products = [];
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
      final shouldFetch = await shouldFetchNewData();

      if (shouldFetch) {
        final isOnline = await productService.checkInternetConnection();

        if (isOnline) {
          final isAppUpdated = await productService.isAppUpdated();
          if (!isAppUpdated) {
            await productService.clearLocalDatabase();
            showUpdateDialog();
            return;
          }

          // Fetch and save new data
          await productService.fetchAndSaveProducts();
          // Load data from local database
          products = await productService.getAllLocalProducts();
        } else {
          await handleOfflineAccess();
          // Load data from local database
          products = await productService.getAllLocalProducts();
        }
      } else {
        // Load data from local database
        products = await productService.getAllLocalProducts();
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> shouldFetchNewData() async {
    final lastFetchDate = await OfflineManager.getLastFetchDate();
    if (lastFetchDate == null) {
      return true; // No fetch history
    }

    final now = DateTime.now();
    final daysSinceLastFetch = now.difference(lastFetchDate).inDays;

    return daysSinceLastFetch >= 30;
  }

  Future<void> handleOfflineAccess() async {
    final skipsRemaining = await OfflineManager.getOfflineSkips();

    if (skipsRemaining > 0) {
      await OfflineManager.decrementOfflineSkips();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Offline mode allowed. Skips remaining: ${skipsRemaining - 1}"),
        ),
      );
    } else {
      // Show mandatory internet connection message
      showInternetRequiredDialog();
    }
  }

  Future<void> searchProducts(String query) async {
    setState(() => isLoading = true);

    try {
      if (query.isEmpty) {
        products = await productService.getAllLocalProducts();
      } else {
        products = await productService.searchLocalProducts(query);
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force the user to update
      builder: (context) {
        return AlertDialog(
          title: Text("Update Required"),
          content: Text("A new version of the app is available. Please update to continue."),
          actions: [
            TextButton(
              onPressed: () {
                // Redirect to app store
                redirectToStore();
              },
              child: Text("Update Now"),
            ),
          ],
        );
      },
    );
  }

  void showInternetRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force the user to connect
      builder: (context) {
        return AlertDialog(
          title: Text("Internet Required"),
          content: Text("You must connect to the internet to continue using the app."),
          actions: [
            TextButton(
              onPressed: () {
                // Retry logic
                Navigator.of(context).pop();
                checkAndFetchData();
              },
              child: Text("Retry"),
            ),
          ],
        );
      },
    );
  }

  void redirectToStore() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final packageName = packageInfo.packageName;

    String url = "";
    if (Theme.of(context).platform == TargetPlatform.android) {
      url = "https://play.google.com/store/apps/details?id=$packageName";
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      // Replace with your app's App Store URL
      url = "https://apps.apple.com/app/idYOUR_APP_ID";
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Can't launch URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch the app store.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search Products"),
      ),
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
