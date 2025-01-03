import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientDataPage extends StatelessWidget {
  final Map<String, dynamic> deviceData;

  const PatientDataPage({super.key, required this.deviceData});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final dateTime = timestamp.toDate();
    return DateFormat('MMMM dd, yyyy \'at\' hh:mm:ss a z').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Data: ${deviceData['serialNumber']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Serial Number: ${deviceData['serialNumber'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 25),
            ),
            Text(
              'Activity: ${deviceData['activity'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 25),
            ),
            Text(
              'Fall Detected: ${_formatTimestamp(deviceData['falldetected'])}',
              style: const TextStyle(fontSize: 25),
            ),
            Text(
              'Fall Predicted: ${_formatTimestamp(deviceData['fallpredicted'])}',
              style: const TextStyle(fontSize: 25),
            ),
            Text(
              'Walk Deterioration: ${_formatTimestamp(deviceData['walkdeterioration'])}',
              style: const TextStyle(fontSize: 25),
            ),
          ],
        ),
      ),
    );
  }
}
