# 📝 Session — COMPLY_HE 3-Dokumen + UI Redesign

**Tanggal:** 6 November 2026
**Project:** POC Liquid eKYC Flutter App
**Status:** ✅ Selesai & Ready for Testing

---

## 🎯 Scope Session Ini

Fokus utama: melengkapi logika **COMPLY_HE** untuk 3 dokumen (Residence Card, Driving License, My Number) + redesign flow UI dari icon-settings ke halaman utama + auto-detect nationality/jenis dokumen dari BE/SDK.

---

## ✅ Yang Sudah Dikerjakan

### 1. Analisis SDK Spec — Dokumen NFC yang Didukung

Baca dokumentasi `[E]LIQUID_eKYC_022_GetICCardInfo_API_v1.3.9.pdf` section **"ID documents for IC card scan"**:

| # | Dokumen | Value Enum |
|---|---------|------------|
| 1 | Driver's Licence | `DRIVER_LICENSE` |
| 2 | National Identity Card (My Number) | `MY_NUMBER_CARD` |
| 3 | Residence Card | `RESIDENCE_CARD` |
| 4 | Special Permanent Resident Certificate | `SPECIAL_PERMANENT_RESIDENT_CERTIFICATE` |

Comply to "He" pakai metode: **"He", "Wa", "Ru", "To"/"Chi"** (IC Scan via SDK)

---

### 2. Bug Fix — My Number Tidak Ada di UI

**File:** `lib/persentation/views/screens/kyc_config_screen.dart`

`LiquidDocumentType.myNumberCard` ada di enum & allow-list, tapi **tidak muncul di radio button UI**. Fix: tambah `myNumberCard` ke filter & tambah deskripsi untuk 3 varian My Number.

### 3. Bug Fix — Allow-list ViewModel

**File:** `lib/persentation/viewmodels/kyc_viewmodel.dart` line 299-318

`_updateDocumentTypeForMethod()` belum include 2 varian My Number. Fix: tambah `myNumberCardWithMyNumber` + `myNumberCardIntegratedDriverLicense`.

### 4. Hapus Special Permanent Resident Certificate

User konfirmasi ga butuh certificate ini. Dihapus dari:
- UI filter dropdown
- `_getDocumentDescription()` switch
- ViewModel allow-list

**Final 3 dokumen COMPLY_HE:** Residence Card, Driving License, My Number.

---

### 5. Redesign Config Screen — Nationality Flow

**File:** `lib/persentation/views/screens/kyc_config_screen.dart` (rewrite)

Flow baru sesuai request:
- **Dropdown 1:** Kewarganegaraan (Indonesia / Jepang)
- **Dropdown 2:** Tipe Dokumen (filtered otomatis)
  - Indonesia → Residence Card saja
  - Jepang → Driver's License + My Number Card
- **Submit:** set verifikasi → navigate ke Applicant ID page

Tambah enum di `lib/core/constant/liquid_constants.dart`:
```dart
enum Nationality {
  indonesia,
  japan;

  List<LiquidDocumentType> get allowedDocuments {
    switch (this) {
      case Nationality.indonesia: return [LiquidDocumentType.residenceCard];
      case Nationality.japan: return [LiquidDocumentType.driverLicense, LiquidDocumentType.myNumberCard];
    }
  }
}
```

Metode hardcoded ke **COMPLY_HE** (ga ada UI selection lagi).

---

### 6. Pindahkan Config ke Halaman Utama

**Files:** `lib/app/app.dart`, `lib/persentation/views/screens/kyc_home_screen.dart`

- `home: KycHomeScreen()` → `home: KycConfigScreen()`
- Hapus `IconButton` settings dari AppBar home
- Hapus method `_navigateToConfig()` (dead code)
- Hapus import dead code di `kyc_home_screen.dart`

Submit behavior:
- Sebelumnya: `Navigator.pop()` (pop balik ke home)
- Sekarang: `Navigator.push(MaterialPageRoute(builder: (_) => KycHomeScreen()))` (push forward karena ini home baru)

Flow: App launch → ConfigScreen → Submit → HomeScreen (ApplicantID) → Verify → ResultScreen.

Android back: HomeScreen → ConfigScreen → close app. ✓

---

### 7. Auto-Detect Nationality + Document Type dari BE/SDK

**Files:** `lib/data/services/kyc_be_api.dart`, `lib/core/constant/liquid_mappings.dart` (baru), `lib/persentation/views/screens/kyc_result_screen.dart`

#### a. Tambah field `idDocumentType` di `OcrResultsBeResponse`

```dart
final String? idDocumentType;  // "01", "02", "03", "12", "13", dll
```

#### b. File baru `lib/core/constant/liquid_mappings.dart`

Berisi:
- **`liquidIdDocumentTypeNames`** — Map code ke display name (15 entries)
  - `"01"` → "Driver's Licence"
  - `"02"` → "Individual Number Card (My Number)"
  - `"03"` → "Residence Card"
  - `"06"` → "Passport"
  - `"11"`, `"12"`, `"13"`, `"42"` untuk IC Card codes
- **`liquidNationalityNames`** — Map ISO 3166-1 alpha-2 ke nama negara (30 countries)
  - `"ID"` → "Indonesia"
  - `"JP"` → "Jepang"
  - `"PH"`, `"BR"`, `"CN"`, `"KR"`, dll
- Helper functions: `resolveDocumentTypeName()`, `resolveNationalityName()`
- Extension `OcrResultsBeResponseMapping` dengan getter:
  - `documentTypeName`, `documentTypeDisplay` → `"Residence Card"`, `"Residence Card (03)"`
  - `nationalityName`, `nationalityDisplay` → `"Indonesia"`, `"Indonesia (ID)"`

#### c. Identity Card di Result Screen

Buat `_buildIdentityCard()` widget baru di result screen — card gradient primaryContainer di posisi prominent (setelah Status Summary). Tampilkan Nationality + Jenis Dokumen dengan auto-resolution.

---

### 8. Logging Enhancements

3 titik log baru untuk debugging:

| # | Lokasi | Tag Log | Level |
|---|--------|---------|-------|
| 1 | `kyc_be_api.dart` `OcrResultsBeResponse.fromMap` | `[OCR-Parse]` | info |
| 2 | `liquid_mappings.dart` `resolveDocumentTypeName/resolveNationalityName` (jika code ga dikenal) | `[OCR-Mapping]` | warning |
| 3 | `kyc_result_screen.dart` `_buildIdentityCard` | `[IdentityCard]` | info |

---

### 9. Bersihin Icon di Identity Card

User feedback: "icon di informasi ini hapus saja. NO AI SLOP."

Dihapus dari `_buildIdentityCard()` section:
- ❌ `Icons.fingerprint` (header card)
- ❌ `Icons.auto_awesome` (AUTO badge)
- ❌ `Icons.public` (label Nasionalitas)
- ❌ `Icons.credit_card` (label Dokumen)
- ❌ Icon di placeholder state

Hasil: text-only card, masih clean.

---

### 10. Fix Button "Selesai" → Balik ke Pengaturan Verifikasi

**File:** `lib/persentation/views/screens/kyc_home_screen.dart`

Sebelumnya: `Navigator.of(ctx).pop()` (cuma pop 1 level)
Sekarang: `Navigator.of(ctx).popUntil((route) => route.isFirst)` (pop sampai page pertama = `KycConfigScreen`)

Dua titik onDone fix (line 349 & 594).

---

### 11. Tab-Aware Identity Card dengan Cascading Fallback

#### a. ViewModel — tambah `_selectedNationality`
**File:** `lib/persentation/viewmodels/kyc_viewmodel.dart`

```dart
Nationality _selectedNationality = Nationality.indonesia;
Nationality get selectedNationality => _selectedNationality;
void setNationality(Nationality nationality) { ... }
```

#### b. ConfigScreen — persist nationality on submit
```dart
viewModel.setNationality(_nationality);  // tambah
```

#### c. Identity Card — tab-aware + fallback

**Tab SDK aktif:**
| Field | Sumber | Fallback |
|-------|--------|----------|
| Nationality | `viewModel.ocrResult?.nationality` | `viewModel.selectedNationality.displayName` |
| Document Type | (SDK ga ada) | `viewModel.selectedDocumentType.displayName` |
| Source tag | `"SDK + Config"` | |

**Tab BE aktif:**
| Field | Sumber | Fallback |
|-------|--------|----------|
| Nationality | `viewModel.beOcrResults?.nationality` | `viewModel.selectedNationality.displayName` |
| Document Type | `viewModel.beOcrResults?.idDocumentType` | `viewModel.selectedDocumentType.displayName` |
| Source tag | `"BE + Config"` | |

Label akhir (sesuai request):
- "Nationality" + code chip [ID/JP/PH/dll]
- "Jenis Dokumen" + code chip [01/02/03/dll]

Placeholder **dihapus total** karena minimum fallback ke user config selalu ada.

---

## 📊 Verifikasi

```bash
dart analyze → 0 error baru (semua warning pre-existing)
```

---

## 📂 Daftar File yang Diubah

| # | File | Perubahan |
|---|------|-----------|
| 1 | `lib/core/constant/liquid_constants.dart` | Tambah `enum Nationality` dengan `allowedDocuments` getter |
| 2 | `lib/app/app.dart` | `home:` → `KycConfigScreen`, hapus import dead |
| 3 | `lib/persentation/views/screens/kyc_config_screen.dart` | Rewrite: nationality dropdown flow, hardcoded COMPLY_HE, push HomeScreen, no icons |
| 4 | `lib/persentation/views/screens/kyc_home_screen.dart` | Hapus IconButton settings, fix onDone → popUntil(isFirst), hapus imports dead |
| 5 | `lib/persentation/viewmodels/kyc_viewmodel.dart` | Tambah `_selectedNationality`, allow-list MyNumber variants, `setNationality()` |
| 6 | `lib/data/services/kyc_be_api.dart` | Tambah `idDocumentType` field di `OcrResultsBeResponse`, log `[OCR-Parse]` |
| 7 | `lib/core/constant/liquid_mappings.dart` | (File baru) Map codes, helper functions, extension getter |
| 8 | `lib/persentation/views/screens/kyc_result_screen.dart` | Import provider + viewmodel, refactor Identity Card tab-aware, log `[IdentityCard]` |

**Total: 8 file (7 diubah + 1 baru)**

---

## 🧪 Testing Path

```
1. App launch → KycConfigScreen
2. Pilih Indonesia → tampil Residence Card saja
3. Pilih Jepang → tampil Driver's License + My Number
4. Submit → push KycHomeScreen
5. Masukkan Applicant ID → "Ambil Token & Mulai"
6. Verifikasi eKYC (IC scan + Face) → sampai ResultScreen
7. Cek tab SDK: Nationality & Jenis Dokumen resolved dari SDK + config fallback
8. Switch tab BE: Nationality & Jenis Dokumen resolved dari BE + config fallback
9. Tap "Selesai" → popUntil(isFirst) → balik ke KycConfigScreen
10. Buka Debug Log → cari tag [OCR-Parse], [OCR-Mapping], [IdentityCard]
```

---

## 💡 Keputusan Penting

1. **Hardcoded COMPLY_HE** — ga ada UI selection method, sesuai mandate project
2. **Nationality 2 negara saja** — Indonesia & Jepang, sesuai use case BNI yang fokus ke WNA Jepang
3. **My Number = Japanese resident ID** — bukan KTP Indonesia. Document type code `02` atau `12`
4. **Cascading fallback** (SDK/BE → user config) — minimum always ada data, ga ada placeholder
5. **Tab-source separation** — SDK & BE tab masing-masing reflect sumbernya, transparency ke user

---

## 🚀 Next Steps (untuk next session)

- [ ] Test di device Android beneran dengan kartu My Number fisik
- [ ] Confirm mapping `id_document_type` codes via real Liquid staging response
- [ ] Production mode: dynamic credentials dari BE (sudah ada code, perlu hardcoded credentials di `liquid_constants.dart`)
- [ ] Resolusi `id_document_type` codes yang belum ada di mapping table (mis. passport `"06"` perlu tambahan)

---

**Session End: 6 November 2026**
**Build Status: Clean (`dart analyze` 0 error)**
