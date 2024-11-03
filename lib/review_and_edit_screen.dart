import 'package:flutter/material.dart';
import 'package:thesis_nlp_app/services/cutter_number_service.dart';
import 'package:thesis_nlp_app/services/gemini_service.dart';
import 'package:thesis_nlp_app/services/firebase_storage_service.dart'; // Import Firebase Storage service
import 'dart:io';

class ReviewAndEditScreen extends StatefulWidget {
  final Map<String, dynamic> entities; // Now supports dynamic types like lists
  final File? coverImage; // Cover image passed from ProcessedEntitiesScreen
  final void Function(Map<String, dynamic>) onSaveBook; // Updated to match dynamic map

  ReviewAndEditScreen({
    required this.entities,
    required this.coverImage,
    required this.onSaveBook,
  });

  @override
  _ReviewAndEditScreenState createState() => _ReviewAndEditScreenState();
}

class _ReviewAndEditScreenState extends State<ReviewAndEditScreen> {
  final TextEditingController titleController = TextEditingController();
  List<TextEditingController> authorControllers = []; // Handle multiple authors
  final TextEditingController programController = TextEditingController();
  final TextEditingController institutionController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController abstractController = TextEditingController();
  final TextEditingController classificationNumberController = TextEditingController();
  final TextEditingController cutterNumberController = TextEditingController();
  final TextEditingController subjectsController = TextEditingController();

  bool _loading = true; // To show loading state when fetching data
  bool isUploading = false; // For image upload progress tracking

  late GeminiService geminiService;
  late CutterNumberService cutterNumberService;
  final FirebaseStorageService _firebaseStorageService = FirebaseStorageService(); // Firebase Storage service

  @override
  void initState() {
    super.initState();

    // Populate initial fields with entities passed from the previous screen
    titleController.text = widget.entities['Title'] ?? '';

    // Handle multiple authors
    if (widget.entities['Authors'] != null && widget.entities['Authors'] is List) {
      List<String> authors = widget.entities['Authors'] as List<String>;
      for (var author in authors) {
        authorControllers.add(TextEditingController(text: author));
      }
    } else {
      authorControllers.add(TextEditingController()); // Add empty controller if no authors are found
    }

    programController.text = widget.entities['Program'] ?? '';
    institutionController.text = widget.entities['Institution'] ?? '';
    yearController.text = widget.entities['Year Submitted'] ?? '';
    descriptionController.text = widget.entities['Description'] ?? '';
    abstractController.text = widget.entities['Abstract'] ?? '';
    classificationNumberController.text = widget.entities['Classification Number'] ?? '';
    cutterNumberController.text = widget.entities['Cutter Number'] ?? '';
    subjectsController.text = widget.entities['Subjects'] ?? '';

    // Initialize services with API key and base URL
    geminiService = GeminiService('YOUR-API-KEY'); // Replace with actual API key
    cutterNumberService = CutterNumberService('YOUR-API-KEY');

    // Fetch additional data (Classification Number, Cutter Number, and Subjects)
    _fetchAdditionalData();
  }

  Future<void> _fetchAdditionalData() async {
    final String title = titleController.text;
    final String abstract = abstractController.text; // Get the abstract text
    final String author = authorControllers.isNotEmpty ? authorControllers[0].text : '';

    try {
      // Fetch Classification Number using both title and abstract
      final String? classificationNumber = await geminiService.getClassificationNumber(title, abstract);

      // Fetch Subjects
      final String? subjects = await geminiService.getSubjects(title, abstract);

      // Fetch Cutter Number
      final String? cutterNumber = await cutterNumberService.getCutterNumber(author, title);

      // Populate the additional fields, using default values in case of null
      classificationNumberController.text = classificationNumber ?? ''; // Use empty string if null
      subjectsController.text = subjects ?? ''; // Use empty string if null
      cutterNumberController.text = cutterNumber ?? 'N/A'; // Use 'N/A' if null

      // Stop loading state
      setState(() {
        _loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching additional data: $e'),
      ));
    }
  }

  Future<void> _saveBook() async {
    setState(() {
      isUploading = true; // Start uploading state
    });

    // Upload the cover image to Firebase Storage if it's present
    String? coverImageUrl;
    if (widget.coverImage != null) {
      String fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.png'; // Generate unique file name
      coverImageUrl = await _firebaseStorageService.uploadImage(widget.coverImage!, fileName);
    }

    setState(() {
      isUploading = false; // End uploading state
    });

    // Collect all the updated information, including additional fetched data and image URL
    Map<String, dynamic> updatedEntities = {
      'Title': titleController.text,
      'Authors': authorControllers.map((controller) => controller.text).toList(), // Store authors as list
      'Program': programController.text,
      'Institution': institutionController.text,
      'Year Submitted': yearController.text,
      'Description': descriptionController.text,
      'Abstract': abstractController.text,
      'Classification Number': classificationNumberController.text,
      'Cutter Number': cutterNumberController.text,
      'Subjects': subjectsController.text,
      'CoverImageUrl': coverImageUrl ?? '', // Include the cover image URL if uploaded
    };

    // Call the save callback passed from the previous screen
    widget.onSaveBook(updatedEntities);

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Book Saved")),
    );

    // Navigate back to the HomeScreen after saving
    Navigator.of(context).popUntil((route) => route.isFirst); // Pops all routes until the first one, which is HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review and Edit'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: isUploading ? null : _saveBook, // Disable button while uploading
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator()) // Show loading while fetching
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.coverImage != null) // Display cover image if available
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Image.file(
                  widget.coverImage!,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            _buildTextField('Title', titleController, 2, 4),

            // Render each author
            ...authorControllers.map((controller) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildTextField('Author', controller, 1, 1),
              );
            }).toList(),

            _buildTextField('Program', programController, 1, 1),
            _buildTextField('Institution', institutionController, 1, 1),
            _buildTextField('Year Submitted', yearController, 1, 1),
            _buildTextField('Description', descriptionController, 1, 1),
            _buildTextField('Abstract', abstractController, 5, null), // Allows dynamic resizing
            _buildTextField('Classification Number', classificationNumberController, 1, 1),
            _buildTextField('Cutter Number', cutterNumberController, 1, 1),
            _buildTextField('Subjects', subjectsController, 5, null), // Allows dynamic resizing
            ElevatedButton(
              onPressed: _saveBook,
              child: Text('Save Book'),
            ),
            if (isUploading)
              CircularProgressIndicator(), // Show loading indicator during upload
          ],
        ),
      ),
    );
  }

  // Helper method to create a TextField with a label
  Widget _buildTextField(String label, TextEditingController controller, int minLines, int? maxLines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        minLines: minLines, // Minimum number of lines to display
        maxLines: maxLines, // Allows dynamic resizing of the field
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10), // Padding inside the text field
        ),
        style: TextStyle(fontSize: 16), // Adjust font size
      ),
    );
  }
}
