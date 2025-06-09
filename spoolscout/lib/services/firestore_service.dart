import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitFilament({
    required String brand,
    required String type,
    required String price,
    required String weight,
    required String temperature,
    required String attributes,
    required String imagePath,
  }) async {
    try {
      final String fileName =
          'filaments/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(File(imagePath));
      final imageUrl = await ref.getDownloadURL();

      await _firestore.collection('submittedFilaments').add({
        'brand': brand,
        'type': type,
        'price': price,
        'weight': weight,
        'temperature': temperature,
        'attributes': attributes
            .split(',')
            .map((e) => e.trim())
            .toList(), // Store as List<String>
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit filament: $e');
    }
  }

  Future<void> rejectFilament(String documentId) async {
    try {
      await _firestore
          .collection('submittedFilaments')
          .doc(documentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to reject filament: $e');
    }
  }

  Stream<List<QueryDocumentSnapshot>> fetchSubmittedFilaments() {
    return _firestore
        .collection('submittedFilaments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
}
