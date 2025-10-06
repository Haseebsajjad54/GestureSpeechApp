import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class GestureService {
  // ====== BLE Configuration ======
  static const String SERVICE_UUID = "12345678-1234-1234-1234-123456789012";
  static const String CHARACTERISTIC_UUID = "87654321-4321-4321-4321-210987654321";

  // ====== BLE Connections ======
  BluetoothDevice? _lhDevice;
  BluetoothDevice? _rhDevice;
  BluetoothCharacteristic? _lhChar;
  BluetoothCharacteristic? _rhChar;

  StreamSubscription? _scanSubscription;

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
  // ====== Connect via BLE ==============================
  // =====================================================
  Future<void> connectBLE() async {
    print("🔍 Scanning for BLE Gloves...");

    // Check Bluetooth state
    if (await FlutterBluePlus.isSupported == false) {
      print("❌ Bluetooth not supported");
      return;
    }

    // Start scan
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      androidUsesFineLocation: true,
    );

    // Listen for scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        final name = r.device.platformName;

        // Check for Left Hand Glove
        if (name.contains("Air") && _lhDevice == null) {
          print("🎯 Found LH Glove: $name");
          _lhDevice = r.device;
          FlutterBluePlus.stopScan();
          await _connectBLEDevice(_lhDevice!, "Air");
        }
        // Check for Right Hand Glove
        else if (name.contains("Glove_RH") && _rhDevice == null) {
          print("🎯 Found RH Glove: $name");
          _rhDevice = r.device;
          FlutterBluePlus.stopScan();
          await _connectBLEDevice(_rhDevice!, "RH");
        }

        // If both gloves found, stop scanning
        if (_lhDevice != null && _rhDevice != null) {
          FlutterBluePlus.stopScan();
          print("✅ Both gloves found!");
          break;
        }
      }
    }, onError: (e) {
      print("❌ Scan error: $e");
    });

    // Auto stop scan after timeout
    await Future.delayed(const Duration(seconds: 10));
    await FlutterBluePlus.stopScan();
  }

  Future<void> _connectBLEDevice(BluetoothDevice device, String hand) async {
    try {
      print("🔗 Connecting to $hand glove: ${device.platformName}");

      // Connect to device
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      print("✅ Connected to $hand glove");

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      bool foundCharacteristic = false;

      for (var service in services) {
        // Check if this is our service
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          print("📡 Found service for $hand glove");

          for (var char in service.characteristics) {
            // Check if this is our characteristic
            if (char.uuid.toString().toLowerCase() == CHARACTERISTIC_UUID.toLowerCase()) {
              print("📡 Found characteristic for $hand glove");

              if (char.properties.notify) {
                if (hand == "LH") {
                  _lhChar = char;
                } else if (hand == "RH") {
                  _rhChar = char;
                }

                // Enable notifications
                await char.setNotifyValue(true);

                // Listen to data
                char.lastValueStream.listen((value) {
                  if (value.isNotEmpty) {
                    final msg = utf8.decode(value);
                    _handleBLEMessage(hand, msg);
                  }
                }, onError: (error) {
                  print("❌ Stream error ($hand): $error");
                });

                foundCharacteristic = true;
                print("✅ $hand Glove notifications enabled!");
                break;
              }
            }
          }
        }

        if (foundCharacteristic) break;
      }

      if (!foundCharacteristic) {
        print("⚠️ Could not find correct characteristic for $hand glove");
      }

    } catch (e) {
      print("❌ Error connecting to $hand glove: $e");
      rethrow;
    }
  }

  void _handleBLEMessage(String hand, String msg) {
    try {
      // Arduino sends: "LH_Flex:10,20,30,40,50 | LH_Gyro:1.2,3.4,5.6 | LH_Accel:0.1,0.2,0.9"
      final parsed = _parseSensorString(msg, hand);
      updateSensorData(hand, parsed);
      // Uncomment for debugging:
      // print("📩 [$hand] Flex: ${parsed['Flex']}, Gyro: ${parsed['Gyro']}, Accel: ${parsed['Accel']}");
    } catch (e) {
      print("❌ BLE parse error ($hand): $e - Message: $msg");
    }
  }

  Map<String, dynamic> _parseSensorString(String msg, String hand) {
    final data = {
      "Flex": <double>[],
      "Gyro": <double>[],
      "Accel": <double>[]
    };

    try {
      // Split by pipe (|)
      final parts = msg.split("|");

      for (var part in parts) {
        part = part.trim();

        // Remove hand prefix (LH_ or RH_)
        part = part.replaceAll("${hand}_", "");

        if (part.contains("Flex:")) {
          final values = part.split(":")[1].split(",");
          data["Flex"] = values.map((e) => double.parse(e.trim())).toList();
        }
        else if (part.contains("Gyro:")) {
          final values = part.split(":")[1].split(",");
          data["Gyro"] = values.map((e) => double.parse(e.trim())).toList();
        }
        else if (part.contains("Accel:")) {
          final values = part.split(":")[1].split(",");
          data["Accel"] = values.map((e) => double.parse(e.trim())).toList();
        }
      }
    } catch (e) {
      print("⚠️ Parse failed for: $msg");
      print("Error: $e");
    }

    return data;
  }

  // =====================================================
  // ====== Common Methods ===============================
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
      return {"error": "⚠️ No data from Gloves. LH: ${sensorData["LH"] != null}, RH: ${sensorData["RH"] != null}"};
    }

    int frames = 0;
    List<List<double>> framesList = [];
    final t0 = DateTime.now();

    print("🎬 Starting gesture recording...");

    while (frames < 20 && DateTime.now().difference(t0).inSeconds < 10) {
      final lh = sensorData["LH"];
      final rh = sensorData["RH"];

      if (lh == null || rh == null) {
        await Future.delayed(const Duration(milliseconds: 50));
        continue;
      }

      final lv = _extractValues(Map<String, dynamic>.from(lh));
      final rv = _extractValues(Map<String, dynamic>.from(rh));

      // Validate data
      if (lv["Flex"]!.length == 5 &&
          lv["Gyro"]!.length == 3 &&
          lv["Accel"]!.length == 3 &&
          rv["Flex"]!.length == 5 &&
          rv["Gyro"]!.length == 3 &&
          rv["Accel"]!.length == 3) {

        // One frame = 22 features
        List<double> frame = [];
        frame.addAll(lv["Flex"]!);  // 5
        frame.addAll(lv["Gyro"]!);  // 3
        frame.addAll(lv["Accel"]!); // 3
        frame.addAll(rv["Flex"]!);  // 5
        frame.addAll(rv["Gyro"]!);  // 3
        frame.addAll(rv["Accel"]!); // 3

        framesList.add(frame);
        frames++;
        print("✅ Frame $frames/20 recorded");

        await Future.delayed(const Duration(milliseconds: 150));
      } else {
        print("⚠️ Incomplete data - LH: ${lv}, RH: ${rv}");
      }
    }

    if (frames < 20) {
      return {"error": "⚠️ Only $frames/20 frames recorded"};
    }

    print("✅ Recording completed! Shape = 1×20×22");

    return await _sendPredictionRequest(framesList);
  }

  Future<Map<String, dynamic>> _sendPredictionRequest(
      List<List<double>> frames) async {
    final url = Uri.parse("http://YOUR_SERVER_IP:8000/predict");

    try {
      print("📤 Sending prediction request...");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"features": [frames]}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print("✅ Prediction received: $result");
        return result;
      } else {
        return {"error": "Server error ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": "Failed to connect: $e"};
    }
  }

  Future<void> disconnect() async {
    // Stop scanning
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();

    // Disconnect BLE devices
    if (_lhDevice != null) {
      await _lhDevice!.disconnect();
      print("❌ LH Glove disconnected");
    }

    if (_rhDevice != null) {
      await _rhDevice!.disconnect();
      print("❌ RH Glove disconnected");
    }

    // Clear references
    _lhDevice = null;
    _rhDevice = null;
    _lhChar = null;
    _rhChar = null;

    sensorData = {"LH": null, "RH": null};

    print("✅ All connections closed");
  }

  // Check connection status
  bool get isLHConnected => _lhDevice != null && _lhChar != null;
  bool get isRHConnected => _rhDevice != null && _rhChar != null;
  bool get areBothConnected => isLHConnected && isRHConnected;
}