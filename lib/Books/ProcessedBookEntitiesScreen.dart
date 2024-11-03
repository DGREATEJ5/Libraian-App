import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'BookReviewAndEditScreen.dart';
import 'package:thesis_nlp_app/services/cutter_number_service.dart'; // Import CutterNumberService

class ProcessedBookEntitiesScreen extends StatefulWidget {
  final List<Map<String, String>> entities;
  final Function(List<Map<String, String>>) onSave;

  ProcessedBookEntitiesScreen({required this.entities, required this.onSave});

  @override
  _ProcessedBookEntitiesScreenState createState() => _ProcessedBookEntitiesScreenState();
}

class _ProcessedBookEntitiesScreenState extends State<ProcessedBookEntitiesScreen> {
  late List<Map<String, String>> _editableEntities;
  File? coverImage; // Cover image file
  String cutterNumber = ''; // Variable to store Cutter Number

  late CutterNumberService cutterNumberService;

  // Temporary variables to store values of Classification Number, Subjects, and Pagination
  String temporaryClassificationNumber = '';
  String temporarySubjects = '';
  String temporaryPagination = '';

  @override
  void initState() {
    super.initState();
    _editableEntities = List<Map<String, String>>.from(widget.entities);

    // Initialize CutterNumberService with the base URL
    cutterNumberService = CutterNumberService('YOUR-SECRET-API');

    // Store temporary values for Classification Number, Subjects, and Pagination
    temporaryClassificationNumber = _getEntityText('Classification Number');
    temporarySubjects = _getEntityText('Subjects');
    temporaryPagination = _getEntityText('Pagination');

    // Remove Classification Number, Subjects, and Pagination from display in this screen
    _editableEntities.removeWhere((entity) =>
    entity['label'] == 'Classification Number' ||
        entity['label'] == 'Subjects' ||
        entity['label'] == 'Pagination'
    );
  }

  String _getEntityText(String label) {
    return _editableEntities.firstWhere(
            (element) => element['label'] == label,
        orElse: () => {'text': ''}
    )['text'] ?? '';
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

  Future<void> _fetchOpenLibraryData() async {
    String isbn = _getEntityText('ISBN');
    String title = _getEntityText('Title');
    String author = _getEntityText('Authors').split(',').first.trim(); // Take the first author and trim spaces

    // Fetch Cutter Number for the first author
    try {
      cutterNumber = await cutterNumberService.getCutterNumber(author, title) ?? 'N/A';
    } catch (e) {
      cutterNumber = 'N/A';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching Cutter Number: $e")),
      );
    }

    Map<String, dynamic> bookDetails = await _fetchBookDetails(isbn: isbn, title: title);

    // Use temporary values if OpenLibrary doesn't return the data
    String classificationNumber = bookDetails['dewey_decimal_class'] ?? temporaryClassificationNumber;
    String subjects = (bookDetails['subjects'] as List?)?.join(', ') ?? temporarySubjects;
    String pagination = bookDetails['pagination'] ?? temporaryPagination;

    // Include the cover image path if available
    if (coverImage != null) {
      _editableEntities.add({'label': 'CoverImagePath', 'text': coverImage!.path});
    }

    // Navigate to the next screen with the gathered data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookReviewAndEditScreen(
          entities: _editableEntities,
          additionalData: {
            'Cutter Number': cutterNumber,
            'Classification Number': classificationNumber,
            'Subjects': subjects,
            'Pagination': pagination,
          },
          onSave: widget.onSave,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchBookDetails({required String isbn, required String title}) async {
    Map<String, dynamic> bookDetails = {};

    // Try to fetch by ISBN
    if (isbn.isNotEmpty) {
      bookDetails = await _getBookDetailsByISBN(isbn);
    }

    // Check if data is incomplete, fall back to title if needed
    if (bookDetails.isEmpty ||
        bookDetails['subjects'] == null ||
        bookDetails['subjects'].isEmpty ||
        bookDetails['dewey_decimal_class'] == null ||
        bookDetails['dewey_decimal_class'].isEmpty ||
        bookDetails['pagination'] == null ||
        bookDetails['pagination'].isEmpty) {
      // Try to fetch by Title if ISBN data is incomplete
      if (title.isNotEmpty) {
        bookDetails = await _getBookDetailsByTitle(title);
      }
    }

    return bookDetails;
  }

  Future<Map<String, dynamic>> _getBookDetailsByISBN(String isbn) async {
    try {
      final isbnUrl = Uri.parse('https://openlibrary.org/isbn/$isbn.json');
      final isbnResponse = await http.get(isbnUrl);

      if (isbnResponse.statusCode != 200) {
        return {};
      }

      final bookDetails = jsonDecode(isbnResponse.body);

      // Extract title
      final title = bookDetails['title'] ?? '';

      // Extract authors using their references
      List<String> authorNames = [];
      if (bookDetails['authors'] != null) {
        for (var author in bookDetails['authors']) {
          final authorUrl = Uri.parse('https://openlibrary.org${author['key']}.json');
          final authorResponse = await http.get(authorUrl);
          if (authorResponse.statusCode == 200) {
            final authorData = jsonDecode(authorResponse.body);
            authorNames.add(authorData['name']);
          }
        }
      }

      // Extract subjects
      final subjects = List<String>.from(bookDetails['subjects'] ?? []);

      // Extract Dewey Decimal Class and Pagination
      final deweyDecimalClass = bookDetails['dewey_decimal_class'] ?? [''];
      final pagination = bookDetails['pagination'] ?? '';

      return {
        "title": title,
        "authors": authorNames,
        "subjects": subjects,
        "dewey_decimal_class": deweyDecimalClass.isNotEmpty ? deweyDecimalClass[0] : '',
        "pagination": pagination,
      };
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getBookDetailsByTitle(String title) async {
    try {
      final searchUrl = Uri.parse('https://openlibrary.org/search.json?title=$title');
      final searchResponse = await http.get(searchUrl);

      if (searchResponse.statusCode != 200) {
        return {};
      }

      final searchData = jsonDecode(searchResponse.body);
      if (searchData['numFound'] == 0) {
        return {};
      }

      // Get the first book entry from the search results
      final bookEntry = searchData['docs'][0];
      final olid = bookEntry['key'];
      final editionKeys = List<String>.from(bookEntry['edition_key'] ?? []);

      if (olid == null) {
        return {};
      }

      final detailsUrl = Uri.parse('https://openlibrary.org$olid.json');
      final detailsResponse = await http.get(detailsUrl);

      if (detailsResponse.statusCode != 200) {
        return {};
      }

      final bookDetails = jsonDecode(detailsResponse.body);

      // Extract authors
      List<String> authorNames = [];
      if (bookDetails['authors'] != null) {
        for (var author in bookDetails['authors']) {
          final authorUrl = Uri.parse('https://openlibrary.org${author['author']['key']}.json');
          final authorResponse = await http.get(authorUrl);
          if (authorResponse.statusCode == 200) {
            final authorData = jsonDecode(authorResponse.body);
            authorNames.add(authorData['name']);
          }
        }
      }

      // Extract subjects
      final subjects = List<String>.from(bookDetails['subjects'] ?? []);

      // Choose the most relevant edition
      String selectedDeweyDecimalClass = 'Unknown';
      String selectedPagination = 'Unknown';

      for (String editionKey in editionKeys) {
        final editionUrl = Uri.parse('https://openlibrary.org/books/$editionKey.json');
        final editionResponse = await http.get(editionUrl);
        if (editionResponse.statusCode == 200) {
          final editionDetails = jsonDecode(editionResponse.body);
          final deweyDecimalClass = editionDetails['dewey_decimal_class'] ?? ['Unknown'];
          final pagination = editionDetails['pagination'] ?? 'Unknown';

          // Example selection logic
          if (deweyDecimalClass[0] != 'Unknown' && pagination != 'Unknown') {
            selectedDeweyDecimalClass = deweyDecimalClass[0];
            selectedPagination = pagination;
            break;
          }
        }
      }

      return {
        "title": title,
        "authors": authorNames,
        "subjects": subjects,
        "dewey_decimal_class": selectedDeweyDecimalClass,
        "pagination": selectedPagination,
      };
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: const Text('Processed Entities', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _fetchOpenLibraryData,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _editableEntities.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: TextField(
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
          ),
          // Cover Image Picker Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _pickCoverImage,
              child: Text('Add Cover Image'),
            ),
          ),
          if (coverImage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.file(
                coverImage!,
                height: 150,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
