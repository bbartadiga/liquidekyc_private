# Project eKYC Flutter - Summary

**Project:** POC Liquid eKYC Flutter App  
**SDK:** Liquid SDK v1.47.0  
**Platform:** Android (Flutter)  
**Architecture:** MVVM + Provider + Repository Pattern

---

# 🇮🇩 INDONESIA

## Apa yang Sudah Dibuat

Aplikasi Flutter POC untuk integrasi Liquid SDK dalam proses verifikasi identitas (eKYC).

### Komponen yang Diimplementasi

| Komponen | Keterangan |
|----------|------------|
| **MethodChannel Bridge** | Flutter ↔ Android Kotlin bridge untuk komunikasi SDK |
| **Home Screen** | Pemilihan dokumen (KTP, SIM, Passport), metode (OCR/NFC/Full), face type (1:1/1:N) |
| **Instruction Screen** | Panduan user 5 halaman sebelum verifikasi |
| **Loading Overlay** | Loading dengan step progress indicator |
| **Error/Retry Dialog** | Dialog reusable untuk error handling & retry |
| **Result Screen** | Tampilan hasil verifikasi (success/error) |
| **Hybrid Mode** | Flag `DEBUG_MODE` untuk switch mock vs real SDK |

### SDK UI (Disediakan Liquid SDK)

- Camera view untuk scan dokumen
- Terms of Use screen
- Review/Confirmation screen
- NFC prompt (native Android)

### Setup Requirements

- minSdk: 24 (Android 7.0+)
- FVM Flutter: 3.38.0
- Android Gradle Plugin 8.x, Kotlin DSL

### Status

| Item | Status |
|------|--------|
| Debug APK | Build berhasil |
| Mock Mode | Semua UI berfungsi |
| Real Mode | Menunggu credentials |
| UI Screens | Lengkap (5 screens + dialogs) |

---

## Struktur Code

```
lib/
├── app/app.dart                    # Root app
├── core/constant/liquid_constants.dart  # Config & enums
├── data/models/kyc_result.dart     # Result model
├── data/repositories/kyc_repository.dart  # SDK abstraction
├── persentation/viewmodels/kyc_viewmodel.dart  # Business logic
├── persentation/views/screens/
│   ├── kyc_home_screen.dart        # ID Selection
│   ├── kyc_instruction_screen.dart # Instructions
│   └── kyc_result_screen.dart      # Result display
├── persentation/views/widgets/
│   ├── kyc_loading_overlay.dart    # Loading UI
│   └── kyc_dialogs.dart            # Dialog helpers
└── services/liquid_ekyc_channel.dart  # MethodChannel client

android/app/src/main/kotlin/.../
├── MainActivity.kt                 # Plugin registration
└── LiquidEkycPlugin.kt            # MethodChannel handler
```

---

## Flow eKYC

```
┌─────────────┐    ┌──────────────┐    ┌───────────┐    ┌─────────────┐
│ Home Screen │ →  │ Instruction  │ →  │ Loading   │ →  │ SDK Camera  │
│ (Selection) │    │ (5 pages)    │    │ (Overlay) │    │ (by SDK)    │
└─────────────┘    └──────────────┘    └───────────┘    └─────────────┘
                                                                  │
                                                                  ▼
                                                           ┌─────────────┐
                                                           │ Result      │
                                                           │ (Client UI) │
                                                           └─────────────┘
```

**Client Buat:** Home, Instruction, Loading, Result, Error Dialogs  
**SDK Buat:** Camera, Terms of Use, Review Screen, NFC Prompt

---

## Mode Debug vs Real

### Debug Mode (saat ini aktif)

```dart
DEBUG_MODE = true  // di liquid_constants.dart & LiquidEkycPlugin.kt
```

- UI berfungsi semua
- Mock responses (tanpa SDK)
- Tidak perlu credentials
- Camera/NFC tidak jalan

### Real Mode (untuk production)

```dart
DEBUG_MODE = false
// + Isi credentials (apiUrl, applicantId, token, apiKey)
// + Uncomment SDK code di Kotlin
```

---

## Pertanyaan ke Vendor

1. Bagaimana cara mendapatkan sandbox credentials untuk testing?
2. iTrust verification - sudah termasuk atau add-on terpisah?
3. NFC - perlu sertifikat/key dari pemerintah?
4. Screen mana yang client harus buat sendiri vs SDK sediakan?
5. Pricing model bagaimana?
6. Ada mock SDK untuk development tanpa credentials?

---

## Build & Run

```bash
# Navigate ke project
cd poc_liquidekyc_flutter

# Build debug APK
flutter build apk --debug

# Run on device
flutter run

# Output: build/app/outputs/flutter-apk/app-debug.apk
```

---

# 🇬🇧 ENGLISH

## What Has Been Built

Flutter POC application for Liquid SDK integration in identity verification (eKYC) process.

### Implemented Components

| Component | Description |
|-----------|-------------|
| **MethodChannel Bridge** | Flutter ↔ Android Kotlin bridge for SDK communication |
| **Home Screen** | Document selection (KTP, SIM, Passport), method (OCR/NFC/Full), face type (1:1/1:N) |
| **Instruction Screen** | 5-page user guide before verification |
| **Loading Overlay** | Loading with step progress indicator |
| **Error/Retry Dialog** | Reusable dialog for error handling & retry |
| **Result Screen** | Verification result display (success/error) |
| **Hybrid Mode** | `DEBUG_MODE` flag to switch mock vs real SDK |

### SDK UI (Provided by Liquid SDK)

- Camera view for document scanning
- Terms of Use screen
- Review/Confirmation screen
- NFC prompt (native Android)

### Setup Requirements

- minSdk: 24 (Android 7.0+)
- FVM Flutter: 3.38.0
- Android Gradle Plugin 8.x, Kotlin DSL

### Status

| Item | Status |
|------|--------|
| Debug APK | Build successful |
| Mock Mode | All UI functional |
| Real Mode | Awaiting credentials |
| UI Screens | Complete (5 screens + dialogs) |

---

## Code Structure

```
lib/
├── app/app.dart                    # Root app
├── core/constant/liquid_constants.dart  # Config & enums
├── data/models/kyc_result.dart     # Result model
├── data/repositories/kyc_repository.dart  # SDK abstraction
├── persentation/viewmodels/kyc_viewmodel.dart  # Business logic
├── persentation/views/screens/
│   ├── kyc_home_screen.dart        # ID Selection
│   ├── kyc_instruction_screen.dart # Instructions
│   └── kyc_result_screen.dart      # Result display
├── persentation/views/widgets/
│   ├── kyc_loading_overlay.dart    # Loading UI
│   └── kyc_dialogs.dart            # Dialog helpers
└── services/liquid_ekyc_channel.dart  # MethodChannel client

android/app/src/main/kotlin/.../
├── MainActivity.kt                 # Plugin registration
└── LiquidEkycPlugin.kt            # MethodChannel handler
```

---

## eKYC Flow

```
┌─────────────┐    ┌──────────────┐    ┌───────────┐    ┌─────────────┐
│ Home Screen │ →  │ Instruction  │ →  │ Loading   │ →  │ SDK Camera  │
│ (Selection) │    │ (5 pages)    │    │ (Overlay) │    │ (by SDK)    │
└─────────────┘    └──────────────┘    └───────────┘    └─────────────┘
                                                                  │
                                                                  ▼
                                                           ┌─────────────┐
                                                           │ Result      │
                                                           │ (Client UI) │
                                                           └─────────────┘
```

**Client Built:** Home, Instruction, Loading, Result, Error Dialogs  
**SDK Built:** Camera, Terms of Use, Review Screen, NFC Prompt

---

## Debug vs Real Mode

### Debug Mode (currently active)

```dart
DEBUG_MODE = true  // in liquid_constants.dart & LiquidEkycPlugin.kt
```

- All UI functional
- Mock responses (without SDK)
- No credentials needed
- Camera/NFC not working

### Real Mode (for production)

```dart
DEBUG_MODE = false
// + Fill credentials (apiUrl, applicantId, token, apiKey)
// + Uncomment SDK code in Kotlin
```

---

## Questions for Vendor

1. How to obtain sandbox credentials for testing?
2. iTrust verification - included or separate add-on?
3. NFC - does it require government certificate/key?
4. Which screens must client build vs SDK provides?
5. What is the pricing model?
6. Is there a mock SDK for development without credentials?

---

## Build & Run

```bash
# Navigate to project
cd poc_liquidekyc_flutter

# Build debug APK
flutter build apk --debug

# Run on device
flutter run

# Output: build/app/outputs/flutter-apk/app-debug.apk
```

---

**Note:** Full technical documentation available in `README.md`