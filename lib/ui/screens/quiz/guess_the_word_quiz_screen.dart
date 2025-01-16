// lib/screens/drug_search_screen.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutterquiz/models/drug.dart';
import 'package:flutterquiz/services/drug_service.dart';
import 'package:flutterquiz/models/data_version.dart';

class GuessTheWordQuizScreen extends StatefulWidget {
    const GuessTheWordQuizScreen({Key? key}) : super(key: key);

    /// If you need a static route to use in your routes.dart or similar:
  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const GuessTheWordQuizScreen(),
      settings: settings,
    );
  }
  
  @override
  _GuessTheWordQuizScreenState createState() => _GuessTheWordQuizScreenState();
}

class _GuessTheWordQuizScreenState extends State<GuessTheWordQuizScreen> {
  final DrugService _drugService = DrugService();
  List<Drug> allDrugs = [];
  List<Drug> filteredDrugs = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  String errorMessage = '';
  String currentVersion = 'N/A';

  @override
  void initState() {
    super.initState();
    loadDrugs();
    searchController.addListener(_search);
  }

  @override
  void dispose() {
    searchController.removeListener(_search);
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadDrugs() async {
    try {
      bool shouldFetch = await _drugService.isRemoteDataNewer();

      if (shouldFetch) {
        await _drugService.fetchAndStoreDrugs();
      }

      // Retrieve all drugs from local storage
      setState(() {
        allDrugs = _drugService.getAllDrugs();
        filteredDrugs = allDrugs;
        DataVersion? localVersion = _drugService.getLocalVersion();
        currentVersion = localVersion?.version ?? 'Unknown';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load drugs: $e';
        isLoading = false;
      });
    }
  }

  void _search() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredDrugs = allDrugs.where((drug) {
        return drug.tradeName.toLowerCase().contains(query) ||
            drug.genericName.toLowerCase().contains(query) ||
            drug.arabicName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      await _drugService.fetchAndStoreDrugs();
      setState(() {
        allDrugs = _drugService.getAllDrugs();
        filteredDrugs = allDrugs;
        DataVersion? localVersion = _drugService.getLocalVersion();
        currentVersion = localVersion?.version ?? 'Unknown';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to refresh drugs: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Drugs (v$currentVersion)'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredDrugs.isNotEmpty
                          ? ListView.builder(
                              itemCount: filteredDrugs.length,
                              itemBuilder: (context, index) {
                                final drug = filteredDrugs[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  child: ListTile(
                                    title: Text(drug.tradeName),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Generic: ${drug.genericName}'),
                                        Text(
                                            'Pharmacology: ${drug.pharmacology}'),
                                        Text('Arabic Name: ${drug.arabicName}'),
                                        Text('Price: \$${drug.price.toStringAsFixed(2)}'),
                                        Text('Company: ${drug.company}'),
                                        Text('Route: ${drug.route}'),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DrugDetailScreen(drug: drug),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            )
                          : Center(child: Text('No drugs found')),
                    ),
                  ],
                ),
    );
  }
}

// Optional: Create a Detailed View Screen
class DrugDetailScreen extends StatelessWidget {
  final Drug drug;

  DrugDetailScreen({required this.drug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(drug.tradeName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drug.tradeName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Generic Name: ${drug.genericName}',
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text('Pharmacology: ${drug.pharmacology}',
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text('Arabic Name: ${drug.arabicName}',
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text('Price: \$${drug.price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text('Company: ${drug.company}',
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text('Route: ${drug.route}', style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              Text('Description:', style: TextStyle(fontSize: 18)),
              SizedBox(height: 5),
              Text(drug.description, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
