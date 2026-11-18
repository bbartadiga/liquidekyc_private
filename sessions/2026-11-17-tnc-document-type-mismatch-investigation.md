# 📝 Session — Investigasi TnC Salah Document Type (My Number → Residence Card)

**Tanggal:** 17 November 2026
**Project:** `module_liquid_ekyc` (POC Liquid eKYC Flutter App)
**Status:** ✅ Fix My Number + Gen-2 support sudah diimplementasikan — TnC per dokumen masih perlu konfirmasi Liquid

---

## 🎯 Scope Session Ini

Investigasi bug: saat user pilih **Jepang → My Number Card**, TnC yang dibuka SDK menampilkan **Terms of Use Residence Card**, bukan My Number. Sementara Indonesia → Residence Card dan Jepang → Driving License "benar".

Deliverable session ini: **root cause analysis + daftar gap di kode + implementasi fix My Number & Gen-2 Residence Card**.

---

## 📨 Update dari Tim Tokyo (17 November 2026)

Forward dari user Tokyo:

> 1. Driving lisense sudah as expected tanpa backside.
> 2. Residence card gen 2, di env. testing belum possible. Tapi, env. prod sudah bisa. mungkin bisa hit prod kali yaa.
> 3. my number, ada pertanyaan dari vendor. Is it possible that in the SDK's "verifyIdChip()" function, the "Identification Document Type" and "Identity Verification Method" are still set to "Residence Card/COMPLY_HE (HE Method)"? We would appreciate it if you could change the arguments to "National Identity Card/COMPLY_HE (HE Method)" and test the functionality.

### Jawaban per poin

| # | Poin | Jawaban |
|---|---|---|
| 1 | Driving License OK, tanpa backside | ✅ **Expected.** COMPLY_HE memang **tidak pernah** mengambil backside photo — cuma IC chip + face selfie. Lihat `docs/comply_he_implementation_audit.md` §10 (sudah didokumentasikan dari D1/D2). Tidak ada perubahan kode. |
| 2 | Gen-2 Residence Card: belum bisa di staging, prod bisa | ✅ **SDK 1.47.0 sudah support** (tidak perlu upgrade SDK). Yang belum ada di app = **mapping native `RESIDENCE_DOCUMENT_GEN2`** + **dropdown option** + **env switch ke production**. Sudah diimplementasikan. Credential production masih kosong — perlu dari Liquid CS. |
| 3 | My Number: apakah `verifyIdChip()` masih Residence Card/COMPLY_HE? | ✅ **YA, vendor benar.** `VerificationHandler.kt:77-81` cuma punya 2 case (`RESIDENCE_CARD`, `DRIVER_LICENSE`), sisanya jatuh ke `else -> RESIDENCE_CARD`. `"MY_NUMBER_CARD"` → **RESIDENCE_CARD**. **Sudah diperbaiki.** |

### Detail poin 3 — kenapa vendor bisa curiga

```
Dart (BENAR)     liquid_constants.dart:316-317   myNumberCard.value → "MY_NUMBER_CARD"
                 channel_verification_handler.dart:152-158  → kirim "MY_NUMBER_CARD" ✅
Kotlin (SALAH)  VerificationHandler.kt:77-81     when(...) { RESIDENCE_CARD, DRIVER_LICENSE, else -> RESIDENCE_CARD }
                                                    → "MY_NUMBER_CARD" TIDAK match → RESIDENCE_CARD ❌
                 VerificationHandler.kt:83        VerificationMethod.COMPLY_HE hardcode (argumen dari Dart diabaikan)
```

Efek di dalam SDK (verified dari binary `Liquid-1.47.0.aar`):

| Seharusnya | Terjadi sebelumnya |
|---|---|
| Upload chip → `/id_doc_photos/my_number_card_ic` | → `/id_doc_photos/residence_card_ic` |
| Flow input 個人番号 12 digit + 生年月日 (`ChipMyNumberInput12digitNumberView`) | Tidak pernah muncul, digantikan flow PIN Residence Card |

### Detail poin 2 — Gen-2 sudah didukung SDK 1.47.0

Interface Spec v1.47.0 (2026/5/14), sheet `verifyIdChip.IN` — enum `LiquidDocumentType` untuk `verifyIdChip()`:

> 運転免許証／マイナンバーカード／マイナンバーカード（＋個人番号）／マイナンバーカード（＋免許情報）／マイナンバーカード（＋公的個人認証）／在留カード／特別永住者証明書／**第2世代在留カード等**／**特定在留カード**／**特定特別永住者証明書**
>
> ※『第2世代在留カード等』を指定した場合、以下のカードのいずれかを読み取った結果を返却します
> ・在留カード ・特別永住者証明書 ・第2世代在留カード ・第2世代特別永住者証明書

**Implikasi untuk app:**
- `RESIDENCE_CARD` (在留カード) = **kartu generasi sekarang saja**
- `RESIDENCE_DOCUMENT_GEN2` (第2世代在留カード等) = **auto-detect 4 jenis** (在留/特別永住/第2在留/第2特別永住) → **ini yang harus dipakai buat test Gen-2**
- Error baru: `chip_unsupported_residence_card_type` (指定書類種別と実カード不一致) + field "在留カード／特別永住者証明書の種別" di response
- SE21111: 指定=第2世代在留カード等 tapi kartu=特定在留カード → error (dan sebaliknya)

Ref: `6. Application SDK/4. …Interface Specification v1.47.0.zip` → PDF sheet `verifyIdChip.IN` (p.31), `verifyIdChip.RES` (p.29), `Appendix(ProcessResults)` (p.80).
Ref tambahan: `17. 2nd Generation Residence Card_Specified Residence Card/1. …対応のご案内.pdf` (IC読取方式 正式版 2026年7〜8月頃; SDK update + auto判別).

---

## 🐛 Problem Report

Config screen (`kyc_config_screen.dart`) punya 2 dropdown:

| Dropdown | Opsi |
|---|---|
| Kewarganegaraan | Indonesia / Jepang |
| Tipe Dokumen | Indonesia → `residenceCard`<br>Jepang → `driverLicense`, `myNumberCard` |

Hasil pengujian TnC SDK:

| Percobaan | TnC yang muncul | Status |
|---|---|---|
| Indonesia → Residence Card | TnC Residence Card | ✅ |
| Japan → Driving License | TnC Driving License | ✅ |
| Japan → My Number | **TnC Residence Card** | ❌ |

---

## 🔍 Metode Investigasi

1. Baca seluruh docs di `/Users/admin/Documents/BNI/Digiremit/Liquid POC Docs` (spesifikasi SDK v1.45.0/v1.47.0, 017 SDKApply API, Manager Item Setup Sheet, Manager Product Spec, Product Spec SDK, Implementation Guide)
2. Baca `documents/SDK Function/` (017 SDKApply API PDF, Postman collection, log file)
3. **Decompile binary SDK** `android/app/libs/Liquid-1.47.0.aar` → `classes.jar` (javap + parser constant pool) untuk trace internal flow TnC
4. Trace kode app: Dart (viewmodel/repository/channel) + Kotlin (plugin/handler)
5. Probe network staging Liquid (gagal — endpoint SDK butuh AWS SigV4, `403 Missing Authentication Token`)

---

## ✅ Temuan Utama: TnC di SDK Itu Server-Side, Bukan Parameter Aplikasi

### Bukti

| Temuan | Sumber |
|---|---|
| `showTermsOfUse()` hanya menerima `TermsOfUseSettings` (6 warna saja). **Tidak ada field document type** | `6. Application SDK/…Interface Specification v1.47.0.pdf` p.12–14; EN v1.45.0 p.6 |
| 017 SDKApply API body: `applicant_id`, `operation_assignment_priority` (1–9), `redirect_url`, `error_redirect_url`, `preferred_language`. **Tidak ada `document_type`** — satu-satunya pemilih KYC setting (Manager) adalah `operation_assignment_priority` | `documents/SDK Function/[E]LIQUID_eKYC_017_SDKApplyAPI_v1.3.6 (1).pdf` p.2–3 |
| TnC diisi dari server: `GET /applicant_agreements`, header `X-Ekyc-Request-Token` → response `termsAndPrivacyURLs`, `termsOfServiceVersion`, `privacyPolicyVersion`, `agreementRequired`, `alreadyAgreed`. **Tidak ada doc type di request** | `Liquid-1.47.0.aar` → `repackage/z01` (path `/applicant_agreements`), `repackage/yz0` (parse `termsAndPrivacyURLs`) |
| Header request TnC: `X-Ekyc-Request-Token`, `X-Ekyc-Api-Version: 1.0.0`, `User-Agent`, `X-Ekyc-Current-Language` | `repackage/o40.a(String,String)` |
| String resources TnC cuma generic: `liquid_terms_agree_screen_title` = "Terms of service", `liquid_terms_agree_screen_text` = "Liquid, Inc. will provide the Personal Authentication Service on behalf of %1$s" | `Liquid-1.47.0.aar` → `res/values/values.xml`, `res/values-ja/values-ja.xml` |
| Manager setting dipisah per (KYC method × ID document), masing-masing punya `ID Document type code` sendiri (Residence Card = 13, Driver's license = 11, National identity card = 12, Special PR = 15, dst) | `8. Implementation Guide/English ver/02_LIQUIDeKYC_ManagerItemSetupSheet_v.4.10…xlsx` (sheet "Residence Card", "Driver's license", "National identity card", "Special Permanent Resident") |
| "Operation priority" = priority dari request item KYC Operation Priority; tiap operation dibedain per ID document | `3. Product Specification/English Version/4. eKYCManagerProductSpecifications_v6.9.pdf` p.15, p.17 |
| TnC function = layar yang disiapkan masing-masing client, isinya Privacy Policy lalu Terms of Use | `3. Product Specification/English Version/2. LIQUIDeKYCApplicant（SDKver.）ProductSpecificationsVer.1.8.6.pdf` p.11 (§2-2) |

### Rantai Deterministiknya

```
dropdown user
   └─(TIDAK ada parameter TnC di SDK)─┐
                                     ▼
operation_assignment_priority  ──►  session/operation di Liquid
   (hardcoded "1" di app)              └─► ID document type + 利用規約/プライバシーポリシー
                                             └─► GET /applicant_agreements (token)
                                                   └─► TnC yang tampil di SDK
```

**Kesimpulan:** TnC yang tampil mengikuti **session**, dan session ditentukan **saat request token** lewat `operation_assignment_priority`._dropdown di app **tidak punya jalur** ke TnC.

---

## 🔴 Root Cause Chain (2 Lapis)

### Layer 1 — Dart: pilihan dokumen tidak pernah dikirim ke Liquid

**File:** `lib/data/services/kyc_be_api.dart:100-113`

```dart
Future<KycTokenResponse?> applyForSdkToken({
  required String applicantId,
  int operationPriority = 1,          // ← default, tidak pernah di-override
}) async {
  body: jsonEncode({
    'applicant_id': applicantId,
    'operation_assignment_priority': operationPriority.toString(),   // ← selalu "1"
  }),
}
```

Call site yang **tidak pernah** override priority:
- `lib/persentation/views/screens/kyc_home_screen.dart:412`
- `lib/persentation/viewmodels/kyc_viewmodel.dart:219`
- `lib/data/services/kyc_be_api.dart:140` (`applyNewApplicant` — hardcoded `'1'`)

### Layer 2 — Kotlin: document type di-downgrade diam-diam

**File:** `android/app/src/main/kotlin/id/co/bni/mobile_remittance_kcln_tokyo/liquid_ekyc/VerificationHandler.kt`

```kotlin
// :32-36 (verifyIdDocument) dan :77-81 (verifyIdChip)
val documentType = when (documentTypeStr.uppercase()) {
    "RESIDENCE_CARD" -> LiquidDocumentType.RESIDENCE_CARD
    "DRIVER_LICENSE"  -> LiquidDocumentType.DRIVER_LICENSE
    else -> LiquidDocumentType.RESIDENCE_CARD   // ← MY_NUMBER_CARD jatuh ke sini
}
```

Efek di dalam SDK (verified via binary 1.47.0):
- Upload foto chip jadi `/id_doc_photos/residence_card_ic` (bukan `/id_doc_photos/my_number_card_ic`)
- Flow input My Number 12 digit + 生年月日 (`document/chip/he/ui/ChipMyNumberInput12digitNumberView`) **tidak pernah muncul** — digantikan flow PIN Residence Card

---

## 🧩 Gap Lain yang Ditemukan

| # | Lokasi | Masalah |
|---|---|---|
| 1 | `VerificationHandler.kt:83` | `VerifyIdChipParameters.Builder(documentType, VerificationMethod.COMPLY_HE)` — `verificationMethod` dari Dart **diabaikan** (hardcode COMPLY_HE) |
| 2 | `VerificationHandler.kt:37-41` | `verifyIdDocument` cuma map `COMPLY_HE`/`COMPLY_HO`, sisanya fallback |
| 3 | `liquid_constants.dart:275-310` | `LiquidDocumentType.fromString()` default → `driverLicense`, padahal `defaultType` = `residenceCard` (inkonsisten) |
| 4 | `kyc_viewmodel.dart:306-326` | `_updateDocumentTypeForMethod()` reset diam-diam ke `residenceCard`; aman sekarang hanya karena `setDocumentType()` dipanggil **setelah** `setVerificationMethod()` di `kyc_config_screen.dart:35-37` |
| 5 | `kyc_be_api.dart:157-206` | `registerApplicantInfo` tidak kirim `nationality`/`sex` ( padahal Postman & 016 API punya field itu) |
| 6 | `kyc_be_api.dart:205` | `registerKycRequestInformation()` (yang punya param `nationality`) **tidak pernah dipanggil** di flow mana pun |
| 7 | `liquid_constants.dart:23-24` | `applicantId` + `token` **hardcoded** (umur token 90 menit per 017 spec). `KycViewModel` constructor (`kyc_viewmodel.dart:34-40`) selalu set `_hasDynamicCredentials = true` dengan token basi |
| 8 | `kyc_home_screen.dart:384-404` | Jalur `BYPASS_BE=true` memakai credentials hardcoded → session lama → TnC lama |
| 9 | `app.dart:13-14` | `KycViewModel` = singleton → `_selectedDocumentType` ngikut antar-run; perlu reset di `reset()`/`cancel()` |

---

## 🎲 Analisis "Flip / Random" — Kenapa TIDAK Random

Priority di kode selamanya `"1"` → **session & TnC selalu sama**. Tidak bisa berubah sendiri.

### Tapi hasil 3 percobaan berbeda → ada yang berubah di sisi Liquid

Kalau priority benar-benar selalu "1", maka Residence Card / Driving License / My Number **wajib nampilin TnC yang sama persis**. Fact-nya beda → berarti:

- Kasus "Driving License benar" **tidak reproducible** dengan code sekarang → kemungkinan lo pernah mengubah priority / applicant ID / token di antara test, **atau**
- **Operation マイナンバーカード + COMPLY_HE belum terdaftar di Liquid Manager** → server fallback ke operation teratas/default (Residence Card). Gejalanya persis: My Number "tenggelam" ke Residence Card.

### Skenario paling mungkin

1. Operation My Number COMPLY_HE belum terdaftar di Manager → fallback ke operation Residence Card.
2. Priority untuk My Number belum di-set → masih "1".

### Yang bisa bikin flip nanti (setelah fix)

| Sumber | Mitigasi |
|---|---|
| Map priority per dokumen tidak lengkap + fallback diam-diam ke "1" | Map lengkap + **throw** kalau priority belum di-set (jangan fallback) |
| Token hardcoded / jalur `BYPASS_BE` | Matikan token hardcoded, reset state tiap run |
| Reuse applicant ID (017: application lama belum complete → bikin baru, token lama invalid) | Pakai applicant ID baru tiap test |
| ViewModel singleton | Reset `_selectedDocumentType` per run |

---

## 🐛 Bonus Temuan: HTTP Logging Mati (Dead Code)

**File:** `lib/data/services/kyc_be_api.dart:55-71`

```dart
static const bool _bypassSsl = true;   // ← const, selalu true

http.Client _createClient() {
  if (_bypassSsl) {
    return _AnnotatedClient(ioClient);   // ← yang selalu kepakai
  }
  if (kDebugMode) {
    return HttpLoggingClient();          // ← DEAD CODE, ga pernah kejalan
  }
  ...
}
```

`_AnnotatedClient.send()` (`kyc_be_api.dart:1508-1528`) **tidak** manggil `HttpLogger` sama sekali.

**Dampak:** semua request ke Liquid (termasuk 017 SDKApply) **nggak ke-log** → lo tidak bisa tahu `operation_assignment_priority` apa yang beneran terkirim, token mana yang dapat, dan response-nya apa. Ini alasan kenapa issue ini susah didiagnosis.

---

## ❓ Yang Harus Dikonfirmasi ke Liquid

1. `operation_assignment_priority` **berapa** untuk tiap kombinasi (ID document × KYC method) di Manager BNI:
   - 在留カード + COMPLY_HE = ?
   - 運転免許証 + COMPLY_HE = ?
   - マイナンバーカード + COMPLY_HE = ?
2. Apakah operation **マイナンバーカード + COMPLY_HE** sudah terdaftar di Liquid Manager, dan apakah sudah punya 利用規約 + プライバシーポリシー sendiri? Kalau belum → **gak ada perubahan kode yang bisa bikin TnC My Number muncul** (pure sisi Manager).
3. Apakah TnC memang berbeda per jenis dokumen, atau 1 TnC global per client? Kalau 1 TnC global → 3 dokumen harusnya sama semua, dan yang lo lihat itu bukan fitur SDK.

### Cara verifikasi tanpa app (Postman)

```
POST {liquidBase}/v1/sdk/applications
Headers: X-Ekyc-Api-key: <api key>
Body:    {"applicant_id":"<id baru>","operation_assignment_priority":"1|2|3"}
```
Bandingkan hasilnya. Kalau priority "3" ditolak / fallback ke "1" → operation My Number memang belum ada di Manager.

---

## 🛠️ Rencana Fix (UPDATE: item 1, 2, 6, 7, 8 sudah dikerjakan — lihat section Implementasi)

| # | File | Perubahan |
|---|------|-----------|
| 1 | `lib/data/services/kyc_be_api.dart` | `_AnnotatedClient.send()` → panggil `HttpLogger()._logRequest/_logResponse`; `_bypassSsl` jadi runtime flag bukan `const` |
| 2 | `lib/core/constant/liquid_constants.dart` | Tambah map `LiquidDocumentType → operationPriority` (nilai final menunggu jawaban Liquid) |
| 3 | `lib/persentation/viewmodels/kyc_viewmodel.dart` | `applyForSdkToken` terima & teruskan priority dari `_selectedDocumentType`; **fail loudly** kalau priority belum di-set |
| 4 | `lib/persentation/views/screens/kyc_home_screen.dart` | Kirim priority saat request token; hapus jalur hardcoded token |
| 5 | `lib/core/constant/liquid_constants.dart` | Kosongkan `applicantId`/`token` hardcoded → app wajib ambil token baru |
| 6 | `android/.../VerificationHandler.kt` | Mapping lengkap semua `LiquidDocumentType` (MY_NUMBER_CARD, MY_NUMBER_CARD_WITH_MY_NUMBER, MY_NUMBER_CARD_INTEGRATED_DRIVER_LICENSE, SPECIAL_PERMANENT_RESIDENT_CERTIFICATE, …); **hapus fallback diam-diam** ke RESIDENCE_CARD |
| 7 | `android/.../VerificationHandler.kt` | `verifyIdChip` pakai `verificationMethod` dari argumen; map lengkap `VerificationMethod` |
| 8 | `lib/core/constant/liquid_constants.dart` | `LiquidDocumentType.fromString()` default disamakan dengan `defaultType` |
| 9 | `lib/data/services/kyc_be_api.dart` | `registerApplicantInfo` kirim `nationality` + `sex`; panggil `registerKycRequestInformation` bila diwajibkan |
| 10 | `lib/persentation/viewmodels/kyc_viewmodel.dart` | Reset `_selectedDocumentType` di `reset()`/`cancel()` |

---

## 🛠️ Implementasi Yang Sudah Dikerjakan

### A. Fix My Number + mapping lengkap (jawaban untuk vendor)

**File:** `android/app/src/main/kotlin/id/co/bni/mobile_remittance_kcln_tokyo/liquid_ekyc/VerificationHandler.kt`

- Tambah 2 helper:
  - `toLiquidDocumentType(value): LiquidDocumentType?` — mapping **13** enum, **return `null` kalau tidak dikenal** (JANGAN fallback diam-diam ke RESIDENCE_CARD)
  - `toVerificationMethod(value): VerificationMethod` — mapping **11** enum (COMPLY_HE/HO/TO/CHI, READ/READ_FACE/READ_OFFLINE, FRONT/FRONT_FACE/FRONT_BACK/FRONT_BACK_FACE)
- `handleVerifyIdChip()` & `handleVerifyIdDocument()` sekarang:
  - baca `verificationMethod` dari argumen Dart (bukan hardcode COMPLY_HE)
  - error `INVALID_DOCUMENT_TYPE` kalau `documentType` ga dikenal (fail loudly, bukan diam-diam jadi Residence Card)
  - log tambahan: `-> LiquidDocumentType: X, VerificationMethod: Y`

### B. Gen-2 Residence Card support

**File:** `lib/core/constant/liquid_constants.dart`

- `LiquidDocumentType` nambah 3 enum: `residenceDocumentGen2`, `specifiedResidenceCard`, `specifiedSpecialPermanentResidentCertificate`
- `fromString` / `value` / `displayName`ovacak untuk 3 enum baru
- `Nationality.allowedDocuments` untuk Indonesia jadi `[residenceCard, residenceDocumentGen2]`
  → dropdown otomatis nampilin "Residence Card (Gen-2 / Auto-detect)"

**File:** `lib/persentation/viewmodels/kyc_viewmodel.dart`

- `_updateDocumentTypeForMethod()` allow-list nambah 3 enum Gen-2/Specified

### C. Env switch staging ↔ production

**File:** `lib/core/constant/liquid_constants.dart`

```dart
static const bool USE_PRODUCTION = false;   // ← flip ke true untuk test Gen-2
static String get url  => USE_PRODUCTION ? _prodUrl  : _stgUrl;
static String get apiKey => USE_PRODUCTION ? _prodApiKey : _stgApiKey;
static String get beUrl => USE_PRODUCTION ? _prodBeUrl : _stgBeUrl;
static String get connectorApiKey => USE_PRODUCTION ? _prodConnectorApiKey : _stgConnectorApiKey;
```

**File:** `lib/data/services/kyc_be_api.dart`

- `_beUrl` + `_apiKey` sekarang getter dari `LiquidConfig` (ikut env switch)
- `_stgApiKey` / `_stgConnectorApiKey` sama persis dengan sheet "18. APIKey and Credential for BNI"

**File:** `lib/app/app.dart`

- `LiquidEkycConfig.apiUrl` & `apiKey` `const` → `final` (nilai sudah bukan const karena pakai getter)

> ⚠️ **Credential production masih kosong** (`_prodApiKey`, `_prodBeUrl`, `_prodConnectorApiKey`).
> Sheet "18. APIKey and Credential for BNI" tab **本番環境** di repo docs masih **kosong** (template).
> Minta ke Liquid CS (cs@liquidinc.asia):
> - Connector URL prod (pola staging: `https://connector-bni.stg-liquid-ekyc.com` → prod: `https://connector-bni.liquid-ekyc.com`?)
> - Connector API key prod
> - SDK API key prod
>
> Catatan: app sekarang lewat proxy BNI `https://103.108.254.29:8066/inbound-liquid`, bukan langsung ke `connector-bni.*`. Kalau prod pake proxy juga, `_prodBeUrl` diisi IP/proxy prod.

### D. Kebersihan

**File:** `test/widget_test.dart`

- import `package:module_liquid_ekyc/...` → `package:module_liquid/...` (nama package di pubspec.yaml = `module_liquid`) — **build test sebelumnya broken**
- ekspektasi teks diupdate: `home:` sudah `KycConfigScreen` ('Pengaturan Verifikasi' / 'Pilih Dokumen'), bukan 'eKYC Verification'

### E. Kirim data chip + auto verification ke Dart (P1)

Temuan: **native bridge cuma kirim 4 key** (`resultStatus`, `errorCode`, `additionalDataTitle`, `additionalDataMessage`). Padahal Dart udah nunggu `liquidChipData` (`chip_result.dart:123-140`) dan `autoVerificationResult`. Akibatnya:

| Yang mati | Impact |
|---|---|
| `chipData` selalu null | `kyc_viewmodel.dart:567` applicantName selalu fallback ke BE / 'User' |
| `myNumber` (個人番号) | nggak pernah ada → user My Number nggak bisa cek |
| `residenceCardType` / `card_type` | nggak pernah ada → badge GEN-2 di tab SDK nggak pernah muncul |
| `liquidDocumentType` (dokumen aktual) | nggak pernah ada → bug mapping native nggak ketahuan |
| `autoVerificationResult` | selalu null → `_deriveDocumentStatus()` (`kyc_result_screen.dart`) selalu jatuh ke "chipResult.isSuccess" |
| `driversLicenseTypes` | SDK `Ocr` punya, UI sudah render (`_buildLicenseTypeRow`), tapi native nggak kirim → row "Tipe SIM" kosong |

**`android/.../VerificationHandler.kt`** — 3 helper baru:

- `buildChipDataMap(result)` → 22 field dari `LiquidChipData`: name, nameKana, birthday, sex, address(+pref/city/other), zipCode, idNumber, issueDate, expireDate, **myNumber**, **liquidDocumentType**, **residenceCardType** (kode numeric 1/2/5/6/7/8 — sama dengan Connector API), residenceCardInfoType, driversLicenseTypes/Conditions/AcquisitionDates, residenceCard(Comprehensive|Individual)Permission, hasIdFacePhoto, hasDocumentFrontImage
- `buildAutoVerificationMap(result)` → flatten 3 sub-object SDK jadi `result` (PASS/FAIL/NOT_APPLICABLE) + `faceResult`/`faceScore`/`photoResult`/`photoScore`/`passiveResult` + `message`
- `isActualDocumentTypeCompatible(requested, actual)` → aturan payung `RESIDENCE_DOCUMENT_GEN2` (menerima 在留/特別永住/第2在留/第2特別永住)

**`android/.../SdkManager.kt`** — callback `verifyIdChip` sekarang kirim `liquidChipData` + `autoVerificationResult` + `liquidDocumentType` + `documentTypeMismatch`, dan log `MISMATCH VerifyIdChip: requested=... actual=...`.

**`android/.../FinalizeHandler.kt`** — OCR map += `driversLicenseTypes`.

### F. Result screen + log (P2, P3)

**`lib/data/models/chip_result.dart`**

- `LiquidChipDataModel` += `liquidDocumentType`, `residenceCardInfoType`, `driversLicenseTypes/Conditions/AcquisitionDates`, `residenceCard(Comprehensive|Individual)Permission`
- `LiquidChipDataModel.displayMyNumber` → masked 4 digit terakhir
- `AutoVerificationResult` += `faceResult`, `faceScore`, `photoResult`, `photoScore`, `passiveResult`
- `ChipVerificationResult` += `documentTypeMismatch`
- `_parseChipData` sekarang log `[ChipParse]` lengkap (doc, card_type, my_number masked)

**`lib/persentation/viewmodels/kyc_viewmodel.dart`**

- `actualDocumentType` / `actualDocumentTypeValue` / `isDocumentTypeMismatch`
- `_checkDocumentTypeMatch()` → log `[Mismatch]` (ERROR kalau beda)

**`lib/persentation/views/screens/kyc_result_screen.dart`**

- Identity card tab SDK: `cardType` sekarang dari **chip data** (bukan OCR — SDK `Ocr` memang nggak punya card_type)
- Badge **DOC MISMATCH** + baris detail "Kartu dibaca: X — bukan Y" kalau tidak cocok
- Section OCR SDK: baris **No. My Number** (masked) + **Card Type** (dari chip)
- Section OCR BE: baris **No. My Number** (masked), `OcrResultsBeResponse` += field `myNumber` (`my_number`)

**`lib/core/services/channel_verification_handler.dart`**

- log chip data lengkap: `liquidDocumentType`, `residenceCardType`, `myNumber` (masked), `hasIdFacePhoto`, `driversLicenseTypes`
- **address di-mask manual** (sebelumnya terkirim mentah ke log Telegram)
- log `documentTypeMismatch`

**`lib/core/constant/liquid_constants.dart`**

- `LiquidDocumentType.fromString()` default: `driverLicense` → `defaultType` (residenceCard)
- `LiquidDocumentType.isCompatibleWith(actual)` — aturan payung Gen-2 (versi Dart, sama dengan versi Kotlin)

### G. HTTP logging aktif (P4)

**Temuan:** `_bypassSsl` = `static const bool = true` → `_createClient()` **selalu** balik `_AnnotatedClient`, cabang `if (kDebugMode) return HttpLoggingClient()` = **dead code**. Akibatnya `HttpLogger` nggak pernah kepakai → **semua request ke Liquid (termasuk 017 SDKApply) invisible**.

**`lib/core/services/http_logger.dart`**

- `_logRequest`/`_logResponse` → public `logRequest`/`logResponse` (dibutuhkan dari file lain)
- `logRequest(..., {String? body})` → log method + URL + headers (**header sensitif dimask: `X-Ekyc-Api-key`, `x-api-key`, `authorization`**) + **request body**
- `logResponse(...)` → preview body disimpan di `HttpLogEntry` untuk **semua** response (dulu cuma error); ke Telegram body tetap cuma dikirim untuk error biar ga spam
- `maxCapturedBytes = 64KB` → batas capture body

**`lib/data/services/kyc_be_api.dart`**

- `_AnnotatedClient.send()` sekarang log ke `HttpLogger` (jalan di **release mode** juga, bukan cuma debug)
- Response body di-capture via `StreamTransformer` yang **nge-tee** (nangkap ≤64KB pertama, stream tetap jalan penuh) → body foto yang gede nggak dibikin OOM
- `_createClient()` dirapihin:_+`badCertificateCallback` tetap on (proxy BNI self-signed), cabang dead code dihapus

**Verifikasi fungsional** (script standalone, pattern sama persis dengan `_AnnotatedClient`):

```
[HTTP] POST https://103.108.254.29:8066/inbound-liquid/v1/sdk/applications
[HTTP Headers] {"Content-Type":"application/json","X-Ekyc-Api-key":"..."}
[HTTP Request Body] {"applicant_id":"111902224425","operation_assignment_priority":"1"}
[HTTP Response] 201 (1010ms) - https://103.108.254.29:8066/inbound-liquid/v1/sdk/applications
[HTTP Body] {"token":"68b2f8376fb3de77d7c8014d3219bead259b8735c32f3cf569b54ae8aa74d172"}
STATUS=201
```

→ `operation_assignment_priority` **kelihatan** di log, dan `token`/`applicant_id` tetap ke-mask di Telegram (`token` via sensitive-key, `applicant_id` via rule digit ≥12).

### H. Refactor file besar (P6)

`kyc_be_api.dart` = **1611 baris** (API client + 12 response model + HTTP client dalam satu file). Dipecah:

**`lib/data/models/` (8 file baru, response model):**

| File | Isi |
|---|---|
| `token_response.dart` | `KycOrchestrationResponse`, `KycTokenResponse` |
| `applicant_info_response.dart` | `ApplicantInfoResponse`, `RegisterApplicationInfoResponse` |
| `ic_card_info_response.dart` | `ICCardInfoResponse` (+ import `JapaneseRomajiHelper`) |
| `verification_results_response.dart` | `VerificationResultsResponse` |
| `ocr_results_response.dart` | `OcrResultsBeResponse` (+ import `appLogger`) |
| `photos_response.dart` | `PhotosResponse`, `IdDocumentPhoto` |
| `liveness_images_response.dart` | `LivenessImagesResponse`, `LivenessImage` |
| `kyc_request_information_response.dart` | `KycRequestInformationResponse` |

**`lib/data/services/liquid_http_client.dart`** — `_AnnotatedClient` (private, di dalam file API) → `LiquidHttpClient` (public, file sendiri). Badge self-signed + HTTP logging + capture body ≤64KB.

**`lib/data/services/kyc_be_api.dart`** — sekarang cuma `KycBeApi` (endpoint methods) + `ProgressCallback` typedef → **1611 → 828 baris**.

**`lib/data/models/chip_result.dart`** (724 baris) ikut dipecah:

| File | Isi |
|---|---|
| `chip_data.dart` | `Sex`, `LiquidChipDataModel` |
| `chip_verification.dart` | status enums, `ChipVerificationResult`, `ChipIdentificationResult`, `MynaIdentificationResult`, `AutoVerificationResult`, `DocumentImage`, extension debug |
| `ocr_result.dart` | `OcrResult` + extension `OcrResultMapping` |
| `chip_result.dart` | **barrel** — `export` 3 file di atas, jadi semua import lama (`kyc_repository.dart`, `face_results.dart`, `document_result.dart`, `kyc_viewmodel.dart`, `kyc_result_screen.dart`, `module_liquid.dart`) tetap jalan tanpa diubah |

Import yang dibuang: `liquid_mappings.dart` sekarang import `data/models/ocr_results_response.dart` (bukan `data/services/kyc_be_api.dart`).

### I. Refactor `kyc_result_screen.dart` + `liquid_constants.dart` (P7)

**`kyc_result_screen.dart` (1921 → 654 baris)**

| File | Isi | Baris |
|---|---|---|
| `views/widgets/kyc_result_widgets.dart` | shared builders jadi top-level function: `buildSection`, `buildSectionHeader`, `buildDetailRow`, `buildDetailPlaceholder`, `buildDetailWithRomaji`, `renderRomajiPair`, `buildAddressSplitRowsWithRomajiAndAsync`, `buildAddressSplitRowsAsync`, `joinAddressFuture`, `buildChangeDetectionRows`, `formatChangeFlag`, `buildLicenseTypeRow`, `buildSourceTag`, `buildIdentityField`, `buildStatusItem`, `buildApiStatusRow`, `formatDate`, `formatSex`, `maskMyNumber` | 526 |
| `views/widgets/kyc_result_identity_sections.dart` | `KycIdentityCard`, `KycStatusSummary`, `KycOcrSdkSection`, `KycOcrBeSection`, `KycGen2CardSection` — semua StatelessWidget dengan param eksplisit | 545 |
| `views/widgets/kyc_result_verification_sections.dart` | `KycChipSection`, `KycFaceSection`, `KycDocumentSection`, `KycPhotosSection`, `KycLivenessSection`, `KycBeApiStatusSection` | 284 |
| `views/screens/kyc_result_screen.dart` | screen utama: header, toggle SDK/BE, queue indicator, `_deriveDocumentStatus()`, actions | 654 |
| `views/screens/kyc_result_wrapper_screens.dart` | `KycSuccessScreen`, `KycErrorScreen` (wrapper tipis, sebelumnya inline) | 110 |

Perubahan struktur:
- Semua section jadi **StatelessWidget dengan param eksplisit** → tidak ada lagi akses `widget.*` atau `context.read<KycViewModel>()` di dalam section
- Field widget (`ocr`, `ic`) di-copy ke local variable dulu → null-promotion Dart tetap jalan
- 2 helper dead code dibuang: `_buildAddressSplitRows`, `_buildAddressSplitRowsWithRomaji` (tidak pernah dipanggil)

**`liquid_constants.dart` (911 → 5 baris barrel)**

| File | Isi | Baris |
|---|---|---|
| `core/constant/liquid_config.dart` | `LiquidConfig` (mode config + env switch staging/production). **Menggantikan file lama yang isinya duplikat `LiquidConfig` + `LiquidCredentials` dead code** | 71 |
| `core/constant/liquid_processing_status.dart` | `LiquidProcessingResultStatus`, `KycStep` | 94 |
| `core/constant/liquid_document_type.dart` | `Nationality`, `LiquidDocumentType` | 189 |
| `core/constant/liquid_verification.dart` | `VerificationMethod`, `FaceVerificationType`, `DisplayLanguage` | 293 |
| `core/constant/liquid_error_codes.dart` | `LiquidErrorCode` (SDK + BE error codes) | 268 |
| `core/constant/liquid_constants.dart` | **barrel** — `export` 5 file di atas, semua import lama tetap jalan | 5 |

### J. Refactor viewmodel + home screen, bersihin dead code (P8)

**`kyc_viewmodel.dart` (873 → 711 baris)** — 3 service baru di `lib/data/services/`:

| File | Isi |
|---|---|
| `kyc_credentials_service.dart` | `KycCredentials` (result) + `KycCredentialsService.fetch()` / `.createNewApplicant()` — ambil token dari 017 SDKApply + register applicant info |
| `kyc_be_data_service.dart` | `KycBeDataBundle` + `KycBeDataService` — `registerApplicationInfo()`, `fetchVerificationResults()`, `fetchPostActivationData()` (OCR + liveness + photos + IC card info), `registerKycResult()` |
| `kyc_verification_runner.dart` | `KycVerificationOutcome` + `KycVerificationRunner.run()` — rangkaian IC chip → document → face sesuai `verificationOrder`, plus OCR quick-preview |

Viewmodel sekarang cuma orchestrator: pick config → init SDK → TnC → `KycVerificationRunner` → BE-1..BE-6 via service → activate.

**`kyc_home_screen.dart` (835 → 616 baris)** — `_BeLoadingDialog` (private, 219 baris) → `lib/persentation/views/widgets/kyc_be_loading_dialog.dart` (public `KycBeLoadingDialog`). Field `_currentIndex` yang ga kepakai dibuang.

**Dead code dibersih:**
- `lib/core/widgets/debug_http_overlay.dart` **dihapus** — `DebugHttpOverlay` widget ga dipakai di mana pun, `HttpLoggingClient` + `getHttpClient()` cuma nyambung ke `LoggingClient` di `http_logger.dart`
- `LoggingClient` di `http_logger.dart` ikut dihapus (setelah `HttpLoggingClient` hilang, ga ada yang pakai) → `package:http` import di file itu juga dibuang

**Angka akhir:** `lib/` total 12.684 baris (dari 12.791), file terbesar sekarang 828 (`kyc_be_api.dart`).

### K. Bersihin 54 warning analyzer (P9)

Semua `warning` + `info` dibersihin → `flutter analyze` **No issues found**.

| # | Perbaikan | File |
|---|---|---|
| 1 | `await` pada `bool` — `JpTransliterate.isKanji()` itu sync, bukan Future. **Bug nyata** | `core/services/japanese_romaji_helper.dart:58` |
| 2 | `result ?? 'null'` di branch yang dijamin non-null | `core/services/japanese_romaji_helper.dart:62` |
| 3 | 6 unused import (`channel_init_handler`, `liquid_ekyc_channel`, `kyc_result_wrapper_screens` ×3, `kyc_home_screen`) | – |
| 4 | `_lastSeenIndex` field mati + assignment-nya | `core/services/telegram_log_uploader.dart` |
| 5 | `_minIntervalMs` / `_maxBatchSize` → `final` | `core/services/telegram_log_uploader.dart` |
| 6 | 5 getter+setter pembungkus field → jadi public field langsung (`beICCardInfo`, `beVerificationResults`, `beOcrResults`, `bePhotos`, `beLivenessImages`) | `persentation/viewmodels/kyc_viewmodel.dart` |
| 7 | `BuildContext` lintas async gap — `ScaffoldMessenger` di-capture sebelum await, guard `context.mounted` | `persentation/views/screens/kyc_home_screen.dart` |
| 8 | Duplikat cek `applicantId.isEmpty` dibuang | `persentation/views/screens/kyc_home_screen.dart` |
| 9 | `DEBUG_MODE`/`BYPASS_BE`/`USE_PRODUCTION` → `debugMode`/`bypassBe`/`useProduction` (konvensi Dart). Kotlin tetap uppercase | `core/constant/liquid_config.dart` |
| 10 | `if (x != null) 'k': x` → `'k': ?x` (null-aware element, Dart 3.8+) — 14 tempat | `data/services/kyc_be_api.dart` |
| 11 | `super.key` di constructor public widget | `persentation/views/widgets/kyc_be_loading_dialog.dart` |
| 12 | `const` constructor | `persentation/views/screens/kyc_home_screen.dart` |
| 13 | Doc comment pakai backtick (avoid HTML interpretation) | `japanese_romaji_helper.dart`, `kyc_result_widgets.dart` |
| 14 | `library module_liquid;` yang ga perlu | `module_liquid.dart` |
| 15 | `[..._logs.reversed.toList()]` → `[..._logs.reversed]` | `core/services/app_logger.dart` |
| 16 | `return '${request.endpoint}'` → `return request.endpoint` | `data/services/kyc_queue_worker.dart` |

Verifikasi semantik null-aware element (Dart 3.10):
```
{'k1': ?null, 'k2': ?'x'}  →  {k2: x}
```
→ entry dihilang kalau value null, sama persis dengan `if (x != null)` versi lama.

### L. Pecah `kyc_be_api.dart` jadi facade + domain API (P10)

`kyc_be_api.dart` tadinya 828 baris dengan **7 salinan pola retry** yang
hampir identik (~450 baris duplikasi). Dipecah jadi:

```
lib/data/services/
  kyc_be_api.dart              → facade (207 baris, 12 method publik, API sama)
  be/
    be_api_config.dart         → konstanta endpoint + beBaseUrl (top-level)
    be_api_base.dart           → abstract base: host, header auth, retry, enqueue (242 baris)
    kyc_be_token_api.dart      → applyForSdkToken, applyNewApplicant
    kyc_be_applicant_api.dart  → registerApplicantInfo, registerKycRequestInformation, registerApplicationInfo
    kyc_be_data_api.dart       → getICCardInfo, getVerificationResults, getOcrResultsFromBe, getPhotos, getLivenessImages
    kyc_be_result_api.dart     → registerKycResult, processKycOrchestration
```

Helper generic di base:
- `getWithRetry<T>` — GET + backoff eksponensial + jitter, enqueue kalau gagal total
- `postWithRetry<T>` — POST + backoff, body response boleh di-parse (buat `registerKycResult` yang body-nya kosong)

API publik `KycBeApi` **tidak berubah** (12 method, signature sama). `onProgress`
tetap settable di facade → diteruskan ke 4 domain API.

Konstanta dipindah ke top-level (`be_api_config.dart`) karena static member
supertype harus di- qualify (`unqualified_reference_to_non_local_static_member`).

#### Normalisasi perilaku (semantik, tidak merusak)

| # | Asli | Sekarang | Alasan |
|---|---|---|---|
| 1 | `getICCardInfo` panggil `onProgress(false)` **sebelum** cek retry | setelah retry exhausted | label loading flickering di UI |
| 2 | `registerApplicationInfo` catch branch enqueue **tanpa body** | dengan body | queue butuh body buat replay POST |
| 3 | `registerKycResult` enqueue timing beda (before/after progress) | seragam | konsistensi |
| 4 | 4 dari 5 GET log `ERROR: status - body`, 1 tidak | semua log | konsisten |

`registerApplicantInfo` **sengaja** dibiarkan sama (retry error HTTP? tidak,
cuma retry exception + delay tetap 1 detik) karena itu dipanggil dari
`kyc_credentials_service` saat setup credential — retry 4x di error HTTP bikin
user nunggu ~7 detik.

### M. Fix bug retry queue worker (P11) — **fitur ini sebelumnya 100% gagal**

Ditemukan pas baca `kyc_queue_worker.dart` pas refactor di atas. Semua request
yang masuk retry queue **pasti gagal** di-retry:

| # | Bug | Impact | Fix |
|---|---|---|---|
| 1 | `_buildUrl` return `request.endpoint` → `/v1/applicants/APP-1/photos` (path relatif, tanpa scheme) | `Uri.parse` → no scheme → `http.Client.get()` throw. **Semua retry gagal.** | prefix `$beBaseUrl` |
| 2 | `_encodeBody` form-urlencoded (`k=v&k=v`) | BE expect JSON → 400 | `jsonEncode` |
| 3 | Header `X-Ekyc-Api-key` tidak dikirim | 401 | tambah header auth |
| 4 | Pakai `http.Client()` biasa | Gagal TLS ke proxy BNI (sertifikat self-signed) | `LiquidHttpClient()` |
| 5 | Timeout 30s (API normal 60s) | timeout prematur | samain 60s |

Verifikasi bug #1 (sebelum fix):
```
Uri.parse('/v1/applicants/APP-1/photos').hasScheme → false
http.Client().get(uri) → throw (No scheme specified)
```

`KycQueueWorker.initialize()` sekarang menerima `http.Client?` biar bisa di-inject
di test.

### N. Tambah unit test

Repo sebelumnya cuma punya smoke test. Sekarang ada contract test:

| File | Isi |
|---|---|
| `test/kyc_be_api_test.dart` | 8 test — ngunci shape request (method, URL, header, body) untuk 6 endpoint + error handling |
| `test/kyc_queue_worker_test.dart` | 3 test — retry GET (URL absolut + header), retry POST (body JSON), retry gagal (tetap di queue, retryCount naik) |

Total test: 1 → 12.

### O. Handle error My Number Card + koreksi mapping error code (P12)

Dimulai dari screenshot Tokyo: SDK nampilin dialog native
**"Identification unsuccessful / You have 9 attempts left until the card is locked"**
setelah layar "Please tap the card".

#### Reverse-engineer SDK 1.47.0 (`android/app/libs/Liquid-1.47.0.aar`)

Dialog itu **cuma** bisa dibedain dari string SDK:

| Resource SDK | Isi |
|---|---|
| `liquid_restart_chip_pin_mismatch_my_number_title` | "Identification unsuccessful" |
| `liquid_restart_chip_pin_mismatch_my_number_message` | "You have %1$s attempts left until the card is locked\nIf it is locked, it must be unlocked by visiting your registered municipal office" |

→ Cocok persis → enum SDK `CHIP_PIN_ERROR_MY_NUMBER_LOCKED` → status
`IC_CHIP_PIN_FAILURE` → **errorCode = SE20005**.

Artinya: **PIN/kredensial yang dimasukkan nggak cocok sama kartu**, bukan
sekadar "kartu gagal kebaca".

Mapping status → `SExxxxx` diambil dari bytecode `ResultHandler` (javap):

```
SE20001 IC_CHIP_LOCKED          SE21011 IC_CHIP_UNUSUAL_UPDATED
SE20005 IC_CHIP_PIN_FAILURE     SE21101/2/3 IC_CHIP_SPECIAL_RESIDENCE
SE20011 IC_CHIP_PIN_INVALID*    SE21201/2/3 IC_CHIP_VERIFICATION_FAILURE
SE20015 IC_CHIP_PIN_INVALID     SE21205 IC_CHIP_EXPIRED
SE21001 IC_CHIP_SPECIAL          SE22001 IC_CHIP_NOT_AVAILABLE
                                 SE22051/52 IC_CHIP_READ_ERROR
                                 SE23001 IC_CHIP_NO_EXTERNAL_CHARACTERS
SE27001 MYNUMBERCARD_..._HISTORY SE27101/2/3 ..._DRIVER_LICENSE_VERIFY_FAILURE
SE27205 ..._DRIVER_LICENSE_EXPIRED   SE80001 USER_CANCEL
```

**Koreksi penting di enum kita** (sebelumnya salah):

| Enum lama | Semula | Seharusnya |
|---|---|---|
| `icChipReadError` | `SE21001` | `SE22051` (+alias SE22052) — SE21001 itu `IC_CHIP_SPECIAL` |
| `movingCard` | `SE22051` | dihapus → gabung ke `icChipReadError` |
| `incorrectPin` | `SE20015` | ✓ benar, tapi belum ditandai "bisa kunci kartu" |
| — | — | baru: `icChipSpecial` (SE21001), `icChipSpecialResidence` (SE21102), `icChipVerificationFailure` (SE21201), `unsupportedDeviceNfc` (SE99998), `mynaIntegratedDriverLicenseVerifyFailure` (SE27101) |

Ditambah dukungan `aliases` (SDK punya beberapa kode untuk satu status yang sama).

#### Fix 1 — peringatan risiko kunci kartu

`LiquidChipErrorData` di SDK punya `attemptsRemainingUntilChipLocked` +
`liquidChipErrorCredentialType`, tapi **nggak diekspos** lewat
`LiquidChipVerificationResult`. Jadi kita ambil langsung dari
`data.liquidChipData?.liquidChipErrorData` di native, terus lempar ke Dart
sebagai `chipErrorData`.

Rantai: `SdkManager.kt` → payload `chipErrorData` → `ChipVerificationResult`
(parse `attemptsRemainingUntilChipLocked`) → `userFriendlyMessage` nambah
peringatan:

> Penting: kartu ini punya batas percobaan. Sisa percobaan: 9 kali. Kalau habis,
> kartu terkunci dan hanya bisa dibuka di kantor kecamatan.

Error yang bisa kunci kartu (`SE20001`, `SE20005`, `SE20011`, `SE20015`) →
`LiquidErrorCode.canLockCard == true` → `KycVerificationOutcome.cardLockRisk` →
UI nampilin **AlertDialog** (bukan SnackBar yang keburu hilang 4 detik).

#### Fix 2 — judul error dari SDK jangan ditimpa

`additionalDataTitle` hardcode ("IC Card Scan Failed") diganti jadi
`_titleOrFallback(errorTitle, fallback)` → kalau SDK kirim "Identification
unsuccessful", itu yang dipakai. Berlaku untuk verifyIdChip / verifyIdDocument /
verifyFace.

#### Fix 3 — mapping error code (lihat tabel di atas)

#### Bonus — log native sekarang masuk file export

Ternyata `SdkManager.log()` cuma tulis ke Logcat, **nggak** nyampe ke app log →
user nggak bisa dapat diagnosa SDK dari file export. Sekarang:
`SdkManager.attachLogChannel()` → `invokeMethod("nativeLog", …)` → Dart
`LiquidEkycChannel._handleNativeCall` → `appLogger.d(tag: 'Native')`.

Tag `Native` disaring di `TelegramLogUploader` (kecuali level ERROR) biar log
SDK yang banyak nggak menimpa log aplikasi di Telegram.

Log tambahan (biar run berikutnya cukup tanpa perlu logcat):
```
[STEP 11] ERROR detail | code:SE20005 | title:Identification unsuccessful | msg:… | attemptsLeft:9 | credential:VERIFICATION_CODE_A
```

#### Test

`test/liquid_error_codes_test.dart` — 11 test: mapping kode, alias, deteksi
kunci kartu, parsing `chipErrorData`, isi pesan.

#### Guard config production

`useProduction = true` sementara `_prodBeUrl` masih `''` → `baseUrl` jadi
`/inbound-liquid` → `Uri.parse` nggak punya scheme → semua request gagal
dengan "No scheme specified" (bug yang sama kayak retry queue worker).

Ditambah `LiquidConfig.hasProductionConfig` + `effectiveUseProduction`:
kalau credentials production belum diisi, otomatis fallback ke staging +
log error di `main.dart`:

```
Config | env:STAGING | sdkUrl:https://applicantsdk-api.stg-liquid-ekyc.com | beUrl:https://103.108.254.29:8066
```

Sekalian dibenerin label `Mode: PRODUCTION` yang hardcode di
`kyc_repository.dart` — dulu nulis PRODUCTION walau URL-nya staging.

### P. Lengkapi mapper `LiquidChipData` (P13)

SDK 1.47.0 expose **46 getter** di `LiquidChipData`, tapi `buildChipDataMap`
(Kotlin) cuma kebaca ~23 field. Sisanya dibuang → data hilang permanen di
sisi app.

#### Yang ditambah

| Group | Field |
|---|---|
| Nama | `nameHalfWidthKana`, `lastNameKanaCandidates`, `lastNameHalfWidthKanaCandidates`, `firstNameKanaCandidates`, `firstNameHalfWidthKanaCandidates`, `previousName`, `previousLastNameKanaCandidates`, `previousLastNameHalfWidthKanaCandidates`, `aliasName` |
| Alamat | `addressModificationHistories` (list alamat sebelumnya) |
| Status tinggal | `movedAbroad`, `plannedAbroadMoveDate`, `japaneseForeignerJudgment`, `pscName`, `pscNames` |
| Gen-2 | `residenceDocumentGen2Data` → 15 field (izin individual/menyeluruh, info type, masa tinggal, jenis izin, status tinggal, batasan pekerjaan, dsb) |
| My Number + SIM | `myNumberCardIntegratedDriverLicenseData` → colorCategory, types, conditions, remarks, acquisitionDates, recordNumber, validUntil |
| Gambar | `hasAddressImage` |

Bitmap tetap nggak dikirim (terlalu besar) — cukup penanda keberadaan.

⚠️ **Temuan penting**: untuk Gen-2, field izin tinggal **level atas kosong**
(`residenceCardIndividualPermission` = null). Semuanya ada di dalam
`residenceDocumentGen2Data`. Makanya `LiquidChipDataModel` punya getter
`displayIndividualPermission` / `displayComprehensivePermission` yang fallback
ke level atas buat kartu non Gen-2.

#### Model Dart baru

- `MyNumberCardIntegratedDriverLicense` (chip_data.dart)
- `ResidenceDocumentGen2` (chip_data.dart) + getter `stayPeriod` ("5 / 3 / 10")

#### `Sex` tambahan

SDK punya `MALE / FEMALE / OTHERS`. `Sex.fromString()` cuma handle `MALE/FEMALE`
sebelumnya → **`OTHERS` jatuh ke `unknown`**. Ditambah `Sex.others`.

#### UI

Result screen → Identity Card sekarang nampilin blok **"Izin Tinggal (Gen-2)"**
(13 baris) kalau chip-nya Gen-2 — data yang sebelumnya hilang total.

#### Test

`test/chip_data_test.dart` — 14 test: parsing field inti, field baru, Gen-2,
SIM terintegrasi, `Sex.OTHERS`, fallback izin non-Gen-2, `displayMyNumber`
sudah disensor.

### Q. Lindungi kartu user dari lock (P14)

Dari screenshot Tokyo: SDK nampilin "Identification unsuccessful / 9 attempts
left until the card is locked".

#### Kenapa di dev kok kayak prod

**Pembacaan chip + validasi kredensial itu 100% on-device** (JPKI public key).
Server staging cuma issuance token/applicant & terima hasil. **Counter
percobaannya ada di IC chip kartunya** — jadi efeknya ke kartu fisik Tokyo
identik dengan production. Staging nggak melindungi kartu sama sekali.

Akar masalahnya: SDK nge-compare input user (tanggal lahir, tanggal berlaku,
kode keamanan) dengan hasil baca kartu. Kode keamanan 4 digit kecil di pojok
kartu → rawan salah ketik / salah OCR → mismatch → counter turun.

#### 3 lapis proteksi

**1. Dialog pre-flight (app kita, sebelum kartu disentuh)**
`kyc_home_screen._showChipCredentialWarning()` → user diberi tahu persis data
apa yang diminta SDK + risikonya, sebelum SDK mulai. Berlaku untuk
MY_NUMBER_CARD & DRIVER_LICENSE.

**2. Counter percobaan di perangkat (`ChipAttemptGuard`)**
- Error yang bisa mengunci kartu (`SE20001/20005/20011/20015`) → counter naik
- Counter disimpan di SharedPreferences → **restart app nggak bisa reset**
- Setelah 3x gagal → app **nggak lagi memanggil SDK** untuk baca chip,
  tampilkan pesan "proses dihentikan demi keamanan kartu"
- Cancel user / error jaringan **nggak** dihitung (nggak memotong jatah kartu)
- Baca chip sukses → counter reset

**3. Error message (sudah di section O)**
Tampilin sisa percobaan (`attemptsRemainingUntilChipLocked`) + peringatan
kunci kartu, dalam bentuk **AlertDialog** (bukan SnackBar).

Plus: log native SDK sekarang ikut masuk file export (section O) → kalau
Tokyo dapet warning lagi, tinggal kirim 1 file.

#### Test

`test/chip_attempt_guard_test.dart` — 6 test: counter naik, bertahan setelah
restart app, blokir setelah max attempts, pesan, reset.

### R. Koreksi: `setExcludeMyNumber` BUKAN alat proteksi kartu (P15)

Awalnya gue sempat merekomendasikan `setExcludeMyNumber(true)` sebagai cara
nghilangin prompt credential. **Itu salah**, dan sudah gue verifikasi di
bytecode SDK.

Flag-nya dikirim ke `ChipVerificationActivity` lewat Intent extra
`EXCLUDE_MY_NUMBER`, lalu dibaca di **tepat 3 kelas** — semuanya di fase
**assembling hasil**:

```java
// kl0 / pl0 / tl0
String myNumber = (arg instanceof p9) ? ((p9) arg).l : null;
if (params.ib.f) {          // ib.f = excludeMyNumber
    myNumber = null;         // ← 個人番号 dibuang dari hasil
}
result.vh.z = myNumber;
```

Jadi `excludeMyNumber`:

| | |
|---|---|
| ❌ | nggak lewatin baca NFC |
| ❌ | nggak lewatin prompt credential |
| ❌ | nggak influence counter percobaan kartu |
| ✅ | **cuma meng-null-kan 個人番号 dari hasil akhir** |

Gunanya sebenarnya: privacy/rekonsiliasi — buang 個人番号 dari device kalau
tidak dibutuhkan. **Bukan** proteksi kartu.

#### Solusi yang bener: jangan baca chip saat dev

`VerificationMethod.requiresIcCard`:

| Method | Baca chip? | Risiko lock kartu |
|---|---|---|
| `COMPLY_HE` | ✅ chip + face | **ADA** ← yang Tokyo pakai |
| `READ`, `READ_FACE`, `READ_OFFLINE` | ✅ | **ADA** |
| `FRONT` | ❌ (dokumen saja) | **nggak ada** |
| `COMPLY_TO`, `COMPLY_CHI`, `COMPLY_HO` | ❌ | **nggak ada** |
| `FRONT_FACE`, `FRONT_BACK`, `FRONT_BACK_FACE` | ❌ | **nggak ada** |

`verificationOrder` sudah ngikutin `requiresIcCard` → kalau method-nya FRONT,
langkah icCard **dilewati total** → nggak ada NFC, nggak ada credential
prompt, nggak ada counter.

Masalahnya: method tadinya **hardcode** `COMPLY_HE` di
`kyc_config_screen.dart:36`. Sekarang:

- `LiquidConfig.verificationMethod` (default `COMPLY_HE`) — bisa di-flip tanpa
  rebuild
- Config screen punya dropdown **Metode Verifikasi**, tiap item ditandai
  `(baca chip)` / `(tanpa chip)` — jadi Tokyo bisa pilih `FRONT` langsung dari
  HP, tanpa rebuild
- Dialog pre-flight credential **cuma muncul** kalau method-nya emang baca chip

#### Rekomendasi ke Tokyo

Test flow My Number di staging pakai method `FRONT` (atau `COMPLY_TO`) →
nggak ada baca chip sama sekali → kartu aman. Method `COMPLY_HE` (chip) baru
dipakai kalau memang mau tes alur chip, dan itupun dengan sengaja SECARA
BERHATI-HATI + maksimal 3 percobaan (sesuai ChipAttemptGuard).

### S. Log native SDK → APP log + Telegram (P16)

Diminta: log dari sisi native bisa diambil & dimunculin di app logger
(APP/HTTPS tab) + log Telegram.

#### Temuan penting: SDK 1.47.0 NOL logging hook

Diverifikasi langsung dari AAR:

| Cek | Hasil |
|---|---|
| referensi `android.util.Log` | **0** → SDK nggak log ke Logcat |
| referensi `PrintStream` (println) | **0** → nggak print ke stdout |
| file log sendiri | nggak ada |
| HTTP client | `java.net.HttpURLConnection` (bukan OkHttp) → **nggak bisa di-inject interceptor** |

Artinya **log internal SDK nggak bisa ditangkap sama sekali** — nggak ada hook.
Yang bisa ditangkap = **titik interaksi kita dengan SDK**, yang itu kita
instrumentasi.

#### Yang sudah berjalan (section O)

`SdkManager.log()` → `invokeMethod("nativeLog", …)` → Dart
`LiquidEkycChannel._handleNativeCall` → `appLogger.d(tag: 'Native')`.

#### Yang ditambahkan di sesi ini

1. **Telegram ikut terima log native** — sebelumnya di-exclude. Sekarang ikut
   kirim, tapi **dibatasi 8 baris per batch** (`_maxNativePerBatch`) supaya
   nggak nutup log aplikasi. Tag `Native` dipisah dari `newOnes` lalu
   ditambahkan di akhir batch.

2. **Instrumentasi native lebih kaya** (`SdkManager.kt`):
   - `VerifyIdChip callback: status=… errorCode=…` (dipisah per baris:
     title, message, chipData/autoVerify/docImage presence)
   - `requestedDocType=… actualDocType=…` → mendeteksi mismatch di native
   - `SDK version: 1.47.0` saat register launchers

3. **`main.dart` instantiate `LiquidEkycChannel()` lebih awal** — supaya
   handler `nativeLog` terpasang sebelum plugin native mulai nelen log.

#### Yang TIDAK bisa (batas SDK)

| Yang desirable | Kenapa nggak bisa |
|---|---|
| Log internal SDK (screen/step yg SDK displaying) | SDK nggak punya logging hook sama sekali |
| HTTP call SDK → `applicantsdk-api` | HttpURLConnection, nggak ada titik inject |

Workaround HTTP call SDK: MITM proxy in-app (dart:io HttpServer +
`ProxySelector.setDefault` + CA custom). Effort besar, risiko TLS break —
belum dikerjakan, karena nggak ada kebutuhan eksplisit.

### T. Sanitasi log export + fix counter "Errors:" (P17)

Karena file export rutin di-share ke CS/user, log harus aman di-share.

#### 1. `LogSanitizer` (shared)

`_sanitize` yang sebelumnya private di `TelegramLogUploader` dipindah ke
`lib/core/services/log_sanitizer.dart` → dipakai bareng oleh Telegram
uploader **dan** export file.

Pola yang dicakup: email, deretan digit ≥12 (applicantId / kartu), dan
`key=value` / `"key":"value"` / `'key':'value'` untuk ~40 key sensitif
(token, api key, nama, alamat, lahir, myNumber, phone, dsb).

**Bug yang ketemu & diperbaiki**: pola single-quote (`'X-Ekyc-Api-key': '...'`)
nggak ke-match sama sekali → **API key Connector bocor mentah** ke file
export. Sekarang ada 3 pola (double-quoted / single-quoted / bare).

#### 2. Export APP + HTTP log sekarang disensor

- APP log: pesan, error, stacktrace → disensor
- HTTP log: URL + response body → disensor (response token BE = token SDK
  yang masih hidup)

#### 3. Counter "Errors:" dibenerin

`AppLogger.errorCount` cuma ngitung error **yang punya objek error**, jadi
bisa 0 padahal ada baris level ERROR. Untuk header export sekarang pakai
`errorLevelCount` (hitung dari level).

### Verifikasi

```bash
fvm flutter analyze            → No issues found! (0 warning, 0 info)
fvm flutter test               → All tests passed! ✅
./gradlew :app:compileDebugKotlin → BUILD SUCCESSFUL ✅
```

---

## 📋 Status per Poin dari Tokyo

| Poin | Status | Keterangan |
|---|---|---|
| 1. Driving License | ✅ Selesai | Tidak ada backside — memang sesuai spek COMPLY_HE. Row "Tipe SIM" sekarang keisi (native kirim `driversLicenseTypes`) |
| 2. Gen-2 Residence Card | 🟡 Code siap, env belum | Perlu credential production + flip `USE_PRODUCTION`. Badge GEN-2 & Card Type sekarang aktif (card_type dari chip data) |
| 3. My Number | ✅ Code siap | `verifyIdChip()` sekarang pakai `MY_NUMBER_CARD` + COMPLY_HE — **siap dites**. Row "No. My Number" (masked) aktif |
| — TnC per dokumen | 🔴 Blocker | Butuh konfirmasi Liquid: `operation_assignment_priority` per operation + registrasi operation My Number di Manager |
| — Deteksi mapping salah | ✅ Aktif | Log `[Mismatch]` + badge DOC MISMATCH di Identity Card |

---

```
1. App launch → KycConfigScreen
2. Pilih Indonesia → Residence Card → Submit → HomeScreen
3. Applicant ID BARU → "Ambil Token & Mulai"
4. Cek log: [HTTP-REQ] POST /v1/sdk/applications → body punya operation_assignment_priority yang BENAR
5. TnC yang muncul HARUS sama dengan operation priority tersebut
6. Ulangi untuk Jepang → Driving License (priority berbeda)
7. Ulangi untuk Jepang → My Number (priority berbeda)
8. Cek log native: [STEP 11] documentType = MY_NUMBER_CARD (bukan RESIDENCE_CARD)
9. Pastikan flow input My Number 12 digit muncul (bukan PIN Residence Card)
```

---

## 📚 Referensi Dokumen

| Kode | Dokumen |
|---|---|
| SDK-IFACE | `6. Application SDK/11. 【EN】LIQUIDeKYCApplicantSDKInterfaceSpecificationsv1.45.0/【EN】LIQUID eKYC Applicant SDK Interface Specifications v1.45.0.pdf` (p.6 TnC function) |
| SDK-IFACE-JP | `6. Application SDK/4. LIQUID eKYC Applicant SDK Version Interface Specification v1.47.0 - …zip` → PDF (p.12–14 showTermsOfUse IN/OUT/RES) |
| SDK-README | `SDK_Android_ver1.47.0/README/README.md` (cara pakai fungsi, catatan evaluation version tidak support My Number) |
| SDK-BIN | `android/app/libs/Liquid-1.47.0.aar` → `classes.jar` (`repackage/z01`, `yz0`, `o40`, `h01`, `q01`, `d11`; `res/values/values.xml`) |
| API-017 | `documents/SDK Function/[E]LIQUID_eKYC_017_SDKApplyAPI_v1.3.6 (1).pdf` (p.1 semantics & token 90 menit, p.2–3 request body) |
| POSTMAN | `documents/SDK Function/liquid-collection-v3.postman_collection.json` (body 017 + endpoint lain) |
| MGR-SHEET | `8. Implementation Guide/English ver/02_LIQUIDeKYC_ManagerItemSetupSheet_v.4.10_Customplan_YYYYMMDD.xlsx` (ID Document type code per sheet) |
| MGR-SPEC | `3. Product Specification/English Version/4. eKYCManagerProductSpecifications_v6.9.pdf` (p.15 Dashboard/Assign Logic, p.17 Operation priority) |
| SDK-SPEC | `3. Product Specification/English Version/2. LIQUIDeKYCApplicant（SDKver.）ProductSpecificationsVer.1.8.6.pdf` (p.11 §2-2 Terms of Use Function, p.34 timeout/90 menit) |

---

## 📂 File yang Diubah Session Ini

| File | Perubahan |
|---|---|
| `android/.../liquid_ekyc/VerificationHandler.kt` | Helper `toLiquidDocumentType()` (13 enum, null-safe) + `toVerificationMethod()` (11 enum); `verifyIdChip` & `verifyIdDocument` pakai argumen dari Dart; error `INVALID_DOCUMENT_TYPE` |
| `lib/core/constant/liquid_constants.dart` | Env switch (`USE_PRODUCTION` + getter url/apiKey/beUrl/connectorApiKey); 3 enum Gen-2/Specified di `LiquidDocumentType`; `Nationality.allowedDocuments` Indonesia + Gen-2; `fromString` default fix; `isCompatibleWith()` |
| `lib/data/services/kyc_be_api.dart` | `_beUrl` + `_apiKey` jadi getter dari `LiquidConfig` (ikut env switch); `OcrResultsBeResponse` += `myNumber` |
| `lib/app/app.dart` | `LiquidEkycConfig.apiUrl` & `apiKey` `const` → `final` |
| `lib/persentation/viewmodels/kyc_viewmodel.dart` | Allow-list `_updateDocumentTypeForMethod()` + 3 enum Gen-2/Specified; `actualDocumentType` / `isDocumentTypeMismatch` / `_checkDocumentTypeMatch()` |
| `lib/data/models/chip_result.dart` | `LiquidChipDataModel` += 10 field + `displayMyNumber`; `AutoVerificationResult` += 5 field; `ChipVerificationResult` += `documentTypeMismatch`; log `[ChipParse]` lengkap |
| `lib/persentation/views/screens/kyc_result_screen.dart` | Badge DOC MISMATCH + detail kartu dibaca; baris No. My Number (masked) di tab SDK & BE; Card Type dari chip data |
| `lib/core/services/channel_verification_handler.dart` | Log chip data lengkap (address di-mask manual, myNumber masked), log `documentTypeMismatch` |
| `android/.../liquid_ekyc/VerificationHandler.kt` | Helper `toLiquidDocumentType()` (13 enum, null-safe) + `toVerificationMethod()` (11 enum) + `buildChipDataMap()` + `buildAutoVerificationMap()` + `isActualDocumentTypeCompatible()`; `verifyIdChip` & `verifyIdDocument` pakai argumen dari Dart; error `INVALID_DOCUMENT_TYPE` |
| `android/.../liquid_ekyc/SdkManager.kt` | Callback chip kirim `liquidChipData` + `autoVerificationResult` + `liquidDocumentType` + `documentTypeMismatch`; `pendingRequestedDocumentType` |
| `android/.../liquid_ekyc/FinalizeHandler.kt` | OCR map += `driversLicenseTypes` |
| `test/widget_test.dart` | Fix import package (`module_liquid_ekyc` → `module_liquid`) + update ekspektasi teks smoke test |

**File yang MASIH perlu diubah (menunggu input Liquid):**

| File | Perubahan |
|---|------|-----------|
| `lib/data/services/kyc_be_api.dart` | `_AnnotatedClient.send()` → panggil `HttpLogger()._logRequest/_logResponse`; `_bypassSsl` jadi runtime flag bukan `const` |
| `lib/data/services/kyc_be_api.dart` | Tambah map `LiquidDocumentType → operationPriority` + kirim `operation_assignment_priority` per dokumen; **fail loudly** kalau belum di-set |
| `lib/persentation/views/screens/kyc_home_screen.dart` | Kirim priority saat request token; hapus jalur hardcoded token |
| `lib/core/constant/liquid_constants.dart` | Kosongkan `applicantId`/`token` hardcoded → app wajib ambil token baru |
| `lib/data/services/kyc_be_api.dart` | `registerApplicantInfo` kirim `nationality` + `sex`; panggil `registerKycRequestInformation` bila diwajibkan |
| `lib/persentation/viewmodels/kyc_viewmodel.dart` | Reset `_selectedDocumentType` di `reset()`/`cancel()` |

---

## 🚀 Next Steps

- [x] Fix mapping native `MY_NUMBER_CARD` + `verificationMethod` (jawaban untuk vendor)
- [x] Tambah support Gen-2 Residence Card (`RESIDENCE_DOCUMENT_GEN2`) + dropdown option
- [x] Env switch staging ↔ production
- [x] Kirim `liquidChipData` + `autoVerificationResult` dari native ke Dart (22 field)
- [x] Kirim `driversLicenseTypes` di OCR map
- [x] Badge DOC MISMATCH + log `[Mismatch]` (dokumen diminta vs dokumen dibaca)
- [x] Baris "No. My Number" (masked) + "Card Type" (dari chip data) di result screen
- [ ] **Dapatkan credential production dari Liquid CS** → isi `_prodApiKey`, `_prodBeUrl`, `_prodConnectorApiKey`
- [ ] **Tes ulang My Number** (Jepang → My Number) → cek logcat `-> LiquidDocumentType: MY_NUMBER_CARD, VerificationMethod: COMPLY_HE` + flow input 12 digit muncul + `[Mismatch] Dokumen sesuai`
- [ ] **Tes Gen-2 di production** (Indonesia → Residence Card (Gen-2)) → cek `id_document_type` = `01036`/`01037` + badge GEN-2 nyala
- [ ] **Jawaban Liquid**: `operation_assignment_priority` per operation + status registrasi operation マイナンバーカード di Manager (blocker TnC)
- [x] HTTP logging hidup (`_AnnotatedClient` → `HttpLogger`, body + headers, release mode juga)
- [ ] Update `docs/comply_he_implementation_audit.md` dengan temuan sesi ini
- [ ] Bersihin token/applicantId hardcoded dari `liquid_constants.dart` sebelum masuk repo

---

**Session End: 17 November 2026**
**Status: Fix My Number + Gen-2 mapping + chip data delivery + mismatch detection sudah diimplementasikan. `flutter analyze` 0 error, `flutter test` passed, `compileDebugKotlin` success. Blocker tersisa: credential production + konfirmasi `operation_assignment_priority` dari Liquid.**
