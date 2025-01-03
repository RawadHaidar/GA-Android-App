import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends activity data to the Firestore 'devices' collection
  Future<void> sendActivityData({
    required String serialNumber,
    required String activity,
  }) async {
    try {
      // Define the update map for Firestore
      Map<String, dynamic> updateData = {
        'serialNumber': serialNumber,
        'activity': activity,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add fields for specific activities with timestamps
      if (activity == 'fall detected') {
        updateData['falldetected'] = FieldValue.serverTimestamp();
      } else if (activity == 'fall prediction') {
        updateData['fallpredicted'] = FieldValue.serverTimestamp();
      } else if (activity == 'walk deterioration') {
        updateData['walkdeterioration'] = FieldValue.serverTimestamp();
      }

      // Update the document in Firestore
      await _firestore.collection('devices').doc(serialNumber).set(
            updateData,
            SetOptions(merge: true), // Merge with existing data
          );

      // print('Activity data for $serialNumber sent successfully.');
    } catch (e) {
      // print('Failed to send activity data: $e');
    }
  }
}
