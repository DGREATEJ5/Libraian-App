import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save data to a Firestore collection
  Future<void> saveData(String collectionName, Map<String, dynamic> data) async {
    try {
      await _db.collection(collectionName).add(data);
      print("Data saved to Firestore successfully!");
    } catch (e) {
      print("Error saving data: $e");
    }
  }

  // Update data in Firestore document
  Future<void> updateData(String collectionName, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collectionName).doc(docId).update(data);
      print("Data updated in Firestore successfully!");
    } catch (e) {
      print("Error updating data: $e");
    }
  }

  // Search data from Firestore by title or authors with case-insensitive search
  Future<List<QueryDocumentSnapshot>> searchDataCaseInsensitive(String collectionName, String query) async {
    try {
      QuerySnapshot snapshot = await _db.collection(collectionName).get();

      // Perform case-insensitive filtering on the fetched data locally
      List<QueryDocumentSnapshot> filteredResults = snapshot.docs.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String title = data['Title']?.toString().toLowerCase() ?? '';
        String authors = data['Authors']?.toString().toLowerCase() ?? ''; // Added for author search
        return title.contains(query.toLowerCase()) || authors.contains(query.toLowerCase()); // Search in title or authors
      }).toList();

      return filteredResults;
    } catch (e) {
      print("Error searching data: $e");
      rethrow;
    }
  }

  // Get count of documents in a collection based on classification range (stored as strings in Firestore)
  Future<int> getCountByClassificationRange(String collectionName, String startRange, String endRange) async {
    try {
      // Fetch all documents from Firestore and filter the classification numbers as doubles
      QuerySnapshot snapshot = await _db.collection(collectionName).get();

      // Convert the start and end range to doubles for numeric comparison
      double startRangeNum = double.tryParse(startRange) ?? 0.0;
      double endRangeNum = double.tryParse(endRange) ?? 999.99;

      // Filter documents by checking their classification number
      int count = snapshot.docs.where((doc) {
        String? classificationNumberStr = doc['Classification Number'];
        if (classificationNumberStr != null) {
          // Sanitize the classification number
          classificationNumberStr = _sanitizeClassificationNumber(classificationNumberStr);
          double classificationNumber = double.tryParse(classificationNumberStr) ?? 0.0;
          return classificationNumber >= startRangeNum && classificationNumber <= endRangeNum;
        }
        return false;
      }).length;

      return count;
    } catch (e) {
      print("Error getting classification count: $e");
      return 0;
    }
  }

  // Get count of all books in the Firestore
  Future<int> getBooksCount() async {
    try {
      QuerySnapshot snapshot = await _db.collection('books').get();
      return snapshot.docs.length; // Return the count of documents
    } catch (e) {
      print("Error getting books count: $e");
      return 0; // Return 0 in case of error
    }
  }

  // Get count of all theses in the Firestore
  Future<int> getThesesCount() async {
    try {
      QuerySnapshot snapshot = await _db.collection('theses').get();
      return snapshot.docs.length; // Return the count of documents
    } catch (e) {
      print("Error getting theses count: $e");
      return 0; // Return 0 in case of error
    }
  }

  // Helper method to sanitize classification numbers
  String _sanitizeClassificationNumber(String classificationNumber) {
    // Remove unwanted characters, e.g., single quotes
    return classificationNumber.replaceAll("'", "").trim();
  }

  // Read data from Firestore collection as QuerySnapshot
  Stream<QuerySnapshot<Object?>> getData(String collectionName) {
    return _db.collection(collectionName).snapshots();
  }

  // Delete document from Firestore
  Future<void> deleteData(String collectionName, String docId) async {
    try {
      await _db.collection(collectionName).doc(docId).delete();
      print("Data deleted from Firestore successfully!");
    } catch (e) {
      print("Error deleting data: $e");
    }
  }
}
