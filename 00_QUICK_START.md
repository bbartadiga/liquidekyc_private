# Quick Start Guide - eKYC Flutter Project

**Untuk developer baru yang ikut project ini**

---

## Langkah 1: Setup Environment

```bash
# 1. Clone atau navigate ke project
cd /Users/admin/Documents/BNI/test-bni/poc_liquidekyc_flutter

# 2. Setup FVM (Flutter Version Manager)
fvm install 3.38.0
fvm use 3.38.0

# 3. Install dependencies
flutter pub get

# 4. Verify setup
flutter doctor
```

---

## Langkah 2: Project Structure (Yang Perlu Kamu Tau)

```
lib/
├── core/constant/liquid_constants.dart    ← ⚠️ CONFIGURATION UTAMA
├── data/services/liquid_connector_api.dart ← Backend API calls
├── persentation/
│   ├── viewmodels/kyc_viewmodel.dart      ← Business logic
│   └── views/screens/
│       ├── kyc_home_screen.dart           ← Main screen
│       ├── kyc_instruction_screen.dart    ← User guide
│       └── kyc_result_screen.dart         ← Result display
```

**File yang sering di-edit:**
- `liquid_constants.dart` - Configuration
- `kyc_home_screen.dart` - UI screens
- `kyc_viewmodel.dart` - Logic
- `LiquidEkycPlugin.kt` - Android side

---

## Langkah 3: Run the App

```bash
# Using FVM
/Users/admin/fvm/versions/3.38.0/bin/flutter run

# Or using system Flutter (if configured)
flutter run
```

### Build APK:
```bash
flutter build apk --debug
```

### Install to Device:
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## Langkah 4: Configuration Modes

Ada 3 mode yang perlu kamu tau:

### Mode 1: DEBUG (Mock Responses)
```dart
// lib/core/constant/liquid_constants.dart
static const bool DEBUG_MODE = true;  // ← Ubah ke true

// android/.../LiquidEkycPlugin.kt  
val DEBUG_MODE = true  // ← Ubah juga di Kotlin
```
✅ UI works, no camera, mock results  
❌ Tidak bisa test NFC/OCR/Face

---

### Mode 2: TRIAL (API Key Only)
```dart
// lib/core/constant/liquid_constants.dart
static const bool DEBUG_MODE = false;
static const String apiKey = 'YOUR_API_KEY';

// android/.../LiquidEkycPlugin.kt
val DEBUG_MODE = false
```
✅ Real SDK works  
✅ Camera opens  
❌ IC Card reading untuk KTP Indonesia tidak bisa (butuh sertifikat pemerintah)

---

### Mode 3: PRODUCTION (Dynamic Credentials)
```dart
// Backend kasih credentials, lalu di Flutter:
viewModel.setCredentials(
  applicantId: 'xxx',
  token: 'yyy',
);
viewModel.startKyc();
```

---

## Langkah 5: Key Concepts

### 5.1 Verification Flow (COMPLY_HE)

```
IC Chip (NFC) → OCR (Back capture) → Face (Verification)
     ↓               ↓                   ↓
   1. NFC        2. Document         3. Face
   Reading       Scanning           Matching
```

### 5.2 Supported Documents

| Document | Code | NFC Support |
|----------|------|-------------|
| Residence Card | `RESIDENCE_CARD` | ✅ |
| Special PR Certificate | `SPECIAL_PERMANENT_RESIDENT_CERTIFICATE` | ✅ |
| Driver License | `DRIVER_LICENSE` | ✅ |

### 5.3 MethodChannel Bridge

```
Flutter (Dart) ←→ MethodChannel ←→ Kotlin (Android) ←→ Liquid SDK
                    ↓
              liquid_ekyc_channel.dart
                    ↓
              LiquidEkycPlugin.kt
```

---

## Langkah 6: Testing

### Test DEBUG Mode:
```dart
// Set DEBUG_MODE = true di 2 tempat
// 1. lib/core/constant/liquid_constants.dart
// 2. android/.../LiquidEkycPlugin.kt

// Run app - UI works, no real SDK calls
```

### Test REAL Mode:
```dart
// Set DEBUG_MODE = false
// Pastikan API Key ada

// Run app - SDK opens camera, NFC, etc
```

### Monitor Logs:
```bash
# Clear logs
adb logcat -c

# Monitor
adb logcat | grep -iE "Liquid|KycViewModel"

# Or
adb logcat -d | grep -iE "liquid|kyc"
```

---

## Common Tasks

### ❓ Ubah Default Document Type
```dart
// lib/core/constant/liquid_constants.dart
enum LiquidDocumentType {
  ...
  static LiquidDocumentType get defaultType => LiquidDocumentType.residenceCard;
}
```

### ❓ Ubah Default Verification Method
```dart
// lib/core/constant/liquid_constants.dart
enum VerificationMethod {
  ...
  static VerificationMethod get defaultMethod => VerificationMethod.complyHe;
}
```

### ❓ Tambah Language Support
```dart
// ViewModel method
viewModel.setLanguage(DisplayLanguage.indonesian);

// Available languages
DisplayLanguage.auto
DisplayLanguage.japanese
DisplayLanguage.english
DisplayLanguage.indonesian
```

### ❓ Handle Result dari Verification
```dart
final result = await viewModel.startKyc();

if (result.isSuccess) {
  // Show success screen
  Navigator.push(...KycResultScreen(isSuccess: true, result: result));
} else {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(viewModel.errorMessage ?? 'Error'))
  );
}
```

### ❓ Connect ke Backend (Production Mode)
```dart
// 1. Backend call SDKApplyAPI → dapet token
// 2. Pass ke mobile
// 3. Set credentials
viewModel.setCredentials(
  applicantId: 'APPLICANT_ID_DARI_BACKEND',
  token: 'TOKEN_DARI_BACKEND',
);

// 4. Start verification
viewModel.startKyc();

// 5. Backend pull results via Connector APIs
```

---

## Troubleshooting Cheat Sheet

| Problem | Solution |
|---------|----------|
| App crash saat start | Check DEBUG_MODE consistency di Dart & Kotlin |
| Camera tidak open | Pastikan DEBUG_MODE = false |
| NFC tidak work | Check device support NFC, card type |
| Error NO_ACTIVITY | Update Kotlin plugin (sudah fixed) |
| Build failed | Run `flutter clean && flutter pub get` |
| ML error di logs | Normal di DEBUG mode, ignore |

---

## File Reference

| File | Purpose |
|------|---------|
| `liquid_constants.dart` | All enums, config, defaults |
| `kyc_viewmodel.dart` | Main business logic |
| `kyc_home_screen.dart` | Main UI screen |
| `LiquidEkycPlugin.kt` | Android MethodChannel |
| `liquid_connector_api.dart` | Backend API calls |

---

## Pre-requisites Knowledge

- Flutter basics (Widget, State, Provider)
- Android basics (Kotlin, MethodChannel)
- eKYC concepts (OCR, NFC, Face Verification)

---

## Questions?

Hubungi team lead atau cek dokumentasi lengkap di `PROJECT_DOCUMENTATION.md`

---

**Happy Coding! 🎉**