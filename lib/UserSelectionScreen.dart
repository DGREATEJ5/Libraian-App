import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Import Lottie package
import 'HomeScreen.dart'; // Import the HomeScreen for Librarians
import 'StudentScreen.dart'; // Import the new StudentScreen

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({Key? key}) : super(key: key);

  @override
  _UserSelectionScreenState createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> with TickerProviderStateMixin {
  double _opacityTitle = 0.0;
  double _opacityImage = 0.0;
  double _opacityDescription = 0.0;
  double _opacityLottie = 0.0;
  double _opacityButtons = 0.0;

  @override
  void initState() {
    super.initState();
    _runAnimations();
  }

  void _runAnimations() async {
    // Animate the title
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _opacityTitle = 1.0;
    });

    // Animate the logo
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _opacityImage = 1.0;
    });

    // Animate the description
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _opacityDescription = 1.0;
    });

    // Animate the Lottie animation
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _opacityLottie = 1.0;
    });

    // Animate the buttons
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _opacityButtons = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent, // Set the background color to blue
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0, // Flat AppBar
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Welcome message
          AnimatedOpacity(
            opacity: _opacityTitle,
            duration: const Duration(milliseconds: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: const [
                  Text(
                    'Welcome To',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Logo animation
          AnimatedOpacity(
            opacity: _opacityImage,
            duration: const Duration(milliseconds: 800),
            child: Image.asset(
              'images/branding2.png',
              height: 120, // Adjust size
            ),
          ),
          // Description animation
          AnimatedOpacity(
            opacity: _opacityDescription,
            duration: const Duration(milliseconds: 800),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                'An innovative app for managing books and theses.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Bigger Lottie Animation (below description)
          AnimatedOpacity(
            opacity: _opacityLottie,
            duration: const Duration(milliseconds: 800),
            child: Lottie.asset(
              'lottie/Animation - 1727502887001.json', // Path to your Lottie animation
              width: 250, // Increased width
              height: 250, // Increased height
              fit: BoxFit.cover,
            ),
          ),
          const Spacer(),
          // Buttons animation
          AnimatedOpacity(
            opacity: _opacityButtons,
            duration: const Duration(milliseconds: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      },
                      child: _buildModernButton(
                        'I am a Librarian',
                        Colors.blue.shade700,
                        Colors.blue.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const StudentScreen()),
                        );
                      },
                      child: _buildModernButton(
                        'I am a Researcher',
                        Colors.green.shade700,
                        Colors.green.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom method to build modern buttons with gradient and shadow
  Widget _buildModernButton(String text, Color startColor, Color endColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25), // More rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
