import 'package:flutter/material.dart';
import 'my_onnx_plugin.dart';
import 'package:flutter_tts/flutter_tts.dart';


void main() {
  // Initialize Flutter bindings first
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ONNX Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _status = "Not loaded";
  List<dynamic> _results = [];
   List<String> gestureLabels = [
    "Hello",
    "Yes",
    "No",
    "Thank You",
    "Peace",
    "Stop"
  ];


  @override
  void initState() {
    super.initState();
    // Load the model after the widget is initialized
    _loadModel();
  }
  final FlutterTts flutterTts = FlutterTts();

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(0.5);
    await flutterTts.speak(text);
  }

  Future<void> _loadModel() async {
    try {
      // Asset se model load karo
      await MyOnnxPlugin.loadModelFromAssets("assets/gesture_model.onnx");
      setState(() {
        _status = "Model loaded successfully from assets";
      });
    } catch (e) {
      setState(() {
        _status = "Error loading model: $e";
      });
    }
  }

  Future<void> _runInference() async {
    try {
      List<double> inputData = List.generate(20 * 22, (i) => i.toDouble());
      List<int> inputShape = [1, 20, 22];

      List<dynamic> results = await MyOnnxPlugin.runInference(inputData, inputShape);

      // Convert results to double list
      List<double> probs = results.map((e) => e as double).toList();

      // Find predicted gesture
      int predictedIndex = probs.indexWhere((p) => p == probs.reduce((a, b) => a > b ? a : b));
      String predictedGesture = gestureLabels[predictedIndex];

      setState(() {
        _results = probs;
        _status = "Predicted: $predictedGesture";
      });

      await _speak(predictedGesture);

    } catch (e) {
      print("Error running inference: $e");
      setState(() {
        _status = "Error running inference: $e";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ONNX Flutter Demo'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model Status:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(_status),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _runInference,
              child: Text('Run Inference'),
            ),
            SizedBox(height: 20),
            if (_results.isNotEmpty) ...[
              Text(
                'Results:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 8),
              Text(_results.toString()),
            ],
          ],
        ),
      ),
    );
  }
}