import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'services/text_processing_service.dart'; // Import the text processing service
import 'ProcessedEntitiesScreen.dart';

class RecognizerScreen extends StatefulWidget {
  final List<File> images; // Accept multiple images
  final Function(Map<String, dynamic>) onSaveBook; // Callback for saving book, now accepts dynamic types for more flexibility

  RecognizerScreen({Key? key, required this.images, required this.onSaveBook}) : super(key: key);

  @override
  State<RecognizerScreen> createState() => _RecognizerScreenState();
}

class _RecognizerScreenState extends State<RecognizerScreen> {
  late TextRecognizer textRecognizer;
  String combinedResults = ""; // Store all extracted texts in a single string
  TextEditingController controller = TextEditingController(); // Single controller for the entire text

  @override
  void initState() {
    super.initState();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    doTextRecognition();
  }

  // Method to perform text recognition on all images and combine the results
  doTextRecognition() async {
    for (var image in widget.images) {
      final inputImage = InputImage.fromFile(image);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      // Combine all recognized text into a single string
      combinedResults += recognizedText.text + "\n\n";
    }

    // Update the controller with the combined results
    setState(() {
      controller.text = combinedResults;
    });
  }

  // Function to handle the check button action
  void _onCheckButtonPressed() async {
    bool proceed = await _showProceedDialog(); // Show confirmation dialog
    if (proceed) {
      // Use the text_processing_service to get formatted entities
      try {
        Map<String, dynamic> data = await processText(controller.text); // Call the service
        Map<String, dynamic> formattedEntities = _formatEntities(data); // Allow dynamic to handle multiple authors

        // Navigate to ProcessedEntitiesScreen with formatted data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessedEntitiesScreen(
              entities: formattedEntities, // Send formatted entities, now dynamic
              onSaveBook: widget.onSaveBook, // Pass the save callback
            ),
          ),
        );
      } catch (e) {
        // Display an error if processing fails
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing text: $e')));
      }
    }
  }

  // Function to show a confirmation dialog
  Future<bool> _showProceedDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Proceed to Automation"),
          content: const Text("Do you want to proceed to automate this?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  // Helper function to format the entities from the response data
  Map<String, dynamic> _formatEntities(Map<String, dynamic> data) {
    // Format the entities into a more user-friendly map
    Map<String, dynamic> entities = {};
    List<String> authors = []; // List to store multiple authors

    for (var entity in data['entities']) {
      if (entity['label'] == 'TITLE') entities['Title'] = entity['text'];
      if (entity['label'] == 'AUTHOR') authors.add(entity['text']); // Add each author to the list
      if (entity['label'] == 'PROGRAM') entities['Program'] = entity['text'];
      if (entity['label'] == 'INSTITUTION') entities['Institution'] = entity['text'];
      if (entity['label'] == 'YEAR_SUBMITTED') entities['Year Submitted'] = entity['text'];
      if (entity['label'] == 'DESCRIPTION') entities['Description'] = entity['text'];
      if (entity['label'] == 'ABSTRACT') entities['Abstract'] = entity['text'];
    }

    // Add the list of authors to the entities map
    entities['Authors'] = authors;

    return entities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: const Text('Recognizer', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _onCheckButtonPressed, // Handle the check button press
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display images in a horizontal scroll view
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.file(widget.images[index]),
                  );
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.all(10),
              color: Colors.grey.shade300,
              child: Column(
                children: [
                  Container(
                    color: Colors.blueAccent,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(
                            Icons.document_scanner,
                            color: Colors.white,
                          ),
                          const Text(
                            'Results',
                            style: TextStyle(color: Colors.white, fontSize: 17),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: controller.text));
                              SnackBar sn = SnackBar(content: Text("Copied"));
                              ScaffoldMessenger.of(context).showSnackBar(sn);
                            },
                            child: const Icon(
                              Icons.copy,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Improved label for the TextField
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Edit Recognized Text',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
