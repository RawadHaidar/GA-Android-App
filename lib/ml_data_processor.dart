import 'package:tflite_flutter/tflite_flutter.dart';

class MlDataProcessor {
  Interpreter? _interpreter;
  bool isLoading = true;
  String _currentState = 'sitting'; // Initial state
  final String modelPath;
  final List<double> mean;
  final List<double> stdDev;

  MlDataProcessor(this.modelPath, this.mean, this.stdDev);

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      isLoading = false;
    } catch (e) {
      isLoading = false;
      throw Exception('Error loading model: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  Future<String> predictActivity(List<List<double>> inputBuffer) async {
    if (isLoading) {
      throw Exception('Model is still loading');
    }
    if (_interpreter == null) {
      throw Exception('Interpreter is not initialized');
    }

    List<List<double>> scaledInput = inputBuffer.map((features) {
      return List<double>.generate(features.length, (index) {
        return (features[index] - mean[index]) / stdDev[index];
      });
    }).toList();

    var output = List<List<double>>.filled(1, List<double>.filled(10, 0.0));

    _interpreter!.run([scaledInput], output);

    int predictedClass = output[0]
        .asMap()
        .entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    _currentState = _mapClassToActivity(predictedClass);
    return _currentState;
  }

  String _mapClassToActivity(int predictedClass) {
    const activityLabels = [
      'laying',
      'still',
      'walking',
      'laying down / sitting up',
      'still',
      'sitting down / standing up',
      'standing up / sitting down',
      'fall detected',
      'fall prediction',
      'walk deterioration'
    ];
    return (predictedClass >= 0 && predictedClass < activityLabels.length)
        ? activityLabels[predictedClass]
        : 'unknown';
  }
}

class Modelselectionmanager {
  bool isLoading = true;
  final Map<String, Map<String, dynamic>> deviceModelData = {
    'model_1': {
      'model': 'assets/models/activity_fall_combined_model.tflite',
      'mean': [
        0.2015291890814896,
        0.719958158995818,
        0.2616696553098246,
        65.63354054592496,
        36.54647937836233,
        20.01634389320581
      ],
      'stdDev': [
        0.25828403406752537,
        0.36099552727694995,
        0.37921567012022867,
        42.49111799476216,
        58.032751888648,
        39.98127215053988
      ]
    },
    'model_2': {
      'model': 'assets/models/activity_fall_combined_model2.tflite',
      'mean': [
        0.18720415288496897,
        0.7256560088202892,
        0.27599595736861604,
        64.86237412715849,
        32.95182561558256,
        18.546107129731652
      ],
      'stdDev': [
        0.2593020666639833,
        0.3453140419777503,
        0.3697760608186425,
        41.50147720418859,
        57.662724203360646,
        38.530510507191636
      ]
    }
  };

  final Map<String, MlDataProcessor> deviceProcessors = {};

  Future<void> initializeDevice(String deviceId) async {
    if (deviceModelData.containsKey(deviceId)) {
      var data = deviceModelData[deviceId]!;
      deviceProcessors[deviceId]
          ?.dispose(); // Dispose previous instance if exists
      var processor = MlDataProcessor(
        data['model'],
        List<double>.from(data['mean']),
        List<double>.from(data['stdDev']),
      );
      deviceProcessors[deviceId] = processor;
      await processor.loadModel(); // Ensure model is loaded before use
      isLoading = false;
    } else {
      throw Exception('No model assigned to device: $deviceId');
    }
  }

  Future<String> processDeviceData(
      String deviceId, List<List<double>> inputData) async {
    if (!deviceProcessors.containsKey(deviceId)) {
      throw Exception('Device not initialized: $deviceId');
    }
    return await deviceProcessors[deviceId]!.predictActivity(inputData);
  }

  void disposeAll() {
    for (var processor in deviceProcessors.values) {
      processor.dispose();
    }
    deviceProcessors.clear();
  }
}
