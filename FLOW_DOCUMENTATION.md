# Liquid eKYC POC - Flow Documentation

## Overview
Dokumentasi lengkap alur integrasi Liquid eKYC SDK dengan Backend API untuk Flutter Mobile App.

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Phase 1: SDK Mobile (Liquid Native SDK)](#phase-1-sdk-mobile-liquid-native-sdk)
3. [Phase 2: Backend API (BE Connector)](#phase-2-backend-api-be-connector)
4. [Flow Diagram](#flow-diagram)
5. [File Structure](#file-structure)
6. [Doc Spec Mapping](#doc-spec-mapping)
7. [Retry & Queue System](#retry--queue-system)
8. [Configuration](#configuration)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FLUTTER MOBILE APP                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐           │
│  │   UI Layer  │────▶│  ViewModel  │────▶│ Repository  │           │
│  │  (Screens)  │     │ KycViewModel│     │KycRepository│           │
│  └─────────────┘     └─────────────┘     └──────┬──────┘           │
│                                                  │                  │
│                     ┌───────────────────────────┼──────────────┐   │
│                     │                           ▼              │   │
│  ┌─────────────────────────────────────────────────────────┐  │   │
│  │                     LIQUID SDK                          │  │   │
│  │  ┌───────────────┐  ┌───────────────┐  ┌─────────────┐  │  │   │
│  │  │   Channel     │  │   Channel     │  │   Channel   │  │  │   │
│  │  │   Init        │  │   Verify      │  │   Finalize  │  │  │   │
│  │  └───────────────┘  └───────────────┘  └─────────────┘  │  │   │
│  └─────────────────────────────────────────────────────────┘  │   │
│                     │                           │              │   │
│                     └───────────────────────────┼──────────────┘   │
│                                                 │                  │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     BE API Layer                            │   │
│  │  ┌───────────────┐  ┌───────────────┐  ┌─────────────┐     │   │
│  │  │   KycBeApi    │  │KycRetryQueue  │  │KycQueueWorker│    │   │
│  │  │ (All Endpoints)│ │(SharedPrefs) │  │(Background) │     │   │
│  │  └───────────────┘  └───────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                 │                  │
└─────────────────────────────────────────────────┼──────────────────┘
                                                  │
                    ┌────────────────────────────┼────────┐
                    │                            ▼         │
              ┌─────▼─────┐              ┌────────────┐   │
              │Local Dev  │              │   Staging  │   │
              │BE Server  │              │ Connector  │   │
              │:8080      │              │ Liquid     │   │
              └───────────┘              └────────────┘   │
```

---

## URL Configuration

### Current Configuration (2026-07-16)

| Environment | URL | Usage |
|-------------|-----|-------|
| **BE Local** | `http://192.168.1.41:8080` | **All BE API calls** (token fetch + endpoints) |
| SDK URL | `https://applicantsdk-api.stg-liquid-ekyc.com` | Liquid SDK API (Native) |

### Important Notes
- All BE API calls (token fetch + endpoints) → **Local BE only** `http://192.168.1.41:8080`
- SDK Mobile connects directly to Liquid SDK API
- No staging URL for BE - always use local for development
- API Key: `my-test-api-key` (for local BE)

### Header Configuration

```dart
Map<String, String> get _headers => {
  'Content-Type': 'application/json',
  'api-key': 'my-test-api-key',
};
```

---

## Phase 1: SDK Mobile (Liquid Native SDK)

### SDK Method Calls

| Step | Doc Spec Ref | Function Name | File | Description |
|------|--------------|---------------|------|-------------|
| 1 | SDKApplyAPI | `startVerify()` | `liquid_ekyc_channel.dart` | Initialize dengan applicantId + token |
| 2 | SDKApplyAPI | `startVerifyTrial()` | `liquid_ekyc_channel.dart` | Initialize dengan apiKey (trial mode) |
| 3 | TermsOfUse | `showTermsOfUse()` | `liquid_ekyc_channel.dart` | Tampilkan screen persetujuan |
| 4 | VerifyIdDocument | `verifyIdDocument()` | `liquid_ekyc_channel.dart` | Scan dokumen (Driver's License, Residence Card, dll) |
| 5 | VerifyIdChip | `verifyIdChip()` | `liquid_ekyc_channel.dart` | Baca IC Card via NFC |
| 6 | IdentifyIdChip | `identifyIdChip()` | `liquid_ekyc_channel.dart` | Get chip data dari IC Card |
| 7 | VerifyFace | `verifyFace()` | `liquid_ekyc_channel.dart` | Face verification (ACTIVE/PASSIVE) |
| 8 | Finalize | `activate()` | `liquid_ekyc_channel.dart` | Finalisasi KYC |
| 9 | Finalize | `getOcrResults()` | `liquid_ekyc_channel.dart` | Ambil data OCR |

### Channel Handlers

| Handler | File | Responsibility |
|---------|------|----------------|
| `ChannelInitHandler` | `channel_init_handler.dart` | `startVerify()`, `startVerifyTrial()` |
| `ChannelTermsHandler` | `channel_terms_handler.dart` | `showTermsOfUse()` |
| `ChannelVerificationHandler` | `channel_verification_handler.dart` | `verifyIdDocument()`, `verifyIdChip()`, `identifyIdChip()`, `identifyIdMyna()`, `verifyFace()` |
| `ChannelFinalizeHandler` | `channel_finalize_handler.dart` | `activate()`, `getOcrResults()`, `customizeDesign()`, `getSdkVersion()`, `isNfcAvailable()`, `changeLanguage()` |

---

## Phase 2: Backend API (BE Connector)

### BE API Endpoints

| Step | Postman # | Doc Spec Ref | Function Name | Endpoint Path | Method |
|------|-----------|--------------|---------------|---------------|--------|
| BE-1 | #3 | RegisterApplicationInfoAPI | `registerApplicationInfo()` | `/v1/applications/{id}/info` | POST |
| BE-2 | #7 | GetVerificationResultsAPI | `getVerificationResults()` | `/v1/applications/{id}/verification-results` | GET |
| BE-3 | #2 | GetOCRResultsAPI | `getOcrResultsFromBe()` | `/v1/applications/{id}/ocr-results` | GET |
| BE-4 | #4 | GetICCardInfoAPI | `getICCardInfo()` | `/v1/applications/{id}/ic-card-info` | GET |
| BE-5 | #5 | GetPhotosAPI | `getPhotos()` | `/v1/applications/{id}/photos` | GET |
| BE-6 | #6 | GetLiveVerificationPhotosAPI | `getLivenessImages()` | `/v1/applications/{id}/live-verification-photos` | GET |
| BE-7 | #8 | RegisterKYCResultAPI | `registerKycResult()` | `/v1/applications/{id}/kyc-result` | POST |
| BE-8 | #1 | SDKApplyAPI | `applyForSdkToken()` | `/v1/sdk/applications` | POST |
| BE-9 | Orchestration | Orchestration | `processKycOrchestration()` | `/v1/orchestration/{id}/process-kyc` | POST |

---

## Flow Diagram

```
[START] User opens app
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 1: User Input                                                 │
│ - Enter Applicant ID in KycHomeScreen                              │
│ - Click "Ambil Token & Mulai"                                      │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 2: Fetch Credentials from BE (Local)                          │
│ - KycViewModel.fetchCredentialsFromBe()                            │
│ - KycBeApi.applyForSdkToken() → POST http://192.168.1.41:8080      │
│              /v1/sdk/applications                                  │
│ - Returns: applicantId, token, sdkUrl                              │
│ - KycViewModel.setCredentials()                                    │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 3: Navigate to KycTokenScreen                                 │
│ - User sees token loaded                                           │
│ - Click "Mulai Verifikasi"                                         │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 4: Start KYC Flow (KycViewModel.startKyc())                   │
│                                                                     │
│ ├─► Mode Selection:                                                │
│ │   - DEBUG_MODE: Use mock responses (bypass SDK)                  │
│ │   - PRODUCTION: Use dynamic credentials from BE                  │
│ │   - TRIAL: Use API Key only                                      │
│ │                                                                │
│ ├─► SDK Initialize:                                                │
│ │   - startVerify() / startVerifyTrial() → Liquid SDK API         │
│ │   - Returns: session token                                      │
│ │                                                                │
│ └─► Terms of Use:                                                  │
│     - showTermsOfUse()                                            │
│     - User accepts terms                                          │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 5: Verification Steps (based on selected method)              │
│                                                                     │
│ Method: COMPLY_HE (IC Card + Face)                                 │
│ ├─► IC Card (NFC):                                                 │
│ │   - verifyIdChip() → Read IC Card                               │
│ │   - identifyIdChip() → Get chip data                            │
│ │   - getOcrResults() → Quick preview OCR                        │
│ │                                                                │
│ └─► Face Verification:                                            │
│     - verifyFace(ACTIVE) → Head movement detection (DEFAULT)      │
│     - verifyFace(PASSIVE) → Frontal photo only                    │
│                                                                     │
│ Method: COMPLY_HO (Document + Face)                                │
│ ├─► Document Scan:                                                 │
│ │   - verifyIdDocument() → Scan document                          │
│ │   - getOcrResults() → Extract OCR data                         │
│ │                                                                │
│ └─► Face Verification:                                            │
│     - verifyFace()                                                │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 6: Finalize KYC (KycViewModel.startKyc() continuation)        │
│                                                                     │
│ ├─► Activate SDK:                                                  │
│ │   - activate() → Finalize & submit KYC                          │
│ │                                                                │
│ ├─► BE API Calls (after activation) → Local BE http://192.168.1.41:8080 │
│ │   - registerApplicationInfo() [BE-1]                            │
│ │   - getVerificationResults() [BE-2]                             │
│ │   - getICCardInfo() [BE-4]                                      │
│ │   - getOcrResultsFromBe() [BE-3]                                │
│ │   - getLivenessImages() [BE-6]                                  │
│ │   - getPhotos() [BE-5]                                          │
│ │   - registerKycResult() [BE-7]                                  │
│ │                                                                │
│ └─► Retry System:                                                 │
│     - If any API fails → Exponential backoff (1s, 2s, 4s)        │
│     - After 3 retries → Enqueue to KycRetryQueue                 │
│     - KycQueueWorker retries every 5 minutes (max 24 hours)      │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 7: Display Results (KycResultScreen)                          │
│                                                                     │
│ - Toggle SDK Data vs BE Data                                       │
│ - Show placeholder for empty fields: "(data dari API)"             │
│ - Dynamic status colors: Green (success), Orange (partial), Red    │
│ - Show queue indicator if pending requests                         │
└─────────────────────────────────────────────────────────────────────┘
     │
     ▼
[END]
```

---

## File Structure

### Backend API Layer

| File | Path | Functions |
|------|------|-----------|
| `kyc_be_api.dart` | `lib/data/services/` | `applyForSdkToken()`, `registerApplicationInfo()`, `getVerificationResults()`, `getICCardInfo()`, `getOcrResultsFromBe()`, `getPhotos()`, `getLivenessImages()`, `registerKycResult()`, `processKycOrchestration()` |
| `kyc_retry_queue.dart` | `lib/data/services/` | `KycRetryQueue.init()`, `enqueue()`, `dequeue()`, `getPendingRequests()`, `clearQueue()`, `removeExpired()` |
| `kyc_queue_worker.dart` | `lib/data/services/` | `KycQueueWorker.start()`, `stop()`, `processQueue()`, `getPendingCount()` |

### Repository Layer

| File | Path | Functions |
|------|------|-----------|
| `kyc_repository.dart` | `lib/data/repositories/` | `initialize()`, `initializeWithCredentials()`, `showTermsOfUse()`, `verifyDocument()`, `verifyIdChip()`, `verifyFace()`, `activate()`, `getOcrResults()`, `changeLanguage()`, `customizeDesign()`, `checkNfcAvailability()`, `getSdkVersion()` |

### Channel/SDK Layer

| File | Path | Functions |
|------|------|-----------|
| `liquid_ekyc_channel.dart` | `lib/core/services/` | All SDK method calls (delegates to handlers) |
| `channel_init_handler.dart` | `lib/core/services/` | `startVerify()`, `startVerifyTrial()` |
| `channel_terms_handler.dart` | `lib/core/services/` | `showTermsOfUse()` |
| `channel_verification_handler.dart` | `lib/core/services/` | `verifyIdDocument()`, `verifyIdChip()`, `identifyIdChip()`, `identifyIdMyna()`, `verifyFace()` |
| `channel_finalize_handler.dart` | `lib/core/services/` | `activate()`, `getOcrResults()`, `customizeDesign()`, `getSdkVersion()`, `isNfcAvailable()`, `changeLanguage()` |

### Model Layer

| File | Path | Models |
|------|------|--------|
| `kyc_result.dart` | `lib/data/models/` | `KycResult` |
| `document_result.dart` | `lib/data/models/` | `DocumentResult` |
| `face_results.dart` | `lib/data/models/` | `FaceResult`, `AutoVerificationResult` |
| `chip_result.dart` | `lib/data/models/` | `ChipVerificationResult`, `ChipIdentificationResult`, `MynaIdentificationResult`, `LiquidChipDataModel`, `ICCardInfoResponse`, `OcrResultsBeResponse`, `VerificationResultsResponse`, `PhotosResponse`, `LivenessImagesResponse` |

### ViewModel Layer

| File | Path | Functions |
|------|------|-----------|
| `kyc_viewmodel.dart` | `lib/persentation/viewmodels/` | `fetchCredentialsFromBe()`, `setCredentials()`, `clearCredentials()`, `startKyc()`, `setVerificationMethod()`, `setDocumentType()`, `setFaceType()`, `setLanguage()`, `setButtonColor()` |

### UI Layer

| File | Path | Screen |
|------|------|--------|
| `kyc_home_screen.dart` | `lib/persentation/views/screens/` | Home screen, input applicant ID |
| `kyc_token_screen.dart` | `lib/persentation/views/screens/` | Token input, start verification |
| `kyc_config_screen.dart` | `lib/persentation/views/screens/` | Configure method, doc type, face type |
| `kyc_instruction_screen.dart` | `lib/persentation/views/screens/` | Instructions before verification |
| `kyc_result_screen.dart` | `lib/persentation/views/screens/` | Results display (SDK vs BE toggle) |

### Constants/Config

| File | Path | Contents |
|------|------|----------|
| `liquid_constants.dart` | `lib/core/constant/` | `LiquidConfig.DEBUG_MODE`, `LiquidConfig.BYPASS_BE`, enums (`VerificationMethod`, `LiquidDocumentType`, `FaceVerificationType`, etc.) |
| `liquid_config.dart` | `lib/core/constant/` | SDK URL, API Key, credentials |

---

## Doc Spec Mapping

| Doc Spec File | API Endpoint | Implemented | Function |
|---------------|--------------|-------------|----------|
| `LIQUID_eKYC_017_SDKApplyAPI_v1.3.6.pdf` | POST /v1/sdk/applications | ✅ | `applyForSdkToken()` |
| `LIQUID_eKYC_013_GetOCRResultsAPI_v1.8.8.pdf` | GET /v1/applications/{id}/ocr-results | ✅ | `getOcrResultsFromBe()` |
| `LIQUID_eKYC_016_RegisterApplicationInfoAPI_v1.3.2.pdf` | POST /v1/applications/{id}/info | ✅ | `registerApplicationInfo()` |
| `LIQUID_eKYC_022_GetICCardInfo_API_v1.3.9.pdf` | GET /v1/applications/{id}/ic-card-info | ✅ | `getICCardInfo()` |
| `LIQUID_eKYC_010_GetPhotosAPI_v1.7.7.pdf` | GET /v1/applications/{id}/photos | ✅ | `getPhotos()` |
| `LIQUID_eKYC_019_GetSDKLiveVerificationPhotosAPI_v1.1.4.pdf` | GET /v1/applications/{id}/live-verification-photos | ✅ | `getLivenessImages()` |
| `LIQUID_eKYC_012_GetVerificationResultsAPI_v1.3.4.pdf` | GET /v1/applications/{id}/verification-results | ✅ | `getVerificationResults()` |
| `LIQUID_eKYC_014_RegisterKYCResultAPI_v1.4.2.pdf` | POST /v1/applications/{id}/kyc-result | ✅ | `registerKycResult()` |
| `LIQUID_eKYC_901_DeleteUserDataAPI_v1.3.9.pdf` | DELETE /v1/applications/{id} | ❌ | Not implemented (MOCK) |

---

## Retry & Queue System

### Configuration

| Setting | Value |
|---------|-------|
| Max retries per request | 3 |
| Base delay | 1 second |
| Max delay | 4 seconds |
| Random jitter | 0-500ms |
| Queue check interval | 5 minutes |
| Max queue age | 24 hours |

### Exponential Backoff

```
Attempt 1 → Fail → Wait 1000-1500ms
     │
     ▼
Attempt 2 → Fail → Wait 2000-2500ms
     │
     ▼
Attempt 3 → Fail → Wait 4000-4500ms
     │
     ▼
All retries exhausted → Enqueue to SharedPreferences
     │
     ▼
KycQueueWorker (background) → Retry every 5 minutes
     │
     ▼
Success or Max 24h reached → Remove from queue
```

---

## Configuration

### Face Verification Type

| Type | Description | Default |
|------|-------------|---------|
| `ACTIVE` | Requires head movement detection | ✅ **Default** |
| `PASSIVE` | Frontal photo only | |

**Location**: `kyc_viewmodel.dart:114`
```dart
FaceVerificationType _selectedFaceType = FaceVerificationType.active;
```

**Change to PASSIVE**: 
```dart
FaceVerificationType _selectedFaceType = FaceVerificationType.passive;
```

### Verification Method

| Method | Description | Default |
|--------|-------------|---------|
| `COMPLY_HE` | IC Card + Face (No document scan) | ✅ **Default** |
| `COMPLY_HO` | Document + Face |
| `FRONT` | Front Document Only |
| `READ` | IC Card Only (No Signature) |

**Location**: `kyc_viewmodel.dart:112`
```dart
VerificationMethod _selectedMethod = VerificationMethod.defaultMethod;  // COMPLY_HE
```

### Document Type

| Type | Description | Default |
|------|-------------|---------|
| `RESIDENCE_CARD` | 在留カード | ✅ **Default** |
| `DRIVER_LICENSE` | 普通自動車驾驶证 |
| `MY_NUMBER_CARD` | 個人番号カード |
| `PASSPORT` | パスポート |

**Location**: `kyc_viewmodel.dart:113`
```dart
LiquidDocumentType _selectedDocumentType = LiquidDocumentType.defaultType;  // Residence Card
```

### BE URL Configuration

**Location**: `kyc_be_api.dart:15`
```dart
static const String _beUrl = 'http://192.168.1.41:8080';
```

All BE API calls go to this URL only (no staging URL).

### Debug Mode Configuration

**Location**: `liquid_constants.dart:14-15`
```dart
static const bool DEBUG_MODE = false;   // true = mock responses, false = real SDK
static const bool BYPASS_BE = false;    // true = skip BE, use hardcoded credentials
```

---

## Data Flow: SDK vs BE

### Result Display

The app displays verification results from two sources:

| Source | Data Type | Display Location |
|--------|-----------|------------------|
| SDK (Native) | OCR, Chip Data, Face Result | Left side of toggle |
| BE (API) | Official data from Liquid | Right side of toggle |

### Placeholder Pattern

Empty fields display: `(data dari API)`

### Status Colors

| Status | Color | Meaning |
|--------|-------|---------|
| Green | `#4CAF50` | Verification passed |
| Orange | `#FF9800` | Partial success |
| Red | `#F44336` | Verification failed |

---

## Key Decisions

1. **BE URL**: Always use local `http://192.168.1.41:8080` (no staging)
2. **FaceVerificationType Default**: `ACTIVE` (requires head movement detection)
3. **VerificationMethod Default**: `COMPLY_HE` (IC Card + Face, no document scan)
4. **DocumentType Default**: `RESIDENCE_CARD`
5. **Display Name Split**: `applicantName` → `first_name` + `last_name`
6. **Date Format**: `YYYY-MM-DD` → `YYYYMMDD` for BE API
7. **URL Pattern**: `/v1/applications/{id}/` (not `/v1/applicants/`)
8. **API Key**: `my-test-api-key` (for local BE)

---

## Testing Notes

### Postman Collection
- File: `documents/SDK Function/liquid-collection-v3.postman_collection.json`
- Base URL: `http://localhost:8080` (local dev BE)
- Test Applicant ID: `111902224425`

### Debug Mode
Set `LiquidConfig.DEBUG_MODE = true` to bypass SDK and BE calls with mock responses.

### Bypass BE Mode
Set `LiquidConfig.BYPASS_BE = true` to skip BE token fetch and use hardcoded credentials.

---

*Document Version: 1.1*
*Last Updated: 2026-07-16*
*Changes: Added local BE URL only (removed staging), updated API key*