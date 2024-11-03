import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:thesis_nlp_app/Books/ProcessedBookEntitiesScreen.dart'; // Import the screen
import 'package:thesis_nlp_app/services/book_text_processing_service.dart'; // Import the book processing service
import 'package:thesis_nlp_app/services/gemini_service_books.dart'; // Import the Gemini service for books
import 'package:flutter_cohere/flutter_cohere.dart'; // Import Cohere package for API calls

class BookRecognizerScreen extends StatefulWidget {
  final List<File> images; // List to accept multiple images
  final Function(List<Map<String, String>>) onSaveBook; // Added callback for saving

  BookRecognizerScreen({Key? key, required this.images, required this.onSaveBook}) : super(key: key);

  @override
  State<BookRecognizerScreen> createState() => _BookRecognizerScreenState();
}

class _BookRecognizerScreenState extends State<BookRecognizerScreen> {
  late TextRecognizer textRecognizer; // Instance of TextRecognizer for extracting text
  String extractedText = ""; // Store all extracted texts in a single string
  TextEditingController textController = TextEditingController(); // Controller to manage the extracted text
  final CohereClient cohereClient = CohereClient(apiKey: 'YOUR-SECRET-API'); // Initialize the Cohere client

  @override
  void initState() {
    super.initState();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin); // Initialize the TextRecognizer
    extractTextFromImages(); // Start extracting text from images
  }

  // Method to perform text extraction on all images and combine the results
  void extractTextFromImages() async {
    for (var image in widget.images) {
      final inputImage = InputImage.fromFile(image);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      // Combine all recognized text into a single string
      extractedText += recognizedText.text + "\n\n";
    }

    // Update the text controller with the combined results
    setState(() {
      textController.text = extractedText;
    });

    // Debugging: Print the raw extracted text
    print("Extracted Text: $extractedText");
  }

  // Function to process text, query Cohere for classification number and subjects, and navigate to processed entities screen
  void processText() async {
    try {
      // Use the Gemini service to process the extracted text
      final GeminiServiceBooks geminiService = GeminiServiceBooks('YOUR-SECRET-API'); // Replace with your API key

      // Call the Gemini service with the extracted text and the specific query
      String? geminiResult = await geminiService.extractBookDetails(extractedText);

      // Debugging: Print the Gemini result
      print("Gemini Result: $geminiResult");

      // Use Cohere to extract the Classification Number (DDC)
      String? classificationNumber = await _getClassificationNumberFromCohere(extractedText);

      // Debugging: Print the Classification Number
      print("Classification Number from Cohere: $classificationNumber");

      // Use Cohere to extract Subjects
      String? subjects = await _getSubjectsFromCohere(extractedText);

      // Debugging: Print the Subjects
      print("Subjects from Cohere: $subjects");

      if (geminiResult != null) {
        // Use the book_text_processing_service to process the Gemini result
        Map<String, dynamic> data = await processBookText(geminiResult); // Call your API service
        List<Map<String, String>> formattedEntities = _formatEntities(data); // Format entities to be displayed

        // If classification number is retrieved, add it to the entities
        if (classificationNumber != null) {
          formattedEntities.add({
            'label': 'Classification Number',
            'text': classificationNumber
          });
        }

        // If subjects are retrieved, add them to the entities
        if (subjects != null) {
          formattedEntities.add({
            'label': 'Subjects',
            'text': subjects
          });
        }

        // Add Pagination entity (for manual input)
        formattedEntities.add({
          'label': 'Pagination',
          'text': '',  // Leave empty for user to input manually
        });

        // Navigate to ProcessedBookEntitiesScreen with formatted data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessedBookEntitiesScreen(
              entities: formattedEntities,
              onSave: (updatedEntities) {
                // Save and pass the extracted book entities back using the callback
                widget.onSaveBook(updatedEntities);
              },
            ),
          ),
        );
      } else {
        // If Gemini result is null, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: No response from Gemini")),
        );
      }
    } catch (e) {
      // Display an error if processing fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing text: $e")),
      );
      // Debugging: Print the error
      print("Error: $e");
    }
  }

  // Function to extract Classification Number using Cohere API
  Future<String?> _getClassificationNumberFromCohere(String extractedText) async {
    try {
      final response = await cohereClient.generate(
        model: 'command-xlarge',
        prompt: 'From this text can u get the DDC or classification number, number only \n\n$extractedText',
        temperature: 0.3,
        maxTokens: 50,
      );

      // Check if the response contains text with the classification number
      if (response != null && response.containsKey('generations')) {
        var generations = response['generations'] as List<dynamic>;

        if (generations.isNotEmpty) {
          var generationText = generations[0]['text']?.toString().trim() ?? '';

          // Use a regex to extract only the numeric part (like "551.48")
          RegExp regExp = RegExp(r'\d+(\.\d+)?');
          Match? match = regExp.firstMatch(generationText);

          return match != null ? match.group(0) : generationText;
        }
      }

      return null;
    } catch (e) {
      print('Error using Cohere API: $e');
      return null;
    }
  }

  // Function to extract Subjects using Cohere API
  Future<String?> _getSubjectsFromCohere(String extractedText) async {
    try {
      final response = await cohereClient.generate(
        model: 'command-xlarge',
        prompt: 'From this text can you get the Subjects and number them (MAX OF 3 SUBJECTS ONLY), show the numbered only no others \n\n$extractedText',
        temperature: 0.3,
        maxTokens: 100,
      );

      // Check if the response contains text with the subjects
      if (response != null && response.containsKey('generations')) {
        var generations = response['generations'] as List<dynamic>;

        if (generations.isNotEmpty) {
          var generationText = generations[0]['text']?.toString().trim() ?? '';

          // Use a regular expression to extract only lines that start with a number (numbered subjects)
          RegExp regExp = RegExp(r'^\d+\.\s.*$', multiLine: true);
          Iterable<Match> matches = regExp.allMatches(generationText);

          // Combine all matches (subjects) into a single string
          String subjects = matches.map((match) => match.group(0) ?? '').join('\n');

          return subjects.isNotEmpty ? subjects : null;
        }
      }

      return null;
    } catch (e) {
      print('Error using Cohere API for subjects: $e');
      return null;
    }
  }


  // Method to format the entities returned from processBookText
  List<Map<String, String>> _formatEntities(Map<String, dynamic> data) {
    List<Map<String, String>> formattedEntities = [];

    if (data.containsKey('entities')) {
      for (var entity in data['entities']) {
        // Replace "Year_of_publication" with "Year Published"
        String label = entity['label'];
        if (label == "Year_of_publication") {
          label = "Year Published";
        }

        formattedEntities.add({
          'label': label,
          'text': entity['text']
        });
      }
    }

    return formattedEntities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: const Text('Book Recognizer', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              bool proceed = await _showProceedDialog();
              if (proceed) {
                processText();
              }
            },
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
                            'Extracted Text',
                            style: TextStyle(color: Colors.white, fontSize: 17),
                          ),
                          InkWell(
                            onTap: () {
                              // Copy the extracted text to clipboard
                              Clipboard.setData(ClipboardData(text: textController.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Copied to clipboard")),
                              );
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: textController,
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

  // Show confirmation dialog before processing
  Future<bool> _showProceedDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Proceed to Automation?"),
          content: Text("Do you want to proceed with automated processing?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Yes"),
            ),
          ],
        );
      },
    );
  }
}
