import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

// Add flutter_blue_plus for BLE
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class GestureService {
  // ====== WebSocket Connections ======
  WebSocketChannel? _lhChannel;
  WebSocketChannel? _rhChannel;

  // ====== BLE Connections ======
  BluetoothDevice? _lhDevice;
  BluetoothDevice? _rhDevice;
  BluetoothCharacteristic? _lhChar;
  BluetoothCharacteristic? _rhChar;

  // Latest incoming ESP32 data
  Map<String, dynamic> sensorData = {
    "LH": null,
    "RH": null,
  };

  // Singleton instance
  static final GestureService _instance = GestureService._internal();
  factory GestureService() => _instance;
  GestureService._internal();

  // =====================================================
  // ====== OPTION 1: Connect via WebSocket (old) ========
  // =====================================================
  Future<void> connectToESP({
    required String lhIp,
    required String rhIp,
  }) async {
    // LH glove
    _lhChannel = WebSocketChannel.connect(Uri.parse("ws://$lhIp:81"));
    _lhChannel!.stream.listen(
          (message) {
        try {
          final data = jsonDecode(message);
          updateSensorData("LH", data);
        } catch (e) {
          print("LH JSON error: $e");
        }
      },
      onError: (err) => print("❌ LH error: $err"),
      onDone: () => print("⚠ LH WebSocket closed"),
    );

    // RH glove
    _rhChannel = WebSocketChannel.connect(Uri.parse("ws://$rhIp:81"));
    _rhChannel!.stream.listen(
          (message) {
        try {
          final data = jsonDecode(message);
          updateSensorData("RH", data);
        } catch (e) {
          print("RH JSON error: $e");
        }
      },
      onError: (err) => print("❌ RH error: $err"),
      onDone: () => print("⚠ RH WebSocket closed"),
    );

    print("✅ Connected to ESP32 gloves via WebSocket");
  }

  // =====================================================
  // ====== OPTION 2: Connect via BLE (new) ==============
  // =====================================================
  Future<void> connectBLE() async {
    print("🔍 Scanning for BLE Gloves...");

    // Start scan
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    // Listen for devices
    FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        final name = r.device.platformName;
        if (name.contains("Glove_LH") && _lhDevice == null) {
          _lhDevice = r.device;
          await _connectBLEDevice(_lhDevice!, "LH");
        } else if (name.contains("Glove_RH") && _rhDevice == null) {
          _rhDevice = r.device;
          await _connectBLEDevice(_rhDevice!, "RH");
        }
      }
    });
  }

  Future<void> _connectBLEDevice(BluetoothDevice device, String hand) async {
    print("🔗 Connecting to $hand glove: ${device.platformName}");
    await device.connect(autoConnect: false);

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var char in service.characteristics) {
        if (char.properties.notify) {
          if (hand == "LH") {
            _lhChar = char;
            await char.setNotifyValue(true);
            char.lastValueStream.listen((value) {
              final msg = utf8.decode(value);
              _handleBLEMessage(hand, msg);
            });
          } else if (hand == "RH") {
            _rhChar = char;
            await char.setNotifyValue(true);
            char.lastValueStream.listen((value) {
              final msg = utf8.decode(value);
              _handleBLEMessage(hand, msg);
            });
          }
        }
      }
    }

    print("✅ $hand Glove connected via BLE!");
  }

  void _handleBLEMessage(String hand, String msg) {
    try {
      // ⚠ ESP32 is sending plain text, not JSON
      // Example: "LH_Flex:10,20,30,40,50 | LH_Gyro:.. | LH_Accel:.."
      final parsed = _parseSensorString(msg);
      updateSensorData(hand, parsed);
      print("📩 [$hand] $parsed");
    } catch (e) {
      print("❌ BLE parse error ($hand): $e");
    }
  }

  Map<String, dynamic> _parseSensorString(String msg) {
    final data = {"Flex": [], "Gyro": [], "Accel": []};

    try {
      final parts = msg.split("|");
      for (var part in parts) {
        part = part.trim();
        if (part.contains("Flex")) {
          data["Flex"] = part.split(":")[1].split(",").map((e) => double.parse(e)).toList();
        } else if (part.contains("Gyro")) {
          data["Gyro"] = part.split(":")[1].split(",").map((e) => double.parse(e)).toList();
        } else if (part.contains("Accel")) {
          data["Accel"] = part.split(":")[1].split(",").map((e) => double.parse(e)).toList();
        }
      }
    } catch (e) {
      print("⚠ Parse failed: $msg");
    }

    return data;
  }

  // =====================================================
  // ====== Common Methods (Both BLE + WS) ===============
  // =====================================================
  void updateSensorData(String hand, Map<String, dynamic> data) {
    if (hand != "LH" && hand != "RH") {
      throw ArgumentError("Hand must be 'LH' or 'RH'");
    }
    sensorData[hand] = data;
  }

  Map<String, List<double>> _extractValues(Map<String, dynamic> data) {
    return {
      "Flex": List<double>.from(data["Flex"] ?? []),
      "Gyro": List<double>.from(data["Gyro"] ?? []),
      "Accel": List<double>.from(data["Accel"] ?? []),
    };
  }

  Future<Map<String, dynamic>> recordGesture() async {
    print("⏳ Waiting for data from Gloves...");
    final startWait = DateTime.now();

    // Wait max 10s for both gloves
    while (DateTime.now().difference(startWait).inSeconds < 10) {
      if (sensorData["LH"] != null && sensorData["RH"] != null) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (sensorData["LH"] == null || sensorData["RH"] == null) {
      return {"error": "⚠ No data from Gloves"};
    }

    int frames = 0;
    List<List<double>> framesList = [];
    final t0 = DateTime.now();

    while (frames < 20 &&
        DateTime.now().difference(t0).inSeconds < 10) {
      final lh = sensorData["LH"];
      final rh = sensorData["RH"];

      final lv = _extractValues(Map<String, dynamic>.from(lh));
      final rv = _extractValues(Map<String, dynamic>.from(rh));

      if (lv["Flex"]!.length == 5 && rv["Flex"]!.length == 5) {
        // One frame = 22 features
        List<double> frame = [];
        frame.addAll(lv["Flex"]!);
        frame.addAll(lv["Gyro"]!);
        frame.addAll(lv["Accel"]!);

        frame.addAll(rv["Flex"]!);
        frame.addAll(rv["Gyro"]!);
        frame.addAll(rv["Accel"]!);

        framesList.add(frame);
        frames++;
        print("✅ Frame $frames/20 recorded");

        await Future.delayed(const Duration(milliseconds: 150));
      }
    }

    if (frames < 20) {
      return {"error": "⚠ Only $frames/20 frames recorded"};
    }

    print("✅ Recording completed! Shape = 1×20×22");

    return await _sendPredictionRequest(framesList);
  }

  Future<Map<String, dynamic>> _sendPredictionRequest(
      List<List<double>> frames) async {
    final url = Uri.parse("http://YOUR_SERVER_IP:8000/predict");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"features": [frames]}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Server error ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": "Failed to connect: $e"};
    }
  }

  void disconnect() {
    // WebSocket disconnect
    _lhChannel?.sink.close();
    _rhChannel?.sink.close();

    // BLE disconnect
    _lhDevice?.disconnect();
    _rhDevice?.disconnect();

    print("❌ Disconnected from Gloves");
  }
}
