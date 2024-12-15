import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class DataProvider with ChangeNotifier {
  final Map<String, WebSocketChannel> _channels =
      {}; // Store WebSocket channels by IP
  final Map<String, Timer> _heartbeatTimers =
      {}; // Store heartbeat timers by IP
  final Map<String, bool> _connectionStatus =
      {}; // Track connection status by IP
  final Map<String, String?> _errorMessages = {}; // Store error messages by IP
  final Map<String, Timer> _reconnectTimers =
      {}; // Store reconnect timers by IP

  void Function(
          String ip, double, double, double, double, double, double, String)?
      onNewData;

  DataProvider();

  void addIpAddress(String ipAddress) {
    if (_channels.containsKey(ipAddress)) {
      print("Already connected to $ipAddress");
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
    _errorMessages[ipAddress] = null;

    channel.stream.listen(
      (message) {
        _connectionStatus[ipAddress] = true;
        _errorMessages[ipAddress] = null; // Clear error message on success
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
    _channels[ipAddress]?.sink.close(status.goingAway);
    _channels.remove(ipAddress);
    _connectionStatus.remove(ipAddress);
    _errorMessages.remove(ipAddress);
    notifyListeners();
  }

  void _handleDisconnection(String ipAddress, String message) {
    _connectionStatus[ipAddress] = false;
    _errorMessages[ipAddress] = message;
    notifyListeners();

    _stopHeartbeat(ipAddress);

    // Attempt reconnect only if the IP is still in the list
    if (_channels.containsKey(ipAddress)) {
      _attemptReconnect(ipAddress);
    }
    print('[$ipAddress] $message');
  }

  void _attemptReconnect(String ipAddress) {
    _reconnectTimers[ipAddress]?.cancel();
    _reconnectTimers[ipAddress] = Timer(const Duration(seconds: 2), () {
      if (_channels.containsKey(ipAddress) && !_connectionStatus[ipAddress]!) {
        print('Reconnecting to $ipAddress...');
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
        print('Heartbeat sent to $ipAddress');
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
      print('[$ipAddress] $ax,$ay,$az,$rx,$ry,$rz, Serial: $serialNumber');
    } catch (e) {
      print('[$ipAddress] Error parsing sensor data: $e');
    }
  }

  bool isConnected(String ipAddress) => _connectionStatus[ipAddress] ?? false;

  String? getErrorMessage(String ipAddress) => _errorMessages[ipAddress];

  @override
  void dispose() {
    _channels.keys.toList().forEach(removeIpAddress); // Disconnect all IPs
    super.dispose();
  }
}
