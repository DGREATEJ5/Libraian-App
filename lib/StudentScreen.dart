import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thesis_nlp_app/services/firestore_service.dart';
import 'ThesisDetailsStudentScreen.dart';
import 'BookDetailsStudentScreen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({Key? key}) : super(key: key);

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  String selectedFolder = '';
  String query = '';
  final FirestoreService firestoreService = FirestoreService();
  String startRange = ''; // Store the starting range for classification
  String endRange = ''; // Store the ending range for classification
  int? yearStart; // Store the selected start year
  int? yearEnd; // Store the selected end year
  String selectedSubClass = ''; // Store the selected subclass title

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: selectedFolder.isEmpty
          ? null
          : AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() {
                  selectedFolder = '';
                  query = ''; // Reset search query
                  startRange = ''; // Reset range
                  endRange = ''; // Reset range
                  yearStart = null; // Reset year
                  yearEnd = null; // Reset year
                  selectedSubClass = ''; // Reset subclass
                });
              },
            ),
            const SizedBox(width: 10),
            Text(
              'Search $selectedFolder',
              style: const TextStyle(color: Colors.white),
            ),
            const Spacer(),
          ],
        ),
      ),
      endDrawer: selectedFolder.isEmpty ? null : _buildDrawer(context),
      body: selectedFolder.isEmpty ? _buildMainScreen(context) : _buildFolderContent(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Text(
              'Browse Categories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildMainClassTile('Computer science, Information & General works', 0.0, 99.99, [
            _buildSubClassTile('Computer science, Knowledge & Systems', 0.0, 9.99),
            _buildSubClassTile('Bibliographies', 10.0, 19.99),
            _buildSubClassTile('Library & Information Sciences', 20.0, 29.99),
            _buildSubClassTile('Encyclopedias & Books of Facts', 30.0, 39.99),
            _buildSubClassTile('[Unassigned]', 40.0, 49.99),
            _buildSubClassTile('Magazines, Journals & Serials', 50.0, 59.99),
            _buildSubClassTile('Associations, Organizations & Museums', 60.0, 69.99),
            _buildSubClassTile('News media, journalism & publishing', 70.0, 79.99),
            _buildSubClassTile('General Collections', 80.0, 89.99),
            _buildSubClassTile('Manuscripts & Rare Books', 90.0, 99.99),
          ]),
          _buildMainClassTile('Philosophy and Psychology', 100.0, 199.99, [
            _buildSubClassTile('Philosophy', 100.0, 109.99),
            _buildSubClassTile('Metaphysics', 110.0, 119.99),
            _buildSubClassTile('Epistemology', 120.0, 129.99),
            _buildSubClassTile('Parapsychology & Occultism', 130.0, 139.99),
            _buildSubClassTile('Philosophical Schools of Thought', 140.0, 149.99),
            _buildSubClassTile('Psychology', 150.0, 159.99),
            _buildSubClassTile('Philosophical Logic', 160.0, 169.99),
            _buildSubClassTile('Ethics', 170.0, 179.99),
            _buildSubClassTile('History, Geographic Treatment, Biography', 180.0, 199.99),
          ]),
          _buildMainClassTile('Religion', 200.0, 299.99, [
            _buildSubClassTile('Religion', 200.0, 209.99),
            _buildSubClassTile('Philosophy & Theory of Religion', 210.0, 219.99),
            _buildSubClassTile('Bible and Specific Religions', 220.0, 299.99),
          ]),
          _buildMainClassTile('Social Sciences', 300.0, 399.99, [
            _buildSubClassTile('Social Sciences, Sociology & Anthropology', 300.0, 309.99),
            _buildSubClassTile('Statistics', 310.0, 319.99),
            _buildSubClassTile('Political Science', 320.0, 329.99),
            _buildSubClassTile('Economics', 330.0, 339.99),
            _buildSubClassTile('Law', 340.0, 349.99),
            _buildSubClassTile('Public Administration & Military Science', 350.0, 359.99),
            _buildSubClassTile('Social Problems & Social Services', 360.0, 369.99),
            _buildSubClassTile('Education', 370.0, 379.99),
            _buildSubClassTile('Commerce, Communications & Transportation', 380.0, 389.99),
            _buildSubClassTile('Customs, Etiquette & Folklore', 390.0, 399.99),
          ]),
          _buildMainClassTile('Language', 400.0, 499.99, [
            _buildSubClassTile('Language', 400.0, 409.99),
            _buildSubClassTile('Linguistics', 410.0, 419.99),
            _buildSubClassTile('Specific Languages', 420.0, 499.99),
          ]),
          _buildMainClassTile('Science', 500.0, 599.99, [
            _buildSubClassTile('Science', 500.0, 509.99),
            _buildSubClassTile('Mathematics', 510.0, 519.99),
            _buildSubClassTile('Astronomy', 520.0, 529.99),
            _buildSubClassTile('Physics', 530.0, 539.99),
            _buildSubClassTile('Chemistry', 540.0, 549.99),
            _buildSubClassTile('Earth Sciences & Geology', 550.0, 559.99),
            _buildSubClassTile('Fossils & Prehistoric Life', 560.0, 569.99),
            _buildSubClassTile('Biology', 570.0, 579.99),
            _buildSubClassTile('Natural History of Plants and Animals', 580.0, 599.99),
          ]),
          _buildMainClassTile('Technology', 600.0, 699.99, [
            _buildSubClassTile('Technology', 600.0, 609.99),
            _buildSubClassTile('Medicine & Health', 610.0, 619.99),
            _buildSubClassTile('Engineering', 620.0, 629.99),
            _buildSubClassTile('Agriculture', 630.0, 639.99),
            _buildSubClassTile('Home & Family Management', 640.0, 649.99),
            _buildSubClassTile('Management & Public Relations', 650.0, 659.99),
            _buildSubClassTile('Chemical Engineering', 660.0, 669.99),
            _buildSubClassTile('Manufacturing', 670.0, 679.99),
            _buildSubClassTile('Manufacture for Specific Uses', 680.0, 689.99),
            _buildSubClassTile('Construction of Buildings', 690.0, 699.99),
          ]),
          _buildMainClassTile('Arts and Recreation', 700.0, 799.99, [
            _buildSubClassTile('Arts', 700.0, 709.99),
            _buildSubClassTile('Area Planning & Landscape Architecture', 710.0, 719.99),
            _buildSubClassTile('Architecture', 720.0, 729.99),
            _buildSubClassTile('Sculpture, Ceramics & Metalwork', 730.0, 739.99),
            _buildSubClassTile('Design & Related Arts', 740.0, 749.99),
            _buildSubClassTile('Painting', 750.0, 759.99),
            _buildSubClassTile('Printmaking & Prints', 760.0, 769.99),
            _buildSubClassTile('Photography, Computer Art, Film, Video', 770.0, 779.99),
            _buildSubClassTile('Music', 780.0, 789.99),
            _buildSubClassTile('Sports, Games & Entertainment', 790.0, 799.99),
          ]),
          _buildMainClassTile('Literature', 800.0, 899.99, [
            _buildSubClassTile('Literature, Rhetoric & Criticism', 800.0, 809.99),
            _buildSubClassTile('Literatures of Specific Languages and Language Families', 810.0, 899.99),
          ]),
          _buildMainClassTile('History and Geography', 900.0, 999.99, [
            _buildSubClassTile('History', 900.0, 909.99),
            _buildSubClassTile('Geography & Travel', 910.0, 919.99),
            _buildSubClassTile('Biography & Genealogy', 920.0, 929.99),
            _buildSubClassTile('History of Specific Continents, Countries, Localities; Extraterrestrial Worlds', 930.0, 999.99),
          ]),
        ],
      ),
    );
  }

  Widget _buildMainClassTile(String title, double startRange, double endRange, List<Widget> subClassTiles) {
    String startRangeStr = startRange.toStringAsFixed(4);
    String endRangeStr = endRange.toStringAsFixed(4);

    return FutureBuilder<int>(
      future: firestoreService.getCountByClassificationRange(selectedFolder.toLowerCase() == 'thesis' ? 'theses' : 'books', startRangeStr, endRangeStr),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListTile(
            title: Text(title),
            trailing: CircularProgressIndicator(),
          );
        }

        final count = snapshot.data ?? 0;

        return ExpansionTile(
          title: Text('$title ($count)'),
          children: subClassTiles,
        );
      },
    );
  }

  Widget _buildSubClassTile(String subClassTitle, double startRange, double endRange) {
    String startRangeStr = startRange.toStringAsFixed(4);
    String endRangeStr = endRange.toStringAsFixed(4);

    return FutureBuilder<int>(
      future: firestoreService.getCountByClassificationRange(selectedFolder.toLowerCase() == 'thesis' ? 'theses' : 'books', startRangeStr, endRangeStr),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListTile(
            title: Text(subClassTitle),
            trailing: CircularProgressIndicator(),
          );
        }

        final count = snapshot.data ?? 0;

        return ListTile(
          title: Text('$subClassTitle ($count)'),
          onTap: () {
            Navigator.pop(context);
            _fetchByClassificationRange(startRangeStr, endRangeStr, subClassTitle); // Pass the selected subclass range
          },
        );
      },
    );
  }

  void _fetchByClassificationRange(String startRange, String endRange, String subClassTitle) {
    setState(() {
      selectedFolder = selectedFolder; // Keep the selected folder
      query = ''; // Reset search query
      this.startRange = startRange; // Update the starting range
      this.endRange = endRange; // Update the ending range
      selectedSubClass = subClassTitle; // Update the selected subclass
    });
  }

  Widget _buildMainScreen(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Image.asset(
              'images/branding2.png',
              height: 120,
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Helps you to easily locate and find books and thesis in the school library.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          Lottie.asset(
            'lottie/Animation - 1727507102137.json',
            width: 180,
            height: 180,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 30),
          const Text(
            "Browse Now",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFolder = 'Books';
                        startRange = ''; // Reset range
                        endRange = ''; // Reset range
                        yearStart = null; // Reset year
                        yearEnd = null; // Reset year
                      });
                    },
                    child: _buildFolderTile('Books', Icons.book_outlined),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFolder = 'Thesis';
                        startRange = ''; // Reset range
                        endRange = ''; // Reset range
                        yearStart = null; // Reset year
                        yearEnd = null; // Reset year
                      });
                    },
                    child: _buildFolderTile('Thesis', Icons.article_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildFolderTile(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 35, color: Colors.blueAccent),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderContent() {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search $selectedFolder',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text('Filters:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showYearFilterDialog,
              ),
            ],
          ),
          if (selectedSubClass.isNotEmpty) // Show the selected subclass
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Category: $selectedSubClass',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    String collectionName = selectedFolder.toLowerCase() == 'thesis' ? 'theses' : 'books';

    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: firestoreService.searchDataCaseInsensitive(collectionName, query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!;
        final filteredResults = results.where((doc) {
          final classificationNumberStr = doc['Classification Number'] ?? '0';
          final sanitizedClassificationNumber = sanitizeClassificationNumber(classificationNumberStr);
          final classificationNumber = double.tryParse(sanitizedClassificationNumber) ?? 0;
          final start = double.tryParse(startRange) ?? 0;
          final end = double.tryParse(endRange) ?? 999.99;

          final yearPublishedStr = selectedFolder == 'Books' ? doc['Year Published'] : doc['Year Submitted'];
          final yearPublished = int.tryParse(yearPublishedStr ?? '') ?? 0;
          final yearStartValue = yearStart ?? 1860;
          final yearEndValue = yearEnd ?? DateTime.now().year;

          return classificationNumber >= start && classificationNumber <= end &&
              yearPublished >= yearStartValue && yearPublished <= yearEndValue;
        }).toList();

        if (filteredResults.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        return ListView.builder(
          itemCount: filteredResults.length,
          itemBuilder: (context, index) {
            final data = filteredResults[index].data() as Map<String, dynamic>;
            final title = data['Title'] ?? 'No Title';
            final String authors = _getAuthors(data['Authors']);
            final String? coverImageUrl = data['CoverImageUrl'];

            return GestureDetector(
              onTap: () {
                if (selectedFolder == 'Thesis') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThesisDetailsStudentScreen(thesisData: data),
                    ),
                  );
                } else if (selectedFolder == 'Books') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailsStudentScreen(bookData: data),
                    ),
                  );
                }
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 100,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: _getImageProvider(coverImageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'By $authors',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getAuthors(dynamic authorsField) {
    if (authorsField == null) return 'Unknown Authors';
    if (authorsField is List) return authorsField.join(', ');
    return authorsField;
  }

  ImageProvider _getImageProvider(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }
    return const AssetImage('images/books.png');
  }

  void _showYearFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Year Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Start Year'),
                value: yearStart,
                items: List.generate(2026 - 1860 + 1, (index) {
                  final year = 1860 + index;
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    yearStart = value;
                  });
                },
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'End Year'),
                value: yearEnd,
                items: List.generate(2026 - 1860 + 1, (index) {
                  final year = 1860 + index;
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    yearEnd = value;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        yearStart = null; // Clear start year
                        yearEnd = null; // Clear end year
                      });
                      Navigator.pop(context); // Close the dialog
                    },
                    child: const Text('Clear Filters', style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String sanitizeClassificationNumber(String classificationNumber) {
    return classificationNumber.replaceAll("'", ""); // Remove single quotes from classification numbers
  }
}
