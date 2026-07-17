# Flutter eKYC Liquid SDK Integration - POC Summary

## Project Info
- **Project**: poc_liquidekyc_flutter
- **SDK Version**: Liquid eKYC v1.47.0
- **Target**: Indonesian eKYC (KTP)

## Configuration

### Constants (`lib/core/utils/liquid_constants.dart`)
```
SDK_MODE = DEBUG_MODE = false        # Production mode
BYPASS_BE = false                    # Backend integration enabled
```

### URLs
```
SDK API:           https://applicantsdk-api.stg-liquid-ekyc.com
BE Backend:        https://connector-bni.stg-liquid-ekyc.com
BE API Key:        JDJhJDEwJENQem1xTFB3NlJodFZ1MEt0THYyMC5XVEEwNEdQc3dDT0RXY0NEYmpmL053WjVIaUt6ZnFD
```

### Hardcoded Test Values
```dart
token:        test_token_123456789
applicantId:  test_applicant_987654321
```

## Flow Implementation

### COMPLY_HE Flow (IC Chip + Face)
```
[BE-0] SDKApplyAPI          → get token
[STEP 10] showTermsOfUse
[STEP 11] verifyIdChip      → IC chip scan
[SDK] getOcrResults()       → OCR preview (instant from SDK)
[STEP 13] verifyFace        → Face verification
[BE-1] registerApplicationInfo  → REQUIRED per vendor (016)
[SDK] activate()            → finalize SDK session
[BE-2] getVerificationResults   → face score, liveness
[BE-3] getOcrResultsFromBe      → OCR official
[BE-4] getLivenessImages        → face photos (3)
[BE-5] getPhotos                → document photos (5)
[BE-6] getICCardInfo            → chip data
[BE-7] registerKycResult        → trigger masking
```

### Key Decisions
1. **registerApplicationInfo WAJIB** - harus dipanggil setelah face verification, sebelum activate()
2. **Dual OCR**: SDK (preview cepat) vs BE (official record)
3. **Face score dari BE API** - SDK returns null untuk liveness/matchScore

## BE API Endpoints

| API | Method | Endpoint |
|-----|--------|----------|
| SDKApplyAPI | POST | /api/v1/auth/token |
| registerApplicationInfo | POST | /api/v1/applicant/register-application-info |
| getVerificationResults | GET | /api/v1/applicant/verification-results |
| getOcrResultsFromBe | GET | /api/v1/applicant/ocr-results |
| getICCardInfo | GET | /api/v1/applicant/ic-card-info |
| getLivenessImages | GET | /api/v1/applicant/liveness-images |
| getPhotos | GET | /api/v1/applicant/photos |
| registerKycResult | POST | /api/v1/applicant/register-kyc-result |

### Required Headers
```dart
Headers:
  - Content-Type: application/json
  - X-Ekyc-Api-Key: <API_KEY>
  - Authorization: Bearer <TOKEN>
```

## Key Files

### Services
- `lib/core/services/liquid_sdk_service.dart` - SDK initialization & flow methods
- `lib/core/services/channel_finalize_handler.dart` - SDK channel methods (getOcrResults)
- `lib/data/services/kyc_be_api.dart` - All 7 BE API calls + response models

### ViewModels
- `lib/persentation/viewmodels/kyc_viewmodel.dart` - Main flow logic

### Screens
- `lib/persentation/views/screens/kyc_home_screen.dart` - Entry point
- `lib/persentation/views/screens/kyc_result_screen.dart` - Result display (clean, no emoji)
- `lib/persentation/views/screens/kyc_debug_screen.dart` - Debug/log viewer

### Models
- `lib/data/models/kyc_result.dart`
- `lib/data/models/document_result.dart`
- `lib/data/models/face_results.dart`
- `lib/data/models/chip_result.dart`
- `lib/data/models/be_responses.dart` - All BE response models

## Result Screen Layout

```
┌─────────────────────────────────────────┐
│  [✓] Verifikasi Berhasil!               │
│      [ eKYC Complete ]                  │
│                                         │
│  Detail Verifikasi                      │
│  ┌─────────────────────────────────┐    │
│  │ [Doc] [IC Chip] [Face]          │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ Data Kartu (OCR - SDK Preview)  │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ Data Kartu (BE Official)        │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ Verifikasi IC Chip              │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ Verifikasi Wajah                │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ BE API Status                   │    │
│  └─────────────────────────────────┘    │
│  [Lihat Log]                            │
│  [Selesai]                              │
└─────────────────────────────────────────┘
```

## Docs Reference
All 10 documents read from `documents/SDK Function/`:
- 017_SDKApplyAPI
- 016_RegisterApplicationInfoAPI
- 012_GetVerificationResultsAPI
- 013_GetOCRResultsAPI
- 022_GetICCardInfo_API
- 010_GetPhotosAPI
- 014_RegisterKYCResultAPI
- 019_GetLivenessImagesAPI
- SDK Specs v1.44.0
- Connection Check Sheet

## Next Steps
1. Update BE API endpoint URLs when vendor provides actual endpoints
2. Test complete flow with real credentials
3. Replace hardcoded token/applicantId with dynamic values
4. Add proper error handling for each BE API call