import 'package:flutter/services.dart';

class TFLiteBridge {
  static const _channel = MethodChannel("gesturevox/tflite");

  static Future<List<double>> runModel(List<double> input) async {
    final output = await _channel.invokeMethod<List<dynamic>>("runModel", input);
    return output!.map((e) => e as double).toList();
  }
}
