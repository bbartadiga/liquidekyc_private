# Liquid eKYC Flutter App - Flow Documentation

## Overview

Aplikasi eKYC ini menggunakan Liquid SDK untuk verifikasi identitas dengan flow:

1. **User input Applicant ID**
2. **Fetch token dari Backend Server**
3. **Panduan KYC**
4. **SDK flows (Terms → Document → IC Chip → Face)**
5. **Result display**

---

## KYC Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FLOW KYC                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────┐       ┌────────────┐       ┌─────────────────────────────┐  │
│  │   Home     │ ────► │  Input     │       │      SDK Handle             │  │
│  │  Screen    │       │  Dialog    │       │  ┌────────────────────────┐ │  │
│  │  (Kita)    │       │  (Kita)    │       │  │ 1. TermsOfUse Screen   │ │  │
│  └────────────┘       └─────┬──────┘       │  │ 2. Document Scan Screen│ │  │
│                             │              │  │ 3. IC Card Read Screen │ │  │
│                             ▼              │  │ 4. Face Capture Screen │ │  │
│                      ┌────────────┐       │  └────────────────────────┘ │  │
│                      │ Fetch      │       │         (Native Android)    │  │
│                      │ Token BE   │       └─────────────────────────────┘  │
│                      └─────┬──────┘                    │                   │
│                            │                          ▼                   │
│                            ▼              ┌─────────────────────────────┐  │
│                      ┌────────────┐       │      Kita Handle            │  │
│                      │ Instruction│       │  ┌────────────────────────┐ │  │
│                      │  Screen    │       │  │ 1. Home Screen         │ │  │
│                      │  (Kita)    │       │  │ 2. Token Input Dialog  │ │  │
│                      └─────┬──────┘       │  │ 3. Instruction Screen  │ │  │
│                            │              │  │ 4. Result Screen       │ │  │
│                            ▼              │  │ 5. Config Screen       │ │  │
│                      ┌────────────┐       │  └────────────────────────┘ │  │
│                      │   SDK      │       │       (Flutter)             │  │
│                      │  Flows     │       └─────────────────────────────┘  │
│                      └─────┬──────┘                                               │
│                            │                                                     │
│                            ▼                                                     │
│                      ┌────────────┐                                              │
│                      │  Result    │                                              │
│                      │  Screen    │                                              │
│                      │  (Kita)    │                                              │
│                      └────────────┘                                              │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Screen List

### Screens yang Kita Handle (Flutter)

| No | Screen | File | Description |
|----|--------|------|-------------|
| 1 | Home Screen | `kyc_home_screen.dart` | Input Applicant ID, fetch token, button mulai |
| 2 | Token Input | `kyc_home_screen.dart` | Bottom sheet untuk input Applicant ID |
| 3 | Instruction Screen | `kyc_instruction_screen.dart` | Panduan langkah-langkah KYC |
| 4 | Result Screen | `kyc_result_screen.dart` | Display semua hasil verifikasi |
| 5 | Config Screen | `kyc_config_screen.dart` | Pengaturan document type, method, dll |
| 6 | Debug Log Screen | `debug_log_screen.dart` | App logs & HTTP logs |

### Screens yang SDK Handle (Native Android)

| No | Screen | SDK Class | Description |
|----|--------|-----------|-------------|
| 1 | Terms of Use | `TermsOfUseActivity` | User accept/decline terms |
| 2 | Document Scan | `DocumentScanActivity` | User scan document front/back, OCR |
| 3 | IC Card Read | `ICCardReadActivity` | User tap NFC chip on document |
| 4 | Face Capture | `FaceCaptureActivity` | User take selfie for face verification |

---

## Detail Screens

### 1. Home Screen (`kyc_home_screen.dart`)

```
┌─────────────────────────────────┐
│  eKYC Verification     [⚙️] [🐛]│
├─────────────────────────────────┤
│         👤                      │
│   Verifikasi Identitas          │
│   Scan kartu IC dan wajah       │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 🔑 Token Session          │  │
│  │ [Edit Applicant ID]       │  │
│  │ BE: 192.168.1.41:8080     │  │
│  └───────────────────────────┘  │
│                                 │
│  [ ▶ Ambil Token & Mulai KYC  ] │
│                                 │
│  ─────────────────────────      │
│  Pengaturan Cepat               │
│  [ 🪪 Residence Card ]          │
│  [ 😊 Active ]                  │
└─────────────────────────────────┘
```

**Flow:**
1. User tap "Edit Applicant ID" → Bottom sheet input
2. User tap "Ambil Token & Mulai" → API call BE
3. BE return token → Navigate ke Instruction Screen

---

### 2. Instruction Screen (`kyc_instruction_screen.dart`)

```
┌─────────────────────────────────┐
│  ← KYC Guide              [?]  │
├─────────────────────────────────┤
│                                 │
│         📋 Panduan              │
│                                 │
│  1️⃣ Accept Terms                │
│     Baca dan setujui syarat     │
│                                 │
│  2️⃣ Scan Dokumen                │
│     Fotokopi kartu identitas    │
│                                 │
│  3️⃣ Baca IC Chip                │
│     Tempelkan ke NFC HP         │
│                                 │
│  4️⃣ Verifikasi Wajah            │
│     Ambil foto selfie           │
│                                 │
│  ┌─────────────────────────┐   │
│  │    [ ▶ Mulai Verifikasi ] │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

**Flow:**
1. User tap "Mulai Verifikasi"
2. Call `viewModel.startKyc()`
3. SDK flows dimulai

---

### 3. SDK Native Flows

```
SDK Native Flows:
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  ┌─────────────────┐                                     │
│  │ Terms of Use    │ ← User accept terms                 │
│  │ (TermsOfUse     │                                     │
│  │ Activity)       │                                     │
│  └────────┬────────┘                                     │
│           │                                              │
│           ▼                                              │
│  ┌─────────────────┐                                     │
│  │ Document Scan   │ ← User scan front/back dokumen      │
│  │ (DocumentScan   │   Return OCR data:                  │
│  │ Activity)       │   - Name, Address, DOB              │
│  └────────┬────────┘   - Document Number                 │
│           │            - Expiry Date                     │
│           ▼                                              │
│  ┌─────────────────┐                                     │
│  │ IC Card Read    │ ← User tap NFC chip                 │
│  │ (ICCardRead     │   Return:                           │
│  │ Activity)       │   - Verification result             │
│  └────────┬────────┘   - Municipality name               │
│           │            - etc.                            │
│           ▼                                              │
│  ┌─────────────────┐                                     │
│  │ Face Capture    │ ← User take selfie                  │
│  │ (FaceCapture    │   Return:                           │
│  │ Activity)       │   - Liveness result                 │
│  └────────┬────────┘   - Match score                     │
│           │            - Auto verification               │
│           ▼                                              │
│  ┌─────────────────┐                                     │
│  │ Return to       │ ← SDK return result to Flutter      │
│  │ Flutter         │                                     │
│  └─────────────────┘                                     │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

### 4. Result Screen (`kyc_result_screen.dart`)

```
┌─────────────────────────────────────────────┐
│            ✓ Verifikasi Berhasil!           │
│              [eKYC Complete]                │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │    [✓ Document] [✓ IC] [✓ Face]     │   │ ← Status summary
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─ Data Kartu (OCR) ─────────────────┐   │
│  │ Nama      : TARO YAMADA            │   │
│  │ Alamat    : Tokyo-to, ...          │   │
│  │ DOB       : 1990-05-15             │   │
│  │ No. Doc   : AB123456789            │   │
│  └────────────────────────────────────┘   │
│                                             │
│  ┌─ IC Chip ──────────────────────────┐   │
│  │ Status   : Berhasil                │   │
│  │ Auto Verify: PASS                  │   │
│  └────────────────────────────────────┘   │
│                                             │
│  ┌─ Face Match ───────────────────────┐   │
│  │ Status   : Berhasil                │   │
│  │ Liveness : PASS                    │   │
│  │ Score    : 850                     │   │
│  └────────────────────────────────────┘   │
│                                             │
│           [        Selesai        ]         │
└─────────────────────────────────────────────┘
```

**Data yang ditampilkan:**
- Status verification (Document/IC Chip/Face)
- OCR data (nama, alamat, DOB, no dokumen)
- IC Chip verification result
- Face match result (liveness, score)

---

## Backend API

### Token Generation

```
POST http://192.168.1.41:8080/v1/sdk/applications

Request:
{
  "applicant_id": "111902224425"
}

Response:
{
  "applicant_id": "111902224425",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Applicant Registration

```
POST http://192.168.1.41:8080/v1/applications/{applicantId}/info

Request:
{
  "applicant_name": "TARO YAMADA",
  "date_of_birth": "1990-05-15",
  "address": "Tokyo-to, Chiyoda-ku, Marunouchi 1-1-1",
  "phone_number": "08123456789",
  "email": "taro.yamada@example.com"
}
```

---

## Debug & Logging

### Debug Log Screen

Akses via icon 🐛 di AppBar home screen.

```
┌─────────────────────────────────┐
│  Debug Logs              [🐛]   │
│  ─────────────────────────────  │
│  [App (25)] [HTTP (3)]          │
│  ─────────────────────────────  │
│  🔴 14:32 Error: timeout        │
│  🔵 14:31 Info: KYC started     │
│  🟠 14:30 HTTP POST /token      │
│                                 │
│  [Copy] [Share] [Clear]         │
└─────────────────────────────────┘
```

**Fitur:**
- Tab App - semua logs aplikasi
- Tab HTTP - semua HTTP requests
- Copy - copy logs ke clipboard
- Share - share via WhatsApp/messages

---

## Architecture Summary

| Component | Description |
|-----------|-------------|
| **Flutter UI** | Screens yang kita bikin (Home, Instruction, Result, Config, Debug) |
| **Liquid SDK** | Native Android library untuk verifikasi (Terms, Document, IC, Face) |
| **Backend Server** | Generate token untuk SDK authentication |
| **Native Plugin** | `LiquidEkycPlugin.kt` - bridge Flutter ↔ SDK |

---

## Key Files

```
lib/
├── main.dart
├── app/
│   └── app.dart                      # App entry point
├── core/
│   ├── constant/
│   │   └── liquid_constants.dart     # Configuration
│   ├── services/
│   │   ├── app_logger.dart           # App logging
│   │   ├── http_logger.dart          # HTTP logging
│   │   └── liquid_ekyc_channel.dart  # Flutter → Native channel
│   ├── screens/
│   │   └── debug_log_screen.dart     # Debug log UI
│   └── widgets/
│       └── kyc_loading_overlay.dart  # Loading overlay
├── data/
│   ├── models/
│   │   ├── kyc_result.dart
│   │   ├── document_result.dart
│   │   ├── face_results.dart
│   │   └── chip_result.dart
│   ├── repositories/
│   │   └── kyc_repository.dart
│   └── services/
│       └── kyc_be_api.dart           # Backend API calls
└── persentation/
    ├── viewmodels/
    │   └── kyc_viewmodel.dart        # Business logic
    └── views/
        └── screens/
            ├── kyc_home_screen.dart
            ├── kyc_instruction_screen.dart
            ├── kyc_result_screen.dart
            └── kyc_config_screen.dart

android/app/src/main/kotlin/.../
├── MainActivity.kt                   # FlutterFragmentActivity
└── plugins/
    └── LiquidEkycPlugin.kt           # Native SDK plugin
```

---

## Build & Run

```bash
# Debug build
flutter build apk --debug

# Debug build split per ABI
flutter build apk --debug --split-per-abi

# Release build
flutter build apk --release

# Run on device
flutter run
```

---

## Notes

1. **Token** - selalu dari BE, tidak di-hardcode
2. **SDK** - handle semua screen verifikasi visual
3. **Kita** - handle navigation, input, dan display hasil
4. **Debug** - gunakan Debug Log screen untuk troubleshooting