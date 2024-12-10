import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_dataprovider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dataprovider.dart';

class ActivityMlDataWidget extends StatefulWidget {
  @override
  _ActivityMlDataWidgetState createState() => _ActivityMlDataWidgetState();
}

class _ActivityMlDataWidgetState extends State<ActivityMlDataWidget> {
  Interpreter? _interpreter;
  String _output = '';
  String output_string = '';
  String _serialNumber = 'N/A';
  bool _isLoading = true;

  late DataProvider _dataProvider;
  late FirebaseDataProvider _firebaseDataProvider;

  List<List<double>> _inputBuffer = [];
  final TextEditingController _ipController =
      TextEditingController(); // Text field controller

  @override
  void initState() {
    super.initState();
    _loadModel();
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
    _firebaseDataProvider = FirebaseDataProvider();
    _dataProvider.onNewData = _bufferData;
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
          'assets/models/activity_fall_combined_model.tflite');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _output = 'Error loading model';
      });
    }
  }

  void _updateIpAddress() {
    final ip = _ipController.text.trim();
    if (ip.isNotEmpty) {
      _dataProvider.setIpAddress(ip);
    }
  }

  void _disconnectFromServer() {
    _dataProvider.disconnect();
    setState(() {
      _serialNumber = 'N/A';
      output_string = 'Disconnected';
      _output = 'Disconnected from WebSocket';
    });
  }

  void _bufferData(double ax, double ay, double az, double rx, double ry,
      double rz, String serialNumber) {
    if (_isLoading || _interpreter == null) {
      return;
    }

    setState(() {
      _serialNumber = serialNumber;
    });

    if (_inputBuffer.length >= 6) {
      _inputBuffer.removeAt(0);
    }
    _inputBuffer.add([ax, ay, az, rx, ry, rz]);

    if (_inputBuffer.length == 6) {
      _predictWithData();
    }
  }

  Future<void> _predictWithData() async {
    if (_interpreter == null) {
      print('Interpreter is not initialized');
      return;
    }

    var input = [_inputBuffer];
    var mean = [
      0.20843079922027016,
      0.7102306692657564,
      0.249322070608623,
      65.94978124323104,
      37.685719081654824,
      21.447627247130217
    ];
    var stdDev = [
      0.26626532547848913,
      0.37681720681319597,
      0.38741141730125095,
      43.94066655893264,
      59.36033325058816,
      41.2216565065153
    ];

    var scaledInput = input.map((batch) {
      return batch.map((features) {
        return List<double>.generate(features.length, (index) {
          return (features[index] - mean[index]) / stdDev[index];
        }).toList();
      }).toList();
    }).toList();

    var output = List<List<double>>.filled(1, List<double>.filled(10, 0.0));

    _interpreter!.run(scaledInput, output);

    var rawOutput = output[0];
    var predictedClass = rawOutput
        .asMap()
        .entries
        .fold<MapEntry<int, double>>(
          MapEntry(0, rawOutput[0]),
          (current, entry) => entry.value > current.value ? entry : current,
        )
        .key;

    switch (predictedClass) {
      case 0:
        output_string = 'laying';
        break;
      case 1:
        output_string = 'standing still';
        break;
      case 2:
        output_string = 'walking';
        break;
      case 3:
        output_string = 'laying down / sitting up';
        break;
      case 4:
        output_string = 'sitting';
        break;
      case 5:
        output_string = 'sitting down';
        break;
      case 6:
        output_string = 'standing up';
        break;
      case 7:
        output_string = 'fall detected';
        break;
      case 8:
        output_string = 'fall prediction';
        break;
      case 9:
        output_string = 'walk deterioration';
        break;
      default:
        output_string = 'unknown';
    }

    setState(() {
      _output = 'Predicted Class: $predictedClass';
    });

    // Send data to Firestore
    await _firebaseDataProvider.sendActivityData(
      serialNumber: _serialNumber,
      activity: output_string,
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10),
        // Wrap Row in a SingleChildScrollView to handle overflow
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Allow horizontal scrolling
          child: Container(
            constraints: BoxConstraints(maxWidth: 700),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Use Expanded to make sure the TextField gets enough space
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'Enter IP Address',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
                SizedBox(width: 10), // Space between the buttons
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _updateIpAddress,
                      child: Text('Connect to IP'),
                    ),
                    SizedBox(width: 10), // Space between buttons
                    ElevatedButton(
                      onPressed: _disconnectFromServer,
                      child: Text('Disconnect   '),
                    ),
                  ],
                ),

                SizedBox(height: 10),
                Text(
                  _isLoading
                      ? 'Loading model...'
                      : 'Serialnumber: $_serialNumber\nActivity: $output_string',
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
