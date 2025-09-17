package com.example.untitled

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.Interpreter
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import android.content.res.AssetFileDescriptor
import java.io.FileInputStream
import kotlin.math.exp

class MainActivity: FlutterActivity() {
    private val CHANNEL = "gesturevox/tflite"
    private lateinit var interpreter: Interpreter

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        try {
            // Load model at startup
            interpreter = Interpreter(loadModelFile("gesture_model.tflite"))

            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "runModel" -> {
                        try {
                            val inputList = call.arguments as List<Double>
                            val prediction = runGestureModel(inputList)
                            result.success(prediction)
                        } catch (e: Exception) {
                            result.error("MODEL_ERROR", "Error running model: ${e.message}", null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        } catch (e: Exception) {
            // Handle model loading error
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                result.error("MODEL_LOAD_ERROR", "Failed to load model: ${e.message}", null)
            }
        }
    }

    private fun runGestureModel(inputData: List<Double>): Map<String, Any> {
        // Ensure input has correct size (440 features = 20 timesteps * 22 features)
        if (inputData.size != 440) {
            throw IllegalArgumentException("Input size must be 440, got ${inputData.size}")
        }

        // Apply normalization similar to MinMaxScaler used in Python
        val normalizedData = normalizeData(inputData)

        // Prepare input tensor - shape should be [1, 20, 22]
        val inputBuffer = ByteBuffer.allocateDirect(1 * 20 * 22 * 4) // 4 bytes per float
        inputBuffer.order(ByteOrder.nativeOrder())

        // Fill input buffer with normalized data
        for (value in normalizedData) {
            inputBuffer.putFloat(value.toFloat())
        }
        inputBuffer.rewind()

        // Prepare output tensor
        // Assuming your model outputs probabilities for gesture classes
        val outputBuffer = ByteBuffer.allocateDirect(1 * 6 * 4) // Assuming 6 classes
        outputBuffer.order(ByteOrder.nativeOrder())

        // Run inference
        interpreter.run(inputBuffer, outputBuffer)

        // Extract output probabilities
        outputBuffer.rewind()
        val probabilities = FloatArray(6)
        for (i in probabilities.indices) {
            probabilities[i] = outputBuffer.float
        }
        println(probabilities)

        // Apply softmax to get normalized probabilities
        val softmaxProbs = softmax(probabilities)

        // Find the class with highest probability
        val maxIndex = softmaxProbs.indices.maxByOrNull { softmaxProbs[it] } ?: 0
        val confidence = softmaxProbs[maxIndex]

        // Map class indices to gesture labels (based on your training data)
        val gestureLabels = arrayOf(
            "السلام علیکم",  // Hello/Peace be upon you
            "آپ کيسے ہيں",         // Thank you
            "وہ لڑکا ہے",     // Sorry/Excuse me
            "وہ لڑکی ہے",     // Welcome
            "رونا",        // Goodbye
            "معذرت"            // Help
        )

        val predictedGesture = if (maxIndex < gestureLabels.size) {
            gestureLabels[maxIndex]
        } else {
            "نامعلوم" // Unknown
        }

        return mapOf(
            "prediction" to predictedGesture,
            "confidence" to confidence.toDouble(),
            "probabilities" to softmaxProbs.map { it.toDouble() },
            "classIndex" to maxIndex
        )
    }

    private fun normalizeData(data: List<Double>): List<Double> {
        // Simple min-max normalization
        // In production, you should use the same scaler parameters from training
        val minVal = data.minOrNull() ?: 0.0
        val maxVal = data.maxOrNull() ?: 1.0
        val range = maxVal - minVal

        return if (range > 0) {
            data.map { (it - minVal) / range }
        } else {
            data.map { 0.5 } // If all values are same, normalize to 0.5
        }
    }

    private fun softmax(logits: FloatArray): FloatArray {
        val maxLogit = logits.maxOrNull() ?: 0f
        val expValues = logits.map { exp((it - maxLogit).toDouble()).toFloat() }
        val sumExp = expValues.sum()
        return expValues.map { it / sumExp }.toFloatArray()
    }

    private fun loadModelFile(modelPath: String): MappedByteBuffer {
        val fileDescriptor: AssetFileDescriptor = assets.openFd(modelPath)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }
}