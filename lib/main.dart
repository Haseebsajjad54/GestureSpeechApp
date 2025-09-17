import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GestureVox App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: GestureRecognitionScreen(),
    );
  }
}

class GestureRecognitionScreen extends StatefulWidget {
  @override
  _GestureRecognitionScreenState createState() => _GestureRecognitionScreenState();
}

class _GestureRecognitionScreenState extends State<GestureRecognitionScreen> {
  static const platform = MethodChannel('gesturevox/tflite');

  String _prediction = 'No prediction yet';
  double _confidence = 0.0;
  List<double> _probabilities = [];
  bool _isLoading = false;
  String _error = '';

  // Real gesture data samples extracted from your dataset
  // Each sample contains 20 timesteps × 22 features = 440 values
  List<double> _getRealGestureData(int gestureType) {
    // Sample data from your actual dataset
    List<List<double>> sampleGestures = [
      // Gesture 0: السلام علیکم (Hello/Peace be upon you)
      [
        210, 215, 206, 212, 255, 0.45, -0.97, -1.28, 6.99, -1.08, 6.36, 169, 227, 224, 178, 174, -1.57, -1.93, -5.54, -3.19, 1.54, 5.63,
        210, 214, 206, 212, 255, 0.47, -0.86, -1.19, 6.78, -1.4, 6.29, 152, 221, 221, 161, 172, -1.48, -2.23, -4.18, -3.54, 1.27, 5.55,
        208, 213, 206, 211, 255, 0.49, -0.95, -1.27, 6.91, -1.33, 6.39, 157, 224, 226, 164, 177, -1.54, -2.29, -4.19, -3.4, 1.18, 5.55,
        208, 211, 205, 211, 255, 0.54, -0.92, -1.15, 6.67, -1.88, 6.34, 161, 219, 231, 167, 180, 0.33, -0.85, -1.05, -3.03, -2.77, 7.87,
        208, 211, 205, 211, 255, 0.54, -0.92, -1.15, 6.67, -1.88, 6.34, 161, 219, 231, 167, 180, 0.33, -0.85, -1.05, -3.03, -2.77, 7.87,
        209, 212, 205, 211, 255, 0.57, -0.86, -1.17, 6.39, -2.09, 6.53, 157, 219, 227, 165, 173, 0.33, -0.61, -1.24, -4.13, -2.69, 8.51,
        209, 212, 205, 211, 255, 0.57, -0.86, -1.17, 6.39, -2.09, 6.53, 157, 219, 227, 165, 173, 0.33, -0.61, -1.24, -4.13, -2.69, 8.51,
        191, 202, 194, 199, 255, 0.67, -0.95, -1.17, 6.4, -1.99, 6.5, 183, 218, 175, 125, 176, -1.9, 3.4, 1.14, -8.43, 4.04, -3.83,
        210, 213, 206, 213, 255, 0.57, -0.9, -1.2, 6.51, -1.65, 6.58, 183, 218, 167, 122, 187, -1.41, 0.6, 0.01, -6.86, 5.98, -3.32,
        210, 213, 206, 212, 255, 0.57, -1.02, -1.25, 6.84, -1.73, 6.33, 194, 227, 191, 144, 182, -1.33, -0.36, 0.04, -5.94, 6.16, -1.84,
        212, 215, 208, 214, 255, 0.56, -1.06, -1.28, 6.88, -1.6, 6.27, 196, 227, 191, 142, 181, -0.43, -1.67, -1.08, -4.58, 7.3, -1.47,
        195, 203, 195, 202, 255, 0.59, -1.1, -1.31, 6.92, -1.28, 6.18, 194, 230, 186, 138, 181, -0.05, -1.55, -1.12, -4.38, 7.03, 0.79,
        212, 215, 207, 214, 255, 0.6, -1.05, -1.27, 7.04, -1.14, 6.16, 206, 231, 173, 135, 188, 0.38, -1.24, -1.28, -3.67, 8.3, 0.22,
        213, 216, 209, 216, 255, 0.59, -1, -1.24, 7.11, -1.12, 6.21, 207, 231, 174, 135, 188, -0.85, -2.59, -2.62, -3.71, 7.85, 0.8,
        213, 216, 209, 216, 255, 0.59, -1, -1.24, 7.11, -1.12, 6.21, 207, 231, 174, 135, 188, -0.85, -2.59, -2.62, -3.71, 7.85, 0.8,
        214, 216, 209, 216, 255, 0.55, -0.92, -1.23, 7.04, -1.36, 6.08, 208, 231, 178, 134, 177, -3.74, -5.18, -5.42, 5.98, 9.35, -2.97,
        214, 216, 209, 216, 255, 0.55, -0.92, -1.23, 7.04, -1.36, 6.08, 208, 231, 178, 134, 177, -3.74, -5.18, -5.42, 5.98, 9.35, -2.97,
        214, 216, 209, 217, 255, 0.63, -0.96, -1.12, 7.25, -1, 6.03, 210, 231, 180, 138, 179, -1.17, -2.77, -2.64, -4.91, 7.88, 1.45,
        215, 217, 210, 216, 255, 0.62, -0.95, -1.13, 7.25, -0.98, 6.05, 212, 232, 181, 139, 177, 0.06, -1.62, -1.55, -4.74, 7.85, 1.54,
        215, 217, 210, 216, 255, 0.62, -0.95, -1.13, 7.25, -0.98, 6.05, 212, 232, 181, 139, 177, 0.06, -1.62, -1.55, -4.74, 7.85, 1.54
      ],

      // Gesture 1: شکریہ (Thank you) - Modified version of base data
      [
        205, 210, 201, 207, 250, 0.40, -0.92, -1.23, 6.94, -1.03, 6.31, 164, 222, 219, 173, 169, -1.52, -1.88, -5.49, -3.14, 1.49, 5.58,
        205, 209, 201, 207, 250, 0.42, -0.81, -1.14, 6.73, -1.35, 6.24, 147, 216, 216, 156, 167, -1.43, -2.18, -4.13, -3.49, 1.22, 5.50,
        203, 208, 201, 206, 250, 0.44, -0.90, -1.22, 6.86, -1.28, 6.34, 152, 219, 221, 159, 172, -1.49, -2.24, -4.14, -3.35, 1.13, 5.50,
        203, 206, 200, 206, 250, 0.49, -0.87, -1.10, 6.62, -1.83, 6.29, 156, 214, 226, 162, 175, 0.28, -0.80, -1.00, -2.98, -2.72, 7.82,
        203, 206, 200, 206, 250, 0.49, -0.87, -1.10, 6.62, -1.83, 6.29, 156, 214, 226, 162, 175, 0.28, -0.80, -1.00, -2.98, -2.72, 7.82,
        204, 207, 200, 206, 250, 0.52, -0.81, -1.12, 6.34, -2.04, 6.48, 152, 214, 222, 160, 168, 0.28, -0.56, -1.19, -4.08, -2.64, 8.46,
        204, 207, 200, 206, 250, 0.52, -0.81, -1.12, 6.34, -2.04, 6.48, 152, 214, 222, 160, 168, 0.28, -0.56, -1.19, -4.08, -2.64, 8.46,
        186, 197, 189, 194, 250, 0.62, -0.90, -1.12, 6.35, -1.94, 6.45, 178, 213, 170, 120, 171, -1.85, 3.35, 1.09, -8.38, 3.99, -3.78,
        205, 208, 201, 208, 250, 0.52, -0.85, -1.15, 6.46, -1.60, 6.53, 178, 213, 162, 117, 182, -1.36, 0.55, -0.04, -6.81, 5.93, -3.27,
        205, 208, 201, 207, 250, 0.52, -0.97, -1.20, 6.79, -1.68, 6.28, 189, 222, 186, 139, 177, -1.28, -0.31, -0.01, -5.89, 6.11, -1.79,
        207, 210, 203, 209, 250, 0.51, -1.01, -1.23, 6.83, -1.55, 6.22, 191, 222, 186, 137, 176, -0.38, -1.62, -1.03, -4.53, 7.25, -1.42,
        190, 198, 190, 197, 250, 0.54, -1.05, -1.26, 6.87, -1.23, 6.13, 189, 225, 181, 133, 176, 0.00, -1.50, -1.07, -4.33, 6.98, 0.74,
        207, 210, 202, 209, 250, 0.55, -1.00, -1.22, 6.99, -1.09, 6.11, 201, 226, 168, 130, 183, 0.33, -1.19, -1.23, -3.62, 8.25, 0.17,
        208, 211, 204, 211, 250, 0.54, -0.95, -1.19, 7.06, -1.07, 6.16, 202, 226, 169, 130, 183, -0.80, -2.54, -2.57, -3.66, 7.80, 0.75,
        208, 211, 204, 211, 250, 0.54, -0.95, -1.19, 7.06, -1.07, 6.16, 202, 226, 169, 130, 183, -0.80, -2.54, -2.57, -3.66, 7.80, 0.75,
        209, 211, 204, 211, 250, 0.50, -0.87, -1.18, 6.99, -1.31, 6.03, 203, 226, 173, 129, 172, -3.69, -5.13, -5.37, 5.93, 9.30, -2.92,
        209, 211, 204, 211, 250, 0.50, -0.87, -1.18, 6.99, -1.31, 6.03, 203, 226, 173, 129, 172, -3.69, -5.13, -5.37, 5.93, 9.30, -2.92,
        209, 211, 204, 212, 250, 0.58, -0.91, -1.07, 7.20, -0.95, 5.98, 205, 226, 175, 133, 174, -1.12, -2.72, -2.59, -4.86, 7.83, 1.40,
        210, 212, 205, 211, 250, 0.57, -0.90, -1.08, 7.20, -0.93, 6.00, 207, 227, 176, 134, 172, 0.01, -1.57, -1.50, -4.69, 7.80, 1.49,
        210, 212, 205, 211, 250, 0.57, -0.90, -1.08, 7.20, -0.93, 6.00, 207, 227, 176, 134, 172, 0.01, -1.57, -1.50, -4.69, 7.80, 1.49
      ]
    ];

    // For other gesture types, create variations of the base data
    if (gestureType < sampleGestures.length) {
      return sampleGestures[gestureType];
    } else {
      // Create variations for other gesture types by modifying the base pattern
      List<double> baseData = List.from(sampleGestures[1]);
      final random = Random(gestureType); // Seed with gesture type for consistency

      for (int i = 0; i < baseData.length; i++) {
        // Apply gesture-specific modifications
        double modifier = 1.0;
        switch (gestureType) {
          case 2: // معاف کریں (Sorry)
            modifier = 0.85 + random.nextDouble() * 0.3;
            break;
          case 3: // خوش آمدید (Welcome)
            modifier = 1.1 + random.nextDouble() * 0.2;
            break;
          case 4: // الوداع (Goodbye)
            modifier = 0.9 + random.nextDouble() * 0.4;
            break;
          case 5: // مدد (Help)
            modifier = 1.15 + random.nextDouble() * 0.3;
            break;
        }

        baseData[i] = baseData[i] * modifier;

        // Add some noise based on gesture type
        double noise = (random.nextDouble() - 0.5) * 0.1;
        baseData[i] += noise;
      }

      return baseData;
    }
  }

  Future<void> _runGestureRecognition(int gestureType) async {
    setState(() {
      _isLoading = true;
      _error = '';
      _prediction = 'Processing...';
    });

    try {
      // Get real gesture data for the selected gesture type
      final inputData = _getRealGestureData(gestureType);

      // Call the native method
      final result = await platform.invokeMethod('runModel', inputData);

      if (result is Map) {
        setState(() {
          _prediction = result['prediction'] ?? 'Unknown';
          _confidence = result['confidence'] ?? 0.0;
          _probabilities = List<double>.from(result['probabilities'] ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception('Invalid response format');
      }
    } on PlatformException catch (e) {
      setState(() {
        _error = "Platform Error: ${e.message}";
        _prediction = 'Error occurred';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error: ${e.toString()}";
        _prediction = 'Error occurred';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GestureVox - Urdu Gesture Recognition'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.gesture,
                        size: 60,
                        color: Colors.teal,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Gesture Recognition Result',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      if (_isLoading)
                        CircularProgressIndicator(color: Colors.teal)
                      else if (_error.isNotEmpty)
                        Text(
                          _error,
                          style: TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        )
                      else
                        Column(
                          children: [
                            Text(
                              _prediction,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Test Different Gestures:',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildGestureButton(0, 'السلام علیکم', 'Hello', Icons.waving_hand),
                    _buildGestureButton(1, 'آپ کيسے ہيں', 'Thank You', Icons.favorite),
                    _buildGestureButton(2, 'وہ لڑکا ہے', 'Sorry', Icons.heart_broken_outlined),
                    _buildGestureButton(3, 'وہ لڑکی ہے', 'Welcome', Icons.emoji_people),
                    _buildGestureButton(4, 'رونا', 'Goodbye', Icons.back_hand),
                    _buildGestureButton(5, 'معذرت', 'Help', Icons.help),
                  ],
                ),
              ),
              if (_probabilities.isNotEmpty) ...[
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Predictions:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),
                        ..._buildProbabilityBars(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestureButton(int gestureType, String urduText, String englishText, IconData icon) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _runGestureRecognition(gestureType),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade100,
        foregroundColor: Colors.teal.shade800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          SizedBox(height: 4),
          Text(
            urduText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            englishText,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProbabilityBars() {
    final labels = [
      'السلام علیکم',
      'شکریہ',
      'معاف کریں',
      'خوش آمدید',
      'الوداع',
      'مدد'
    ];

    return List.generate(_probabilities.length, (index) {
      if (index >= labels.length) return SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                labels[index],
                style: TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: _probabilities[index],
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '${(_probabilities[index] * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    });
  }
}