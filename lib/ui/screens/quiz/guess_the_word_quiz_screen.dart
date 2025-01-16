// lib/screens/drug_search_screen.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutterquiz/models/drug.dart';
import 'package:flutterquiz/services/drug_service.dart';
import 'package:flutterquiz/models/data_version.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuessTheWordQuizScreen extends StatefulWidget {
  const GuessTheWordQuizScreen({Key? key}) : super(key: key);

  /// Static route for navigation
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
  String searchCriteria = 'Trade Name'; // Default search criterion
  Drug? selectedDrug; // Currently selected drug for the description button

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

      setState(() {
        allDrugs = _drugService.getAllDrugs();
        filteredDrugs = []; // Do not show drugs before searching
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

    if (query.length < 2) {
      setState(() {
        filteredDrugs = [];
      });
      return;
    }

    String pattern = '^' + RegExp.escape(query).replaceAll(r'\*', '.*').replaceAll(r'\ ', '.*');
    RegExp regex = RegExp(pattern, caseSensitive: false);

    setState(() {
      filteredDrugs = allDrugs.where((drug) {
        String fieldToSearch;
        switch (searchCriteria) {
          case 'Trade Name':
            fieldToSearch = drug.tradeName.toLowerCase();
            break;
          case 'Generic Name':
            fieldToSearch = drug.genericName.toLowerCase();
            break;
          case 'Arabic Name':
            fieldToSearch = drug.arabicName.toLowerCase();
            break;
          case 'Pharmacology':
            fieldToSearch = drug.pharmacology.toLowerCase();
            break;
          case 'Price':
            fieldToSearch = drug.price.toString();
            break;
          default:
            fieldToSearch = drug.tradeName.toLowerCase();
        }
        return regex.hasMatch(fieldToSearch);
      }).toList();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      bool shouldFetch = await _drugService.isRemoteDataNewer();

      if (shouldFetch) {
        await _drugService.fetchAndStoreDrugs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data has been updated to version $currentVersion.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data is already up to date.')),
        );
      }

      setState(() {
        allDrugs = _drugService.getAllDrugs();
        _search();
        DataVersion? localVersion = _drugService.getLocalVersion();
        currentVersion = localVersion?.version ?? 'Unknown';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to refresh drugs: $e';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing data: $e')),
      );
    }
  }

  Future<String?> fetchImageUrl(String query) async {
    final String apiKey = 'YOUR_API_KEY';
    final String searchEngineId = 'YOUR_SEARCH_ENGINE_ID';
    final String searchUrl =
        'https://www.googleapis.com/customsearch/v1?q=$query&searchType=image&key=$apiKey&cx=$searchEngineId&num=1';

    try {
      final response = await http.get(Uri.parse(searchUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].length > 0) {
          return data['items'][0]['link'];
        }
      }
    } catch (e) {
      print('Error fetching image: $e');
    }
    return null;
  }

  void _showSimilarDrugs() {
    if (selectedDrug == null) return;

    setState(() {
      filteredDrugs = allDrugs
          .where((drug) =>
              drug.genericName.toLowerCase() ==
              selectedDrug!.genericName.toLowerCase())
          .toList();
    });
  }

  void _showAlternativeDrugs() {
    if (selectedDrug == null) return;

    setState(() {
      filteredDrugs = allDrugs
          .where((drug) =>
              drug.pharmacology.toLowerCase() ==
              selectedDrug!.pharmacology.toLowerCase())
          .toList();
    });
  }

  Future<void> _showDrugImage() async {
    if (selectedDrug == null) return;

    String query = selectedDrug!.tradeName;
    String? imageUrl = await fetchImageUrl(query);

    if (imageUrl != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Image of ${selectedDrug!.tradeName}'),
          content: Image.network(imageUrl),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image found for ${selectedDrug!.tradeName}.')),
      );
    }
  }

  void _onDrugTap(Drug drug) {
    setState(() {
      selectedDrug = drug;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrugDetailScreen(drug: drug),
      ),
    );
  }

  void _onDescriptionButtonClick() {
    if (selectedDrug == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrugDetailScreen(drug: selectedDrug!),
      ),
    );
  }

  final List<String> searchCriteriaOptions = [
    'Trade Name',
    'Generic Name',
    'Arabic Name',
    'Pharmacology',
    'Price'
  ];

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
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                labelText: 'Search',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          DropdownButton<String>(
                            value: searchCriteria,
                            items: searchCriteriaOptions
                                .map((criteria) => DropdownMenuItem<String>(
                                      value: criteria,
                                      child: Text(criteria),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  searchCriteria = value;
                                  _search();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    if (selectedDrug != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _onDescriptionButtonClick,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              selectedDrug!.tradeName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
                                  child: ListTile(
                                    // **Modification 17: Style Trade Names Bold and Generic Names Normal**
                                    title: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: drug.tradeName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontSize: 16,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' (${drug.genericName})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black54,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Pharmacology: ${drug.pharmacology}'),
                                        Text('Arabic Name: ${drug.arabicName}'),
                                        Text('Price: \$${drug.price.toStringAsFixed(2)}'),
                                        Text('Company: ${drug.company}'),
                                        Text('Route: ${drug.route}'),
                                      ],
                                    ),
                                    isThreeLine: true,
                                   onTap: () => _onDrugTap(drug),
                                  ),
                                );
                              },
                            )
                          : Center(child: Text('No drugs found')),
                    ),
                    // **Modification 18: Bottom Buttons - Similar, Alternative, Image**
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          // Dynamic Description Button is already added above
                          // Row for Similar and Alternative Buttons
                          Row(
                            children: [
                              // Similar Button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      selectedDrug != null ? _showSimilarDrugs : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: Text(
                                    'Similar',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              // Alternative Button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedDrug != null
                                      ? _showAlternativeDrugs
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: Text(
                                    'Alternative',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          // Image Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  selectedDrug != null ? _showDrugImage : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: Text(
                                'Image',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class DrugDetailScreen extends StatelessWidget {
  final Drug drug;

  DrugDetailScreen({required this.drug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
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
              Text(
                'Generic Name:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              Text(
                drug.genericName,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Pharmacology:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              Text(
                drug.pharmacology,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Company:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              Text(
                drug.company,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Route:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              Text(
                drug.route,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Description:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 5),
              Text(
                drug.description,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
