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
  final Modelselectionmanager _modelselectionmanger = Modelselectionmanager();
  bool _isLoading = true;

  final List<TextEditingController> _ipControllers = [];
  final List<String> _serialNumbers = [];
  final List<String> _activityOutputs = [];
  final List<String?> _selectedModels = []; // Track selected models for each IP
  final List<String> _availableModels = ['model_1', 'model_2'];

  final Set<String> _registeredIps = {};
  final Map<String, List<List<double>>> _deviceBuffers = {};

  final calibrator = Calibrator();

  @override
  void initState() {
    super.initState();
    _modelselectionmanger.initializeDevice('model_1').then((_) {
      setState(() {
        _isLoading = _modelselectionmanger.isLoading;
      });
    });
    _modelselectionmanger.initializeDevice('model_2').then((_) {
      setState(() {
        _isLoading = _modelselectionmanger.isLoading;
      });
    });
  }

  void _addIpContainer() {
    setState(() {
      _ipControllers.add(TextEditingController());
      _serialNumbers.add('N/A');
      _activityOutputs.add('No activity detected');
      _selectedModels.add(null); // Initially no model selected
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
      _selectedModels.removeAt(index);
    });
  }

  void _connectToIp(int index) {
    final ip = _ipControllers[index].text.trim();
    final selectedModel = _selectedModels[index];

    // Validate IP Address
    if (!isValidIP(ip)) {
      setState(() {
        _activityOutputs[index] = 'Invalid IP Address';
      });
      return;
    }

    if (selectedModel == null) {
      setState(() {
        _activityOutputs[index] = 'ML model not selected';
      });
      return;
    }

    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    // Check if the IP address is already registered
    if (!_registeredIps.contains(ip)) {
      _registeredIps.add(ip);
      dataProvider.addIpAddress(ip);
      _deviceBuffers[ip] = [];
    }

    final firebaseDataProvider = FirebaseDataProvider();

    dataProvider.setDeviceCallback(ip,
        (ip, ax, ay, az, rx, ry, rz, serial) async {
      setState(() {
        _serialNumbers[index] = serial;
      });

      final buffer = _deviceBuffers[ip]!;
      buffer.add([ax, ay, az, rx, ry, rz]);

      if (buffer.length > 6) buffer.removeAt(0);

      if (buffer.length == 6) {
        try {
          String activity = await _modelselectionmanger.processDeviceData(
              selectedModel, buffer);
          setState(() {
            _activityOutputs[index] = activity;
          });

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
        setState(() {
          _activityOutputs[index] = 'Collecting data...';
        });
      }
    });
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

  bool isValidIP(String? ip) {
    if (ip == null || ip.isEmpty) return false;
    final regex = RegExp(
        r'^(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)$');
    return regex.hasMatch(ip);
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
            "Press Add IP Address to add the devices connected to your Wi-Fi network.",
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
              shrinkWrap: true,
              physics:
                  const BouncingScrollPhysics(), // Optional, better scrolling effect
              itemCount: _ipControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 280,
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
                            DropdownButton<String>(
                              value: _selectedModels[index],
                              hint: const Text('Select Model'),
                              items: _availableModels.map((model) {
                                return DropdownMenuItem(
                                  value: model,
                                  child: Text(model),
                                );
                              }).toList(),
                              onChanged: (model) {
                                setState(() {
                                  _selectedModels[index] = model;
                                });
                              },
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
