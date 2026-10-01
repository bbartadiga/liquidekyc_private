# POC Liquid eKYC Flutter App

Implementasi Flutter eKYC menggunakan Liquid SDK v1.47.0 dengan arsitektur MVVM + Provider dan Android MethodChannel bridge.

---

## 📋 Daftar Isi

1. [Struktur Project](#struktur-project)
2. [Arsitektur](#arsitektur)
3. [Konfigurasi](#konfigurasi)
4. [Flow eKYC](#flow-ekyc)
5. [Komponen UI](#komponen-ui)
6. [Mode Debug vs Real](#mode-debug-vs-real)
7. [Setup & Installation](#setup--installation)
8. [Build & Run](#build--run)
9. [Referensi SDK](#referensi-sdk)

---

## 🏗️ Struktur Project

```
lib/
├── app/
│   ├── app.dart                    # Root app dengan Provider setup
│   └── liquid_config.dart          # Konfigurasi SDK credentials
├── core/
│   ├── constant/
│   │   └── liquid_constants.dart   # Enums, constants, DEBUG_MODE flag
│   └── di/
│       └── injection.dart          # Dependency injection
├── data/
│   ├── models/
│   │   ├── kyc_result.dart         # Model result dari SDK
│   │   └── kyc_step.dart           # Enum step proses KYC
│   └── repositories/
│       └── kyc_repository.dart     # Repository pattern untuk SDK calls
├── persentation/
│   ├── viewmodels/
│   │   └── kyc_viewmodel.dart      # ViewModel dengan Business Logic
│   └── views/
│       ├── screens/
│       │   ├── kyc_home_screen.dart         # ID Selection screen
│       │   ├── kyc_instruction_screen.dart  # User instruction screens
│       │   ├── kyc_result_screen.dart       # Result/Success/Error screen
│       │   └── kyc_status_screen.dart       # Progress indicator
│       └── widgets/
│           ├── kyc_loading_overlay.dart     # Loading overlay dengan step
│           └── kyc_dialogs.dart             # Error/Retry/Confirm dialogs
└── services/
    └── liquid_ekyc_channel.dart    # Flutter MethodChannel client

android/app/src/main/kotlin/.../
├── MainActivity.kt                 # Plugin registration
└── LiquidEkycPlugin.kt            # MethodChannel handler (Hybrid mode)
```

---

## 🏛️ Arsitektur

### Pattern: MVVM + Repository + Provider

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ Home Screen │→ │ Instruction  │→ │ Result Screen    │   │
│  │ (Selection) │  │ Screen       │  │ (Success/Error)  │   │
│  └─────────────┘  └──────────────┘  └──────────────────┘   │
└────────────────────────────┬────────────────────────────────┘
                             │ Provider.of<KycViewModel>
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    ViewModel Layer                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ KycViewModel                                          │   │
│  │ - selectedMethod, selectedDocument, selectedFaceType │   │
│  │ - startKyc(), cancelKyc()                            │   │
│  │ - isLoading, currentStep, errorMessage               │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                  Repository Layer                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ KycRepository                                        │   │
│  │ - launchDocumentVerification()                       │   │
│  │ - launchFaceVerification()                           │   │
│  │ - launchNFCVerification()                            │   │
│  │ - init()                                             │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                 MethodChannel Layer                          │
│  ┌─────────────────────┐    ┌──────────────────────────┐   │
│  │ liquid_ekyc_channel │───→│ LiquidEkycPlugin.kt      │   │
│  │ (Flutter)           │    │ (Android Kotlin)         │   │
│  └─────────────────────┘    └──────────────────────────┘   │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                       SDK Layer                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Liquid SDK (v1.47.0)                                 │   │
│  │ - LIQUID                                             │   │
│  │ - LiquidPluginML                                     │   │
│  │ - itrustekyclibrary (iTrust/Cybertrust)              │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚙️ Konfigurasi

### 1. Liquid Constants (`lib/core/constant/liquid_constants.dart`)

```dart
class LiquidConfig {
  // ============ SDK Credentials (ISI UNTUK REAL MODE) ============
  static const String apiUrl = 'YOUR_API_ENDPOINT_URL';
  static const String applicantId = 'YOUR_APPLICANT_ID';
  static const String token = 'YOUR_TOKEN';
  static const String apiKey = 'YOUR_API_KEY';

  // ============ Debug Mode Flag ============
  // true = Mock responses (tanpa SDK), false = Real SDK calls
  static const bool DEBUG_MODE = true;
}
```

### 2. Android Plugin (`android/app/src/main/kotlin/.../LiquidEkycPlugin.kt`)

```kotlin
object LiquidEkycPlugin {
    // sama dengan Dart DEBUG_MODE
    val DEBUG_MODE = true  // ubah ke false untuk real mode

    // Uncomment untuk real mode:
    // private val liquid: LIQUID? = null
    // private var currentVerificationType: String = ""
}
```

### 3. Android Gradle (`android/app/build.gradle.kts`)

```kotlin
android {
    defaultConfig {
        minSdk = 24  // minimum 24 untuk Liquid SDK
        // ...
    }
}
```

### 4. Android Permissions (`android/app/src/main/AndroidManifest.xml`)

```xml
<!-- Di luar <application> tag -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.NFC" />
<uses-permission android:name="android.permission.INTERNET" />

<uses-feature android:name="android.hardware.camera" android:required="true" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

---

## 🔄 Flow eKYC

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. HOME SCREEN (ID Selection)                                    │
│                                                                  │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │ [Pilih Jenis Dokumen]                                       │  │
│ │ ○ KTP                                                       │  │
│ │ ○ SIM                                                       │  │
│ │ ○ Passport                                                  │  │
│ ├────────────────────────────────────────────────────────────┤  │
│ │ [Pilih Metode Verifikasi]                                   │  │
│ │ ○ OCR + Face Match                                          │  │
│ │ ○ NFC + Face Match                                          │  │
│ │ ○ Full (OCR + NFC + Face Match)                             │  │
│ ├────────────────────────────────────────────────────────────┤  │
│ │ [Pilih Face Type]                                           │  │
│ │ ○ 1:1 Verification                                         │  │
│ │ ○ 1:N Identification                                       │  │
│ ├────────────────────────────────────────────────────────────┤  │
│ │                                                            │  │
│ │ [🚀 Mulai Verifikasi]                                       │  │
│ └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│ 2. INSTRUCTION SCREEN (Multi-page Guide)                        │
│                                                                  │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │ 1/5  ● ○ ○ ○ ○                                              │  │
│ │                                                            │  │
│ │ 📄 Persiapan Dokumen                                        │  │
│ │                                                            │  │
│ │ • Pastikan dokumen tidak rusak atau expired                │  │
│ │ • Bersihkan permukaan dokumen dari sidik jari              │  │
│ │ • Siapkan dokumen asli (bukan foto/scan)                   │  │
│ │                                                            │  │
│ │                              [Next →]                      │  │
│ └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│ Halaman lain:                                                    │
│ - 2: Panduan Pencahayaan                                        │
│ - 3: Panduan Wajah (1:1 / 1:N)                                  │
│ - 4: Panduan Chip IC (untuk NFC)                                │
│ - 5: iTrust/Cybertrust Declaration                              │
└──────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│ 3. LOADING OVERLAY (Step Indicator)                             │
│                                                                  │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │                                                            │  │
│ │              ╭──────────────────────────╮                  │  │
│ │              │       ◉ (spinning)       │                  │  │
│ │              │                          │                  │  │
│ │              │   Memindai Dokumen...    │                  │  │
│ │              │   Arahkan kamera ke      │                  │  │
│ │              │   dokumen identitas      │                  │  │
│ │              │                          │                  │  │
│ │              │   ● ○ ● ○ ○              │                  │  │
│ │              ╰──────────────────────────╯                  │  │
│ │                                                            │  │
│ └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│ 4. SDK Native UI (tanpa client control)                         │
│                                                                  │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │ [Camera View - SDK yang render]                            │  │
│ │                                                            │  │
│ │    ┌──────────────────────────────┐                        │  │
│ │    │                              │                        │  │
│ │    │      [Document Frame]        │                        │  │
│ │    │                              │                        │  │
│ │    └──────────────────────────────┘                        │  │
│ │                                                            │  │
│ │ [Terms of Use Screen - SDK]                                │  │
│ │ [Review Screen - SDK]                                      │  │
│ │                                                            │  │
│ └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│ 5. RESULT SCREEN                                                │
│                                                                  │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │                                                            │  │
│ │                    ✅ (green circle)                       │  │
│ │                                                            │  │
│ │            Verifikasi Berhasil!                            │  │
│ │                                                            │  │
│ │ ┌──────────────────────────────────────────────────────┐  │  │
│ │ │ Nama        : John Doe                                │  │  │
│ │ │NIK          : 1234567890123456                       │  │  │
│ │ │Jenis Kelamin: Laki-laki                               │  │  │
│ │ │Alamat       : Jl. Contoh No. 123                     │  │  │
│ │ │Berlaku Until: 01/01/2030                             │  │  │
│ │ └──────────────────────────────────────────────────────┘  │  │
│ │                                                            │  │
│ │ [Lanjutkan]                                                │  │
│ │                                                            │  │
│ │                       [Selesai]                           │  │
│ └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🎨 Komponen UI

### 1. Home Screen (`kyc_home_screen.dart`)

**Fungsi:** ID Selection screen - user pilih dokumen, metode, face type

**Key properties:**
- `selectedMethod: VerificationMethod` - OCR, NFC, atau Full
- `selectedDocumentType: LiquidDocumentType` - KTP, SIM, Passport, dll
- `selectedFaceType: FaceType` - 1:1 atau 1:N
- `isInProgress: bool` - cek apakah ada progress KYC sebelumnya

**Key methods:**
- `_buildDocumentSelector()` - radio buttons untuk dokumen
- `_buildMethodSelector()` - radio buttons untuk metode
- `_buildFaceTypeSelector()` - radio buttons untuk face type
- `_buildStartButton()` - button utama dengan navigation ke instruction screen

### 2. Instruction Screen (`kyc_instruction_screen.dart`)

**Fungsi:** Multi-page user guide sebelum KYC dimulai

**Props:**
```dart
KycInstructionScreen({
  required VerificationMethod method,      // untuk content yang relevan
  required LiquidDocumentType documentType, // untuk content yang relevan
  required VoidCallback onStart,           // callback saat user tap "Mulai"
  required VoidCallback onBack,            // callback saat user tap "Back"
})
```

**Pages:**
1. Persiapan Dokumen
2. Panduan Pencahayaan
3. Panduan Wajah
4. Panduan Chip IC (jika NFC method)
5. iTrust/Cybertrust Declaration

### 3. Loading Overlay (`kyc_loading_overlay.dart`)

**Fungsi:** Full-screen loading dengan step indicator

**Props:**
```dart
KycLoadingOverlay({
  required String title,      // e.g., "Memindai Dokumen..."
  String? message,            // e.g., "Arahkan kamera ke dokumen"
  KycStep? step,              // untuk progress indicator
})
```

**Steps (`KycStep` enum):**
- `initializing` - Menginisialisasi SDK
- `termsOfUse` - Menampilkan Syarat & Ketentuan
- `documentScan` - Memindai Dokumen
- `icCardRead` - Membaca Chip IC
- `faceScan` - Memindai Wajah
- `activating` - Mengaktifkan/Menyelesaikan

### 4. Dialogs (`kyc_dialogs.dart`)

**Fungsi:** Reusable dialog components

```dart
// Error Dialog
KycErrorDialog.show(
  context,
  title: 'Verifikasi Gagal',
  message: 'Terjadi kesalahan',
  errorCode: 'ERR_001',
  onRetry: () => Navigator.pop(context),
);

// Retry Confirmation Dialog
KycRetryDialog.show(
  context,
  title: 'Coba Lagi?',
  message: 'Apakah Anda ingin mengulang verifikasi?',
  onConfirm: () => startKyc(),
  onCancel: () => Navigator.pop(context),
);

// Cancel Confirmation Dialog
KycConfirmDialog.show(
  context,
  title: 'Batal?',
  message: 'Verifikasi belum selesai. Batalkan?',
  onConfirm: () => cancelKyc(),
  onCancel: () {},
);
```

### 5. Result Screen (`kyc_result_screen.dart`)

**Fungsi:** Universal result display (success/error)

```dart
// Success
KycResultScreen(
  isSuccess: true,
  result: kycResult,
  onNext: () => proceedToNextStep(),
  onDone: () => Navigator.pop(context),
);

// Error
KycResultScreen(
  isSuccess: false,
  title: 'Verifikasi Gagal',
  message: 'Terjadi kesalahan',
  errorCode: 'ERR_001',
  onRetry: () => retry(),
  onCancel: () => Navigator.pop(context),
  onDone: () => Navigator.pop(context),
);
```

---

## 🔀 Mode Debug vs Real

### Debug Mode (`DEBUG_MODE = true`)

```dart
// Di liquid_constants.dart dan LiquidEkycPlugin.kt
static const bool DEBUG_MODE = true;
```

**Karakteristik:**
- ✅ Semua UI screens berfungsi (instruction, loading, result, dialogs)
- ✅ Navigation flow normal
- ❌ Camera/NFC SDK tidak dipanggil
- ✅ Mock responses langsung kembali
- ✅ Tidak perlu credentials
- ✅ Aman untuk development/testing UI

**Mock Response Example:**
```json
{
  "isSuccess": true,
  "result": {
    "isSuccess": true,
    "verificationResult": {
      "name": "DEMO_USER",
      "nik": "1234567890123456",
      "birthDate": "1990-01-01",
      "gender": "Laki-laki",
      "address": "DEMO_ADDRESS",
      "validUntil": "2030-01-01"
    }
  }
}
```

### Real Mode (`DEBUG_MODE = false`)

```dart
// Di liquid_constants.dart
static const bool DEBUG_MODE = false;

// Di LiquidEkycPlugin.kt
val DEBUG_MODE = false

// Uncomment SDK code:
private val liquid: LIQUID? = null
// uncomment all liquid?.call() lines
```

**Yang perlu diisi:**
1. `apiUrl` - Endpoint Liquid API
2. `applicantId` - Applicant ID dari Liquid dashboard
3. `token` - Token autentikasi
4. `apiKey` - API Key

**Flow:**
1. SDK init dengan credentials
2. Launch document verifier (camera opens)
3. User scan document → SDK capture & OCR
4. SDK terms screen (if configured)
5. SDK review screen (if configured)
6. Face verification (camera opens again)
7. NFC verification (if selected) → NFC prompt
8. SDK return result via MethodChannel

---

## 🚀 Setup & Installation

### Prerequisites

- Flutter SDK (via FVM): `/Users/admin/fvm/versions/3.38.0/bin/flutter`
- Java 17 (untuk Android Gradle plugin 8.x)
- Android SDK dengan NDK (untuk native libraries)
- Android Studio / command line tools

### Steps

1. **Clone / Navigate ke project:**
   ```bash
   cd /Users/admin/Documents/BNI/test-bni/poc_liquidekyc_flutter
   ```

2. **Setup FVM (jika belum):**
   ```bash
   fvm install 3.38.0
   fvm use 3.38.0
   ```

3. **Get dependencies:**
   ```bash
   flutter pub get
   ```

4. **Configure credentials** (untuk real mode):
   - Edit `lib/core/constant/liquid_constants.dart`
   - Edit `LiquidEkycPlugin.kt`

5. **Setup Android SDK License:**
   ```bash
   yes | sdkmanager --licenses 2>/dev/null || true
   ```

---

## 🔨 Build & Run

### Build Debug APK

```bash
# Clean build
rm -rf build android/app/build

# Flutter build
flutter build apk --debug

# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Build Release APK

```bash
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Run on Device/Emulator

```bash
# List devices
flutter devices

# Run
flutter run -d <device_id>

# Example:
flutter run -d emulator-5554
flutter run -d 192.168.1.100:5555
```

### Run with specific Flutter version

```bash
/Users/admin/fvm/versions/3.38.0/bin/flutter run
```

---

## 📚 Referensi SDK

### Liquid SDK Components

| Library | Version | Purpose |
|---------|---------|---------|
| `LIQUID` | - | Core SDK untuk eKYC |
| `LiquidPluginML` | - | ML models untuk OCR & face matching |
| `itrustekyclibrary` | - | iTrust dari Cybertrust untuk document authenticity |
| `androidtiffbitmapfactory` | - | TIFF image processing |
| `jp2-android` | - | JPEG2000 image support |

### Key SDK Classes

```kotlin
// Android Kotlin
val liquid = LIQUID.getInstance()
liquid.init(applicationContext, ...)
liquid.setInfo(apiUrl, applicantId, token, apiKey)
liquid.launchDocumentVerification(activity, requestCode, documentType)
liquid.launchFaceVerification(activity, requestCode, faceType)
liquid.launchNFCVerification(activity, requestCode)
```

### MethodChannel Contract

| Channel | Method | Direction | Description |
|---------|--------|-----------|-------------|
| `com.liquid.ekyc` | `init` | Dart → Kotlin | Initialize SDK |
| `com.liquid.ekyc` | `setInfo` | Dart → Kotlin | Set credentials |
| `com.liquid.ekyc` | `launchDocumentVerification` | Dart → Kotlin | Start document scan |
| `com.liquid.ekyc` | `launchFaceVerification` | Dart → Kotlin | Start face scan |
| `com.liquid.ekyc` | `launchNFCVerification` | Dart → Kotlin | Start NFC read |

### Result Format

```dart
class KycResult {
  bool isSuccess;
  bool isCancelled;
  String? errorCode;
  String? errorMessage;
  Map<String, dynamic>? verificationResult;
  // fields: name, nik, birthDate, gender, address, validUntil, dll.
}
```

### SDK UI Screens (handled by SDK, not client)

- **Terms of Use Screen** - SDK renders automatically
- **Camera View** - SDK renders with document frame overlay
- **Review Screen** - SDK shows captured data for confirmation
- **NFC Prompt** - Native Android NFC system dialog

---

## ⚠️ Troubleshooting

### ML Errors di Debug Mode

> `ML initialization error` atau camera-related errors

**Penyebab:** SDK ML library di-load meskipun DEBUG_MODE=true

**Solusi:** Pastikan `DEBUG_MODE = true` di Kotlin file - SDK launchers tidak dipanggil dalam debug mode

### minSdk Warning

> `Minimum SDK version should be 24 or higher`

**Solusi:** Set `minSdk = 24` di `build.gradle.kts`

### jniLibs Packaging

> `PackagingOptions.jniLibs.useLegacyPackaging should be set to true`

**Solusi:** Tambahkan di `build.gradle.kts`:
```kotlin
packaging {
    jniLibs {
        useLegacyPackaging = true
    }
}
```

### Flutter Analyze Errors

> `Undefined identifier` atau `Missing parameter`

**Solusi:** Pastikan semua imports benar dan semua required parameters di-pass ke widgets

---

## 📝 Catatan Penting

1. **Folder naming:** `persentation` (dengan typo) - ini intentional, jangan rename
2. **Hybrid mode:** Single `DEBUG_MODE` flag mengontrol seluruh flow
3. **SDK UI:** SDK memberikan UI sendiri untuk camera, NFC, terms, review - client hanya build selection/instruction/loading/result screens
4. **Credentials:** Untuk development/testing, gunakan DEBUG_MODE=true tanpa credentials
5. **Android configuration:** minSdk 24, Java 17, Kotlin DSL (build.gradle.kts)

---

## 📞 Support

- Dokumentasi SDK: Liquid SDK v1.47.0 documentation
- iTrust: https://www.cybertrust.co.jp/
- Isu: Report ke development team