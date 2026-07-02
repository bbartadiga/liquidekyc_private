# 📚 Dokumentasi Project eKYC Flutter - Liquid SDK Integration

**Versi:** 1.0.0  
**Tanggal:** Juni 2025  
**Platform:** Android (Flutter)  
**SDK:** Liquid eKYC Applicant SDK v1.47.0

---

## 📋 Daftar Isi

1. [Gambaran Project](#1-gambaran-project)
2. [Struktur Project](#2-struktur-project)
3. [Arsitektur](#3-arsitektur)
4. [Setup & Konfigurasi](#4-setup--konfigurasi)
5. [Flow eKYC](#5-flow-ekyc)
6. [Integrasi Backend](#6-integrasi-backend)
7. [UI Components](#7-ui-components)
8. [SDK Integration](#8-sdk-integration)
9. [Build & Deployment](#9-build--deployment)
10. [Testing Guide](#10-testing-guide)
11. [Troubleshooting](#11-troubleshooting)
12. [API Reference](#12-api-reference)
13. [FAQ](#13-faq)

---

## 1. Gambaran Project

### 1.1 Deskripsi

Project ini adalah implementasi **Proof of Concept (POC)** untuk integrasi **Liquid eKYC SDK** dalam aplikasi Flutter untuk proses verifikasi identitas (eKYC).

### 1.2 Teknologi Stack

| Komponen | Teknologi | Versi |
|----------|-----------|-------|
| Frontend | Flutter | 3.38.0 (FVM) |
| State Management | Provider | 6.1.2 |
| HTTP Client | http | 1.2.0 |
| Platform | Android | API 24+ |
| SDK | Liquid eKYC | v1.47.0 |

### 1.3 Fitur Utama

- ✅ Verifikasi identitas menggunakan IC Card (NFC)
- ✅ OCR untuk scan dokumen
- ✅ Face verification dengan liveness detection
- ✅ Multi-language support (Indonesian, English, Japanese, dll)
- ✅ UI screens: Home, Instruction, Loading, Result
- ✅ Hybrid mode: Debug (mock) / Real (SDK)

### 1.4 Supported Documents (COMPLY_HE Method)

| Document Type | Code | IC Support | OCR Support | NFC Required |
|---------------|------|------------|-------------|--------------|
| Residence Card | RESIDENCE_CARD | ✅ | ✅ | ✅ |
| Special Permanent Resident Certificate | SPECIAL_PERMANENT_RESIDENT_CERTIFICATE | ✅ | ✅ | ✅ |
| Driver License | DRIVER_LICENSE | ✅ | ✅ | ✅ |

---

## 2. Struktur Project

```
poc_liquidekyc_flutter/
├── lib/
│   ├── app/
│   │   ├── app.dart                 # Root application widget
│   │   └── liquid_config.dart       # Legacy config (deprecated)
│   │
│   ├── core/
│   │   ├── constant/
│   │   │   └── liquid_constants.dart    # All constants, enums, config
│   │   ├── di/
│   │   │   └── injection.dart           # Dependency injection
│   │   └── services/
│   │       └── liquid_ekyc_channel.dart # Flutter MethodChannel client
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── kyc_result.dart          # Main result model
│   │   │   ├── document_result.dart     # OCR results
│   │   │   ├── face_results.dart        # Face verification results
│   │   │   └── chip_result.dart         # IC chip results
│   │   ├── repositories/
│   │   │   └── kyc_repository.dart      # SDK abstraction layer
│   │   └── services/
│   │       └── liquid_connector_api.dart # Backend API service
│   │
│   ├── persentation/
│   │   ├── viewmodels/
│   │   │   └── kyc_viewmodel.dart       # Business logic & state
│   │   └── views/
│   │       ├── screens/
│   │       │   ├── kyc_home_screen.dart          # Main selection screen
│   │       │   ├── kyc_instruction_screen.dart   # User guide
│   │       │   ├── kyc_result_screen.dart        # Result display
│   │       │   └── kyc_status_screen.dart        # Progress indicator
│   │       └── widgets/
│   │           ├── kyc_loading_overlay.dart      # Loading UI
│   │           └── kyc_dialogs.dart              # Dialog helpers
│   │
│   └── main.dart                    # Entry point
│
├── android/
│   └── app/src/main/kotlin/.../
│       ├── MainActivity.kt          # Plugin registration
│       └── plugins/
│           └── LiquidEkycPlugin.kt  # MethodChannel handler
│
├── pubspec.yaml                     # Flutter dependencies
├── build.gradle.kts                 # Android Gradle config
└── README_PROJECT.md                # This documentation
```

---

## 3. Arsitektur

### 3.1 Pattern: MVVM + Provider + Repository

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI Layer (Screens)                       │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ Home Screen │→ │ Instruction  │→ │ Result Screen        │   │
│  │ (Selection) │  │ Screen       │  │ (Success/Error)      │   │
│  └──────┬──────┘  └──────────────┘  └──────────────────────┘   │
│         │                                                          │
│         ▼                                                          │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                 ViewModel (KycViewModel)                     │ │
│  │  - State management (loading, steps, errors)                │ │
│  │  - Business logic                                           │ │
│  │  - Credentials handling                                     │ │
│  └────────────────────────────┬────────────────────────────────┘ │
│                               │                                    │
│                               ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                   Repository Layer                           │ │
│  │  - KycRepository (SDK abstraction)                          │ │
│  │  - LiquidConnectorApi (Backend API)                         │ │
│  └────────────────────────────┬────────────────────────────────┘ │
│                               │                                    │
│                               ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                 Service Layer                                │ │
│  │  ┌─────────────────────┐    ┌──────────────────────────┐    │ │
│  │  │ liquid_ekyc_channel │───→│ LiquidEkycPlugin (Kotlin)│    │ │
│  │  │ (Flutter)           │    │ (Android)                │    │ │
│  │  └─────────────────────┘    └──────────────────────────┘    │ │
│  └────────────────────────────┬────────────────────────────────┘ │
│                               │                                    │
│                               ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                     SDK Layer                                │ │
│  │  Liquid SDK v1.47.0 + iTrust + ML Kit                       │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Credentials Flow

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   Backend       │         │   Mobile App    │         │   Liquid SDK    │
└────────┬────────┘         └────────┬────────┘         └────────┬────────┘
         │                           │                           │
         │  1. POST /sdk/applications │                           │
         │───────────────────────────→                           │
         │                           │                           │
         │  2. {token, applicant_id} │                           │
         │←──────────────────────────│                           │
         │                           │                           │
         │                           │  3. setCredentials()       │
         │                           │───────────────────────────→│
         │                           │                           │
         │                           │  4. startKyc()             │
         │                           │───────────────────────────→│
         │                           │                           │
         │                           │  5. SDK UI (IC→OCR→Face)   │
         │                           │←───────────────────────────│
         │                           │                           │
         │                           │  6. GET /applicants/:id/*  │
         │←──────────────────────────│                           │
```

---

## 4. Setup & Konfigurasi

### 4.1 Prerequisites

| Tool | Version | Path |
|------|---------|------|
| Flutter | 3.38.0 | `/Users/admin/fvm/versions/3.38.0/bin/flutter` |
| Java | 17+ | System |
| Android SDK | 24+ | ~/Library/Android/sdk |
| Gradle | 8.x | Project |
| minSdk | 24 | Android |

### 4.2 Clone & Setup

```bash
# Navigate ke project
cd /Users/admin/Documents/BNI/test-bni/poc_liquidekyc_flutter

# Setup FVM (jika belum)
fvm install 3.38.0
fvm use 3.38.0

# Get dependencies
flutter pub get

# Build debug APK
flutter build apk --debug
```

### 4.3 Configuration Files

#### 4.3.1 Liquid Constants (`lib/core/constant/liquid_constants.dart`)

```dart
class LiquidConfig {
  // ════════════════════════════════════════════════════════════════
  // MODE CONFIGURATION
  // ════════════════════════════════════════════════════════════════
  
  // true  = DEBUG MODE (mock responses, no SDK camera)
  // false = REAL MODE (call actual SDK, camera works)
  static const bool DEBUG_MODE = false;
  
  // ════════════════════════════════════════════════════════════════
  // SDK CREDENTIALS (STAGING)
  // ════════════════════════════════════════════════════════════════
  
  // SDK API URL (tanpa trailing slash)
  static const String url = 'https://applicantsdk-api.stg-liquid-ekyc.com';
  
  // Trial Mode: API Key only (tanpa applicantId/token)
  static const String apiKey = 'JDJhJDEwJFRIQTBRTXllRG9tdnNNVEx3dHlVcXV4YTdvUWRyczZpbTJNVkZkNFYuM1hlL0taWXlMSDVX';
  
  // Production Mode: Dynamic credentials dari backend
  // static const String applicantId = '';
  // static const String token = '';
  
  // ════════════════════════════════════════════════════════════════
  // CONNECTOR API CREDENTIALS (Backend → LIQUID)
  // ════════════════════════════════════════════════════════════════
  
  static const String connectorUrl = 'https://connector-bni.stg-liquid-ekyc.com';
  static const String connectorApiKey = 'JDJhJDEwJENQem1xTFB3NlJodFZ1MEt0THYyMC5XVEEwNEdQc3dDT0RXY0NEYmpmL053WjVIaUt6ZnFD';
}
```

#### 4.3.2 Kotlin Plugin (`android/app/src/main/kotlin/.../LiquidEkycPlugin.kt`)

```kotlin
// ════════════════════════════════════════════════════════════════
// CONFIGURATION - Change DEBUG_MODE here
// DEBUG_MODE = true  -> Mock responses, no SDK camera
// DEBUG_MODE = false -> Real SDK, camera works
// ════════════════════════════════════════════════════════════════
val DEBUG_MODE = false  // CHANGE THIS TO SWITCH MODES
```

#### 4.3.3 Android Gradle (`android/app/build.gradle.kts`)

```kotlin
android {
    defaultConfig {
        minSdk = 24  // Minimum 24 untuk Liquid SDK
    }
}
```

#### 4.3.4 Android Permissions (`android/app/src/main/AndroidManifest.xml`)

```xml
<!-- Di luar <application> tag -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.NFC" />
<uses-permission android:name="android.permission.INTERNET" />

<uses-feature android:name="android.hardware.camera" android:required="true" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

### 4.4 Mode Configuration Quick Reference

| Mode | DEBUG_MODE (Dart) | DEBUG_MODE (Kotlin) | Credentials Needed |
|------|-------------------|---------------------|-------------------|
| **DEBUG** | `true` | `true` | None (mock responses) |
| **TRIAL** | `false` | `false` | API Key only |
| **PRODUCTION** | `false` | `false` | applicantId + token (dynamic) |

---

## 5. Flow eKYC

### 5.1 Complete Flow (COMPLY_HE Method)

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         MOBILE eKYC FLOW                                    │
│                                                                            │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                 │
│  │   1. Init    │───→│  2. Terms    │───→│  3. IC Chip  │                 │
│  │ startVerify  │    │ showTerms    │    │ verifyIdChip │                 │
│  │   Trial()    │    │   OfUse      │    │    (NFC)     │                 │
│  └──────────────┘    └──────────────┘    └──────┬───────┘                 │
│                                                 │                          │
│                                                 ▼                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                 │
│  │   6. Done    │←───│  5. Face     │←───│  4. OCR      │                 │
│  │  activate()  │    │ verifyFace   │    │verifyIdDoc   │                 │
│  └──────────────┘    └──────────────┘    └──────────────┘                 │
│                                                                            │
│  Step Details:                                                             │
│  1. Initialize SDK with credentials (API Key or applicantId+token)         │
│  2. Show Terms of Use screen (SDK handles)                                 │
│  3. Read IC chip via NFC - get data from chip                              │
│  4. Capture backside of card for OCR                                       │
│  5. Face verification with liveness detection                              │
│  6. Activate/Finalize - send data to server                                │
└────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 User Flow (UI Perspective)

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              USER EXPERIENCE                                │
│                                                                            │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                    HOME SCREEN                                       │   │
│  │  • Select Document Type (Residence Card, etc)                       │   │
│  │  • Select Face Type (Active/Passive)                                │   │
│  │  • Check NFC Status                                                 │   │
│  │  • [Mulai Verifikasi] button                                        │   │
│  └─────────────────────────────┬──────────────────────────────────────┘   │
│                                │                                           │
│                                ▼                                           │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                  INSTRUCTION SCREEN (5 pages)                       │   │
│  │  1. Document Preparation                                            │   │
│  │  2. Lighting Guide                                                  │   │
│  │  3. Face Guide (Active/Passive)                                    │   │
│  │  4. IC Chip Guide (NFC)                                            │   │
│  │  5. iTrust Declaration                                             │   │
│  │                                                                     │   │
│  │  [Next] → [Next] → [Next] → [Next] → [Mulai]                       │   │
│  └─────────────────────────────┬──────────────────────────────────────┘   │
│                                │                                           │
│                                ▼                                           │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                     SDK SCREENS (Native)                            │   │
│  │                                                                     │   │
│  │  Terms of Use → IC Chip Reading → OCR → Face Scan → Review          │   │
│  │                                                                     │   │
│  └─────────────────────────────┬──────────────────────────────────────┘   │
│                                │                                           │
│                                ▼                                           │
│  ┌────────────────────────────────────────────────────────────────────┐   │
│  │                    RESULT SCREEN                                    │   │
│  │  • Success: Data display, Continue button                          │   │
│  │  • Error: Error message, Retry button                              │   │
│  │  • Cancel: Back to Home                                            │   │
│  └────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────┘
```

### 5.3 Verification Order (Per Method)

| Method | Order | IC | OCR | Face |
|--------|-------|-----|-----|------|
| **COMPLY_HE** | IC → OCR → Face | ✅ | ✅ | ✅ |
| COMPLY_HO | Doc → Face | ❌ | ✅ | ✅ |
| COMPLY_TO | Doc only | ❌ | ✅ | ❌ |
| READ | IC only | ✅ | ❌ | ❌ |

**Note:** Project ini menggunakan **COMPLY_HE** sebagai default.

---

## 6. Integrasi Backend

### 6.1 Backend API Flow

```
┌────────────────────┐     ┌────────────────────┐     ┌────────────────────┐
│     Mobile App     │     │   Your Backend     │     │    Liquid API      │
└────────┬───────────┘     └────────┬───────────┘     └────────┬───────────┘
         │                          │                          │
         │                          │  1. POST /v1/sdk/applications
         │                          │──────────────────────────→
         │                          │                          │
         │                          │  2. {token, applicant_id}
         │                          │<──────────────────────────
         │                          │                          │
         │  3. Set credentials      │                          │
         │←─────────────────────────│                          │
         │  (applicant_id, token)   │                          │
         │                          │                          │
         │  4. startKyc()           │                          │
         │──────────────────────────│                          │
         │                          │                          │
         │                          │  5. GET /v1/applicants/:id/ocr_results
         │                          │<──────────────────────────
         │                          │                          │
         │                          │  6. GET /v1/applicants/:id/photos
         │                          │<──────────────────────────
         │                          │                          │
         │                          │  7. GET /v1/applicants/:id/id_document_ic_information
         │                          │<──────────────────────────
         │                          │                          │
         │                          │  8. GET /v1/applicants/:id/verification_results
         │                          │<──────────────────────────
```

### 6.2 Mobile Code Integration

#### 6.2.1 Initialize with Dynamic Credentials (Production)

```dart
// Dalam kode Flutter Anda, setelah dapat credentials dari backend:
final viewModel = context.read<KycViewModel>();

viewModel.setCredentials(
  applicantId: 'APPLICANT_ID_DARI_BACKEND',
  token: 'TOKEN_DARI_BACKEND',
  sdkUrl: 'https://applicantsdk-api.stg-liquid-ekyc.com', // optional
);

// Jalankan verifikasi
final result = await viewModel.startKyc();

if (result.isSuccess) {
  // Handle success
} else {
  // Handle error
}
```

#### 6.2.2 Clear Credentials (Back to Trial Mode)

```dart
viewModel.clearCredentials();
```

#### 6.2.3 Check Credentials Status

```dart
bool hasCredentials = viewModel.hasDynamicCredentials;
// true = Production mode
// false = Trial/Debug mode
```

### 6.3 Backend API Service

Lokasi: `lib/data/services/liquid_connector_api.dart`

#### Available Methods:

| Method | API | Description |
|--------|-----|-------------|
| `applyForSdk()` | 017 | Get token dari applicant_id |
| `getOcrResults()` | 013 | Get OCR text results |
| `getPhotos()` | 010 | Get photo data (Base64) |
| `getICCardInfo()` | 022 | Get IC chip data |
| `getVerificationResults()` | 012 | Get AI verification results |

---

## 7. UI Components

### 7.1 Screen Overview

| Screen | File | Description |
|--------|------|-------------|
| Home Screen | `kyc_home_screen.dart` | Main selection screen dengan step-by-step guide |
| Instruction Screen | `kyc_instruction_screen.dart` | 5-page user guide |
| Result Screen | `kyc_result_screen.dart` | Success/error display |
| Status Screen | `kyc_status_screen.dart` | Progress indicator |

### 7.2 Widget Components

| Widget | File | Description |
|--------|------|-------------|
| Loading Overlay | `kyc_loading_overlay.dart` | Full-screen loading dengan step indicator |
| Dialogs | `kyc_dialogs.dart` | Error, Retry, Confirm dialogs |

### 7.3 Home Screen Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  eKYC Verification                                    [?] [🌐]   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 📋 Verifikasi Identitas                                    │  │
│  │ Lengkapi verifikasi identitas Anda dengan memindai         │  │
│  │ kartu IC dan mengambil foto wajah.                         │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 🔄 Alur Verifikasi (COMPLY_HE)                            │  │
│  │                                                            │  │
│  │  ① NFC/Chip IC     → Baca data dari chip     [✓]          │  │
│  │  ② OCR             → Pindai belakang kartu   [✓]          │  │
│  │  ③ Face            → Verifikasi wajah Anda    [✓]          │  │
│  │                                                            │  │
│  │  ⚠️ Pastikan NFC aktif...                                 │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 🪪 Pilih Jenis Dokumen IC                                  │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │ 💳 Residence Card                    ✓                │ │  │
│  │  │    Kartu Izin Tinggal                                 │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │ 🪪 Special PR Certificate                            │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │ 🚗 Driver License                                   │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 😊 Tipe Verifikasi Wajah                                   │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │ 🔥 Active Detection                                  │ │  │
│  │  │    Gerakkan mulut & nyalakan flash        ○          │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │ 😊 Passive Detection                                 │ │  │
│  │  │    Tidak perlu aksi khusus                 ●          │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 📡 NFC Tersedia                              [OK]         │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│            ┌─────────────────────────────────┐                  │
│            │      🚀 Mulai Verifikasi        │                  │
│            └─────────────────────────────────┘                  │
│                                                                 │
│              SDK v1.47.0 • Residence Card                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. SDK Integration

### 8.1 MethodChannel Contract

| Channel | Method | Direction | Description |
|---------|--------|-----------|-------------|
| `com.liquid.ekyc/channel` | `startVerify` | Dart → Kotlin | Init dengan applicantId + token |
| `com.liquid.ekyc/channel` | `startVerifyTrial` | Dart → Kotlin | Init dengan API Key only |
| `com.liquid.ekyc/channel` | `showTermsOfUse` | Dart → Kotlin | Show ToS screen |
| `com.liquid.ekyc/channel` | `verifyIdChip` | Dart → Kotlin | NFC reading |
| `com.liquid.ekyc/channel` | `verifyIdDocument` | Dart → Kotlin | OCR scan |
| `com.liquid.ekyc/channel` | `verifyFace` | Dart → Kotlin | Face verification |
| `com.liquid.ekyc/channel` | `changeLanguage` | Dart → Kotlin | Change SDK language |
| `com.liquid.ekyc/channel` | `isNfcAvailable` | Dart → Kotlin | Check NFC |
| `com.liquid.ekyc/channel` | `getSdkVersion` | Dart → Kotlin | Get SDK version |

### 8.2 Kotlin Plugin Architecture

```kotlin
class LiquidEkycPlugin : FlutterPlugin, ActivityAware {
    // Stored activity reference
    private var activity: Activity? = null
    
    // SDK credentials
    private var sdkUrl: String = ""
    private var sdkApplicantId: String = ""
    private var sdkToken: String = ""
    private var sdkApiKey: String = ""
    
    // SDK Launchers (class function pattern)
    private var showTermsOfUseLauncher = ShowTermsOfUse()
    private var verifyIdDocumentLauncher = VerifyIdDocument()
    private val verifyIdChipLauncher = VerifyIdChip()
    private val verifyFaceLauncher = VerifyFace()
    
    // Method handlers
    fun handleMethodCall(call, result) {
        when (call.method) {
            "startVerifyTrial" -> handleStartVerifyTrial(call, result)
            "showTermsOfUse" -> handleShowTermsOfUse(result)
            "verifyIdChip" -> handleVerifyIdChip(call, result)
            "verifyIdDocument" -> handleVerifyIdDocument(call, result)
            "verifyFace" -> handleVerifyFace(call, result)
            // ...
        }
    }
}
```

### 8.3 SDK UI Screens (Handled by SDK)

| Screen | Provider | Client Control |
|--------|----------|----------------|
| Terms of Use | SDK | ❌ |
| IC Chip Camera | SDK | ❌ |
| Document Camera | SDK | ❌ |
| Face Camera | SDK | ❌ |
| Review Screen | SDK | ✅ (showReviewScreen param) |

### 8.4 SDK Configuration Parameters

#### VerifyIdDocumentParameters
```kotlin
val params = VerifyIdDocumentParameters.Builder(
    documentType,      // RESIDENCE_CARD, DRIVER_LICENSE, etc.
    verificationMethod // COMPLY_HE, COMPLY_HO, etc.
)
    .setShowReviewScreen(true/false)
    .build()
```

#### VerifyFaceParameters
```kotlin
val params = VerifyFaceParameters.Builder()
    .setShowReviewScreen(true/false)
    .build()
```

---

## 9. Build & Deployment

### 9.1 Build Commands

```bash
# Navigate ke project
cd /Users/admin/Documents/BNI/test-bni/poc_liquidekyc_flutter

# Clean & get dependencies
flutter clean
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build with specific target
flutter build apk --debug --target-platform android-arm64
```

### 9.2 Output Locations

| Build Type | Location |
|------------|----------|
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` |

### 9.3 Install to Device

```bash
# Via ADB
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Or via Flutter
flutter install
```

### 9.4 APK Size Reference

| Build | Approximate Size |
|-------|------------------|
| Debug | ~110 MB |
| Release | ~40-50 MB |

---

## 10. Testing Guide

### 10.1 Test Modes

| Mode | How to Test | What Works |
|------|-------------|------------|
| **DEBUG** | Set `DEBUG_MODE = true` in both Dart & Kotlin | Mock responses, no camera |
| **TRIAL** | Set `DEBUG_MODE = false`, use API Key only | Real SDK, API Key auth |
| **PRODUCTION** | Set credentials via `setCredentials()` | Real SDK, full auth |

### 10.2 Testing Checklist

- [ ] App starts without crash
- [ ] Home screen displays correctly
- [ ] Document type selection works
- [ ] Face type selection works
- [ ] NFC status shows correctly
- [ ] Instruction screen navigates properly
- [ ] Loading overlay appears during verification
- [ ] Terms of Use screen appears (SDK)
- [ ] IC Chip reading works (SDK)
- [ ] OCR scan works (SDK)
- [ ] Face verification works (SDK)
- [ ] Result screen displays correctly
- [ ] Error handling works
- [ ] Language change works

### 10.3 Log Monitoring

```bash
# Clear logs
adb logcat -c

# Monitor specific tags
adb logcat | grep -iE "LiquidEkycPlugin|KycViewModel|LiquidSDK"

# Read recent logs
adb logcat -d | grep -iE "liquid|kyc"
```

### 10.4 Expected Logs

```
I/flutter: [KycViewModel] startKyc() called - Mode: REAL
I/flutter: [KycViewModel]   Method: COMPLY_HE, Document: RESIDENCE_CARD
I/flutter: [KycViewModel] Using TRIAL mode initialization with API Key
D/LiquidEkycPlugin: Method call: startVerifyTrial
D/LiquidEkycPlugin: handleStartVerifyTrial called
I/flutter: [KycViewModel] Init result: success, isSuccess: true
```

---

## 11. Troubleshooting

### 11.1 Common Issues

#### Issue: `NO_ACTIVITY` Error
```
I/flutter: [LiquidSDK] showTermsOfUse ERROR: NO_ACTIVITY
```

**Cause:** Activity not available in MethodChannel callback

**Solution:** Already fixed - plugin now uses `context` instead of stored `activity`

#### Issue: ML Initialization Error
```
E/LB: fail to open node: No such file or directory
```

**Cause:** ML library trying to load but not properly initialized

**Solution:** This is normal in DEBUG mode. Real SDK initialization will handle this.

#### Issue: Camera Not Opening
**Check:**
1. `DEBUG_MODE` is `false` in both Dart AND Kotlin
2. Device has camera permission
3. Trial API Key is valid

#### Issue: NFC Not Working
**Check:**
1. Device has NFC hardware
2. NFC is enabled in device settings
3. Card type supports NFC (Residence Card, Driver License)

### 11.2 Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| `NO_ACTIVITY` | Activity not available | Update Kotlin plugin |
| `NO_CONTEXT` | Context not available | Check app lifecycle |
| `INVALID_CREDENTIALS` | Missing required params | Check credentials |
| `CHIP_ERROR` | NFC reading failed | Retry or check card |
| `DOCUMENT_ERROR` | OCR failed | Retry with better lighting |
| `FACE_ERROR` | Face verification failed | Retry with better conditions |

---

## 12. API Reference

### 12.1 Liquid Connector API Endpoints

#### SDKApplyAPI (Get Token)
```
POST https://connector-bni.stg-liquid-ekyc.com/v1/sdk/applications
Headers: X-Ekyc-Api-Key: <connector_api_key>
Body: {
  "applicant_id": "YOUR_UNIQUE_ID",
  "operation_assignment_priority": "1"
}
Response: {
  "token": "...",
  "applicant_id": "..."
}
```

#### GetOCRResultsAPI
```
GET https://connector-bni.stg-liquid-ekyc.com/v1/applicants/:id/ocr_results
Headers: X-Ekyc-Api-Key: <connector_api_key>
Response: {
  "name": "...",
  "birthday": "...",
  "address": "...",
  "id_number": "...",
  "expire_date": "..."
}
```

#### GetPhotosAPI
```
GET https://connector-bni.stg-liquid-ekyc.com/v1/applicants/:id/photos
Headers: X-Ekyc-Api-Key: <connector_api_key>
Response: {
  "face_front_photo": "BASE64...",
  "id_document_photos": ["BASE64...", ...]
}
```

#### GetICCardInfoAPI
```
GET https://connector-bni.stg-liquid-ekyc.com/v1/applicants/:id/id_document_ic_information
Headers: X-Ekyc-Api-Key: <connector_api_key>
Response: {
  "id_face_photo": "BASE64...",
  "signature": "BASE64...",
  "name": "...",
  "address": "...",
  ...
}
```

#### GetVerificationResultsAPI
```
GET https://connector-bni.stg-liquid-ekyc.com/v1/applicants/:id/verification_results
Headers: X-Ekyc-Api-Key: <connector_api_key>
Response: {
  "face_match_score": 85.5,
  "liveness_result": "PASS",
  "fraud_detection_result": "..."
}
```

### 12.2 Flutter ViewModel API

```dart
// Initialization
KycViewModel({KycRepository? repository})

// State
bool isLoading
KycStep currentStep
KycResult? lastResult
bool nfcAvailable
String? sdkVersion

// Selection
VerificationMethod selectedMethod
LiquidDocumentType selectedDocumentType
FaceVerificationType selectedFaceType

// Actions
Future<KycResult> startKyc()
void setVerificationMethod(VerificationMethod method)
void setDocumentType(LiquidDocumentType documentType)
void setFaceType(FaceVerificationType faceType)
void setLanguage(DisplayLanguage language)

// Credentials (Production Mode)
void setCredentials({required String applicantId, required String token, String? sdkUrl})
void clearCredentials()
bool hasDynamicCredentials

// Utilities
void reset()
Future<String?> getSdkVersion()
Future<bool> checkNfcAvailability()
```

---

## 13. FAQ

### Q: Apa bedanya DEBUG_MODE vs TRIAL vs PRODUCTION?

**A:**
- **DEBUG_MODE:** Mock responses tanpa perlu SDK. Untuk testing UI saja.
- **TRIAL:** Pakai API Key saja. Untuk development tanpa credentials dari backend.
- **PRODUCTION:** Perlu applicantId + token dari backend. Untuk real deployment.

### Q: Kenapa ada 2 file config (liquid_constants.dart dan liquid_config.dart)?

**A:** `liquid_config.dart` adalah file legacy yang tidak digunakan. Gunakan `liquid_constants.dart`.

### Q: Apakah bisa switch mode saat app running?

**A:** Ya, gunakan `setCredentials()` untuk production atau `clearCredentials()` untuk trial mode.

### Q: Apakah SDK handles semua screen?

**A:** Tidak sepenuhnya. Yang SDK handle:
- Terms of Use
- Camera UI (IC, Document, Face)
- Review screen (optional)

Yang CLIENT handle:
- Home screen (selection)
- Instruction screen
- Loading overlay
- Result screen

### Q: Kenapa trial mode tidak bisa untuk KTP Indonesia?

**A:** Karena COMPLY_HE method menggunakan IC chip reading. KTP Indonesia (e-KTP) membutuhkan sertifikat dari pemerintah (Jaringantop). Residence Card, Driver License, dan Special PR card bisa digunakan di trial mode.

### Q: Bagaimana jika NFC tidak tersedia?

**A:** Method COMPLY_HE membutuhkan NFC. Jika NFC tidak tersedia, gunakan method lain seperti COMPLY_HO (Document + Face only).

---

## 📞 Support

- **Project Lead:** [BNI Team]
- **SDK Documentation:** `SDK_Android_ver1.47.0/README/README.md`
- **API Spec:** `documents/SDK Function/`

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | June 2025 | Initial POC with COMPLY_HE method |