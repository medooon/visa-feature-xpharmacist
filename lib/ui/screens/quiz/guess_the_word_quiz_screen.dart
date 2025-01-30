import 'package:flutter/material.dart';

class IllnessData {
  final String system;
  final String name;
  final String treatment1;
  final String treatment2;
  final String treatment3;
  final String treatment4;
  final String complementary;
  final String cautions;
  final List<String> imageUrls;
  final int caseAvailability;

  IllnessData({
    required this.system,
    required this.name,
    required this.treatment1,
    required this.treatment2,
    required this.treatment3,
    required this.treatment4,
    required this.complementary,
    required this.cautions,
    required this.imageUrls,
    required this.caseAvailability,
  });
}

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
  String? selectedCountry = 'Egypt';
  String? selectedSystem;
  String? selectedIllness;
  List<IllnessData> illnessesList = []; // Load from your data source
  List<String> systemsList = [];
  List<IllnessData> filteredIllnesses = [];

  @override
  void initState() {
    super.initState();
    // TODO: Load initial data from your data source
    // Mock data for demonstration
    illnessesList = [
      IllnessData(
        system: 'GIT',
        name: 'Constipation',
        treatment1: 'Treatment 1 for Egypt',
        treatment2: 'Treatment 2 for Egypt',
        treatment3: '',
        treatment4: '',
        complementary: 'Complementary for Egypt',
        cautions: 'Cautions for Egypt',
        imageUrls: ['https://example.com/image1.jpg'],
        caseAvailability: 1,
      ),
      // Add more mock data
    ];
    systemsList = _getUniqueSystems();
  }

  List<String> _getUniqueSystems() {
    return illnessesList.map((e) => e.system).toSet().toList();
  }

  void _filterIllnesses() {
    filteredIllnesses = illnessesList.where((illness) {
      final countryMatch = selectedCountry == 'Egypt' 
          ? illness.caseAvailability == 1 || illness.caseAvailability == 3
          : illness.caseAvailability == 2 || illness.caseAvailability == 3;
      return illness.system == selectedSystem && countryMatch;
    }).toList();
    selectedIllness = null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIllnessData = illnessesList.firstWhere(
      (e) => e.name == selectedIllness,
      orElse: () => IllnessData(
        system: '', name: '', treatment1: '', treatment2: '', treatment3: '', 
        treatment4: '', complementary: '', cautions: '', imageUrls: [], 
        caseAvailability: 0),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Pharmacist Treatment Guide')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCountrySelector(),
              SizedBox(height: 20),
              _buildSystemDropdown(),
              SizedBox(height: 20),
              _buildIllnessDropdown(),
              SizedBox(height: 30),
              if (selectedIllness != null) ...[
                _buildImageGallery(selectedIllnessData.imageUrls),
                SizedBox(height: 20),
                _buildTreatmentSection(selectedIllnessData),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return ToggleButtons(
      isSelected: [selectedCountry == 'Egypt', selectedCountry == 'Saudi'],
      onPressed: (index) {
        setState(() {
          selectedCountry = index == 0 ? 'Egypt' : 'Saudi';
          _filterIllnesses();
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Egypt'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Saudi'),
        ),
      ],
    );
  }

  Widget _buildSystemDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select System',
        border: OutlineInputBorder(),
      ),
      value: selectedSystem,
      items: systemsList
          .map((system) => DropdownMenuItem(
                value: system,
                child: Text(system),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedSystem = value;
          _filterIllnesses();
        });
      },
    );
  }

  Widget _buildIllnessDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select Illness',
        border: OutlineInputBorder(),
      ),
      value: selectedIllness,
      items: filteredIllnesses
          .map((illness) => DropdownMenuItem(
                value: illness.name,
                child: Text(illness.name),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedIllness = value;
        });
      },
    );
  }

  Widget _buildImageGallery(List<String> imageUrls) {
    if (imageUrls.isEmpty) return SizedBox();
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrls[index],
                width: 200,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTreatmentSection(IllnessData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTreatmentCard('Treatment Solution 1', data.treatment1),
        _buildTreatmentCard('Treatment Solution 2', data.treatment2),
        _buildTreatmentCard('Treatment Solution 3', data.treatment3),
        _buildTreatmentCard('Treatment Solution 4', data.treatment4),
        _buildTreatmentCard('Complementary Treatment', data.complementary),
        _buildTreatmentCard('Cautions & Advice', data.cautions),
      ].where((child) => child != null).toList(),
    );
  }

  Widget? _buildTreatmentCard(String title, String? content) {
    if (content == null || content.isEmpty) return null;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
