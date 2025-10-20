import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/prediction_controller.dart';




class GloveConnectionScreen extends StatelessWidget {
  const GloveConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GloveConnectionController(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gesture Glove Connector"),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Consumer<GloveConnectionController>(
              builder: (context, controller, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.statusMessage,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text("Last Prediction:"),
                          Text(controller.lastPrediction),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: controller.isConnecting ? null : controller.connectGloves,
                      icon: const Icon(Icons.bluetooth_connected),
                      label: const Text("Connect Gloves"),
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.disconnectGloves,
                      icon: const Icon(Icons.bluetooth_disabled),
                      label: const Text("Disconnect Gloves"),
                    ),
                    if (controller.isStreaming)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(width: 10),
                          Text("Streaming data..."),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}