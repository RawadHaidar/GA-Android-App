import 'package:flutter/material.dart';
import 'package:kicare_ml_firebase_server1/firebase_dataprovider.dart';
import 'package:provider/provider.dart';
import 'dataprovider.dart';
import 'ml_data_processor.dart';
import 'sensor_calibrator.dart';

class ActivityMlDataWidget extends StatefulWidget {
  const ActivityMlDataWidget({super.key});

  @override
  _ActivityMlDataWidgetState createState() => _ActivityMlDataWidgetState();
}

class _ActivityMlDataWidgetState extends State<ActivityMlDataWidget> {
  final dataProvider = DataProvider();

  final MlDataProcessor _mlProcessor = MlDataProcessor();
  bool _isLoading = true;

  final List<TextEditingController> _ipControllers = [];
  final List<String> _serialNumbers = [];
  final List<String> _activityOutputs = [];

  final Set<String> _registeredIps = {}; // Keep track of registered IPs
  final Map<String, List<List<double>>> _deviceBuffers =
      {}; // Buffers for each device

  final calibrator = Calibrator();
  @override
  void initState() {
    super.initState();
    _mlProcessor.loadModel().then((_) {
      setState(() {
        _isLoading = _mlProcessor.isLoading;
      });
    });
  }

  void _addIpContainer() {
    setState(() {
      _ipControllers.add(TextEditingController());
      _serialNumbers.add('N/A');
      _activityOutputs.add('No activity detected');
    });
  }

  void _removeIpContainer(int index) {
    final ip = _ipControllers[index].text.trim();
    if (ip.isNotEmpty) {
      Provider.of<DataProvider>(context, listen: false).removeIpAddress(ip);
    }
    setState(() {
      _ipControllers[index].dispose();
      _ipControllers.removeAt(index);
      _serialNumbers.removeAt(index);
      _activityOutputs.removeAt(index);
    });
  }

  void _connectToIp(int index) {
    final ip = _ipControllers[index].text.trim();
    if (ip.isNotEmpty) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);

      // Check if the IP address is already registered
      if (!_registeredIps.contains(ip)) {
        _registeredIps.add(ip); // Add IP to the set
        dataProvider.addIpAddress(ip); // Register IP with DataProvider

        // Initialize a data buffer for the device
        _deviceBuffers[ip] = [];
      }

      final firebaseDataProvider =
          FirebaseDataProvider(); // Firebase provider instance

// Set up the callback for this specific IP
      dataProvider.setDeviceCallback(
        ip,
        (ip, ax, ay, az, rx, ry, rz, serial) async {
          // Update UI with serial number
          setState(() {
            _serialNumbers[index] = serial;
          });

          // Add new sensor data to the buffer
          final buffer = _deviceBuffers[ip]!;

          if (serial == "111111") {
            //calibrate sensor 111111 data before adding to the buffer
            buffer.add([
              ax,
              ay,
              az,
              (((rx / 100) * 1000).roundToDouble()) / 1000,
              (((ry / 100) * 1000).roundToDouble()) / 1000,
              (((rz / 100) * 1000).roundToDouble()) / 1000
            ]);
          } else {
            buffer.add([
              ax,
              ay,
              az,
              (((rx / 100) * 1000).roundToDouble()) / 1000,
              (((ry / 100) * 1000).roundToDouble()) / 1000,
              (((rz / 100) * 1000).roundToDouble()) / 1000
            ]);
          }

          // Maintain buffer size at 6 lines
          if (buffer.length > 6) {
            buffer.removeAt(0); // Remove the oldest line
          }

          // If buffer has enough data, predict activity and send to Firestore
          if (buffer.length == 6) {
            try {
              final activity = await _mlProcessor.predictActivity(buffer);

              // Update the UI for the specific IP
              setState(() {
                _activityOutputs[index] = activity;
              });

              // Send activity data to Firestore
              await firebaseDataProvider.sendActivityData(
                serialNumber: serial,
                activity: activity,
              );
            } catch (e) {
              dataProvider.setLatestError(ip, e.toString());
              setState(() {
                _activityOutputs[index] = 'Error: $e';
              });
            }
          } else {
            // Collecting data message
            setState(() {
              _activityOutputs[index] = 'Collecting data...';
            });
          }
        },
      );
    }
  }

  void _disconnectFromIp(int index) {
    final ip = _ipControllers[index].text.trim();
    if (ip.isNotEmpty) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);

      // Remove IP from DataProvider and the registered IPs set
      dataProvider.removeIpAddress(ip);
      _registeredIps.remove(ip);

      // Clear the buffer for the IP address
      _deviceBuffers.remove(ip);

      setState(() {
        _serialNumbers[index] = 'N/A';
        _activityOutputs[index] = 'Disconnected';
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _ipControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1000,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            "Pess Add IP Address to add the devices connected to your Wifi network.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addIpContainer,
            child: const Text('Add IP Address'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _ipControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 200,
                        child: Column(
                          children: [
                            TextField(
                              controller: _ipControllers[index],
                              decoration: const InputDecoration(
                                hintText: 'e.g., 192.168.0.155',
                                labelText: 'Enter IP Address',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _connectToIp(index),
                                  child: const Text('Connect'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _disconnectFromIp(index),
                                  child: const Text('Disconnect'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _removeIpContainer(index),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isLoading
                                  ? 'Loading model...'
                                  : 'Serial: ${_serialNumbers[index]}\n'
                                      'Activity: ${_activityOutputs[index]}\n'
                                      'Status: ${Provider.of<DataProvider>(context).getLatestError(_ipControllers[index].text.trim())}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
