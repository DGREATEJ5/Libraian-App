import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file to Firebase Storage
  Future<String?> uploadImage(File file, String fileName) async {
    try {
      // Create a reference to the Firebase Storage bucket
      Reference storageRef = _storage.ref().child('uploads/$fileName');

      // Upload the file to Firebase Storage
      UploadTask uploadTask = storageRef.putFile(file);

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL for the uploaded file
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("File uploaded to Firebase Storage: $downloadUrl");
      return downloadUrl; // Return the download URL
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // Delete file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      Reference storageRef = _storage.refFromURL(fileUrl);
      await storageRef.delete();
      print("File deleted from Firebase Storage: $fileUrl");
    } catch (e) {
      print("Error deleting file: $e");
    }
  }
}
