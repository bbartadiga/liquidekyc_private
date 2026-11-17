# eKYC COMPLY_HE Implementation Audit — Liquid POC Docs

## Scope

- **Project:** `module_liquid_ekyc` (Flutter + Android)
- **Method:** `COMPLY_HE` (IC chip scan + OCR + Face)
- **Documents:** Residence Card, Driving License, My Number Card
- **Nationality:** Indonesia, Jepang
- **Source docs:** `/Users/admin/Documents/BNI/Digiremit/Liquid POC Docs/`

## Citation Format

```
[N] filename.pdf — page X
```

Referensi dokumen Liquid yang dipakai:

| Kode | Dokumen | Bahasa |
|------|---------|--------|
| D1 | `5. Connector API Specification (Individual)/English ver/[E]LIQUID_eKYC_022_GetICCardInfo_API_v1.3.9.pdf` | 🇬🇧 |
| D2 | `5. Connector API Specification (Individual)/[E]LIQUID_eKYC_022_ICカード読取情報取得API_v1.4.2.pdf` | 🇯🇵 |
| D3 | `5. Connector API Specification (Individual)/Japanese ver/` (013 OCR, 014 Register, 016 Register AppInfo, 017 SDK Apply, 019 Liveness, 901 Delete) | 🇯🇵 |
| D4 | `9. Connector API Specification/English/[E]LIQUID_eKYC_022_GetICCardInfo_API_v1.3.9.pdf` (sama D1 — versi EN) | 🇬🇧 |
| D5 | `4. Connector API Specification (Common)/6. LIQUID_eKYC_G05_APIマスターコード（APIGenericCode）_v1.4.3.pdf` | 🇯🇵 |
| D6 | `17. 2nd Generation Residence Card/1. Information on LIQUID eKYC Support…PDF` | 🇯🇵 |
| D7 | `17. 2nd Generation Residence Card/2. Second-Generation Specified Residence Card PDF` | 🇯🇵 |
| D8 | `13. IC Omakase Pack/3. [EN]LIQUIDeKYCICScanIntegrationPackSpefications.Ver.1.5.0.pdf` | 🇬🇧 |

---

# 🔴 Bug Kritis: Document Type di-Downgrade ke Residence Card (17 Nov 2026)

## Gejala

Pilih **Jepang → My Number Card** → SDK baca kartu sebagai **Residence Card**, dan TnC yang muncul = TnC Residence Card.

## Root Cause

**Dart sudah benar** — `liquid_constants.dart:316-317` (`myNumberCard.value` → `"MY_NUMBER_CARD"`), dikirim di `channel_verification_handler.dart:152-158`.

**Kotlin yang salah** — `android/.../liquid_ekyc/VerificationHandler.kt:77-81`:

```kotlin
val documentType = when (documentTypeStr.uppercase()) {
    "RESIDENCE_CARD" -> LiquidDocumentType.RESIDENCE_CARD
    "DRIVER_LICENSE" -> LiquidDocumentType.DRIVER_LICENSE
    else -> LiquidDocumentType.RESIDENCE_CARD   // ← "MY_NUMBER_CARD" jatuh ke sini
}
val params = VerifyIdChipParameters.Builder(documentType, VerificationMethod.COMPLY_HE)  // ← method hardcode
```

Efek di dalam SDK (verified dari binary `Liquid-1.47.0.aar`):

| Seharusnya | Terjadi |
|---|---|
| Upload chip → `/id_doc_photos/my_number_card_ic` | → `/id_doc_photos/residence_card_ic` |
| Flow input 個人番号 12 digit + 生年月日 | Tidak pernah muncul (ganti flow PIN) |

## Fix (sudah diimplementasikan)

`VerificationHandler.kt` — 2 helper baru:

- `toLiquidDocumentType(value): LiquidDocumentType?` → 13 enum, **null kalau tidak dikenal** (fail loudly, bukan fallback diam-diam)
- `toVerificationMethod(value): VerificationMethod` → 11 enum, dipakai `verifyIdChip` **dan** `verifyIdDocument`

Unknown `documentType` → `result.error("INVALID_DOCUMENT_TYPE", ...)`.

**Docs ref:** Interface Spec v1.47.0 sheet `verifyIdChip.IN` (enum `LiquidDocumentType` & `VerificationMethod`), README SDK "書類ICカードファンクション開始".

## Chip Data & Auto Verification sekarang sampai ke Dart

**Sebelum:** native bridge (`SdkManager.kt`) cuma kirim 4 key (`resultStatus`, `errorCode`, `additionalDataTitle`, `additionalDataMessage`). `chipData` & `autoVerificationResult` **selalu null** → 個人番号, `card_type`, dokumen aktual, dan status auto-verification tidak pernah tampil.

**Sekarang (`VerificationHandler.kt` + `SdkManager.kt`):**
- `buildChipDataMap()` → 22 field dari `LiquidChipData` (termasuk `myNumber`, `liquidDocumentType`, `residenceCardType` kode 1/2/5/6/7/8, `driversLicenseTypes`)
- `buildAutoVerificationMap()` → flatten `faceResult`/`faceScore`/`photoResult`/`photoScore`/`passiveResult`
- `isActualDocumentTypeCompatible()` → aturan payung `RESIDENCE_DOCUMENT_GEN2`
- OCR map += `driversLicenseTypes` (`FinalizeHandler.kt`)

**Deteksi mismatch:** `KycViewModel.isDocumentTypeMismatch` (dokumen diminta vs dokumen dibaca dari chip) → log `[Mismatch]` + badge **DOC MISMATCH** di Identity Card. Rule identik di Kotlin & Dart (`LiquidDocumentType.isCompatibleWith`).

**Docs ref:** SDK binary 1.47.0 → `result/chip/LiquidChipData` (getters), `result/auto/AutoVerificationResult`, `result/chip/LiquidResidenceCardType` (enum UNDETECTED/RESIDENCE_CARD/SPECIAL_PERMANENT_RESIDENT_CERTIFICATE/RESIDENCE_CARD_GEN2/SPECIAL_PERMANENT_RESIDENT_CERTIFICATE_GEN2/SPECIFIED_RESIDENCE_CARD/SPECIFIED_SPECIAL_PERMANENT_RESIDENT_CERTIFICATE).

## Gen-2 Residence Card — SDK 1.47.0 sudah support

`RESIDENCE_CARD` (在留カード) = **generasi sekarang saja**.
`RESIDENCE_DOCUMENT_GEN2` (第2世代在留カード等) = **auto-detect 4 jenis**: 在留カード / 特別永住者証明書 / 第2世代在留カード / 第2世代特別永住者証明書.

Error baru: `chip_unsupported_residence_card_type` + field "在留カード／特別永住者証明書の種別" di response. SE21111: 指定書類種別 ≠ kartu yang dipakai → error.

**Implementasi:** `LiquidDocumentType.residenceDocumentGen2` + `specifiedResidenceCard` + `specifiedSpecialPermanentResidentCertificate`; dropdown Indonesia → `[residenceCard, residenceDocumentGen2]`.

**Catatan env:** Gen-2 belum bisa dites di staging (per tim Tokyo) — hanya di production. Sudah ada env switch `LiquidConfig.USE_PRODUCTION` (default `false`); credential production masih kosong, harus diminta ke Liquid CS.

**Docs ref:** `6. Application SDK/4. …Interface Specification v1.47.0.zip` → PDF sheet `verifyIdChip.IN` (p.31) & `verifyIdChip.RES` (p.29); `17. 2nd Generation Residence Card_Specified Residence Card/1. …対応のご案内.pdf`.

---

# ✅ Sudah Di-Implement di Project

## 1. Setup & Method Configuration

### HARDCODE method `COMPLY_HE`
- `lib/core/constant/liquid_constants.dart:103` — `defaultMethod = VerificationMethod.complyHe`
- `lib/persentation/views/screens/kyc_config_screen.dart:_onSubmit` — `viewModel.setVerificationMethod(VerificationMethod.complyHe)` (hardcoded, no UI choice)
- **Docs ref:** D8 page "Document IC Scan Function" — COMPLY_HE cocok untuk IC reading with chip.

### Verification Order (IC + Face, no doc scan)
- `lib/core/constant/liquid_constants.dart:218-229` — `verificationOrder` returns `['icCard', 'face']` saat COMPLY_HE
- **Docs ref:** D1/D2 page "Specification" → COMPLY_HE flow is IC→OCR→Face.

### 3-Dokumen Filter di Config Screen
- `lib/persentation/views/screens/kyc_config_screen.dart:58-62` UI filter: `residenceCard | driverLicense | myNumberCard`
- `lib/persentation/viewmodels/kyc_viewmodel.dart:304-310` allow-list untuk COMPLY_HE: `driverLicense | myNumberCard (+2 varian) | residenceCard`
- **Docs ref:** D1 page "ID documents for IC card scan" → Driver's licence, National Identity Card, Residence card, Special Permanent Resident Certificate.

## 2. Nationality Selection Flow

### 2 Negara: Indonesia & Jepang
- `lib/core/constant/liquid_constants.dart:89-109` — `enum Nationality { indonesia, japan }` dengan `allowedDocuments` getter
- `lib/persentation/views/screens/kyc_config_screen.dart` — dropdown nationality dengan auto-filter document:
  - Indonesia → Residence Card saja
  - Jepang → Driving License + My Number
- `lib/persentation/viewmodels/kyc_viewmodel.dart:112-130` — `_selectedNationality` field, `setNationality()`, `selectedNationality` getter
- **Docs ref:** D7 page "本人確認書類コード表" — nationality ISO code 'ID' / 'JP' untuk Indonesia/Jepang.

### Persist nationality untuk fallback
- `lib/persentation/views/screens/kyc_config_screen.dart:_onSubmit()` — panggil `viewModel.setNationality(_nationality)` sebelum push HomeScreen.

## 3. Document Type Mapping (`liquid_mappings.dart`)

### ID Document Type — 12 kode basic
`lib/core/constant/liquid_mappings.dart:10-25`:
```
'01' Driver's Licence           '02' Individual Number Card (My Number)
'03' Residence Card              '04' Driving History Certificate
'05' Special Perm Resident      '06' Passport
'07' Student ID Card             '08' Student Notebook
'09' Health Insurance Card
'11' Driver's Licence (IC)      '12' National Identity Card (IC, My Number)
'13' Residence Card (IC)         '14' Special Perm Resident (IC)
'42' JPKI Public Cert
```
- **Docs ref:** D5 page 15-16 (本人確認書類コード表 COMPLY_HE) — codes `11`, `12`, `13`, `15` confirmed.

### Nationality ISO 3166-1 alpha-2 — 30 negara
`lib/core/constant/liquid_mappings.dart:28-55`:
- `ID`, `JP`, `PH`, `BR`, `CN`, `KR`, `VN`, `TH`, `MM`, `KH`, `LA`, `MY`, `SG`, `NP`, `IN`, `BD`, `PK`, `LK`, `US`, `CA`, `GB`, `AU`, `NZ`, `DE`, `FR`, `NL`, `RU`, `TW`, `HK`, `MO`
- **Docs ref:** D5 page 11 (対象地域コード) confirms ISO 3166-1 alpha-2.

### Extension getters di `OcrResultsBeResponse`
`lib/core/constant/liquid_mappings.dart:75-89`:
- `documentTypeName`, `documentTypeDisplay` → `"Residence Card (03)"`
- `nationalityName`, `nationalityDisplay` → `"Indonesia (ID)"`
- **Docs ref:** D1 page 6 → `id_document_type` field validasi, page 9 → `nationality` ISO alpha-2.

## 4. Parser Models (`id_document_type` di OCR)

### BE OCR Response — `idDocumentType` field
- `lib/data/services/kyc_be_api.dart:1140-1218` — `OcrResultsBeResponse` punya field `idDocumentType` (parser dari `map['id_document_type']?.toString()`).
- **Docs ref:** D1 page 6 → response #1 `id_document_type` (Code of ID document type, integer, refs APIGenericCode).
- **Docs ref:** D3 OCR page 6 → same field name.

### SDK OCR Result
- `lib/data/models/chip_result.dart:240-588` — `OcrResult` model dengan fields lengkap: name, birthday, sex, address, nationality, idNumber, residentStatus, etc.
- **Docs ref:** D8 "Document IC Scan Function return values" → matching fields.

## 5. Logging Strategy

### `[OCR-Parse-SDK]` — SDK OCR parsing
- `lib/data/models/chip_result.dart:534` — log raw parsed SDK fields
  ```
  name | birthday | sex | nationality | id_number | resident_status | 
  stay_period | expire_date | address=***MASKED***
  ```

### `[OCR-Parse-BE]` — BE OCR parsing
- `lib/data/services/kyc_be_api.dart:1196` — log raw BE fields including `id_document_type`
  ```
  id_document_type | nationality | name | birthday | sex | id_number | 
  expire_date | issue_date | resident_status | stay_period | address=***MASKED***
  ```

### `[OCR-Mapping]` — Unknown code warning
- `lib/core/constant/liquid_mappings.dart:62` dan :70 — warn level saat code ga ada di tabel
  ```
  [OCR-Mapping] Unknown id_document_type code: "99" — add to liquidIdDocumentTypeNames
  [OCR-Mapping] Unknown nationality code: "XX" — add to liquidNationalityNames
  ```

### `[IdentityCard]` — Tab-aware render log
- `lib/persentation/views/screens/kyc_result_screen.dart:426` — log hasil render card dengan source SDK+Config atau BE+Config

## 6. UI — Identity Card di Result Screen

### Tab-aware cascade fallback
- `lib/persentation/views/screens/kyc_result_screen.dart:_buildIdentityCard` (line ~391-512)
- Tab SDK: nationality dari `viewModel.ocrResult?.nationality`, docType dari `viewModel.selectedDocumentType`
- Tab BE: nationality & docType dari `viewModel.beOcrResults`, fallback ke user config
- Source tag dinamis: `SDK + Config` atau `BE + Config`
- **Docs ref:** D8 page "OCR result" — SDK returns nationality, AE returns both nationality+id_document_type.

### Labels (sesuai request: "Nationality" + "Jenis Dokumen")
Card prominent di result screen: Nationality + Jenis Dokumen dengan code chip (e.g., `[ID]`, `[03]`).

## 7. Result Screen "Selesai" → Balik ke Config

- `lib/persentation/views/screens/kyc_home_screen.dart:` — 2 titik `onDone` pakai `Navigator.of(ctx).popUntil((route) => route.isFirst)` → balik ke `KycConfigScreen`.

## 8. Telegram Log Uploader

- `lib/core/services/telegram_log_uploader.dart` (BARU) — auto-subscribe `appLogger.stream`, batch WARNING/ERROR/INFO/DEBUG ke Telegram bot.
- `lib/main.dart` — `TelegramLogUploader.init(minLevel: LogLevel.debug)` setelah `appLogger.init()`.
- Privacy sanitizer: 35+ sensitive keys auto-masked (`name`, `birthday`, `address`, `id_number`, `nationality`, `token`, `x-api-key`, dll).

## 9. AppLog & HTTPLog capture di Release Mode

- `lib/core/services/app_logger.dart:108-126` — `if (!kDebugMode) return` di-remove → logs capture di release juga.
- `lib/core/services/http_logger.dart` — `_logRequest/_logResponse` sekarang forward ke `appLogger` dengan tag `HTTP-REQ` / `HTTP-RESP` (level info/error).

---

# ❌ ~~Belum Di-Implement~~ → Semua sudah di-apply (Nov 2026 update)

## 1. Gen-2 Residence Card (4 cards baru)

### Status: Card types yang BELUM ada di mapping

Per D5 page 15 (本人確認書類コード表 COMPLY_HE):

| Code | Document | Implement? |
|------|----------|------------|
| `01036` | 第2世代在留カード (Gen-2 Residence) | ❌ **MISSING** di `liquid_mappings.dart` |
| `01037` | 第2世代特別永住者証明書 (Gen-2 SPR Cert) | ❌ **MISSING** |
| `01038` | 特定在留カード (Specified Residence, MN-integrated) | ❌ **MISSING** |
| `01039` | 特定特別永住者証明書 (Specified SPR, MN-integrated) | ❌ **MISSING** |

### Action Items
1. Tambahkan 4 entry baru ke `liquid_mappings.dart` `liquidIdDocumentTypeNames`:
```dart
'01036': 'Gen-2 Residence Card',
'01037': 'Gen-2 Special Permanent Resident Certificate',
'01038': 'Specified Residence Card (My Number integrated)',
'01039': 'Specified Special Permanent Resident Certificate',
```
- **Docs ref:** D5 page 15-16 (へ対応 code table 01036-01039).
- **Docs ref:** D6 page 5-13 (correspondence matrix per card type).
- **Docs ref:** D7 page "Card codes" (01036-01039 newly numbered).

### Timeline (PENTING untuk verify)
Per D6 page 9 (対応状況マトリクス):
| Type | SDK availability | IC Omakase Pack |
|------|-------------------|------------------|
| 第2世代在留カード | 2026年7〜8月 | 2026年8〜9月 |
| 第2世代特別永住者 | 2026年7〜8月 | 2026年8〜9月 |
| 特定在留カード | 2026年7〜8月 | 2026年8〜9月 |
| 特定特別永住者 | 2026年7〜8月 | 2026年8〜9月 |

**Current SDK version lo: `1.47.0`.** Perlu konfirmasi ke Liquid apakah `1.47.0` sudah support atau perlu upgrade ke versi lebih baru.
**Docs ref:** D6 page 9.

### Quirks per Gen-2 (per D7 page 5-13)

For Gen-2 Residence Card via COMPLY_HE:
- **User pilih "在留カード" / "特別永住者証明書" / "第2世代在留カード等"** (blended enum) — SDK auto-detect apakah current atau Gen-2.
- **Hasil:** response code `id_document_type` jadi `01036` atau `01037` (bukan `13` atau `15`).
- **License:** bisa 指定 Specified → "特定在留カード / 特定特別永住者証明書" (new SDK enum, MUST specify upfront).
- **Docs ref:** D7 page 2 (SDK usage flow per type).

## 2. MyNumber Variants (IC Card)

Belum ada mapping untuk 3 variant IC My Number:

| Code | Document | Implement? |
|------|----------|------------|
| `01023` | マイナンバーカード（＋個人番号） | ❌ **MISSING** |
| `01035` | マイナンバーカード（＋免許情報） | ❌ **MISSING** |
| `01040` | マイナンバーカード（＋公的個人認証） | ❌ **MISSING** |

- **Docs ref:** D5 page 17 (へ対応 code table 01023, 01035, 01040).
- **Action:** Tambahkan ke `liquidIdDocumentTypeNames`.

## 3. Special Permanent Resident Code `15` (current)

- Code `15` (特別永住者証明書 IC) belum spesifik di mapping. Sekarang masih fallback ke `'14'` (salah).
- **Action:** Update `'14'` → `'15'`, mapping to "Special Permanent Resident Certificate (current)".
- **Docs ref:** D5 page 16.

## 4. Fields Belum Ada di Models — Khusus Gen-2

Per D7 page 5-13, D2 API response (page 17 onwards) — fields ini RETURNED HANYA untuk Gen-2 cards:

### `ICCardInfoResponse` (lib/data/services/kyc_be_api.dart:955)
**Belum ada:**
- `cardType` (在留カード／特別永住者証明書の種別) — `0,1,2,5,6,7,8`
- `residentStatusCode` (3-digit)
- `kindOfPermissionCode` (2-digit)
- `employmentRestrictionCode` (1-digit)
- `nationalityCode3` (3-digit ISO)
- `nationalityCode3Alt` (3-digit second candidate)
- **Docs ref:** D7 page 6 (在留カード／特別永住者証明書の種別 返却フィールド).
- **Docs ref:** D2 page 17-22 (各書類フィールド IC chip data).

### `OcrResultsBeResponse` (lib/data/services/kyc_be_api.dart:1140)
**Belum ada (5 fields sama):**
- `cardType`
- `residentStatusCode`
- `kindOfPermissionCode`
- `employmentRestrictionCode`
- `nationalityCode3`
- **Docs ref:** D1 page "Response data" → versi 1.3.9; D2 page 17 directly has v1.4.2 spec with these new fields.

### Action Items
1. Tambahkan 5-6 fields ke `ICCardInfoResponse`
2. Tambahkan parser di `fromMap`
3. Tambahkan same 5 fields ke `OcrResultsBeResponse` + parser
4. Ganti `id_document_type` parsing dari `String` jadi `String` (sudah ada) tapi tambahkan logic untuk handle short vs long codes (3-digit vs 5-digit)

## 5. Nationality 3-Digit Code Master

Per D5 page 14 (国籍 (3桁)) + page 41 onwards (国籍コード表) — table 41 mencakup ~40 negara umum WNA di Jepang.

### Status
- `liquidNationalityNames` di project cuma punya 30 negara ISO **2-digit** alpha-2.
- BELUM ada mapping untuk 3-digit (IDN, JPN, VNM, USA, KOR, dll).

### Action Items
Buat map baru atau extend existing:
```dart
const Map<String, String> liquidNationalityNames3 = {
  'JPN': 'Jepang', 'IDN': 'Indonesia', 'VNM': 'Vietnam',
  'PHL': 'Filipina', 'MMR': 'Myanmar', 'KHM': 'Kamboja',
  'LAO': 'Laos', 'THA': 'Thailand', 'CHN': 'Tiongkok',
  // ... dst ~40 negara
};
```
- **Docs ref:** D5 page 41 国籍コード表 — full table.

## 6. Stay Period Field (Split Year/Month/Day)

Per D7 page 13-14, untuk Gen-2:
- `stayPeriodYear` (年)
- `stayPeriodMonth` (月)
- `stayPeriodDay` (日)

### Status
- `OcrResultsBeResponse.stayPeriod` ada di project — tapi cuma single string ("3年" format).
- **Belum ada split year/month/day fields.**

### Action Items
Tambah fields di `OcrResultsBeResponse` + `ICCardInfoResponse`:
```dart
final int? stayPeriodYear;
final int? stayPeriodMonth;
final int? stayPeriodDay;
```
- **Docs ref:** D7 page 13-15 (在留期間年/月/日 format YYMM or DDD).
- **Docs ref:** D2 page 19-22 (same fields).

## 7. Update Logs untuk Field Baru Gen-2

### Status
- `[OCR-Parse-SDK]` dan `[OCR-Parse-BE]` belum log:
  - `cardType` (1 / 2 / 5 / 6 / 7 / 8)
  - `residentStatusCode`
  - `kindOfPermissionCode`
  - `employmentRestrictionCode`
  - `nationalityCode3`
- **Action:** Update log message di `chip_result.dart` line ~536 dan `kyc_be_api.dart` line 1196.

### Contoh log yang harus ditambah:
```
[OCR-Parse-BE] ...
  card_type=5(Gen-2 在留) | resident_status_code=T03 教授 | 
  kind_of_permission_code=C0 | employment_restriction_code=1 | 
  nationality_code3=IDN
```

## 8. Nationality Mapping Helper Function

### Status
- Untuk **3-digit** codes belum ada `resolveNationalityName3(code)` helper di `liquid_mappings.dart`.

### Action Items
Tambah:
```dart
String? resolveNationalityName3(String? code) {
  if (code == null || code.isEmpty) return null;
  return liquidNationalityNames3[code.toUpperCase()] ?? code;
}
```
Dan extension getter di `OcrResultsBeResponse.nationalityCode3Name`.

## 9. SDK Version Verification (Blocked by Vendor)

### Status
- Project pakai `SDK_Android_ver1.47.0` & `SDK_iOS_ver1.47.0`.
- Belum konfirmasi apakah SDK 1.47.0 includes Gen-2 support.

### Next Steps
- Hubungi vendor Liquid atau cek release notes untuk:
  - Apakah 1.47.0 sudah include `01036-01039` codes
  - Apakah SDK 1.47.0 sudah bisa auto-detect Gen-2 cards
  - Atau perlu upgrade ke 1.48.x atau lebih baru

**Docs ref:** D6 page 9 (Timeline).
**Risk:** Kalau SDK belum support, kalau user coba scan Gen-2 card → **"PINエラーを表すダイアログ" muncul** (current SDK behavior per D6 page 9).

## 10. Backside Photo di COMPLY_HE — TIDAK APPLICABLE

### Konfirmasi (jawaban untuk pertanyaan awal)

**COMPLY_HE TIDAK PERNAH拍 裏面 (backside) foto dokumen.**

| Document Type di COMPLY_HE | Front Image | Backside Photo |
|---------------------------|-------------|----------------|
| Driver's Licence (11) | IC chip only | ❌ NO (cuma IC chip + face selfie) |
| My Number (12) | IC chip only | ❌ NO |
| Residence Card Current (13) | IC chip only | ❌ NO |
| Residence Card Gen-2 (01036) | IC chip only (with new fields) | ❌ NO |
| Specified Residence (01038) | IC chip only | ❌ NO |
| Special Perm Resident (15) | IC chip only | ❌ NO |

- **Docs ref:** D1/D2 "Specification" — COMPLY_HE tidak拍 backside photo. Backside photo hanya untuk COMPLY_TO, COMPLY_CHI, dan COMPLY_Ho.
- **Docs ref:** D8 page "verifyIdChip" → tidak ada parameter backside image.
- **Action:** TIDAK perlu code tambahan untuk backside support di project ini.

---

# 📊 Ringkasan

| Item | Status | Complexity |
|------|--------|------------|
| COMPLY_HE method hardcode | ✅ Done | – |
| 3-doc UI filter | ✅ Done | – |
| Nationality dropdown flow | ✅ Done | – |
| Cascade fallback identity card | ✅ Done | – |
| ID doc type mapping basic 12 codes | ✅ Done | – |
| Logs (OCR-Parse, OCR-Mapping, IdentityCard) | ✅ Done | – |
| Telegram log uploader | ✅ Done | – |
| Gen-2 Residence codes (`01036-01039`) | ✅ Done | – |
| MyNumber variants (`01023/01035/01040`) | ❌ TODO | Low |
| Native mapping `LiquidDocumentType` (MY_NUMBER_CARD dll) | ✅ Done (17 Nov) | – |
| Gen-2 `RESIDENCE_DOCUMENT_GEN2` mapping + dropdown option | ✅ Done (17 Nov) | – |
| Env switch staging ↔ production | ✅ Done (17 Nov, kredensial prod masih kosong) | – |
| Chip data (`myNumber`, `card_type`, dokumen aktual) sampai ke Dart | ✅ Done (17 Nov) | – |
| Auto verification result (`faceScore` dll) sampai ke Dart | ✅ Done (17 Nov) | – |
| Deteksi mismatch dokumen (diminta vs dibaca) | ✅ Done (17 Nov) | – |
| HTTP logging aktif (request ke Liquid kelihatan) | ❌ TODO | Low |
| `operation_assignment_priority` per dokumen (fix TnC per doc type) | ❌ TODO | Medium (+ konfirmasi Liquid) |
| Special PR Cert code `15` | ❌ TODO | Trivial |
| Fields `cardType/residentStatusCode/...` di models | ❌ TODO | Medium |
| Nationality 3-digit mapping | ❌ TODO | Low |
| Stay period split year/month/day | ❌ TODO | Low |
| Update logs untuk field baru | ❌ TODO | Low |
| SDK version verification (Gen-2 support) | ✅ Done (17 Nov) | SDK 1.47.0 sudah support (Interface Spec v1.47.0 sheet `verifyIdChip.IN`) |

## Estimasi Effort

| Tugas | Lines |
|-------|-------|
| Update `liquid_mappings.dart` (tambah 8 codes + nationality 3-letter) | ~50 |
| Add fields ke `ICCardInfoResponse` + parser | ~25 |
| Add fields ke `OcrResultsBeResponse` + parser | ~25 |
| Update log strings di 2 file | ~10 |
| **Total** | **~110 lines** |

1-2 jam kerja kalau udah ada docs referensi ini.
