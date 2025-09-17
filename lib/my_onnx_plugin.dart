// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/services.dart';
//
// class MyOnnxPlugin {
//   static const MethodChannel _channel = MethodChannel('onnx_channel');
//
//   // Asset se copy karke load karne wala function (bina path_provider ke)
//   static Future<void> loadModelFromAssets(String assetPath) async {
//     try {
//       // Asset ko read karo
//       final ByteData data = await rootBundle.load(assetPath);
//
//       // Manual cache directory path use karo
//       final String cacheDir = '/data/data/com.example.untitled/cache';
//       final Directory directory = Directory(cacheDir);
//
//       // Directory create karo agar exist nahi karti
//       if (!await directory.exists()) {
//         await directory.create(recursive: true);
//       }
//
//       // File path banao
//       final String fileName = assetPath.split('/').last;
//       final File tempFile = File('$cacheDir/$fileName');
//
//       // Asset data ko file mein write karo
//       await tempFile.writeAsBytes(data.buffer.asUint8List());
//
//       // Ab file path se load karo
//       await loadModel(tempFile.path);
//     } catch (e) {
//       throw Exception('Failed to load model from assets: $e');
//     }
//   }
//
//   static Future<void> loadModel(String modelPath) async {
//     await _channel.invokeMethod('loadModel', {"path": modelPath});
//   }
//
//   static Future<List<dynamic>> runInference(List<double> input, List<int> shape) async {
//     final result = await _channel.invokeMethod('runInference', {
//       "input": input,
//       "shape": shape,
//     });
//     return result as List<dynamic>;
//   }
// }