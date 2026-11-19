# 📝 Session — My Number Card Lock Warning + Pipeline Log Native

**Tanggal:** 18 November 2026
**Project:** `module_liquid_ekyc` (POC Liquid eKYC Flutter App)
**Status:** ✅ Fix error handling My Number Card + proteksi kartu + pipeline log native — siap dites Tokyo

---

## 🎯 Scope Session Ini

Mulai dari **screenshot Tokyo**: SDK nampilin dialog native

> **Identification unsuccessful**
> You have 9 attempts left until the card is locked
> If it is locked, it must be unlocked by visiting your registered municipal office

setelah layar "Please tap the card". Goal sesi ini:

1. Identifikasi **akar masalah** dari bytecode SDK 1.47.0 (bukan tebakan)
2. **Koreksi mapping error code** yang salah di enum kita
3. **Lindungi kartu user** dari terkunci
4. **Pipeline log native SDK** → app logger (APP/HTTPS) + Telegram
5. **Lengkapi mapper `LiquidChipData`** (46 getter SDK → hanya 23 kepakai)

---

## 📸 Input dari Tokyo

### Screenshot (16:30)
Layar "Please tap the card" (SDK native) + dialog "Identification unsuccessful / 9 attempts left".

### App log export (`liquid_kyc_app_logs_20261109_1550.txt`)
87 entries, 4 level ERROR, **header tulis "Errors: 0"** (bug counter), token & applicantId **mentah**.

### Telegram log
5 batch, urutan **terbalik** (newest-first).

---

## 🔍 A. Akar masalah: identifikasi dari bytecode SDK

Dialog itu **cuma** bisa dibedain dari string SDK (AAR `Liquid-1.47.0.aar`):

| Resource SDK | Isi |
|---|---|
| `liquid_restart_chip_pin_mismatch_my_number_title` | "Identification unsuccessful" |
| `liquid_restart_chip_pin_mismatch_my_number_message` | "You have %1$s attempts left until the card is locked\nIf it is locked, it must be unlocked by visiting your registered municipal office" |

→ Cocok persis → enum SDK `CHIP_PIN_ERROR_MY_NUMBER_LOCKED` → status
`IC_CHIP_PIN_FAILURE` → **errorCode = `SE20005`**.

### Artinya

**PIN/kredensial yang dimasukkan nggak cocok sama kartu** — bukan sekadar "kartu gagal kebaca".

SDK nge-compare input user dengan hasil baca kartu. Yang diminta SDK
(`liquid_chip_my_number_chip_input_*`):

| Field | Sumber |
|---|---|
| Tanggal lahir | depan kartu |
| Tanggal berlaku | depan kartu |
| Kode keamanan (4 digit) | pojok kartu, **print kecil** |

Kode keamanan kecil → rawan salah ketik / salah OCR → mismatch → jatah
percobaan kartu turun.

### Kenapa di dev kayak production

**Pembacaan chip + validasi kredensial itu 100% on-device** (JPKI public key).
Server staging cuma issuance token/applicant & terima hasil. **Counter
percobaannya ada di IC chip kartunya** — efeknya ke kartu fisik identik dengan
production. Staging **nggak melindungi kartu sama sekali**.

---

## 🔍 B. Koreksi mapping error code (Fix 3)

Mapping `ChipVerificationResultStatus → SExxxxx` diambil dari bytecode
`ResultHandler` (javap). **Otoritatif, bukan tebakan.**

```
SE20001 IC_CHIP_LOCKED              SE21101/2/3 IC_CHIP_SPECIAL_RESIDENCE
SE20005 IC_CHIP_PIN_FAILURE         SE21201/2/3 IC_CHIP_VERIFICATION_FAILURE
SE20011 IC_CHIP_PIN_INVALID         SE21205 IC_CHIP_EXPIRED
SE20015 IC_CHIP_PIN_INVALID         SE22001 IC_CHIP_NOT_AVAILABLE
SE21001 IC_CHIP_SPECIAL             SE22051/52 IC_CHIP_READ_ERROR
SE21011 IC_CHIP_UNUSUAL_UPDATED     SE23001 IC_CHIP_NO_EXTERNAL_CHARACTERS
SE27001 MYNUMBERCARD_..._HISTORY    SE27101/2/3 ..._DRIVER_LICENSE_VERIFY_FAILURE
SE27205 ..._DRIVER_LICENSE_EXPIRED  SE80001 USER_CANCEL
```

### Yang SALAH di enum kita sebelumnya

| Enum lama | Semula | Seharusnya |
|---|---|---|
| `icChipReadError` | `SE21001` | `SE22051` (+alias SE22052) — SE21001 itu `IC_CHIP_SPECIAL` |
| `movingCard` | `SE22051` | dihapus → gabung ke `icChipReadError` |
| `incorrectPin` | `SE20015` | ✓ benar, tapi belum ditandai "bisa kunci kartu" |

Ditambah: `icChipSpecial` (SE21001), `icChipSpecialResidence` (SE21102),
`icChipVerificationFailure` (SE21201), `unsupportedDeviceNfc` (SE99998),
`mynaIntegratedDriverLicenseVerifyFailure` (SE27101) + dukungan `aliases`
(SDK punya beberapa kode untuk satu status yang sama).

---

## 🔍 C. Koreksi: `setExcludeMyNumber` BUKAN alat proteksi kartu

Awalnya sempat direkomendasikan sebagai cara hilangin prompt credential.
**SALAH** — sudah diverifikasi di bytecode.

Flag-nya dikirim ke `ChipVerificationActivity` lewat Intent extra
`EXCLUDE_MY_NUMBER`, lalu dibaca di **tepat 3 kelas** — semuanya fase
**assembling hasil**:

```java
// kl0 / pl0 / tl0
String myNumber = (arg instanceof p9) ? ((p9) arg).l : null;
if (params.ib.f) {          // ib.f = excludeMyNumber
    myNumber = null;         // ← 個人番号 dibuang dari hasil
}
result.vh.z = myNumber;
```

| | |
|---|---|
| ❌ | nggak lewatin baca NFC |
| ❌ | nggak lewatin prompt credential |
| ❌ | nggak influence counter percobaan kartu |
| ✅ | **cuma meng-null-kan 個人番号 dari hasil akhir** |

Gunanya sebenarnya: **privacy/rekonsiliasi** — buang 個人番号 dari device
kalau nggak butuh. Bukan proteksi kartu.

### Terjemahan

| Jepang | Baca | Arti |
|---|---|---|
| **個人番号** | kojin bangō | "My Number" — nomor 12 digit (My Number Act) |
| 個人番号カード | | My Number Card |
| 認証用情報 | ninshō yō jōhō | "authentication information" — DOB + tgl berlaku + kode keamanan |
| 在留カード | zairyū kādo | Residence Card |
| 特別永住者証明書 | | Special Permanent Resident Certificate |
| 第2世代在留カード | | 2nd Generation Residence Card |

---

## 🛡️ D. Proteksi kartu dari lock

### 1. Dialog pre-flight (sebelum kartu disentuh)
`kyc_home_screen._showChipCredentialWarning()` → user diberi tahu persis
data apa yang diminta SDK + risikonya. **Cuma muncul kalau method-nya emang
baca chip.**

### 2. `ChipAttemptGuard` — counter di perangkat, restart-proof

| | |
|---|---|
| Yang dihitung | **Cuma** error yang bisa mengunci kartu (`SE20001/20005/20011/20015`) |
| Yang nggak dihitung | Cancel user, error jaringan, timeout — nggak memotong jatah kartu |
| Disimpan di | SharedPreferences → **restart app nggak bisa reset** |
| Batas | 3x gagal → app **nggak lagi memanggil SDK** buat baca chip |
| Sukses | counter reset |

### 3. Error message (Fix 1)
Tampilin sisa percobaan (`attemptsRemainingUntilChipLocked` — diambil dari
`LiquidChipErrorData` SDK yang **nggak diekspos** lewat
`LiquidChipVerificationResult`, jadi kita ambil langsung dari
`data.liquidChipData?.liquidChipErrorData`) + peringatan kunci kartu, dalam
**AlertDialog** (bukan SnackBar yang keburu hilang 4 detik).

> Penting: kartu ini punya batas percobaan. Sisa percobaan: 9 kali. Kalau
> habis, kartu terkunci dan hanya bisa dibuka di kantor kecamatan.

---

## 🔀 E. Method verification = satu-satunya lever kita

`VerificationMethod.requiresIcCard`:

| Method | Baca chip? | Risiko lock kartu |
|---|---|---|
| `COMPLY_HE` | ✅ chip + face | **ADA** ← yang Tokyo pakai |
| `READ`, `READ_FACE`, `READ_OFFLINE` | ✅ | **ADA** |
| `FRONT` | ❌ (dokumen saja) | **nggak ada** |
| `COMPLY_TO`, `COMPLY_CHI`, `COMPLY_HO` | ❌ | **nggak ada** |
| `FRONT_FACE`, `FRONT_BACK`, `FRONT_BACK_FACE` | ❌ | **nggak ada** |

`verificationOrder` sudah ngikutin `requiresIcCard` → kalau FRONT, langkah
`icCard` **dilewati total** → nggak ada NFC, nggak ada credential prompt,
nggak ada counter.

### Yang berubah (final: OPSI D — hardcode COMPLY_HE)

**Keputusan user: project ini HANYA pakai `COMPLY_HE`. Dropdown dibuang, method
lain dihapus.**

- `VerificationMethod` enum → cuma `complyHe` (10 method lain dihapus)
- `requiresDocument` = false, `requiresIcCard` = true, `requiresFace` = true
- `verificationOrder` → `['icCard', 'face']` (selalu)
- `kyc_config_screen.dart` → hardcode `VerificationMethod.complyHe`, dropdown
  dihapus
- `LiquidConfig.verificationMethod` → dihapus
- `kyc_viewmodel.dart:_updateDocumentTypeForMethod()` → case `read`/`readFace`
  dihapus (enum-nya udah nggak ada)
- Kotlin `toVerificationMethod()` **dipertahankan** lengkap (decoder 1:1 ke
  enum SDK, `else -> COMPLY_HE` aman) — mapping buat method yang belum dipakai
  cuma dead code

**Alasan hapus method lain** (bukan cuma dropdown):
- Asumsi komposisi langkah kita (document / backside photo / offline) buat
  method lain **nggak akurat** → flow bolong
- Liquid server yang nentuin flow sebenarnya (CE00030) → method yang nggak
  dikonfigurasi di BE ditolak
- `COMPLY_HO` butuh backside photo yang nggak diimplementasi
- `READ_OFFLINE` butuh konsep offline yang nggak ada di `startVerify` kita

Kalau someday butuh method lain: tambahin enum **BERSAMA** implementasi
langkahnya, jangan cuma enum-nya.

Dialog pre-flight credential tetap ada (COMPLY_HE memang baca chip).

### ⚠️ Batas: flow milik SDK + BE

Flow **nggak bisa diubah dari app** — semua layar/prompt/dialog ada di
`ChipVerificationActivity`. Yang kita pegang cuma "minta flow mana".

Dan flow-nya **server-side**: `VerificationMethod` masuk Intent extra
`VERIFICATION_METHOD` → SDK pakai buat minta flow ke `applicantsdk-api` →
**Liquid server yang validasi**. Bukti: error code
`CE00030 — Authenticity method not allowed for this verification type`.

**Method nggak pernah dikirim ke BE** di payload kita:

| Request | Body |
|---|---|
| `applyForSdkToken` | `{applicant_id, operation_assignment_priority}` |
| `registerApplicantInfo` | `{first_name, last_name, birthday, address1, phone_number}` |
| `registerApplicationInfo` | `{first_name, last_name, birthday, address1, phone_number}` |

→ konfigurasi flow menempel di **applicant record** sisi Liquid (CS yang atur).

**Belum dicek ke Liquid CS:** apakah applicant Tokyo di staging boleh pakai
`FRONT`/`COMPLY_TO`, atau COMPLY_HE doang.

### Konflik kalau FRONT dipakai untuk semua

**1. Deteksi mismatch (fitur inti TNC) mati total**

```dart
LiquidDocumentType? get actualDocumentType {
  final value = _chipVerificationResult?.chipData?.liquidDocumentType;  // dari chip
}
bool get isDocumentTypeMismatch {
  final actual = actualDocumentType;
  if (actual == null) return false;   // tanpa chip → SELALU false
}
```

Tanpa chip → `actualDocumentType == null` → mismatch selalu false. Seluruh
investigasi TNC jadi nggak bermakna. (Ini inherent, bukan bug — mustahil dicek
tanpa baca chip.)

**2. Data applicant ke BE jadi data palsu** — SUDAH DIPERBAIKI

```dart
// SEBELUM: chip → BE → fallback  →  tanpa chip = kirim data palsu
applicantName: chipData?.displayName ?? beICCardInfo?.displayName ?? 'User',
dateOfBirth:  chipData?.displayBirthday ?? beICCardInfo?.displayBirthday ?? '19900101',
address:      chipData?.fullAddress ?? beICCardInfo?.fullAddress ?? 'Address',

// SESUDAH: chip (signed JPKI) → OCR → BE → fallback
```

+ nambah `OcrResult.fullAddress` (gabungan pref+city+other+address).

---

## 📋 F. Lengkapi mapper `LiquidChipData`

SDK 1.47.0 expose **46 getter** di `LiquidChipData`, tapi `buildChipDataMap`
(Kotlin) cuma kebaca ~23 field. Sisanya dibuang → data hilang permanen.

### Yang ditambah

| Group | Field |
|---|---|
| Nama | `nameHalfWidthKana`, `lastNameKanaCandidates` (+ half-width), `firstNameKanaCandidates` (+ half-width), `previousName`, `previousLastNameKanaCandidates` (+ half-width), `aliasName` |
| Alamat | `addressModificationHistories` |
| Status tinggal | `movedAbroad`, `plannedAbroadMoveDate`, `japaneseForeignerJudgment`, `pscName`, `pscNames` |
| Gen-2 | `residenceDocumentGen2Data` → 15 field (izin individual/menyeluruh, info type, masa tinggal, jenis izin, status tinggal, batasan pekerjaan, dsb) |
| My Number + SIM | `myNumberCardIntegratedDriverLicenseData` → colorCategory, types, conditions, remarks, acquisitionDates, recordNumber, validUntil |
| Gambar | `hasAddressImage` |

Bitmap tetap nggak dikirim (terlalu besar).

### ⚠️ Temuan penting

Untuk **Gen-2**, field izin tinggal **level atas kosong**
(`residenceCardIndividualPermission` = null). Semuanya ada di dalam
`residenceDocumentGen2Data`. Makanya ada getter fallback:

```dart
String? get displayIndividualPermission =>
    residenceDocumentGen2?.individualPermission ?? residenceCardIndividualPermission;
```

### `Sex` tambahan

SDK punya `MALE / FEMALE / OTHERS`. `Sex.fromString()` cuma handle dua
pertama → **`OTHERS` jatuh ke `unknown`**. Ditambah `Sex.others`.

### Model Dart baru

- `MyNumberCardIntegratedDriverLicense` (chip_data.dart)
- `ResidenceDocumentGen2` (chip_data.dart) + getter `stayPeriod` ("5 / 3 / 10")

### UI

Result screen → Identity Card nampilin blok **"Izin Tinggal (Gen-2)"** (13 baris)
kalau chip-nya Gen-2.

---

## 📡 G. Pipeline log native SDK

### Temuan: SDK 1.47.0 NOL logging hook

Diverifikasi langsung dari AAR:

| Cek | Hasil |
|---|---|
| referensi `android.util.Log` | **0** → SDK nggak log ke Logcat |
| `PrintStream` (println) | **0** |
| file log sendiri | nggak ada |
| HTTP client | `java.net.HttpURLConnection` (bukan OkHttp) → **nggak bisa di-inject interceptor** |

**Log internal SDK nggak bisa ditangkap sama sekali.** Yang bisa ditangkap =
**titik interaksi kita dengan SDK**.

### Yang sudah jalan

```
SdkManager.log() → invokeMethod("nativeLog", …) → Dart
  → LiquidEkycChannel._handleNativeCall → appLogger.d(tag: 'Native')
```

→ masuk **APP log export** ✓

### Tambahan sesi ini

1. **Telegram ikut terima log native** — sebelumnya di-exclude. Sekarang ikut
   kirim, tapi **dibatasi 8 baris per batch** (`_maxNativePerBatch`) supaya
   nggak nutup log aplikasi.

2. **Instrumentasi native lebih kaya** (`SdkManager.kt`):
   - `VerifyIdChip callback: status=… errorCode=…` + title/message/
     chipData-presence dipisah per baris
   - `requestedDocType=… actualDocType=…` → mendeteksi mismatch di native
   - `SDK version: 1.47.0` saat register launchers

3. **`main.dart` instantiate `LiquidEkycChannel()` lebih awal** — supaya
   handler `nativeLog` terpasang sebelum plugin native mulai nelen log.

### Yang TIDAK bisa (batas SDK)

| Yang desirable | Kenapa nggak bisa |
|---|---|
| Log internal SDK (step/layar yg SDK displaying) | nggak ada logging hook sama sekali |
| HTTP call SDK → `applicantsdk-api` | HttpURLConnection, nggak ada titik inject |

Workaround HTTP call SDK: MITM proxy in-app (dart:io HttpServer +
`ProxySelector.setDefault` + CA custom). Effort besar, risiko TLS break —
belum dikerjakan, belum ada kebutuhan eksplisit.

---

## 🔒 H. Sanitasi log export + fix counter "Errors:"

Karena file export rutin di-share ke CS/user, log harus aman di-share.

### 1. `LogSanitizer` (shared)

`_sanitize` yang sebelumnya private di `TelegramLogUploader` dipindah ke
`lib/core/services/log_sanitizer.dart` → dipakai bareng oleh Telegram uploader
**dan** export file.

Pola: email, deretan digit ≥12 (applicantId / kartu), dan
`key=value` / `"key":"value"` / `'key':'value'` untuk ~40 key sensitif
(token, api key, nama, alamat, lahir, myNumber, phone, dsb).

**Bug yang ketemu & diperbaiki:** pola single-quote (`'X-Ekyc-Api-key': '...'`)
nggak ke-match → **API key Connector bocor mentah** ke file export. Sekarang
3 pola.

### 2. Export APP + HTTP log disensor

- APP log: pesan, error, stacktrace
- HTTP log: URL + response body (response token BE = token SDK yang masih hidup)

### 3. Counter "Errors:" dibenerin

`AppLogger.errorCount` cuma ngitung error **yang punya objek error** → bisa 0
padahal ada baris level ERROR. Header export sekarang pakai
`errorLevelCount` (hitung dari level).

### 4. Guard config production

`useProduction = true` sementara `_prodBeUrl` masih `''` → `baseUrl` jadi
`/inbound-liquid` → `Uri.parse` nggak punya scheme → **"No scheme specified"**
(bug yang sama kayak retry queue worker). Ditambah
`LiquidConfig.hasProductionConfig` + `effectiveUseProduction` → auto-fallback
staging + log error di `main.dart`. Sekalian dibenerin label
`Mode: PRODUCTION` yang hardcode di `kyc_repository.dart`.

---

## 📋 Alur share log (untuk Tokyo)

**Debug Log Screen → Share (ikon share) → "All Logs (APP + HTTP + Native SDK)"**

Opsi ini sekarang **di paling atas** share sheet, supaya nggak salah pilih.

File: `liquid_kyc_all_logs_<timestamp>.txt`

| Bagian | Isi |
|---|---|
| APP LOGS | STEP 1..11, error detail, **log native SDK** (tag `[Native]`), hasil BE |
| HTTP LOGS | request ke BE/Connector API + response (sudah disensor) |

> Catatan: file yang dikirim Tokyo sebelumnya (`liquid_kyc_app_logs_...txt`) =
> opsi **"App Logs Only"**. Mulai sekarang pakai **"All Logs"** biar HTTP-nya
> ikut.

### Baris yang perlu dicari untuk kasus My Number

```
[STEP 11] ERROR detail | code:SE20005 | title:... | msg:... | attemptsLeft:9 | credential:...
[Native] VerifyIdChip callback: status=ERROR errorCode=SE20005
[Native]   requestedDocType=MY_NUMBER_CARD actualDocType=...
[STEP 11] Chip attempt recorded | gagal=1/3 sisa=2
```

---

## ✅ File yang berubah

### Kotlin
| File | Perubahan |
|---|---|
| `SdkManager.kt` | bridge `nativeLog` ke Dart, instrumentasi callback chip, `requestedDocType`/`actualDocType`, versi SDK |
| `LiquidEkycPlugin.kt` | `SdkManager.attachLogChannel(channel)` |
| `VerificationHandler.kt` | `buildChipDataMap` lengkap (46 getter), `LiquidChipErrorData` |
| `FinalizeHandler.kt` | `getSdkVersionQuietly()` |

### Dart
| File | Perubahan |
|---|---|
| `lib/core/constant/liquid_error_codes.dart` | mapping SDK 1.47.0 + `aliases` + `canLockCard` |
| `lib/core/constant/liquid_config.dart` | `verificationMethod`, `hasProductionConfig`, `effectiveUseProduction` |
| `lib/core/services/chip_attempt_guard.dart` | **baru** — counter percobaan |
| `lib/core/services/log_sanitizer.dart` | **baru** — sensor data sensitif |
| `lib/core/services/liquid_ekyc_channel.dart` | handler `nativeLog` |
| `lib/core/services/telegram_log_uploader.dart` | native log ikut + limit 8/batch |
| `lib/core/services/channel_verification_handler.dart` | fallback My Number, pertahankan title SDK, log detail |
| `lib/core/screens/debug_log_screen.dart` | export disensor, counter Errors dibenerin |
| `lib/data/models/chip_data.dart` | 2 model baru + ~20 field, `Sex.others`, `fullAddress` |
| `lib/data/models/chip_verification.dart` | `attemptsRemainingUntilChipLocked`, lock warning |
| `lib/data/models/ocr_result.dart` | `fullAddress` |
| `lib/data/services/kyc_verification_runner.dart` | guard + catat kegagalan |
| `lib/persentation/viewmodels/kyc_viewmodel.dart` | `cardLockRisk`, fallback OCR ke BE |
| `lib/persentation/views/screens/kyc_home_screen.dart` | dialog pre-flight, AlertDialog lock risk |
| `lib/persentation/views/screens/kyc_config_screen.dart` | dropdown method |
| `lib/persentation/views/widgets/kyc_result_identity_sections.dart` | blok "Izin Tinggal (Gen-2)" |
| `lib/main.dart` | init channel lebih awal, log config env |

### Test
| File | Test |
|---|---|
| `test/liquid_error_codes_test.dart` | 11 — mapping kode, alias, deteksi kunci kartu |
| `test/chip_data_test.dart` | 14 — parsing field inti & baru, Gen-2, SIM terintegrasi |
| `test/chip_attempt_guard_test.dart` | 6 — counter, restart-proof, blokir |
| `test/log_sanitizer_test.dart` | 7 — token, api key, applicantId, nama, email |
| `test/telegram_log_uploader_test.dart` | 2 — komposisi batch |

---

## 🔍 Verifikasi

```bash
fvm flutter analyze                          → No issues found!
fvm flutter test                             → All tests passed (52)
./gradlew :app:compileDebugKotlin --rerun-tasks → BUILD SUCCESSFUL
```

---

## 📌 Yang masih terbuka

1. **Liquid CS** — apakah applicant Tokyo di staging boleh pakai
   `FRONT`/`COMPLY_TO`, atau COMPLY_HE doang? (tentukan usefulness dropdown)
2. **Liquid CS** — konfigurasi flow per applicant (CE00030)
3. **Liquid CS** — schema BE `registerApplicationInfo`: bisa kirim
   `my_number` / data Gen-2?
4. **schema BE** — `operation_assignment_priority` (dari dokumen Liquid) —
   default 1 + fail loudly kalau invalid
5. **Opsional** — MITM proxy in-app kalau butuh HTTP traffic SDK

---

## 💡 Rekomendasi ke Tokyo

- Project ini **hanya** COMPLY_HE (IC Card + Face) — sesuai permintaan user.
- Kartu My Number punya batas percobaan; salah ketik = satu jatah hilang.
  Pastikan kode keamanan 4 digit kecil diketik benar.
- ChipAttemptGuard auto-block setelah 3x gagal → jangan retry berulang.
- Kalau mau tes chip berulang, pakai kartu pengganti, bukan kartu utama.
- Share log: **"All Logs (APP + HTTP + Native SDK)"** — satu file, isinya
  APP log (termasuk log native SDK), HTTP log, dan Telegram sudah ikut
  nerima log native.

### U. Fix BE flow sesuai spec Liquid (P18)

Diverifikasi dari `Liquid POC Docs` + `documents/SDK Function`:

- **Interface Spec v1.45.0 p.28** — Comply to "He" = Initialization → Terms of
  Use → Document IC Card (COMPLY_HE) → Facial Recognition → **Activate**
- **Recommended Sequence v1.44.0** — activate = **fungsi SDK terakhir**
- **G01 API List** — semua Connector API harus **setelah activate()**

#### 3 perubahan

**1. Endpoint 016 RegisterApplicationInfo**
| | |
|---|---|
| Lama | `POST /v1/applicants/{id}/info` → BE balas *"Missing Authentication Token"* |
| **Baru** | `POST /v1/kyc_request_informations` (spec 016 v1.3.4) |

Body juga diperbaiki sesuai spec: tambah `applicant_id`, `nationality`, `sex`,
`zip_code`, field kana, `address2..4`, `id_number`. Field opsional null dibuang.

> Path lama **nggak ada** di spec maupun di Postman collection (collection itu
> mock lokal `localhost:8080`).

**2. BE-1 & BE-2 digeser ke SESUDAH `activate()`**
- G01 012: "Calling this API **before executing the Activate Function** may
  result in error code **CE00017**"
- G01 016: "Calling this API **immediately after executing the Activate
  Function** may result in an error"

Urutan sekarang: `activate() → BE-1 (016) → BE-2 (012) → BE-3..5 → BE-6 (014)`

**3. Jeda ≥1 detik + retry antar panggilan BE**
G01: *"Make sure to call after a 1 second interval with several retries"*.
`BeCallRunner` (baru) — jeda 1 detik + retry 3× untuk kode transien
(CE00004 / CE00008 / CE00017).

#### File

| File | Perubahan |
|---|---|
| `lib/data/models/applicant_info_payload.dart` | **baru** — payload 016 + pemecah nama/alamat sesuai spec |
| `lib/data/services/be/be_call_runner.dart` | **baru** — jeda + retry |
| `lib/data/services/be/kyc_be_applicant_api.dart` | `registerApplicationInfo` → path/body spec; `registerKycRequestInformation` dihapus (duplikat) |
| `lib/data/services/kyc_be_api.dart` | facade mengikuti |
| `lib/data/services/kyc_be_data_service.dart` | pakai `BeCallRunner` di semua call BE |
| `lib/persentation/viewmodels/kyc_viewmodel.dart` | BE-1/BE-2 digeser ke setelah `activate()` |

#### Test
`test/applicant_info_payload_test.dart` — 11 test (body, pemecah nama full-width,
pemecah alamat, birthday <1900, retry runner) + `test/kyc_be_api_test.dart` diupdate.

#### 🔄 CARA ROLLBACK

Kalau test Tokyo gagal & mau balik ke versi sebelum perubahan ini:

```bash
cd /Users/admin/Documents/BNI/Digiremit/Dev/module_liquid_ekyc

# Lihat commit yg perlu di-rollback
git log --oneline -5

# Rollback ke commit SEBELUM fix BE flow
git revert <commit-hash-fix-BE-flow>     # bikin commit baru (aman buat history)

# atau hard reset (HILANG semua commit sesudahnya — jangan dipakai kalau
# udah ada commit lain di atasnya)
git reset --hard <commit-hash-sebelum-fix-BE-flow>
```

Checkpoint sebelum & sesudah:

| Commit | Isi |
|---|---|
| `eb741dd` | refactor + My Number + log pipeline (**SEBELUM** fix BE flow) ← **titik rollback** |
| `<hash baru>` | fix BE flow: 016 path/body, geser BE-1/BE-2, jeda+retry |

Cara paling aman: `git revert <hash baru>` → history tetap linear, gampang
dibandyol ke Tokyo.

**Rollback частиyal** (kalau cuma satu bagian yang bermasalah):
- Endpoint 016 salah lagi → revert `kyc_be_applicant_api.dart` + `kyc_be_api.dart`
  + `kyc_be_data_service.dart` + `kyc_viewmodel.dart` (bikin `registerApplicationInfo`
  balikin ke `POST /v1/applicants/{id}/info` + body lama)
- Activate gagal (`[FINAL] Activate KYC → FAILED`) → geser BE-1/BE-2 balik ke
  sebelum `activate()` di `kyc_viewmodel.dart`
- Jeda 1 detik bikin lambat → turunin `BeCallRunner.spacing` ke
  `Duration(milliseconds: 200)` atau `Duration.zero`

#### ⚠️ Efek samping yang mungkin muncul (bukan bug)

| Gejala | Arti | Tindakan |
|---|---|---|
| `[BE-6]` **muncul** sekarang (sebelumnya nggak pernah) | 016 sukses → 014 jalan → Liquid mulai masking image (batch 5 menit) | Wajar. Kalau tes ulang pakai applicantId sama, foto bisa udah masked |
| Total flow lebih lama ~6 detik | Jeda 1 detik × 6 call | Wajar, loading overlay nutupin |
| `[BE-2] VerificationResults → SUCCESS` tapi score tetap null | My Number Card emang nggak ada passive auto-verification (`NOT_APPLICABLE`) | Wajar, bukan urutan |

## 📌 Yang TIDAK boleh berubah (regresi guard)

- Flow COMPLY_HE: `icCard` → `face`, tanpa scan dokumen terpisah
- `documentType` mapping ke Liquid SDK enum (jangan fallback diam-diam)
- Chip data → BE (`registerApplicationInfo`) + fallback OCR
- `documentTypeMismatch` detection (TNC)
