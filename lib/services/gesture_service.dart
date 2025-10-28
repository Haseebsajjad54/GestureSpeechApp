import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';


class GestureService {
  bool isLHConnected = false;
  bool isRHConnected = false;

  BluetoothDevice? leftGlove;
  BluetoothDevice? rightGlove;

  bool get areBothConnected => isLHConnected && isRHConnected;

  Future<void> connectBLE() async {
    print("🔍 Scanning for BLE Gloves...");

    // ✅ Check Bluetooth availability
    final isAvailable = await FlutterBluePlus.isSupported;
    if (!isAvailable) {
      print("❌ Bluetooth not available on this device.");
      throw Exception("Bluetooth not available");
    }

    // ✅ Check if Bluetooth is ON
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      print("❌ Bluetooth is OFF. Please turn it on.");
      throw Exception("Bluetooth is turned off");
    }

    // ✅ Stop any previous scan
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("⚠️ Error stopping previous scan: $e");
    }

    // ✅ Check already connected devices first
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
    for (var device in connectedDevices) {
      final name = device.platformName;
      if (name.contains("Glove_LH") && !isLHConnected) {
        leftGlove = device;
        isLHConnected = true;
        print("✅ Left Hand Glove Already Connected: ${device.remoteId}");
      }
      if (name.contains("Glove_RH") && !isRHConnected) {
        rightGlove = device;
        isRHConnected = true;
        print("✅ Right Hand Glove Already Connected: ${device.remoteId}");
      }
    }

    // If both are already connected, return early
    if (areBothConnected) {
      print("🎯 Both gloves already connected!");
      return;
    }

    // ✅ Start scanning
    print("🔎 Starting BLE scan...");

    late StreamSubscription<List<ScanResult>> subscription;
    Completer<void> scanCompleter = Completer<void>();

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: false,
    );

    subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (final result in results) {
        final name = result.device.platformName;

        if (name.isEmpty) continue; // Skip devices with no name

        print("📡 Found device: $name (RSSI: ${result.rssi})");

        // ✅ Connect Left Glove
        if (name.contains("Glove_LH") && !isLHConnected) {
          try {
            print("🔗 Connecting to Left Hand Glove...");
            await result.device.connect(
              timeout: const Duration(seconds: 10),
              autoConnect: false,
            );
            leftGlove = result.device;
            isLHConnected = true;
            print("✅ Left Hand Glove Connected: ${result.device.remoteId}");
          } catch (e) {
            print("❌ Failed to connect Left Glove: $e");
          }
        }

        // ✅ Connect Right Glove
        if (name.contains("Glove_RH") && !isRHConnected) {
          try {
            print("🔗 Connecting to Right Hand Glove...");
            await result.device.connect(
              timeout: const Duration(seconds: 10),
              autoConnect: false,
            );
            rightGlove = result.device;
            isRHConnected = true;
            print("✅ Right Hand Glove Connected: ${result.device.remoteId}");
          } catch (e) {
            print("❌ Failed to connect Right Glove: $e");
          }
        }

        // ✅ Both connected → stop scan
        if (areBothConnected) {
          print("🎯 Both gloves connected successfully!");
          if (!scanCompleter.isCompleted) {
            scanCompleter.complete();
          }
        }
      }
    }, onError: (error) {
      print("❌ Scan error: $error");
      if (!scanCompleter.isCompleted) {
        scanCompleter.completeError(error);
      }
    });

    // ✅ Wait for scan completion or timeout
    try {
      await scanCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print("⏱️ Scan timeout reached");
        },
      );
    } catch (e) {
      print("⚠️ Scan error: $e");
    }

    // ✅ Stop scan and cancel subscription
    await FlutterBluePlus.stopScan();
    await subscription.cancel();

    // ✅ Final status
    if (areBothConnected) {
      print("🎉 SUCCESS: Both gloves connected!");
    } else if (isLHConnected || isRHConnected) {
      print("⚠️ Partial connection:");
      print("   Left: ${isLHConnected ? '✅' : '❌'}");
      print("   Right: ${isRHConnected ? '✅' : '❌'}");
    } else {
      print("❌ No gloves found. Make sure they are powered on and in range.");
      throw Exception("No gloves found");
    }
  }

  /// Disconnect from gloves
  Future<void> disconnect() async {
    try {
      if (leftGlove != null) {
        await leftGlove!.disconnect();
        print("🔌 Left Glove disconnected");
      }
      if (rightGlove != null) {
        await rightGlove!.disconnect();
        print("🔌 Right Glove disconnected");
      }
    } catch (e) {
      print("⚠️ Disconnect error: $e");
    }

    isLHConnected = false;
    isRHConnected = false;
    leftGlove = null;
    rightGlove = null;
  }

  /// Get sensor data from a specific glove
  // Future<String?> readGloveData(bool isLeftHand) async {
  //   try {
  //     final device = isLeftHand ? leftGlove : rightGlove;
  //
  //     if (device == null) {
  //       print("❌ ${isLeftHand ? 'Left' : 'Right'} glove not connected");
  //       return null;
  //     }
  //
  //     // Discover services
  //     List<BluetoothService> services = await device.discoverServices();
  //
  //     // Find your service UUID
  //     const serviceUuid = "12345678-1234-1234-1234-123456789012";
  //     const characteristicUuid = "87654321-4321-4321-4321-210987654321";
  //
  //     for (var service in services) {
  //       if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
  //         for (var characteristic in service.characteristics) {
  //           if (characteristic.uuid.toString().toLowerCase() ==
  //               characteristicUuid.toLowerCase()) {
  //
  //             // Read data
  //             List<int> value = await characteristic.read();
  //             String data = String.fromCharCodes(value);
  //             return data;
  //           }
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     print("❌ Error reading glove data: $e");
  //   }
  //   return null;
  // }
  List<List<double>> gestureBuffer = [];
  static const int FRAMES_PER_GESTURE = 20;
  static const int FRAME_DELAY_MS = 150;
  static const int SENSORS_PER_FRAME = 22;

  /// Collects gesture data over 3 seconds (20 frames at 150ms intervals)
  /// Returns a 2D list: (20, 22) where 20 = frames, 22 = sensor values per frame
  Future<List<List<double>>?> getSensorData() async {
    try {
      gestureBuffer.clear();

      print("📊 Starting gesture capture: 20 frames over 3 seconds...");

      // Collect 20 frames
      for (int frame = 0; frame < FRAMES_PER_GESTURE; frame++) {
        // Read data from both gloves
        List<double>? leftData = await readGloveData(true);
        List<double>? rightData = await readGloveData(false);

        if (leftData == null || rightData == null) {
          print("❌ Failed to read from one or both gloves at frame $frame");
          return null;
        }

        // Validate data length (each glove should have 11 values)
        // Left: 5 flex + 3 gyro + 3 accel = 11
        // Right: 5 flex + 3 gyro + 3 accel = 11
        // Total: 22 values
        if (leftData.length != 11 || rightData.length != 11) {
          print("❌ Invalid data length at frame $frame. Left: ${leftData.length}, Right: ${rightData.length}");
          return null;
        }

        // Combine data from both gloves into a single frame
        List<double> frameData = [...leftData, ...rightData];
        gestureBuffer.add(frameData);

        print("✅ Frame ${frame + 1}/$FRAMES_PER_GESTURE captured: ${frameData.length} values");

        // Wait 150ms before next frame (skip delay on last frame)
        if (frame < FRAMES_PER_GESTURE - 1) {
          await Future.delayed(Duration(milliseconds: FRAME_DELAY_MS));
        }
      }

      print("✅ Gesture capture complete: ${gestureBuffer.length} frames");
      return gestureBuffer;

    } catch (e) {
      print("❌ Error getting sensor data: $e");
      return null;
    }
  }

  /// Reads sensor data from a single glove
  /// Returns 11 values: [5 flex, 3 gyro, 3 accel]
  Future<List<double>?> readGloveData(bool isLeftHand) async {
    try {
      final device = isLeftHand ? leftGlove : rightGlove;

      if (device == null) {
        print("❌ ${isLeftHand ? 'Left' : 'Right'} glove not connected");
        return null;
      }

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find your service UUID
      const serviceUuid = "12345678-1234-1234-1234-123456789012";
      const characteristicUuid = "87654321-4321-4321-4321-210987654321";

      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                characteristicUuid.toLowerCase()) {

              // Read data as bytes
              List<int> value = await characteristic.read();

              // Convert bytes to list of doubles (should be 11 values)
              List<double> doubleValues = _bytesToDoubles(value);

              // Validate expected length
              if (doubleValues.length != 11) {
                print("⚠️ Warning: ${isLeftHand ? 'Left' : 'Right'} glove returned ${doubleValues.length} values, expected 11");
              }

              return doubleValues;
            }
          }
        }
      }
      print("❌ Characteristic not found for ${isLeftHand ? 'Left' : 'Right'} glove");
    } catch (e) {
      print("❌ Error reading glove data: $e");
    }
    return null;
  }

  /// Helper function to convert bytes to doubles
  /// Assumes each value is 4 bytes (float32)
  List<double> _bytesToDoubles(List<int> bytes) {
    List<double> doubles = [];

    // Process bytes in groups of 4 (assuming float32 encoding)
    for (int i = 0; i < bytes.length; i += 4) {
      if (i + 3 < bytes.length) {
        // Convert 4 bytes to float
        ByteData byteData = ByteData(4);
        byteData.setUint8(0, bytes[i]);
        byteData.setUint8(1, bytes[i + 1]);
        byteData.setUint8(2, bytes[i + 2]);
        byteData.setUint8(3, bytes[i + 3]);

        double value = byteData.getFloat32(0, Endian.little);
        doubles.add(value);
      }
    }

    return doubles;
  }

  /// Optional: Convert buffer to format expected by TensorFlow Lite
  /// Input shape: (1, 20, 22)
  List<List<List<double>>> formatForModel(List<List<double>> buffer) {
    if (buffer.length != FRAMES_PER_GESTURE ||
        buffer[0].length != SENSORS_PER_FRAME) {
      throw Exception("Invalid buffer dimensions");
    }

    // Wrap in another list to create batch dimension (1, 20, 22)
    return [buffer];
  }

// Helper function to convert bytes to float32 array (if data is binary)
  List<double> _bytesToFloat32Array(List<int> bytes) {
    List<double> floats = [];
    ByteData byteData = ByteData.view(Uint8List.fromList(bytes).buffer);

    try {
      // Read as float32 values (4 bytes per float)
      for (int i = 0; i < byteData.lengthInBytes; i += 4) {
        if (i + 4 <= byteData.lengthInBytes) {
          double value = byteData.getFloat32(i, Endian.little);
          floats.add(value);
        }
      }
      return floats;
    } catch (e) {
      print("❌ Error converting to float32 array: $e");
      return [];
    }
  }

  /// Subscribe to real-time notifications from gloves
  Stream<String>? subscribeToGlove(bool isLeftHand) {
    try {
      final device = isLeftHand ? leftGlove : rightGlove;

      if (device == null) {
        print("❌ ${isLeftHand ? 'Left' : 'Right'} glove not connected");
        return null;
      }

      const serviceUuid = "12345678-1234-1234-1234-123456789012";
      const characteristicUuid = "87654321-4321-4321-4321-210987654321";

      return device.servicesStream.asyncExpand((services) async* {
        for (var service in services) {
          if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
            for (var characteristic in service.characteristics) {
              if (characteristic.uuid.toString().toLowerCase() ==
                  characteristicUuid.toLowerCase()) {

                // Enable notifications
                await characteristic.setNotifyValue(true);

                // Stream the data
                await for (var value in characteristic.lastValueStream) {
                  if (value.isNotEmpty) {
                    yield String.fromCharCodes(value);
                  }
                }
              }
            }
          }
        }
      });
    } catch (e) {
      print("❌ Error subscribing to glove: $e");
      return null;
    }
  }
}