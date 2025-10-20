import 'package:flutter/material.dart';
import 'dart:async';
import '../services/gesture_service.dart';
import '../services/apiService.dart';

class GloveConnectionController extends ChangeNotifier {
  final GestureService _gestureService = GestureService();
  final ApiService _apiService = ApiService();
  Timer? _dataStreamTimer;

  // State variables
  bool _isConnecting = false;
  bool _isStreaming = false;
  String _statusMessage = "Not Connected";
  String _lastPrediction = "No prediction yet";

  // Getters
  bool get isConnecting => _isConnecting;
  bool get isStreaming => _isStreaming;
  String get statusMessage => _statusMessage;
  String get lastPrediction => _lastPrediction;

  // Connect to gloves
  Future<void> connectGloves() async {
    _isConnecting = true;
    _statusMessage = "Connecting to gloves...";
    notifyListeners();

    try {
      await _gestureService.connectBLE();
      _statusMessage = _gestureService.areBothConnected
          ? "✅ Both Gloves Connected"
          : "⚠️ Partial Connection";

      if (_gestureService.areBothConnected) {
        startDataStream();
      }
    } catch (e) {
      _statusMessage = "❌ Connection Failed: $e";
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  // Start streaming data from gloves
  void startDataStream() {
    if (_isStreaming) return;

    _isStreaming = true;
    notifyListeners();

    _dataStreamTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
          try {
            final features = await _gestureService.readGloveData(true);

            if (features != null && features.isNotEmpty) {
              final prediction = await _apiService.sendPredictionRequest(features);

              _lastPrediction = prediction ?? "No response";
              notifyListeners();
            }
          } catch (e) {
            print("Error in data stream: $e");
          }
        });
  }

  // Stop streaming data
  void stopDataStream() {
    _dataStreamTimer?.cancel();
    _dataStreamTimer = null;
    _isStreaming = false;
    _lastPrediction = "No prediction yet";
    notifyListeners();
  }

  // Disconnect gloves
  Future<void> disconnectGloves() async {
    stopDataStream();
    await _gestureService.disconnect();
    _statusMessage = "🔌 Disconnected";
    notifyListeners();
  }

  @override
  void dispose() {
    stopDataStream();
    super.dispose();
  }
}