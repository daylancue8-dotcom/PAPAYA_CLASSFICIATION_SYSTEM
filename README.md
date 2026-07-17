# PAPAYA_CLASSFICIATION_SYSTEM
Real-time Papaya Ripeness Detection mobile app using a lightweight CNN exported to TFLite for on-device inference. Captures camera frames, classifies ripeness (Unripe / Ripe / Overripe), and shows results with confidence and recommendations.

Features

Real-time mode: continuous live detection with a scanning UI.
Manual capture: capture photo → detailed result screen.
On-device ML: inference with tflite_flutter using a bundled TFLite model and labels.
Confidence filtering: predictions below 75% are suppressed to avoid false positives.
Tech Stack

Mobile framework: Flutter
ML runtime: tflite_flutter
Camera & images: camera, image, image_picker
Key Files

Classifier: lib/classifier/papaya_classifier.dart
Camera flow: lib/screens/camera_screen.dart
Result UI: lib/screens/result_screen.dart
Dependencies & assets: pubspec.yaml
Model + labels: assets/papaya_model.tflite, assets/labels.txt

Quick Start

Install Flutter and set up your device/emulator.
From repository root:
cd frontend
flutter pub get
flutter run

Notes

Threshold logic (75% min confidence) is implemented in camera_screen.dart. Adjust _minConfidence if needed.
Replace the TFLite model or retrain if you need different classes or improved accuracy.
Contributing

How to help: open issues for bugs, add tests, improve model preprocessing, or refine UI.
License: add your preferred license file or update LICENSE in the repo.
