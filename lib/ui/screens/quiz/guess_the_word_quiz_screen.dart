// lib/screens/drug_search_screen.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutterquiz/models/drug.dart';
import 'package:flutterquiz/services/drug_service.dart';
import 'package:flutterquiz/models/data_version.dart';
import 'package:url_launcher/url_launcher.dart';


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
          case 'Pharmacology':
            fieldToSearch = drug.pharmacology.toLowerCase();
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

/// Show Google Images (in-app) if a drug is selected
  Future<void> _showDrugImage() async {
    if (selectedDrug == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No drug selected')),
      );
      return;
    }

    final tradeName = selectedDrug!['tradeName'] ?? 'N/A';
    final googleImagesUrl = 'https://www.google.com/search?tbm=isch&q=$tradeName';

    // Launch in an in-app WebView
    if (await canLaunchUrl(Uri.parse(googleImagesUrl))) {
      await launchUrl(Uri.parse(googleImagesUrl),
          mode: LaunchMode.inAppWebView);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $googleImagesUrl'),
        ),
      );
    }
  }

void _onDrugTap(Drug drug) {
  setState(() {
    selectedDrug = drug; // Only set the selected drug
  });

  // Remove navigation logic here
  // Navigator.push(
  //   context,
  //   MaterialPageRoute(
  //     builder: (context) => DrugDetailScreen(drug: drug),
  //   ),
  // );
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
    'Pharmacology',
    
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
              // Search and Results Section
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
        dropdownColor: Colors.white, // Dropdown background color
        style: TextStyle(
          color: Colors.black, // Text color
          fontSize: 16, // Optional: Adjust font size
        ),
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
)
              Expanded(
                child: filteredDrugs.isNotEmpty
                    ? ListView.builder(
                        itemCount: filteredDrugs.length,
                        itemBuilder: (context, index) {
                          final drug = filteredDrugs[index];
                          return Card(
                            child: ListTile(
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
                                  ],
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${drug.genericName}'),
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
              // Description Button and Bottom Buttons Section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Description Button
                    if (selectedDrug != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DrugDetailScreen(drug: selectedDrug!),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              'Description', // Button text
                               style: TextStyle(
                                 fontWeight: FontWeight.bold, // Bold text
                                fontSize: 16,                // Optional size adjustment
                              ),
                          ),
                        ),
                      ),
                    SizedBox(height: 10),
                    // Row of Similar, Alternative, and Image Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedDrug != null
                                ? _showSimilarDrugs
                                : null,
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
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedDrug != null
                                ? _showDrugImage
                                : null,
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
            ),
          ],

    );
  ),
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
