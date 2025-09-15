package com.example.untitled

import ai.onnxruntime.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.FloatBuffer

class MyOnnxPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var env: OrtEnvironment? = null
    private var session: OrtSession? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "onnx_channel")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> {
                val modelPath = call.argument<String>("path")!!
                try {
                    env = OrtEnvironment.getEnvironment()
                    session = env!!.createSession(modelPath, OrtSession.SessionOptions())
                    result.success("Model loaded")
                } catch (e: Exception) {
                    result.error("LOAD_ERROR", "Failed to load model: ${e.message}", null)
                }
            }
            "runInference" -> {
//                try {
//                    val inputData = call.argument<List<Double>>("input")!!
//                    // Convert List<Double> -> FloatArray
//                    val floatInput = inputData.map { it.toFloat() }.toFloatArray()
//                    val shape = longArrayOf(1, floatInput.size.toLong())
//
//                    // Create tensor using FloatBuffer approach
//                    val buffer = FloatBuffer.allocate(floatInput.size)
//                    buffer.put(floatInput)
//                    buffer.rewind()
//
//                    val tensor = OnnxTensor.createTensor(env!!, buffer, shape)
//
//                    val outputs = session!!.run(mapOf("input" to tensor))
//                    val outputTensor = outputs[0] as OnnxTensor
//                    val outputArray = outputTensor.floatBuffer.array()
//
//                    result.success(outputArray.map { it.toDouble() })
//
//                    // Clean up
//                    tensor.close()
//                    outputs.forEach { it.value.close() }
//                } catch (e: Exception) {
//                    result.error("INFERENCE_ERROR", "Failed to run inference: ${e.message}", null)
//                }
                try {
                    val inputData = call.argument<List<Double>>("input")!!
                    val inputShape = call.argument<List<Int>>("shape")!!

                    val floatInput = inputData.map { it.toFloat() }.toFloatArray()
                    val shape = inputShape.map { it.toLong() }.toLongArray()

                    val buffer = FloatBuffer.allocate(floatInput.size)
                    buffer.put(floatInput)
                    buffer.rewind()

                    val tensor = OnnxTensor.createTensor(env!!, buffer, shape)

                    val outputs = session!!.run(mapOf("input" to tensor))
                        print("Results: $outputs")
                    val rawOutput = outputs[0].value
                    val outputList: List<Double> = when (rawOutput) {
                        is Array<*> -> (rawOutput as Array<FloatArray>).flatMap { row -> row.map { it.toDouble() } }
                        is FloatArray -> rawOutput.map { it.toDouble() }
                        else -> throw Exception("Unsupported output type: ${rawOutput!!::class.java}")
                    }

                    result.success(outputList)

                    tensor.close()
                    outputs.close()
                } catch (e: Exception) {
                    e.printStackTrace()
                    result.error("INFERENCE_ERROR", "Failed to run inference: ${e.message}", null)
                }


            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // Clean up resources
        session?.close()
        env?.close()
    }
}
