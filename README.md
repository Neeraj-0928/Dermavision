# DermaVision 🩺✨

> **AI-Powered Dermatological Screening & Skin Health Management System**

DermaVision is an intelligent mobile health solution built with **Flutter** and **TensorFlow Lite**. It integrates real-time computer vision, edge-based machine learning for skin image validation, disease screening analysis, automated PDF medical report generation, and clinic discovery services.

---

## 🌟 Key Features

### 1. 📱 Cross-Platform Mobile Experience (Flutter)
- **Modern UI/UX**: Clean, responsive, medical-grade aesthetic with dark/light theme support.
- **Interactive Onboarding**: Guided walkthrough illustrating AI diagnostics, skin safety, and clinic discovery.
- **Firebase Authentication**: Secure user registration, email verification, and profile management.
- **Interactive Dashboard**: Quick access to recent scans, health metrics, and saved reports.

### 2. 🧠 Edge AI Skin vs. Non-Skin Validation Model
- **Pre-analysis Validation**: Custom deep-learning filter deployed directly on-device using **TensorFlow Lite (`skin_non_skin.tflite`)**.
- **Rejection of Invalid Inputs**: Ensures only genuine skin images proceed to disease analysis, filtering out accidental captures, background objects, and irrelevant surfaces.
- **Confidence Abstain Band**: Threshold calibration configured via `model_meta.json` to prevent ambiguous borderline predictions.
- **Cross-Platform Engine Support**: Native platform bindings and graceful fallback interfaces for web/desktop.

### 3. 📄 Clinical Reporting & PDF Generation
- **Automated Medical Reports**: Generates professional, formatted PDF clinical summaries containing:
  - Patient & timestamp metadata
  - Input dermoscopic / clinical image
  - Prediction confidence and severity risk breakdown
  - Recommended precautions and consult guidelines
- **History Tracking**: Local and cloud synchronization of past scans and diagnostic trends.

### 4. 🏥 Clinic Finder & Geolocation
- **Nearby Dermatologist Locator**: Integrates location services to recommend verified local skin clinics and dermatologists.

---

## 🏗️ Repository Architecture

```text
├── dermavision/                 # Flutter Mobile Application
│   ├── android/                 # Android native project files
│   ├── ios/                     # iOS native project files
│   ├── assets/
│   │   ├── images/              # UI illustrations, brand badges, onboarding assets
│   │   └── models/
│   │       └── skin_non_skin.tflite # Deployed on-device TFLite model (~9.5 MB)
│   ├── lib/
│   │   ├── core/theme/          # Design tokens, AppColors, AppTextStyles
│   │   ├── models/              # UserModel, ReportModel data contracts
│   │   ├── providers/           # State management (Auth, Reports)
│   │   ├── screens/             # Onboarding, Auth, Home, Scan, Result, Reports, Profile
│   │   ├── services/            # TFLite engine, SkinDetector, PDF & Clinic services
│   │   └── widgets/             # Reusable UI components & buttons
│   └── pubspec.yaml             # Flutter dependencies & assets config
│
├── skin_non_skin/               # AI Model Training & Evaluation Pipeline
│   ├── skin_nonskin.py          # Data ingestion, augmentation & training script
│   ├── model_meta.json          # Calibrated confidence thresholds & metadata
│   ├── skin_non_skin.tflite     # Exported float32/quantized edge inference model
│   ├── best_skin_non_skin_model.keras # Checkpointed deep learning weights
│   ├── accuracy_curve.png       # Training vs. Validation accuracy curve
│   ├── loss_curve.png           # Training vs. Validation loss curve
│   ├── auc_curve.png            # ROC-AUC evaluation curve
│   └── confusion_matrix.png     # Validation confusion matrix
│
└── .gitignore                   # Excludes large raw datasets, build caches & gradle artifacts
```

---

## 📊 Machine Learning Model Details (Skin vs. Non-Skin Filter)

| Metric / Parameter | Value / Specification |
| :--- | :--- |
| **Model Format** | TensorFlow Lite (`.tflite`) & Keras (`.keras`) |
| **Deployment Target** | On-Device Edge Inference (Mobile) |
| **Model Size** | ~9.5 MB (TFLite) |
| **Confidence Threshold (Skin)** | `≥ 0.62` |
| **Non-Skin Threshold** | `≤ 0.38` |
| **Abstain Band** | Active for ambiguous/borderline predictions |
| **Lighting Normalization** | Luminance-only lighting normalization |

### Evaluation Metrics
The pipeline scripts generate comprehensive performance plots located in `skin_non_skin/`:
- `accuracy_curve.png`
- `loss_curve.png`
- `auc_curve.png`
- `confusion_matrix.png`

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.0.0 or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / Xcode (with Android SDK / iOS toolchain configured)
- Physical device or emulator with camera support

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Neeraj-0928/Dermavision.git
   cd Dermavision/dermavision
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```

---

## 🔒 Notes on Models & Datasets

- **Trained Edge Models**: The production-ready `skin_non_skin.tflite` model is included in `dermavision/assets/models/` and `skin_non_skin/` for immediate deployment and testing.
- **Raw Image Datasets**: Multi-gigabyte raw training image datasets are excluded from version control via `.gitignore` to comply with Git repository storage standards.
- **Upcoming Updates**: Additional fine-grained skin lesion classification models (7-class HAM10000 / ISIC multi-level disease classifiers) will be updated in subsequent milestones.

---

## 📜 License
This project is developed for academic, research, and non-commercial health technology demonstration purposes.
