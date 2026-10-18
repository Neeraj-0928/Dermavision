abstract class TfliteEngine {
  bool get isSupported;
  Future<void> loadModel(String assetPath);
  void run(Object input, Object output);
  void close();
}
