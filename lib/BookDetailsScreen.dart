import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:thesis_nlp_app/services/firestore_service.dart';
import 'package:thesis_nlp_app/services/firebase_storage_service.dart';

class BookDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final String docId;
  final String collectionName;

  BookDetailsScreen({
    required this.book,
    required this.docId,
    required this.collectionName,
  });

  @override
  _BookDetailsScreenState createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  File? coverImage;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _firebaseStorageService = FirebaseStorageService();
  final GlobalKey _repaintBoundaryKey = GlobalKey(); // Key for capturing the blue box

  final TextEditingController classificationNumberController = TextEditingController();
  final TextEditingController cutterNumberController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  List<TextEditingController> authorControllers = [];
  final TextEditingController programController = TextEditingController();
  final TextEditingController institutionController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController abstractController = TextEditingController();

  String? oldCoverImageUrl;

  @override
  void initState() {
    super.initState();

    oldCoverImageUrl = widget.book['CoverImageUrl'];

    classificationNumberController.text = widget.book['Classification Number'] ?? '';
    cutterNumberController.text = widget.book['Cutter Number'] ?? '';
    yearController.text = widget.book['Year Submitted'] ?? '';
    titleController.text = widget.book['Title'] ?? '';

    if (widget.book['Authors'] != null && widget.book['Authors'] is List) {
      List<String> authors = List<String>.from(widget.book['Authors']);
      for (var author in authors) {
        authorControllers.add(TextEditingController(text: author));
      }
    } else {
      authorControllers.add(TextEditingController());
    }

    programController.text = widget.book['Program'] ?? '';
    institutionController.text = widget.book['Institution'] ?? '';
    descriptionController.text = widget.book['Description'] ?? '';
    subjectController.text = widget.book['Subjects'] ?? '';
    abstractController.text = widget.book['Abstract'] ?? '';
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

  Future<void> _saveBlueBoxAsImage() async {
    try {
      RenderRepaintBoundary boundary =
      _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save the image in the Pictures directory
      Directory? externalDir = await getExternalStorageDirectory();
      String dirPath = '${externalDir?.parent.parent.parent.parent.path}/Pictures';
      final directory = Directory(dirPath);

      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      String sanitizedTitle = titleController.text.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final imagePath = '$dirPath/${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to $imagePath')),
      );
    } catch (e) {
      print("Error saving image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
    }
  }

  Future<void> _saveAndGoBack() async {
    setState(() {
      widget.book['Classification Number'] = classificationNumberController.text;
      widget.book['Cutter Number'] = cutterNumberController.text;
      widget.book['Year Submitted'] = yearController.text;
      widget.book['Title'] = titleController.text;
      widget.book['Authors'] = authorControllers.map((controller) => controller.text).toList();
      widget.book['Program'] = programController.text;
      widget.book['Institution'] = institutionController.text;
      widget.book['Description'] = descriptionController.text;
      widget.book['Subjects'] = subjectController.text;
      widget.book['Abstract'] = abstractController.text;
    });

    if (coverImage != null) {
      if (oldCoverImageUrl != null && oldCoverImageUrl!.isNotEmpty) {
        await _firebaseStorageService.deleteFile(oldCoverImageUrl!);
      }

      String fileName = 'book_cover_${DateTime.now().millisecondsSinceEpoch}.png';
      String? newCoverImageUrl = await _firebaseStorageService.uploadImage(coverImage!, fileName);

      if (newCoverImageUrl != null) {
        widget.book['CoverImageUrl'] = newCoverImageUrl;
      }
    }

    try {
      await _firestoreService.updateData(widget.collectionName, widget.docId, widget.book);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data Updated')),
      );
    } catch (e) {
      print("Error updating data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating: $e')),
      );
    }

    Navigator.pop(context, widget.book);
  }

  Future<void> _deleteThesis() async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Thesis'),
        content: const Text('Do you want to delete this processed thesis?'),
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
        if (oldCoverImageUrl != null && oldCoverImageUrl!.isNotEmpty) {
          await _firebaseStorageService.deleteFile(oldCoverImageUrl!);
        }

        await _firestoreService.deleteData(widget.collectionName, widget.docId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thesis deleted successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print("Error deleting thesis: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting thesis: $e')),
        );
      }
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
            onPressed: _deleteThesis,
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
            else if (widget.book['CoverImageUrl'] != null)
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

            _buildEditableRow('Classification Number', classificationNumberController),
            _buildEditableRow('Cutter Number', cutterNumberController),
            _buildEditableRow('Year Submitted', yearController),
            _buildEditableRow('Title', titleController),
            ...authorControllers.map((controller) => _buildEditableRow('Author', controller)).toList(),
            _buildEditableRow('Program', programController),
            _buildEditableRow('Institution', institutionController),
            _buildEditableRow('Description', descriptionController),
            _buildEditableRow('Subjects', subjectController, minLines: 3, maxLines: null), // Adjusted for Subjects
            _buildEditableRow('Abstract', abstractController, minLines: 5, maxLines: null),

            const SizedBox(height: 20),

            // Blue box with Save button
            Stack(
              children: [
                RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: Card(
                    color: Colors.blue.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              '${classificationNumberController.text}\n${cutterNumberController.text}\n${yearController.text}',
                              style: TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  authorControllers.map((c) => c.text).join(', '),
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  titleController.text,
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '/${authorControllers.map((c) => c.text).join(', ')}, ${yearController.text}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${descriptionController.text} p.; Thesis (${programController.text}) - ${institutionController.text}, ${yearController.text}.',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              '${subjectController.text}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.save),
                    onPressed: _saveBlueBoxAsImage,
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
