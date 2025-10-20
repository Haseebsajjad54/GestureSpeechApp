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
    final isAvailable = await FlutterBluePlus.isAvailable;
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
    List<BluetoothDevice> connectedDevices = await FlutterBluePlus.connectedDevices;
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

  Future<List<double>?> getSensorData() async {
    try {
      // Read data from both gloves
      List<double>? leftData = await readGloveData(true);
      List<double>? rightData = await readGloveData(false);

      if (leftData == null || rightData == null) {
        print("❌ Failed to read from one or both gloves");
        return null;
      }

      // Combine data from both gloves into a single features list
      List<double> features = [...leftData, ...rightData];

      print("✅ Combined features from both gloves: $features");
      return features;
    } catch (e) {
      print("❌ Error getting sensor data: $e");
      return null;
    }
  }

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

              // Convert bytes to list of doubles
              List<double> doubleValues = _bytesToDoubles(value);
              print("✅ ${isLeftHand ? 'Left' : 'Right'} glove data: $doubleValues");
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

// Helper function to convert bytes to list of doubles
  List<double> _bytesToDoubles(List<int> bytes) {
    List<double> doubles = [];

    try {
      // If bytes represent ASCII comma-separated values (e.g., "1.2,3.4,5.6")
      String data = String.fromCharCodes(bytes);
      List<String> values = data.split(',');

      for (var value in values) {
        double? parsed = double.tryParse(value.trim());
        if (parsed != null) {
          doubles.add(parsed);
        }
      }

      // If no values parsed, try interpreting bytes as float32 array
      if (doubles.isEmpty) {
        doubles = _bytesToFloat32Array(bytes);
      }

      return doubles;
    } catch (e) {
      print("❌ Error converting bytes to doubles: $e");
      return [];
    }
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