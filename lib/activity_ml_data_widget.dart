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
      0.21297677691765976,
      0.6996563452967415,
      0.246378137461884,
      65.7319399483927,
      38.35796387520527,
      21.779284541402706
    ];
    var stdDev = [
      0.2731105627301171,
      0.3840568129795698,
      0.38958532434556586,
      44.64709485819556,
      59.2081425813222,
      42.604528730363455
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _isLoading
          ? 'Loading model...'
          : 'Serialnumber: $_serialNumber\nActivity: $output_string',
      style: TextStyle(fontSize: 30),
    );
  }
}
