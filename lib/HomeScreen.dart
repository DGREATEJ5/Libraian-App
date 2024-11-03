import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thesis_nlp_app/Books/BookRecognizerScreen.dart';
import 'package:thesis_nlp_app/RecognizerScreen.dart';
import 'package:thesis_nlp_app/SavedBooksScreen.dart';
import 'package:thesis_nlp_app/services/firestore_service.dart'; // Import the FirestoreService
import 'package:thesis_nlp_app/services/firebase_storage_service.dart'; // Import Firebase Storage service
import 'package:thesis_nlp_app/Visualizations.dart'; // Import the Visualizations screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ImagePicker imagePicker;
  late List<CameraDescription> _cameras;
  late CameraController controller;
  bool isInit = false;
  List<File> images = []; // List to store multiple images
  List<String> imageUrls = []; // List to store uploaded image URLs

  final FirestoreService _firestoreService = FirestoreService(); // Initialize FirestoreService
  final FirebaseStorageService _firebaseStorageService = FirebaseStorageService(); // Initialize Firebase Storage Service

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    initializeCamera();
  }

  initializeCamera() async {
    _cameras = await availableCameras();
    controller = CameraController(_cameras[0], ResolutionPreset.high);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        isInit = true;
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
          // Handle access errors here
            break;
          default:
          // Handle other errors here
            break;
        }
      }
    });
  }

  // Mode selection variables
  bool books = false;
  bool recognize = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen', style: TextStyle(color: Colors.white)),
        centerTitle: true, // Center the title
        actions: [
          IconButton(
            icon: const Icon(Icons.book, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedBooksScreen(), // No need to pass savedBooks or savedTheses
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white), // Visualization icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Visualizations(), // Navigate to Visualizations screen
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.blue, // Updated to blue
      ),
      body: Column(
        children: [
          // Top Menu for Mode Selection
          Card(
            color: Colors.blue, // Updated to blue
            margin: const EdgeInsets.all(8), // Reduce margin for more camera space
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: buildMenuButton('Book', Icons.scanner, books, () {
                      setState(() {
                        books = true;
                        recognize = false;
                      });
                    }),
                  ),
                  Expanded(
                    child: buildMenuButton('Thesis', Icons.document_scanner, recognize, () {
                      setState(() {
                        books = false;
                        recognize = true;
                      });
                    }),
                  ),
                ],
              ),
            ),
          ),
          // Expanded Camera Preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8), // Reduce side padding
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: isInit
                          ? AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      )
                          : const Center(child: CircularProgressIndicator()), // Show loading indicator while initializing
                    ),
                    // Overlay image set to cover the entire container
                    Positioned.fill(
                      child: Image.asset(
                        "images/f1.png",
                        fit: BoxFit.fill, // Cover to ensure it fills the space
                      ),
                    ),
                    // Animated line effect
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.white,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                      ).animate(onPlay: (controller) => controller.repeat()).moveY(
                          begin: 0,
                          end: MediaQuery.of(context).size.height - 300,
                          duration: 2000.ms),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom Control Panel
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, left: 8.0, right: 8.0), // Add padding at the bottom for balance
            child: Card(
              color: Colors.blue, // Updated to blue
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 50, // Maintain space for the check icon
                      child: images.isNotEmpty
                          ? InkWell(
                        child: const Icon(
                          Icons.check,
                          size: 35,
                          color: Colors.white,
                        ),
                        onTap: () {
                          processImages(); // Use this button to process images
                        },
                      )
                          : Container(), // Empty container to reserve space
                    ),
                    InkWell(
                      child: const Icon(
                        Icons.camera,
                        size: 50,
                        color: Colors.white,
                      ),
                      onTap: () async {
                        // Capture multiple images using the camera
                        final XFile? file = await controller.takePicture();
                        if (file != null) {
                          final croppedImage = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageCropper(
                                image: File(file.path).readAsBytesSync(),
                              ),
                            ),
                          );

                          if (croppedImage != null) {
                            setState(() {
                              images.add(File(file.path)..writeAsBytesSync(croppedImage));
                            });

                            // Ask if the user wants to add another image
                            bool addMore = await _askAddMoreImages(context);
                            if (!addMore) {
                              // Navigate based on mode
                              processImages();
                            }
                          }
                        }
                      },
                    ),
                    InkWell(
                      child: const Icon(
                        Icons.image_outlined,
                        size: 35,
                        color: Colors.white,
                      ),
                      onTap: () async {
                        // Pick multiple images from the gallery
                        final List<XFile>? files = await imagePicker.pickMultiImage();
                        if (files != null && files.isNotEmpty) {
                          for (var file in files) {
                            final croppedImage = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageCropper(
                                  image: File(file.path).readAsBytesSync(),
                                ),
                              ),
                            );

                            if (croppedImage != null) {
                              setState(() {
                                images.add(File(file.path)..writeAsBytesSync(croppedImage));
                              });
                            }
                          }

                          // Ask if the user wants to add more images after picking
                          bool addMore = await _askAddMoreImages(context);
                          if (!addMore) {
                            // Navigate based on mode
                            processImages();
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to build menu button
  Widget buildMenuButton(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 25,
            color: isActive ? Colors.black : Colors.white,
          ),
          Text(
            label,
            style: TextStyle(color: isActive ? Colors.black : Colors.white),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Future<bool> _askAddMoreImages(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Another Image?"),
          content: const Text("Would you like to add another image?"),
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

  // Upload images to Firebase Storage before navigating
  Future<void> _uploadImages() async {
    for (var image in images) {
      String? imageUrl = await _firebaseStorageService.uploadImage(image, DateTime.now().toIso8601String());
      if (imageUrl != null) {
        imageUrls.add(imageUrl); // Store image URLs
      }
    }
  }

  Future<void> navigateToRecognizerScreen() async {
    if (images.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) {
            return RecognizerScreen(
              images: images, // Pass images
              onSaveBook: (thesis) {
                setState(() {
                  images.clear(); // Clear images after saving
                  _firestoreService.saveData('theses', thesis); // Save to Firestore
                });
                Navigator.pop(context); // Return to HomeScreen after saving
              },
            );
          },
        ),
      );
    }
  }

  Future<void> navigateToBookRecognizerScreen() async {
    if (images.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) {
            return BookRecognizerScreen(
              images: images, // Pass the images to the BookRecognizerScreen
              onSaveBook: (bookEntities) {
                // Map to store the final book data
                Map<String, String> bookData = {};
                // Temporary list to store authors if multiple entries exist
                List<String> authorsList = [];

                for (var entity in bookEntities) {
                  String label = entity['label'] ?? '';
                  String text = entity['text'] ?? '';

                  if (label == 'Authors') {
                    // Collect all authors
                    authorsList.add(text);
                  } else {
                    // Add other entities to the map
                    bookData[label] = text;
                  }
                }

                // Combine all authors into a single string
                if (authorsList.isNotEmpty) {
                  bookData['Authors'] = authorsList.join(', ');
                }

                setState(() {
                  images.clear(); // Clear images after saving
                  _firestoreService.saveData('books', bookData); // Save to Firestore
                });

                Navigator.pop(context); // Return to HomeScreen after saving
              },
            );
          },
        ),
      );
    }
  }

  // Updated function to process and navigate based on multiple images
  Future<void> processImages() async {
    if (recognize) {
      await navigateToRecognizerScreen(); // Recognize thesis
    } else if (books) {
      await navigateToBookRecognizerScreen(); // Recognize books
    }
  }
}
