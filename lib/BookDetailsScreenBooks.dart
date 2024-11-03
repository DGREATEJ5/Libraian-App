import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart'; // For saving files
import 'package:image_picker/image_picker.dart';
import 'package:thesis_nlp_app/services/firestore_service.dart'; // FirestoreService import
import 'package:thesis_nlp_app/services/firebase_storage_service.dart'; // FirebaseStorageService import
import 'dart:ui' as ui;
import 'package:flutter/services.dart'; // For broadcasting media scan intent

class BookDetailsScreenBooks extends StatefulWidget {
  final Map<String, dynamic> book; // Book data (Map) for the screen
  final String docId; // Document ID for Firestore operations
  final String collectionName; // Firestore collection name (e.g., 'books')

  BookDetailsScreenBooks({
    required this.book,
    required this.docId,
    required this.collectionName,
  });

  @override
  _BookDetailsScreenBooksState createState() => _BookDetailsScreenBooksState();
}

class _BookDetailsScreenBooksState extends State<BookDetailsScreenBooks> {
  File? coverImage;
  final FirestoreService _firestoreService = FirestoreService(); // FirestoreService instance
  final FirebaseStorageService _firebaseStorageService = FirebaseStorageService(); // FirebaseStorageService instance
  final GlobalKey _repaintBoundaryKey = GlobalKey(); // Key for capturing the widget

  // Controllers for each field
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorsController = TextEditingController();
  final TextEditingController isbnController = TextEditingController();
  final TextEditingController publisherController = TextEditingController();
  final TextEditingController yearPublishedController = TextEditingController();
  final TextEditingController paginationController = TextEditingController();
  final TextEditingController subjectsController = TextEditingController();
  final TextEditingController cutterNumberController = TextEditingController();
  final TextEditingController editionController = TextEditingController(); // Edition controller
  final TextEditingController volumeController = TextEditingController(); // Volume controller
  final TextEditingController classificationNumberController = TextEditingController(); // Classification Number controller

  String? oldCoverImageUrl; // Track old cover image URL

  @override
  void initState() {
    super.initState();

    // Initialize fields with book data
    oldCoverImageUrl = widget.book['CoverImageUrl'];

    titleController.text = widget.book['Title'] ?? '';
    authorsController.text = widget.book['Authors'] ?? '';
    isbnController.text = widget.book['ISBN'] ?? '';
    publisherController.text = widget.book['Publisher'] ?? '';
    yearPublishedController.text = widget.book['Year Published'] ?? '';
    paginationController.text = widget.book['Pagination'] ?? '';
    subjectsController.text = widget.book['Subjects'] ?? '';
    cutterNumberController.text = widget.book['Cutter Number'] ?? '';
    editionController.text = widget.book['Edition'] ?? ''; // Initialize Edition
    volumeController.text = widget.book['Volume'] ?? '';   // Initialize Volume
    classificationNumberController.text = widget.book['Classification Number'] ?? 'Unknown Classification'; // Initialize Classification Number
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
                    setState(() {
                      coverImage = File(pickedFile.path);
                    });
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
                    setState(() {
                      coverImage = File(pickedFile.path);
                    });
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

  Future<void> _saveAndGoBack() async {
    setState(() {
      widget.book['Title'] = titleController.text;
      widget.book['Authors'] = authorsController.text;
      widget.book['ISBN'] = isbnController.text;
      widget.book['Publisher'] = publisherController.text;
      widget.book['Year Published'] = yearPublishedController.text;
      widget.book['Pagination'] = paginationController.text;
      widget.book['Subjects'] = subjectsController.text;
      widget.book['Cutter Number'] = cutterNumberController.text;
      widget.book['Edition'] = editionController.text;
      widget.book['Volume'] = volumeController.text;
      widget.book['Classification Number'] = classificationNumberController.text;
    });

    // If a new cover image has been selected, upload it to Firebase and update Firestore
    if (coverImage != null) {
      // Delete the old cover image from Firebase Storage if it exists
      if (oldCoverImageUrl != null && oldCoverImageUrl!.isNotEmpty) {
        await _firebaseStorageService.deleteFile(oldCoverImageUrl!);
      }

      // Upload new image to Firebase Storage
      String fileName = 'book_cover_${DateTime.now().millisecondsSinceEpoch}.png';
      String? newCoverImageUrl = await _firebaseStorageService.uploadImage(coverImage!, fileName);

      // Update Firestore with the new image URL
      if (newCoverImageUrl != null) {
        widget.book['CoverImageUrl'] = newCoverImageUrl;
      }
    }

    // Update the book data in Firestore
    try {
      await _firestoreService.updateData(widget.collectionName, widget.docId, widget.book);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book Updated Successfully')),
      );
    } catch (e) {
      print("Error updating data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating book: $e')),
      );
    }

    Navigator.pop(context, widget.book);
  }

  Future<void> _deleteBook() async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Do you want to delete this book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete the cover image from Firebase Storage if it exists
        if (oldCoverImageUrl != null && oldCoverImageUrl!.isNotEmpty) {
          await _firebaseStorageService.deleteFile(oldCoverImageUrl!);
        }

        // Delete the book document from Firestore
        await _firestoreService.deleteData(widget.collectionName, widget.docId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book deleted successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print("Error deleting book: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting book: $e')),
        );
      }
    }
  }

  Future<void> _saveBlueBoxAsImage() async {
    try {
      RenderRepaintBoundary boundary =
      _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Sanitize the book title for the filename
      String sanitizedTitle = titleController.text.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');

      // Save to Pictures folder
      Directory? externalDir = await getExternalStorageDirectory();
      String dirPath = '${externalDir?.parent.parent.parent.parent.path}/Pictures';
      final directory = Directory(dirPath);

      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      final imagePath = '$dirPath/${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      // Trigger media scan to make image appear in Photos app
      await _scanFile(imagePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved as $imagePath')),
      );
    } catch (e) {
      print("Error saving image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
    }
  }

  // Function to trigger a media scan to make the image appear in the Photos app
  Future<void> _scanFile(String path) async {
    const MethodChannel _channel = MethodChannel('com.example.myapp/scanner');
    try {
      await _channel.invokeMethod('scanFile', {'path': path});
    } catch (e) {
      print("Error scanning file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book['Title'] ?? 'Book Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: _pickCoverImage,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteBook,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coverImage != null)
              Image.file(
                coverImage!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else if (widget.book['CoverImageUrl'] != null &&
                widget.book['CoverImageUrl'].isNotEmpty)
              Image.network(
                widget.book['CoverImageUrl'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Image.asset(
                'images/books.png',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 10),

            // Editable fields
            _buildEditableRow('Title', titleController),
            _buildEditableRow('Authors', authorsController),
            _buildEditableRow('ISBN', isbnController),
            _buildEditableRow('Publisher', publisherController),
            _buildEditableRow('Year Published', yearPublishedController),
            _buildEditableRow('Pagination', paginationController),
            _buildEditableRow('Classification Number', classificationNumberController), // Add Classification Number
            _buildEditableRow('Subjects', subjectsController, minLines: 1, maxLines: null),
            _buildEditableRow('Cutter Number', cutterNumberController),
            _buildEditableRow('Edition', editionController),
            _buildEditableRow('Volume', volumeController),

            const SizedBox(height: 20),

            // Display Card wrapped in RepaintBoundary for image capture
            Stack(
              children: [
                RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: Card(
                    color: Colors.blue.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${classificationNumberController.text}\n${cutterNumberController.text}\n${yearPublishedController.text}',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  titleController.text,
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'By ${authorsController.text}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '. __ ${editionController.text} . __ ${volumeController.text} . __',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${publisherController.text}, c${yearPublishedController.text}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  paginationController.text,
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Included index',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${isbnController.text}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  subjectsController.text,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Save button at the top-right corner of the card
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.save),
                    onPressed: _saveBlueBoxAsImage, // Capture and save the widget as an image
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveAndGoBack,
        child: Icon(Icons.save),
      ),
    );
  }

  // Helper method to build a row with editable fields
  Widget _buildEditableRow(String label, TextEditingController controller, {int minLines = 1, int? maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
