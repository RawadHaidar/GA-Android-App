import 'package:tflite_flutter/tflite_flutter.dart';

class MlDataProcessor {
  Interpreter? _interpreter;
  bool isLoading = true;

  MlDataProcessor() {
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
          'assets/models/activity_fall_combined_model.tflite');
      isLoading = false;
    } catch (e) {
      isLoading = false;
      throw Exception('Error loading model: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
  }

  Future<String> predictActivity(List<List<double>> inputBuffer) async {
    if (_interpreter == null) {
      throw Exception('Interpreter is not initialized');
    }

    var input = [inputBuffer];
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

    return _mapClassToActivity(predictedClass);
  }

  String _mapClassToActivity(int predictedClass) {
    switch (predictedClass) {
      case 0:
        return 'laying';
      case 1:
        return 'standing still';
      case 2:
        return 'walking';
      case 3:
        return 'laying down / sitting up';
      case 4:
        return 'sitting';
      case 5:
        return 'sitting down';
      case 6:
        return 'standing up';
      case 7:
        return 'fall detected';
      case 8:
        return 'fall prediction';
      case 9:
        return 'walk deterioration';
      default:
        return 'unknown';
    }
  }
}
