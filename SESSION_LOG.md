# 📝 eKYC Flutter Project - Chat Session Log

**Tanggal:** 10 Juni 2025
**Project:** POC Liquid eKYC Flutter App  
**Status:** ✅ POC Selesai & Siap Testing

---

## 📋 Ringkasan Project

Project ini adalah implementasi **Proof of Concept (POC)** untuk integrasi Liquid eKYC SDK v1.47.0 dalam aplikasi Flutter untuk verifikasi identitas.

### Teknologi Stack
- **Flutter:** 3.38.0 (FVM)
- **State Management:** Provider
- **Platform:** Android (minSdk 24)
- **SDK:** Liquid eKYC Applicant SDK v1.47.0

---

## ✅ Yang Sudah Selesai

### 1. Code Implementation

| Komponen | File | Status |
|----------|------|--------|
| **MethodChannel Bridge** | `liquid_ekyc_channel.dart` | ✅ |
| **Kotlin Plugin** | `LiquidEkycPlugin.kt` | ✅ |
| **ViewModel** | `kyc_viewmodel.dart` | ✅ |
| **Repository** | `kyc_repository.dart` | ✅ |
| **Home Screen** | `kyc_home_screen.dart` | ✅ |
| **Instruction Screen** | `kyc_instruction_screen.dart` | ✅ |
| **Result Screen** | `kyc_result_screen.dart` | ✅ |
| **Loading Overlay** | `kyc_loading_overlay.dart` | ✅ |
| **Dialogs** | `kyc_dialogs.dart` | ✅ |
| **Backend API Service** | `liquid_connector_api.dart` | ✅ |

### 2. Configuration

| File | Content |
|------|---------|
| `liquid_constants.dart` | API URL, API Key, DEBUG_MODE flag, all enums |
| `LiquidEkycPlugin.kt` | DEBUG_MODE, credentials storage, SDK launchers |
| `build.gradle.kts` | minSdk 24, ABI filters |
| `AndroidManifest.xml` | CAMERA, NFC, INTERNET permissions |

### 3. Documentation

| File | Description |
|------|-------------|
| `PROJECT_DOCUMENTATION.md` | Dokumentasi lengkap (13 sections) |
| `QUICK_START.md` | Quick start guide untuk developer baru |
| `README.md` | Technical documentation |
| `README_PROJECT.md` | Ringkasan dalam 2 bahasa |

---

## 🔄 Flow eKYC (COMPLY_HE Method)

```
1. Initialize SDK (startVerifyTrial dengan API Key)
2. Show Terms of Use (SDK handles)
3. IC Chip Reading via NFC
4. OCR Scan (Back of card)
5. Face Verification (Liveness Detection)
6. Activate & Get Results
```

### Backend Integration Flow:
```
BE: POST /v1/sdk/applications → {token, applicant_id}
Mobile: setCredentials(applicant_id, token)
Mobile: startKyc() → SDK calls
BE: GET results via /v1/applicants/:id/*
```

---

## ⚙️ Configuration Summary

### Mode Configuration

| Mode | Dart DEBUG_MODE | Kotlin DEBUG_MODE | Credentials |
|------|-----------------|-------------------|-------------|
| DEBUG | `true` | `true` | None (mock) |
| TRIAL | `false` | `false` | API Key only |
| PRODUCTION | `false` | `false` | applicantId + token |

### Current Status: TRIAL MODE

```dart
// liquid_constants.dart
DEBUG_MODE = false
url = 'https://applicantsdk-api.stg-liquid-ekyc.com'
apiKey = 'JDJhJDEwJFRIQTBRTXllRG9tdnNNVEx3dHlVcXV4YTdvUWRyczZpbTJNVkZkNFYuM1hlL0taWXlMSDVX'
```

### Credentials (Staging)

| Type | Value |
|------|-------|
| **SDK URL** | `https://applicantsdk-api.stg-liquid-ekyc.com` |
| **SDK API Key** | `JDJhJDEwJFRIQTBRTXllRG9tdnNNVEx3dHlVcXV4YTdvUWRyczZpbTJNVkZkNFYuM1hlL0taWXlMSDVX` |
| **Connector URL** | `https://connector-bni.stg-liquid-ekyc.com` |
| **Connector API Key** | `JDJhJDEwJENQem1xTFB3NlJodFZ1MEt0THYyMC5XVEEwNEdQc3dDT0RXY0NEYmpmL053WjVIaUt6ZnFD` |

---

## 🗂️ Project Structure

```
lib/
├── app/
│   ├── app.dart                 # Root app widget
│   └── liquid_config.dart       # Legacy (deprecated)
├── core/
│   ├── constant/
│   │   └── liquid_constants.dart    # Main config
│   ├── di/
│   │   └── injection.dart
│   └── services/
│       └── liquid_ekyc_channel.dart # MethodChannel client
├── data/
│   ├── models/                  # Result models
│   ├── repositories/
│   │   └── kyc_repository.dart  # SDK abstraction
│   └── services/
│       └── liquid_connector_api.dart # Backend API
├── persentation/
│   ├── viewmodels/
│   │   └── kyc_viewmodel.dart   # Business logic
│   └── views/
│       ├── screens/             # UI screens
│       └── widgets/             # Reusable widgets
android/app/src/main/kotlin/.../
├── MainActivity.kt
└── plugins/
    └── LiquidEkycPlugin.kt      # MethodChannel handler
```

---

## 📊 Key Decisions

1. **COMPLY_HE Method** sebagai default - NFC + OCR + Face
2. **Residence Card** sebagai default document type
3. **Hybrid Mode** - Single DEBUG_MODE flag untuk switch
4. **Trial Mode** - Pakai API Key saja tanpa applicantId/token
5. **UI Screens** - Client handle: Home, Instruction, Loading, Result
6. **SDK Screens** - SDK handle: Terms, Camera, Review

---

## 🐛 Issues & Fixes

| Issue | Solution |
|-------|----------|
| NO_ACTIVITY error | Update Kotlin plugin - use `context` instead of stored `activity` |
| APK not found after build | Use full path: `build/app/outputs/flutter-apk/app-debug.apk` |
| PDF can't read | Summarized from user-provided text |

---

## 📝 Pertanyaan ke Vendor (yang sudah dibuat)

1. Bagaimana cara mendapatkan sandbox credentials?
2. iTrust verification - included atau add-on?
3. NFC - perlu sertifikat pemerintah?
4. Screen yang client harus buat vs SDK sediakan?
5. Pricing model?
6. Mock SDK untuk development?
7. Application Form & Expiry Confirmation - SDK handle atau client?

---

## 🚀 Next Steps

| Step | Status | Action |
|------|--------|--------|
| BE Integration | ⏳ Waiting | Backend call SDKApplyAPI → pass credentials |
| Real Device Testing | ⏳ Waiting | Install APK → test full flow |
| Production Mode | ⏳ Waiting | Set dynamic credentials |
| KTP Indonesia | ⏳ Pending | Tanya vendor tentang sertifikat |

---

## 📄 Dokumentasi Files

| File | Purpose |
|------|---------|
| `PROJECT_DOCUMENTATION.md` | Dokumentasi lengkap untuk developer |
| `QUICK_START.md` | Quick guide untuk developer baru |
| `README.md` | Technical details |
| `README_PROJECT.md` | Ringkasan (ID/EN) |
| `SESSION_LOG.md` | This file - chat history summary |

---

## 💡 Tips untuk Developer Baru

1. Baca `QUICK_START.md` dulu
2. Check `PROJECT_DOCUMENTATION.md` untuk detail
3. DEBUG_MODE di 2 tempat: Dart & Kotlin
4. Gunakan `adb logcat | grep -i liquid` untuk monitoring
5. Trial mode tidak support KTP Indonesia IC reading

---

## 📞 Key Contacts

- **BNI Team** - Project Lead
- **Liquid Inc.** - SDK Vendor
- **Backend Team** - API Integration (waiting)

---

**Session End: 10 Juni 2025**  
**Project Status: ✅ POC Complete**  
**Next: Waiting for Backend team untuk production integration**