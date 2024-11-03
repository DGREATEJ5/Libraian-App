import 'package:flutter/material.dart';

class BookDetailsStudentScreen extends StatelessWidget {
  final Map<String, dynamic> bookData; // Book data from Firestore

  BookDetailsStudentScreen({required this.bookData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          bookData['Title'] ?? 'Book Details',
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
            // Title card
            _buildInfoCard('Title', bookData['Title'] ?? 'No Title', Icons.title),

            // Authors card
            _buildInfoCard(
              'Authors',
              _getAuthors(bookData['Authors']),
              Icons.person,
            ),

            // Publisher
            _buildInfoCard('Publisher', bookData['Publisher'] ?? 'Unknown Publisher', Icons.publish),

            // Year Published
            _buildInfoCard('Year Published', bookData['Year Published'] ?? 'Unknown Year', Icons.calendar_today),

            // ISBN Number
            _buildInfoCard('ISBN', bookData['ISBN'] ?? 'Unknown ISBN', Icons.bookmark),

            // Classification Number
            _buildInfoCard('Classification Number', bookData['Classification Number'] ?? 'Unknown Classification', Icons.class_),

            // Conditionally display Edition if available
            if (bookData['Edition'] != null && bookData['Edition'].isNotEmpty)
              _buildInfoCard('Edition', bookData['Edition'], Icons.edit),

            // Conditionally display Volume if available
            if (bookData['Volume'] != null && bookData['Volume'].isNotEmpty)
              _buildInfoCard('Volume', bookData['Volume'], Icons.layers),

            // Pagination
            _buildInfoCard('Pagination', bookData['Pagination'] ?? 'Unknown Pagination', Icons.menu_book),

            // Subjects
            _buildInfoCard(
              'Subjects',
              _getSubjects(bookData['Subjects']),
              Icons.list,
            ),
          ],
        ),
      ),
    );
  }

  // Method to build a modern card-based display for book details
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

  // Helper method to handle different types of Authors field (String or List)
  String _getAuthors(dynamic authorsField) {
    if (authorsField == null) {
      return 'Unknown Authors';
    }

    if (authorsField is List) {
      return authorsField.isNotEmpty ? authorsField.join(', ') : 'Unknown Authors';
    } else if (authorsField is String) {
      return authorsField;
    } else {
      return 'Unknown Authors';
    }
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
