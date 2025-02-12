import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutterquiz/models/drug.dart';
import 'package:flutterquiz/services/drug_service.dart';
import 'package:flutterquiz/models/data_version.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String selectedCountry = 'Egypt'; // Default country filter

  // URL for the version JSON file
  final String versionUrl = 'https://x-pharmacist.com/version.json';

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
      // Check if local data exists
      bool hasLocalData = await _drugService.hasLocalData();

      if (!hasLocalData) {
        // If no local data exists, fetch data from the server
        await _drugService.fetchAndStoreDrugs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data fetched from the server.')),
        );
      }

      // Update the UI with the latest data
      setState(() {
        allDrugs = _drugService.getAllDrugs(); // Get all drugs from local storage
        filteredDrugs = []; // Do not show drugs before searching
        DataVersion? localVersion = _drugService.getLocalVersion();
        currentVersion = localVersion?.version ?? 'Unknown'; // Update the version
        isLoading = false; // Stop loading
      });
    } catch (e) {
      // Handle errors
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

    // Replace spaces with wildcards (.*)
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

  // Fetch version info from the JSON URL
  Future<Map<String, dynamic>> fetchVersionInfo() async {
    try {
      final response = await http.get(Uri.parse(versionUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load version info');
      }
    } catch (e) {
      throw Exception('No internet connection or there is a problem');
    }
  }

  // Show update dialog if a new version is available
  Future<void> _showUpdateDialog(String remoteVersion) async {
    DataVersion? localVersion = _drugService.getLocalVersion();
    String localVersionStr = localVersion?.version ?? 'Unknown';

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New Version Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Version: $localVersionStr'),
              Text('New Version: $remoteVersion'),
              SizedBox(height: 10),
              Text('Updating will take a minute. Do you want to proceed?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog
                await _refreshData(); // Fetch and update data
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      // Fetch version info from the JSON URL
      Map<String, dynamic> versionInfo = await fetchVersionInfo();
      String remoteVersion = versionInfo['version'] ?? 'Unknown';

      DataVersion? localVersion = _drugService.getLocalVersion();
      String localVersionStr = localVersion?.version ?? 'Unknown';

      // Check if the remote version is newer
      if (_isVersionNewer(remoteVersion, localVersionStr)) {
        // Show update dialog
        await _showUpdateDialog(remoteVersion);
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
        errorMessage = 'No internet connection or there is a problem';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  // Helper method to compare semantic versions
  bool _isVersionNewer(String remote, String local) {
    List<int> remoteParts = remote.split('.').map(int.parse).toList();
    List<int> localParts = local.split('.').map(int.parse).toList();

    for (int i = 0; i < remoteParts.length; i++) {
      if (i >= localParts.length) return true;
      if (remoteParts[i] > localParts[i]) return true;
      if (remoteParts[i] < localParts[i]) return false;
    }
    return false;
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

    final tradeName = selectedDrug!.tradeName ?? 'N/A';
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
      selectedDrug = drug; // Update the selected drug
    });
  }

  void _onDescriptionButtonClick() {
    if (selectedDrug == null) return;

    // Check if the drug has a description_id
    if (selectedDrug!.descriptionId.isNotEmpty) {
      // Find the drug with the matching description_id
      Drug? descriptionDrug = allDrugs.firstWhere(
        (drug) => drug.id == selectedDrug!.descriptionId,
        orElse: () => selectedDrug!,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DrugDetailScreen(drug: descriptionDrug),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DrugDetailScreen(drug: selectedDrug!),
        ),
      );
    }
  }

  final List<String> searchCriteriaOptions = [
    'Trade Name',
    'Generic Name',
    'Pharmacology',
  ];

  void _filterByCountry(String country) {
    setState(() {
      selectedCountry = country;
      if (country == 'Egypt') {
        filteredDrugs = allDrugs.where((drug) => drug.ke.contains('1') || drug.ke.contains('2')).toList();
      } else if (country == 'Saudi') {
        filteredDrugs = allDrugs.where((drug) => drug.ke.contains('1') || drug.ke.contains('3')).toList();
      }
    });
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
          TextButton(
            onPressed: () => _filterByCountry('Egypt'),
            child: Text('Egypt', style: TextStyle(color: selectedCountry == 'Egypt' ? Colors.red : Colors.grey)),
          ),
          TextButton(
            onPressed: () => _filterByCountry('Saudi'),
            child: Text('Saudi', style: TextStyle(color: selectedCountry == 'Saudi' ? Colors.red : Colors.grey)),
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
                            dropdownColor: Colors.white,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
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
                    ),
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
                                    onTap: () => _onDrugTap(drug), // Update selected drug
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
                          // Description Button (always visible)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: selectedDrug != null
                                    ? _onDescriptionButtonClick
                                    : null, // Disable if no drug is selected
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Text(
                                  selectedDrug != null
                                      ? 'Description: ${selectedDrug!.tradeName}'
                                      : 'Description', // Show trade name if selected
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
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
      backgroundColor: Colors.white,
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
              Text(drug.description, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
