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
  String searchCriteria = 'Trade Name';
  Drug? selectedDrug;
  String? selectedCountry; // Track selected country

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

  // Existing loadDrugs, _search, fetchVersionInfo, _showUpdateDialog, 
  // _refreshData, _isVersionNewer, _showSimilarDrugs, _showAlternativeDrugs,
  // _showDrugImage, _onDrugTap methods remain the same...

  void _onDescriptionButtonClick() {
    if (selectedDrug == null) return;

    if (selectedDrug!.descriptionId.isNotEmpty) {
      Drug? descriptionDrug = allDrugs.firstWhere(
        (drug) => drug.id == selectedDrug!.descriptionId,
        orElse: () => selectedDrug!,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DrugDetailScreen(drug: descriptionDrug)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DrugDetailScreen(drug: selectedDrug!)),
      );
    }
  }

  void _filterByCountry(String country) {
    setState(() {
      selectedCountry = country;
      // Don't filter here, just track selection
      // Actual filtering will happen in _search()
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back arrow
        title: const SizedBox.shrink(), // Remove title
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _filterByCountry('Egypt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedCountry == 'Egypt' 
                  ? Colors.blue[800] 
                  : Colors.blue[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text(
              'Egypt',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _filterByCountry('Saudi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedCountry == 'Saudi' 
                  ? Colors.green[800] 
                  : Colors.green[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text(
              'Saudi',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: searchCriteria,
                            dropdownColor: Colors.grey[100],
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Trade Name', child: Text('Trade Name')),
                              DropdownMenuItem(value: 'Generic Name', child: Text('Generic Name')),
                              DropdownMenuItem(value: 'Pharmacology', child: Text('Pharmacology')),
                            ],
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
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    title: Text(
                                      drug.tradeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(drug.genericName),
                                    onTap: () => _onDrugTap(drug),
                                  ),
                                );
                              },
                            )
                          : const Center(child: Text('No drugs found')),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: selectedDrug != null ? _onDescriptionButtonClick : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              selectedDrug != null 
                                  ? 'Description: ${selectedDrug!.tradeName}' 
                                  : 'Description',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedDrug != null ? _showSimilarDrugs : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Similar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedDrug != null ? _showAlternativeDrugs : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Alternative',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedDrug != null ? _showDrugImage : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Image',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
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

  // Modified _search method to include country filtering
  void _search() {
    final query = searchController.text.toLowerCase();

    if (query.length < 2) {
      setState(() => filteredDrugs = []);
      return;
    }

    String pattern = '^${RegExp.escape(query).replaceAll(r'\*', '.*').replaceAll(r'\ ', '.*')}';
    RegExp regex = RegExp(pattern, caseSensitive: false);

    List<Drug> tempList = allDrugs.where((drug) {
      String fieldToSearch;
      switch (searchCriteria) {
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

    // Apply country filter after search
    if (selectedCountry != null) {
      tempList = tempList.where((drug) {
        List<String> keValues = drug.ke.split(',');
        return selectedCountry == 'Egypt' 
            ? (keValues.contains('1') || keValues.contains('2'))
            : (keValues.contains('1') || keValues.contains('3'));
      }).toList();
    }

    setState(() => filteredDrugs = tempList);
  }
}

// DrugDetailScreen remains the same...
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
