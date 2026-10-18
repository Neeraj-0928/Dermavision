import 'package:tflite_flutter/tflite_flutter.dart';
import 'tflite_engine_interface.dart';

class TfliteEngineImpl implements TfliteEngine {
  Interpreter? _interpreter;

  @override
  bool get isSupported => true;

  @override
  Future<void> loadModel(String assetPath) async {
    _interpreter ??= await Interpreter.fromAsset(assetPath);
  }

  @override
  void run(Object input, Object output) {
    if (_interpreter == null) {
      throw StateError('TFLite interpreter is not initialized.');
    }
    _interpreter!.run(input, output);
  }

  @override
  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}

TfliteEngine getTfliteEngine() => TfliteEngineImpl();
