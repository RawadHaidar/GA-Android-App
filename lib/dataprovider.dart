import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class DataProvider with ChangeNotifier {
  bool isGenerating = false;
  WebSocketChannel? _channel;

  // Callback to notify when new data is received
  void Function(double, double, double, double, double, double, String)?
      onNewData;

  void startGeneratingData() {
    if (isGenerating) return;

    isGenerating = true;
    _connectToWebSocket();

    print('Started generating data');
  }

  void stopGeneratingData() {
    if (!isGenerating) return;

    isGenerating = false;
    _channel?.sink.close(1000); // Gracefully close the WebSocket connection
    _channel = null;
    notifyListeners();

    print('Stopped generating data');
  }

  void _connectToWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.0.155:81'),
    );

    _channel?.stream.listen(
      (message) {
        if (isGenerating) {
          _updateSensorData(message);
        }
      },
      onDone: () {
        print('WebSocket connection closed');
        _channel = null;
      },
      onError: (error) {
        print('WebSocket error: $error');
        _channel = null;
      },
    );
  }

  void _updateSensorData(String message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);

      final double? ax = data['accelX']?.toDouble();
      final double? ay = data['accelY']?.toDouble();
      final double? az = data['accelZ']?.toDouble();
      final double? rx = data['rotationX']?.toDouble();
      final double? ry = data['rotationY']?.toDouble();
      final double? rz = data['rotationZ']?.toDouble();
      final String? serialNumber =
          data['serialNumber']; // Extract serial number

      if (ax != null &&
          ay != null &&
          az != null &&
          rx != null &&
          ry != null &&
          rz != null &&
          serialNumber != null) {
        onNewData?.call(ax, ay, az, rx, ry, rz, serialNumber);
      }
      print('$ax,$ay,$az,$rx,$ry,$rz, Serial: $serialNumber');
    } catch (e) {
      print('Error parsing sensor data: $e');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    super.dispose();
  }
}
