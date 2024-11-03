import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:thesis_nlp_app/UserSelectionScreen.dart'; // Import the UserSelectionScreen
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thesis Library App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const UserSelectionScreen(), // Start with the UserSelectionScreen
    );
  }
}
