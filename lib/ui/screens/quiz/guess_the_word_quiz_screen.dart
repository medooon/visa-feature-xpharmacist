import 'package:flutter/material.dart';
import 'package:flutterquiz/model/drug.dart';
import 'package:flutterquiz/db/drug_database.dart';

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
  List<Drug> _drugs = [];
  List<Drug> _filteredDrugs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDrugs(); // Fetch data when the screen loads
  }

  // Fetch drugs from API or SQLite
  Future<void> _fetchDrugs() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch drugs from API
      final drugs = await fetchDrugs('https://egypt.moazpharmacy.com/products.json');
      await _storeDrugsLocally(drugs); // Save data locally
      setState(() {
        _drugs = drugs;
        _filteredDrugs = drugs;
        _isLoading = false;
      });
    } catch (e) {
      // If fetching from API fails, load from local database
      final drugs = await _getDrugsOffline();
      setState(() {
        _drugs = drugs;
        _filteredDrugs = drugs;
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Store drugs locally in SQLite
  Future<void> _storeDrugsLocally(List<Drug> drugs) async {
    await DrugDatabase.instance.insertDrugs(drugs);
  }

  // Fetch drugs from SQLite when offline
  Future<List<Drug>> _getDrugsOffline() async {
    return await DrugDatabase.instance.fetchDrugsFromDB();
  }

  // Filter drugs based on search input
  void _filterDrugs(String query) {
    final filtered = _drugs.where((drug) {
      final tradeNameLower = drug.tradeName.toLowerCase();
      final genericNameLower = drug.genericName.toLowerCase();
      final arabicNameLower = drug.arabicName.toLowerCase();
      final queryLower = query.toLowerCase();

      return tradeNameLower.contains(queryLower) ||
          genericNameLower.contains(queryLower) ||
          arabicNameLower.contains(queryLower);
    }).toList();

    setState(() {
      _filteredDrugs = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drug Search'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search by Trade, Generic, or Arabic Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _filterDrugs,
                      ),
                    ),
                    Expanded(
                      child: _filteredDrugs.isEmpty
                          ? const Center(child: Text('No results found'))
                          : ListView.builder(
                              itemCount: _filteredDrugs.length,
                              itemBuilder: (context, index) {
                                final drug = _filteredDrugs[index];
                                return ListTile(
                                  title: Text(drug.tradeName),
                                  subtitle: Text(
                                    '${drug.genericName} (${drug.arabicName})',
                                  ),
                                  trailing: Text(
                                    '\$${drug.price.toStringAsFixed(2)}',
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
