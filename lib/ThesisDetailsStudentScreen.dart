import 'package:flutter/material.dart';

class ThesisDetailsStudentScreen extends StatelessWidget {
  final Map<String, dynamic> thesisData; // Thesis data from Firestore

  ThesisDetailsStudentScreen({required this.thesisData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          thesisData['Title'] ?? 'Thesis Details',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: IconThemeData(color: Colors.white), // Makes the back arrow white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title card with highlighted title
            _buildInfoCard('Title', thesisData['Title'] ?? 'No Title', Icons.title),

            // Authors card
            _buildInfoCard(
              'Authors',
              (thesisData['Authors'] != null && thesisData['Authors'] is List)
                  ? (thesisData['Authors'] as List).join(', ')
                  : 'Unknown Authors',
              Icons.person,
            ),

            // Program card
            _buildInfoCard('Program', thesisData['Program'] ?? 'Unknown Program', Icons.school),

            // Institution card
            _buildInfoCard('Institution', thesisData['Institution'] ?? 'Unknown Institution', Icons.location_city),

            // Year submitted
            _buildInfoCard('Year Submitted', thesisData['Year Submitted'] ?? 'Unknown Year', Icons.calendar_today),

            // Classification and Cutter Numbers
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard('Classification Number', thesisData['Classification Number'] ?? 'Unknown Classification', Icons.code),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoCard('Cutter Number', thesisData['Cutter Number'] ?? 'Unknown Cutter Number', Icons.bookmark),
                ),
              ],
            ),

            // Description
            _buildInfoCard('Description', thesisData['Description'] ?? 'No Description', Icons.description),

            // Subjects
            _buildMultiLineInfoCard(
              'Subjects',
              _getSubjects(thesisData['Subjects']),
              Icons.list,
            ),

            // Abstract
            _buildAbstractSection(thesisData['Abstract'] ?? 'No Abstract'),
          ],
        ),
      ),
    );
  }

  // Method to build a modern card-based display for thesis details
  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Special method to handle multi-line content for Subjects
  Widget _buildMultiLineInfoCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build the Abstract section
  Widget _buildAbstractSection(String abstractText) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.article, size: 28, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text(
                  'Abstract:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              abstractText,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to handle different types of Subjects field
  String _getSubjects(dynamic subjectsField) {
    if (subjectsField == null) {
      return 'No Subjects';
    }

    if (subjectsField is List) {
      return subjectsField.isNotEmpty ? subjectsField.join(', ') : 'No Subjects';
    } else if (subjectsField is String) {
      return subjectsField;
    } else {
      return 'No Subjects';
    }
  }
}
