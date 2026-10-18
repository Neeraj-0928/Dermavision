import 'tflite_engine_interface.dart';
import 'tflite_engine_stub.dart'
    if (dart.library.io) 'tflite_engine_native.dart';

export 'tflite_engine_interface.dart';

TfliteEngine createTfliteEngine() => getTfliteEngine();
