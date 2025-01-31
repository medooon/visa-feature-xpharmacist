import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure this package is imported
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  factory IllnessData.fromJson(Map<String, dynamic> json) {
    return IllnessData(
      system: json['system'] ?? '',
      name: json['name'] ?? '',
      treatment1: json['treatment1'] ?? '',
      treatment2: json['treatment2'] ?? '',
      treatment3: json['treatment3'] ?? '',
      treatment4: json['treatment4'] ?? '',
      complementary: json['complementary'] ?? '',
      cautions: json['cautions'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      caseAvailability: json['caseAvailability'] ?? 0,
    );
  }
}

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
  String? selectedCountry = 'Egypt';
  String? selectedSystem;
  String? selectedIllness;
  List<IllnessData> illnessesList = [];
  List<String> systemsList = [];
  List<IllnessData> filteredIllnesses = [];
  bool isLoading = true;
  String? errorMessage;

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await http.get(Uri.parsehttps://egypt.moazpharmacy.com/ill.json'));
      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonData = json.decode(decodedBody);
        illnessesList = jsonData.map((item) => IllnessData.fromJson(item)).toList();
        systemsList = _getUniqueSystems();
        setState(() => isLoading = false);
      } else {
        setState(() {
          errorMessage = 'Failed to load data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
    }
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
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blue[800],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            errorMessage!,
            style: GoogleFonts.nunito(
              fontSize: 18,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    final selectedIllnessData = illnessesList.firstWhere(
      (e) => e.name == selectedIllness,
      orElse: () => IllnessData(
        system: '', name: '', treatment1: '', treatment2: '', 
        treatment3: '', treatment4: '', complementary: '', cautions: '', 
        imageUrls: [], caseAvailability: 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pharmacist Treatment Guide',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCountrySelector(),
              const SizedBox(height: 20),
              _buildSystemDropdown(),
              const SizedBox(height: 20),
              _buildIllnessDropdown(),
              const SizedBox(height: 30),
              if (selectedIllness != null) ...[
                _buildImageGallery(selectedIllnessData.imageUrls),
                const SizedBox(height: 20),
                _buildTreatmentSection(selectedIllnessData),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return Row(
      children: [
        Expanded(
          child: _buildCountryButton('Egypt'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCountryButton('Saudi'),
        ),
      ],
    );
  }

  Widget _buildCountryButton(String country) {
    final isSelected = selectedCountry == country;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        setState(() {
          selectedCountry = country;
          _filterIllnesses();
        });
      },
      child: Text(
        country,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSystemDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select System',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: GoogleFonts.nunito(color: Colors.black),
      ),
      style: _isArabic(selectedSystem ?? '')
          ? GoogleFonts.lateef(fontSize: 16, color: Colors.black)
          : GoogleFonts.nunito(fontSize: 16, color: Colors.black),
      dropdownColor: Colors.white,
      value: selectedSystem,
      items: systemsList.map((system) {
        return DropdownMenuItem(
          value: system,
          child: Container(
            alignment: _isArabic(system) ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              system,
              style: _isArabic(system)
                  ? GoogleFonts.lateef(fontSize: 16, color: Colors.black)
                  : GoogleFonts.nunito(fontSize: 16, color: Colors.black),
            ),
          ),
        );
      }).toList(),
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
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: GoogleFonts.nunito(color: Colors.black),
      ),
      style: _isArabic(selectedIllness ?? '')
          ? GoogleFonts.lateef(fontSize: 16, color: Colors.black)
          : GoogleFonts.nunito(fontSize: 16, color: Colors.black),
      dropdownColor: Colors.white,
      value: selectedIllness,
      items: filteredIllnesses.map((illness) {
        return DropdownMenuItem(
          value: illness.name,
          child: Container(
            alignment: _isArabic(illness.name) ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              illness.name,
              style: _isArabic(illness.name)
                  ? GoogleFonts.lateef(fontSize: 16, color: Colors.black)
                  : GoogleFonts.nunito(fontSize: 16, color: Colors.black),
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedIllness = value;
        });
      },
    );
  }

  Widget _buildImageGallery(List<String> imageUrls) {
    if (imageUrls.isEmpty) return const SizedBox();
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
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTreatmentSection(IllnessData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTreatmentCard('Treatment Solution 1', data.treatment1),
        _buildTreatmentCard('Treatment Solution 2', data.treatment2),
        _buildTreatmentCard('Treatment Solution 3', data.treatment3),
        _buildTreatmentCard('Treatment Solution 4', data.treatment4),
        _buildTreatmentCard('Complementary Treatment', data.complementary),
        _buildTreatmentCard('Cautions & Advice', data.cautions),
      ].whereType<Widget>().toList(),
    );
  }

  Widget? _buildTreatmentCard(String title, String? content) {
    if (content == null || content.isEmpty) return null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                alignment: _isArabic(content) ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  content,
                  textAlign: _isArabic(content) ? TextAlign.right : TextAlign.left,
                  style: _isArabic(content)
                      ? GoogleFonts.lateef(fontSize: 14, color: Colors.black)
                      : GoogleFonts.nunito(fontSize: 14, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
