import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class DataProvider with ChangeNotifier {
  WebSocketChannel? _channel;
  bool isConnected = false; // Track WebSocket connection status
  String? errorMessage; // Store error message if any
  Timer? _heartbeatTimer; // Timer for heartbeat checks
  Timer? _reconnectTimer; // Timer for reconnection attempts
  String? ipAddress; // Store the dynamically set IP address
  bool _manualDisconnect = false; // Track if disconnect was manual

  void Function(double, double, double, double, double, double, String)?
      onNewData;

  DataProvider();

  void setIpAddress(String newIpAddress) {
    ipAddress = newIpAddress;
    _manualDisconnect = false; // Reset flag for new connection attempts
    _connectToWebSocket(); // Connect to the new IP address
  }

  void _connectToWebSocket() {
    if (ipAddress == null || ipAddress!.isEmpty) {
      errorMessage = "IP address is not set.";
      notifyListeners();
      return;
    }

    final uri = Uri.parse('ws://$ipAddress:81');
    _channel = WebSocketChannel.connect(uri);

    _channel?.stream.listen(
      (message) {
        isConnected = true;
        errorMessage = null; // Clear error message on successful connection
        _startHeartbeat(); // Start heartbeat after successful connection
        _updateSensorData(message);
        notifyListeners();
      },
      onDone: () {
        if (!_manualDisconnect) {
          _handleDisconnection(
              'Device disconnected. Attempting to reconnect...');
        }
      },
      onError: (error) {
        if (!_manualDisconnect) {
          _handleDisconnection(
              'WebSocket error: $error. Attempting to reconnect...');
        }
      },
    );
  }

  void disconnect() {
    _manualDisconnect = true; // Set flag to prevent reconnection attempts
    _channel?.sink.close(status.goingAway);
    _channel = null;
    isConnected = false;
    _stopHeartbeat(); // Stop heartbeat when manually disconnected
    notifyListeners();
  }

  void _handleDisconnection(String message) {
    isConnected = false;
    errorMessage = message;
    notifyListeners();

    _stopHeartbeat(); // Stop heartbeat when disconnected

    // Attempt reconnect only if not manually disconnected
    if (!_manualDisconnect) {
      _attemptReconnect();
    }
    print(message);
  }

  void _attemptReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (!isConnected && ipAddress != null && !_manualDisconnect) {
        print('Reconnecting to WebSocket...');
        _connectToWebSocket();
      }
    });
  }

  void _startHeartbeat() {
    _stopHeartbeat(); // Stop any existing heartbeat
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      try {
        _channel?.sink.add(jsonEncode({'type': 'ping'}));
        print('Heartbeat sent');
      } catch (e) {
        _handleDisconnection(
            'Heartbeat failed: $e. Attempting to reconnect...');
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
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
      final String? serialNumber = data['serialNumber'];

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
    _manualDisconnect = true; // Ensure no reconnection attempts on dispose
    _stopHeartbeat(); // Stop the heartbeat timer
    _reconnectTimer?.cancel(); // Cancel the reconnection timer
    _channel?.sink.close(status.goingAway); // Close the WebSocket connection
    super.dispose();
  }
}
