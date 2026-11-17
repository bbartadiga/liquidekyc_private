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

### Verifikasi

```bash
fvm flutter analyze            → 0 error (64 info/warning pre-existing)
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
- [ ] HTTP logging hidup (`_AnnotatedClient` → `HttpLogger`, `_bypassSsl` runtime) — biar request 017 ke Liquid kelihatan
- [ ] Update `docs/comply_he_implementation_audit.md` dengan temuan sesi ini
- [ ] Bersihin token/applicantId hardcoded dari `liquid_constants.dart` sebelum masuk repo

---

**Session End: 17 November 2026**
**Status: Fix My Number + Gen-2 mapping + chip data delivery + mismatch detection sudah diimplementasikan. `flutter analyze` 0 error, `flutter test` passed, `compileDebugKotlin` success. Blocker tersisa: credential production + konfirmasi `operation_assignment_priority` dari Liquid.**
