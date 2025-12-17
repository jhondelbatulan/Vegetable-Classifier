import 'package:tflite_v2/tflite_v2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TFLiteHelper {
  static Future loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  static Future<List?> classifyImage(String imagePath) async {
    final results = await Tflite.runModelOnImage(
      path: imagePath,
      numResults: 10,
      threshold: 0.1,
    );
    
    // Debug: print all predictions to console
    if (results != null) {
      // ignore: avoid_print
      print('=== All Predictions ===');
      for (int i = 0; i < results.length; i++) {
        // ignore: avoid_print
        print('${i + 1}. ${results[i]['label']}: ${(results[i]['confidence'] * 100).toStringAsFixed(2)}%');
      }
      // ignore: avoid_print
      print('====================');
    }
    
    return results;
  }

  /// Logs a single prediction (map with 'label' and 'confidence') to Firestore.
  /// Adds a document to the `predictions` collection with a server timestamp.
  static Future<void> logPrediction(Map? prediction, {String? imagePath, bool submitted = false}) async {
    if (prediction == null) return;

    try {
      final doc = {
        'label': prediction['label'] ?? '',
        'confidence': prediction['confidence'] ?? 0.0,
        'imagePath': imagePath ?? '',
        'submitted': submitted,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('predictions').add(doc);
    } catch (e) {
      // Don't crash the app if logging fails; print for local debugging.
      // In production consider more robust error handling.
      // ignore: avoid_print
      print('Firestore log error: $e');
    }
  }

  static close() {
    Tflite.close();
  }
}
