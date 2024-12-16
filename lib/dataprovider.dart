import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class DataProvider with ChangeNotifier {
  final Map<String, WebSocketChannel> _channels = {};
  final Map<String, Timer> _heartbeatTimers = {};
  final Map<String, bool> _connectionStatus = {};
  final Map<String, String> _latestErrorMessage =
      {}; // Store the latest error message per IP
  final Map<String, Timer> _reconnectTimers = {};
  final Map<String, String> _ipErrors = {}; // Map to store errors for each IP

  void Function(
          String ip, double, double, double, double, double, double, String)?
      onNewData;

  DataProvider();

  void addIpAddress(String ipAddress) {
    if (_channels.containsKey(ipAddress)) {
      logError(ipAddress, "Already connected to $ipAddress");
      return;
    }
    _connectToWebSocket(ipAddress);
  }

  void removeIpAddress(String ipAddress) {
    _disconnectWebSocket(ipAddress);
  }

  void _connectToWebSocket(String ipAddress) {
    final uri = Uri.parse('ws://$ipAddress:81');
    final channel = WebSocketChannel.connect(uri);
    _channels[ipAddress] = channel;

    _connectionStatus[ipAddress] = false; // Initially disconnected
    _latestErrorMessage[ipAddress] =
        ""; // Initialize the latest error message for the IP

    channel.stream.listen(
      (message) {
        _connectionStatus[ipAddress] = true;
        _clearLatestError(
            ipAddress); // Clear error messages on successful connection
        _startHeartbeat(ipAddress); // Start heartbeat for this connection
        _updateSensorData(ipAddress, message);
        notifyListeners();
      },
      onDone: () {
        _handleDisconnection(ipAddress, 'Device disconnected.');
      },
      onError: (error) {
        _handleDisconnection(ipAddress, 'WebSocket error: $error');
      },
    );
  }

  void _disconnectWebSocket(String ipAddress) {
    _stopHeartbeat(ipAddress);
    _reconnectTimers[ipAddress]?.cancel();
    _channels[ipAddress]?.sink.close(status.normalClosure);
    _channels.remove(ipAddress);
    _connectionStatus.remove(ipAddress);
    _latestErrorMessage.remove(ipAddress);
    notifyListeners();
  }

  void _handleDisconnection(String ipAddress, String message) {
    _connectionStatus[ipAddress] = false;
    logError(ipAddress, message); // Log the disconnection error
    notifyListeners();

    _stopHeartbeat(ipAddress);

    // Attempt reconnect only if the IP is still in the list
    if (_channels.containsKey(ipAddress)) {
      _attemptReconnect(ipAddress);
    }
  }

  void _attemptReconnect(String ipAddress) {
    _reconnectTimers[ipAddress]?.cancel();
    _reconnectTimers[ipAddress] = Timer(const Duration(seconds: 2), () {
      if (_channels.containsKey(ipAddress) && !_connectionStatus[ipAddress]!) {
        logError(ipAddress, 'Reconnecting to $ipAddress...');
        _connectToWebSocket(ipAddress);
      }
    });
  }

  void _startHeartbeat(String ipAddress) {
    _stopHeartbeat(ipAddress);
    _heartbeatTimers[ipAddress] =
        Timer.periodic(const Duration(seconds: 3), (timer) {
      try {
        _channels[ipAddress]?.sink.add(jsonEncode({'type': 'ping'}));
        logError(ipAddress, 'Heartbeat sent to $ipAddress');
      } catch (e) {
        _handleDisconnection(ipAddress, 'Heartbeat failed: $e');
      }
    });
  }

  void _stopHeartbeat(String ipAddress) {
    _heartbeatTimers[ipAddress]?.cancel();
    _heartbeatTimers.remove(ipAddress);
  }

  void _updateSensorData(String ipAddress, String message) {
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
        onNewData?.call(ipAddress, ax, ay, az, rx, ry, rz, serialNumber);
      }
      logError(ipAddress, 'Sensor data received: $ax,$ay,$az,$rx,$ry,$rz');
    } catch (e) {
      logError(ipAddress, 'Error parsing sensor data: $e');
    }
  }

  /// Log the latest error for a specific IP and print it
  void logError(String ipAddress, String message) {
    _latestErrorMessage[ipAddress] = message; // Store the latest error
    print('[$ipAddress] $message');
    setLatestError(ipAddress, message);
  }

  /// Clear the latest error message for a specific IP
  void _clearLatestError(String ipAddress) {
    _latestErrorMessage[ipAddress] = "";
  }

  void setLatestError(String ip, String error) {
    _ipErrors[ip] = error;
    notifyListeners();
  }

  String getLatestError(String ip) {
    return _ipErrors[ip] ?? 'No errors';
  }

  bool isConnected(String ipAddress) => _connectionStatus[ipAddress] ?? false;

  @override
  void dispose() {
    _channels.keys.toList().forEach(removeIpAddress); // Disconnect all IPs
    super.dispose();
  }
}
