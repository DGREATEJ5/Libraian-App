import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'review_and_edit_screen.dart';

class ProcessedEntitiesScreen extends StatefulWidget {
  final Map<String, dynamic> entities; // Allow dynamic for handling lists like multiple authors
  final void Function(Map<String, dynamic>) onSaveBook;

  ProcessedEntitiesScreen({
    required this.entities,
    required this.onSaveBook,
  });

  @override
  _ProcessedEntitiesScreenState createState() => _ProcessedEntitiesScreenState();
}

class _ProcessedEntitiesScreenState extends State<ProcessedEntitiesScreen> {
  final TextEditingController titleController = TextEditingController();
  List<TextEditingController> authorControllers = [];
  final TextEditingController programController = TextEditingController();
  final TextEditingController institutionController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController abstractController = TextEditingController();

  File? coverImage;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    titleController.text = widget.entities['Title'] ?? '';

    // Initialize authors - assumes widget.entities['Authors'] is a List<String>
    if (widget.entities['Authors'] != null && widget.entities['Authors'] is List) {
      List<String> authors = widget.entities['Authors'] as List<String>;
      for (var author in authors) {
        authorControllers.add(TextEditingController(text: author));
      }
    } else {
      authorControllers.add(TextEditingController()); // Add an empty controller if no authors
    }

    programController.text = widget.entities['Program'] ?? '';
    institutionController.text = widget.entities['Institution'] ?? '';
    yearController.text = widget.entities['Year Submitted'] ?? '';
    descriptionController.text = widget.entities['Description'] ?? '';
    abstractController.text = widget.entities['Abstract'] ?? '';

    // If a cover image path is already present, load the file
    if (widget.entities['CoverImagePath'] != null && widget.entities['CoverImagePath']!.isNotEmpty) {
      coverImage = File(widget.entities['CoverImagePath']!);
    }
  }

  Future<void> _pickCoverImage() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a Photo'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    bool confirm = await _reviewImage(File(pickedFile.path));
                    if (confirm) {
                      setState(() {
                        coverImage = File(pickedFile.path);
                      });
                    }
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    bool confirm = await _reviewImage(File(pickedFile.path));
                    if (confirm) {
                      setState(() {
                        coverImage = File(pickedFile.path);
                      });
                    }
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _reviewImage(File image) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Review Image'),
          content: Image.file(image),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Retake'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Use This Photo'),
            ),
          ],
        );
      },
    );
  }

  void _goToReviewScreen() {
    // Collect the current entity data and pass the cover image file (without uploading)
    Map<String, dynamic> currentEntities = {
      'Title': titleController.text,
      'Authors': authorControllers.map((controller) => controller.text).toList(), // Store authors as list
      'Program': programController.text,
      'Institution': institutionController.text,
      'Year Submitted': yearController.text,
      'Description': descriptionController.text,
      'Abstract': abstractController.text,
    };

    // Navigate to the review screen, passing the current entities and the cover image file
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewAndEditScreen(
          entities: currentEntities,
          coverImage: coverImage, // Pass the cover image file
          onSaveBook: widget.onSaveBook,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Processed Entities'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _goToReviewScreen, // Navigate to review screen
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              maxLines: null,
              minLines: 2,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),

            // Render each author
            ...authorControllers.map((controller) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Author',
                    border: OutlineInputBorder(),
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 10),
            TextField(
              controller: programController,
              decoration: InputDecoration(
                labelText: 'Program',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: institutionController,
              decoration: InputDecoration(
                labelText: 'Institution',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: yearController,
              decoration: InputDecoration(
                labelText: 'Year Submitted',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: abstractController,
              maxLines: null,
              minLines: 5,
              decoration: InputDecoration(
                labelText: 'Abstract',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickCoverImage,
              child: Text('Add Cover Image'),
            ),
            SizedBox(height: 20),
            if (coverImage != null)
              Image.file(
                coverImage!,
                height: 150,
              ),
          ],
        ),
      ),
    );
  }
}
