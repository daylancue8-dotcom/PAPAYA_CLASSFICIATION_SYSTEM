# 🍈 PapayaCheck — Flutter TFLite App
Real-Time Papaya Ripeness Detection System

---

## 📁 Project Structure

```
papaya_app/
├── lib/
│   ├── main.dart                        # App entry point
│   ├── classifier/
│   │   └── papaya_classifier.dart       # TFLite inference helper
│   └── screens/
│       ├── splash_screen.dart           # Loading screen
│       ├── home_screen.dart             # Main menu
│       ├── camera_screen.dart           # Live camera detection
│       ├── gallery_screen.dart          # Upload from gallery
│       ├── result_screen.dart           # Classification results
│       └── about_screen.dart            # Study info
├── assets/
│   └── models/
│       ├── papaya_model.tflite          # ← PUT YOUR MODEL HERE
│       └── labels.txt                   # ← Class labels
├── android/
│   └── app/src/main/AndroidManifest.xml # Camera permissions
├── pubspec.yaml                          # Dependencies
└── convert_to_tflite.ipynb             # Colab conversion notebook
```

---

## 🚀 Setup Instructions

### Step 1 — Train your model
Run `papaya_ripeness_classification.ipynb` in Google Colab

### Step 2 — Convert model to TFLite
Run `convert_to_tflite.ipynb` in Google Colab
This produces:
- `papaya_model.tflite`
- `labels.txt`

### Step 3 — Add model to Flutter
Copy both files to:
```
assets/models/papaya_model.tflite
assets/models/labels.txt
```

### Step 4 — Install dependencies
```bash
flutter pub get
```

### Step 5 — Run the app
```bash
flutter run
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---|---|---|
| tflite_flutter | ^0.10.4 | On-device AI inference |
| camera | ^0.10.5 | Live camera feed |
| image | ^4.1.7 | Image processing |
| image_picker | ^1.0.4 | Gallery access |

---

## 📱 App Screens

1. **Splash Screen** — Loading animation
2. **Home Screen** — Choose detection mode
3. **Camera Screen** — Live real-time detection
4. **Gallery Screen** — Upload photo from gallery
5. **Result Screen** — Classification result + confidence + recommendation
6. **About Screen** — Study and model information

---

## ⚠️ Important Notes

- Make sure `labels.txt` class order matches your training:
  ```
  overripe   ← index 0
  ripe       ← index 1
  unripe     ← index 2
  ```
  Keras sorts class names alphabetically by default.

- If your training used a different order, update `labels.txt` accordingly.

- For Android, minimum SDK version should be 21 or higher.

---

## 🎓 Study Information

**Title:** Development of a Real-Time Papaya Ripeness Detection and
Classification System Using Convolutional Neural Network

**Institution:** [Your School Name], Tacloban City, Leyte

**Dataset:** Locally collected from Tacloban City, validated by DA RFO VIII
