import 'tflite_engine_interface.dart';

class TfliteEngineImpl implements TfliteEngine {
  @override
  bool get isSupported => false;

  @override
  Future<void> loadModel(String assetPath) async {}

  @override
  void run(Object input, Object output) {
    throw UnsupportedError('TFLite is not supported on this platform.');
  }

  @override
  void close() {}
}

TfliteEngine getTfliteEngine() => TfliteEngineImpl();
