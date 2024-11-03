import 'package:flutter/material.dart';
import 'dart:io';
import 'package:thesis_nlp_app/services/firebase_storage_service.dart'; // Import Firebase Storage service

class BookReviewAndEditScreen extends StatefulWidget {
  final List<Map<String, String>> entities;
  final Map<String, String> additionalData;
  final Function(List<Map<String, String>>) onSave;

  BookReviewAndEditScreen({
    required this.entities,
    required this.additionalData,
    required this.onSave,
  });

  @override
  _BookReviewAndEditScreenState createState() => _BookReviewAndEditScreenState();
}

class _BookReviewAndEditScreenState extends State<BookReviewAndEditScreen> {
  late List<Map<String, String>> _editableEntities;
  File? coverImage; // Variable to hold the cover image
  bool isUploading = false; // Track image upload state

  final FirebaseStorageService _firebaseStorageService = FirebaseStorageService(); // Initialize Firebase Storage service

  @override
  void initState() {
    super.initState();
    _editableEntities = List<Map<String, String>>.from(widget.entities);

    // Load cover image if path is available
    String? coverImagePath = _editableEntities.firstWhere(
          (element) => element['label'] == 'CoverImagePath',
      orElse: () => {'text': ''},
    )['text'];

    if (coverImagePath != null && coverImagePath.isNotEmpty) {
      coverImage = File(coverImagePath);
    }

    // Add additional data (Cutter Number, Classification Number, Subjects, Pagination)
    _editableEntities.add({
      'label': 'Cutter Number',
      'text': widget.additionalData['Cutter Number'] ?? 'N/A',
    });
    _editableEntities.add({
      'label': 'Classification Number',
      'text': widget.additionalData['Classification Number'] ?? 'N/A',
    });
    _editableEntities.add({
      'label': 'Subjects',
      'text': widget.additionalData['Subjects'] ?? 'N/A',
    });
    _editableEntities.add({
      'label': 'Pagination',
      'text': widget.additionalData['Pagination'] ?? 'N/A',
    });
  }

  Future<void> _saveBook() async {
    setState(() {
      isUploading = true; // Set uploading state to true
    });

    // Upload cover image to Firebase Storage if it's present
    String? coverImageUrl;
    if (coverImage != null) {
      String fileName = 'book_cover_${DateTime.now().millisecondsSinceEpoch}.png'; // Generate unique file name
      coverImageUrl = await _firebaseStorageService.uploadImage(coverImage!, fileName);
    }

    setState(() {
      isUploading = false; // Reset uploading state
    });

    if (coverImageUrl != null) {
      // Update the cover image URL in the editable entities
      _editableEntities.add({'label': 'CoverImageUrl', 'text': coverImageUrl});
    }

    // Remove the CoverImagePath from being saved
    _editableEntities.removeWhere((entity) => entity['label'] == 'CoverImagePath');

    // Save the book using the onSave callback
    widget.onSave(_editableEntities);

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Book Saved")),
    );

    // Navigate back to the home screen or previous screen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: const Text('Review and Edit', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: isUploading ? null : _saveBook, // Disable save button while uploading
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display cover image if available
            if (coverImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Image.file(
                  coverImage!,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ListView.builder(
              shrinkWrap: true, // Set to true to use in a Column
              physics: NeverScrollableScrollPhysics(), // Prevent scrolling conflict
              itemCount: _editableEntities.length,
              itemBuilder: (context, index) {
                // Filter out CoverImagePath from display
                if (_editableEntities[index]['label'] == 'CoverImagePath') {
                  return SizedBox.shrink();
                }
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: _editableEntities[index]['label'] == 'Subjects'
                        ? TextField(
                      maxLines: null, // Multiline input for Subjects
                      decoration: InputDecoration(
                        labelText: _editableEntities[index]['label'],
                      ),
                      controller: TextEditingController(
                        text: _editableEntities[index]['text'],
                      ),
                      onChanged: (value) {
                        _editableEntities[index]['text'] = value;
                      },
                    )
                        : TextField(
                      decoration: InputDecoration(
                        labelText: _editableEntities[index]['label'],
                      ),
                      controller: TextEditingController(
                        text: _editableEntities[index]['text'],
                      ),
                      onChanged: (value) {
                        _editableEntities[index]['text'] = value;
                      },
                    ),
                  ),
                );
              },
            ),
            if (isUploading)
              CircularProgressIndicator(), // Show loading indicator during upload
          ],
        ),
      ),
    );
  }
}
