import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class PapayaClassifier {
  static const String _modelPath  = 'assets/papaya_model.tflite';
  static const String _labelsPath = 'assets/labels.txt';
  static const int    _inputSize  = 224;
  static const int    _numClasses = 3;

  Interpreter?   _interpreter;
  List<String>   _labels = [];
  bool           _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // ── Initialize model ──────────────────────────────────────
  Future<void> initialize() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: options,
      );

      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();

      _isInitialized = true;
      debugPrint('✅ PapayaClassifier initialized');
      debugPrint('   Labels: $_labels');
    } catch (e) {
      debugPrint('❌ Failed to initialize classifier: $e');
      _isInitialized = false;
    }
  }

  // ── Classify image from bytes ──────────────────────────────
  Future<ClassificationResult?> classifyImage(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      debugPrint('❌ Classifier not initialized');
      return null;
    }

    try {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      img.Image resizedImage = img.copyResize(
        image,
        width:  _inputSize,
        height: _inputSize,
      );

      // ── FIXED: ResNet50 preprocess_input ──────────────────
      // Must match training preprocessing exactly
      final input = _imageToResNet50Input(resizedImage);

      final output = List.filled(1 * _numClasses, 0.0)
          .reshape([1, _numClasses]);

      _interpreter!.run(input, output);

      final probabilities = List<double>.from(output[0]);
      final maxIndex      = _argmax(probabilities);
      final confidence    = probabilities[maxIndex];
      final label         = _labels[maxIndex];

      return ClassificationResult(
        label:           label,
        confidence:      confidence,
        allProbabilities: Map.fromIterables(_labels, probabilities),
      );
    } catch (e) {
      debugPrint('❌ Classification error: $e');
      return null;
    }
  }

  // ── ResNet50 preprocess_input ─────────────────────────────
  // Matches: tf.keras.applications.resnet50.preprocess_input
  // Converts RGB → BGR and subtracts ImageNet channel means
  List<List<List<List<double>>>> _imageToResNet50Input(img.Image image) {
    // ImageNet channel means (BGR order)
    const double meanB = 103.939;
    const double meanG = 116.779;
    const double meanR = 123.68;

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = image.getPixel(x, y);

            // ── Convert RGB → BGR and subtract means ─────────
            final b = pixel.b.toDouble() - meanB;
            final g = pixel.g.toDouble() - meanG;
            final r = pixel.r.toDouble() - meanR;

            // Return in BGR order (ResNet50 format)
            return [b, g, r];
          },
        ),
      ),
    );
    return input;
  }

  // ── Get index of max value ────────────────────────────────
  int _argmax(List<double> values) {
    int    maxIndex = 0;
    double maxValue = values[0];
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxValue) {
        maxValue = values[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  // ── Dispose ───────────────────────────────────────────────
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

// ── Classification Result Model ───────────────────────────
class ClassificationResult {
  final String              label;
  final double              confidence;
  final Map<String, double> allProbabilities;

  const ClassificationResult({
    required this.label,
    required this.confidence,
    required this.allProbabilities,
  });

  // ── Display label ─────────────────────────────────────────
  String get displayLabel => label;

  // ── Confidence as percentage ──────────────────────────────
  String get confidencePercent =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  // ── Color for each class ──────────────────────────────────
  // ✅ Capitalized to match training labels: Unripe, Ripe, Overripe
  Color get labelColor {
    switch (label) {
      case 'Ripe':
        return const Color(0xFF4CAF50);     // Green
      case 'Unripe':
        return const Color(0xFF2196F3);     // Blue
      case 'Overripe':
        return const Color(0xFFFF5722);     // Deep Orange
      default:
        return const Color(0xFF9E9E9E);     // Grey
    }
  }

  // ── Emoji for each class ──────────────────────────────────
  String get emoji {
    switch (label) {
      case 'Ripe':     return '✅';
      case 'Unripe':   return '🟡';
      case 'Overripe': return '⚠️';
      default:         return '❓';
    }
  }

  // ── Recommendation text ───────────────────────────────────
  String get recommendation {
    switch (label) {
      case 'Ripe':
        return 'This papaya is ready to eat or sell. '
            'Best consumed within 1–2 days.';
      case 'Unripe':
        return 'This papaya needs more time to ripen. '
            'Store at room temperature for 3–5 more days.';
      case 'Overripe':
        return 'This papaya is overripe. Use immediately '
            'for smoothies or cooking. Not ideal for direct sale.';
      default:
        return 'Unable to determine ripeness. Please try again.';
    }
  }
}

// ── Minimal Color class (if not using Flutter material) ───
// Remove this if you already have Flutter material imported
// Use Flutter's `Color` type from painting via material imports elsewhere.
// No local Color shim here to avoid type conflicts with Flutter.