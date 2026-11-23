# Constraints

Last reviewed: 2026-11-20

Aturan ini berlaku untuk SEMUA perubahan di project ini — manusia maupun agent.
Kalau satu aturan mau dilonggarkan, itu keputusan manusia yang eksplisit, bukan
ngarang sendiri.

## Floor (selalu berlaku, tanpa setup)

- **Nggak ngarang data domain.** Setiap tabel/daftar nilai yang berasal dari
  kartu, OCR, spec Liquid, atau API BE (kode status tinggal, label kebangsaan,
  daftar dropdown, tabel error, dst) **wajib punya sumber yang jelas di file
  yang sama**: nomor halaman spec PDF, nama endpoint BE, atau file + fungsi di
  host app. Tabel tanpa sumber = karangan → nggak boleh masuk.
  Dihapusin contoh: list "Visa Status" & "Nationality" yang dulu ditulis
  tanpa sumber (lihat `lib/core/constant/visa_status_mapping.dart`).
- Nggak ada suppression baru: `// ignore:`, `// ignore_for_file:`, `/* istanbul */`
- Nggak ada stub yang lempar: `UnimplementedError`, `throw StateError('TODO')`
- Nggak ada test yang di-skip atau dihapus tanpa alasan di commit message
- Nggak ada secret (API key, token, X-Ekyc-Api-key) di source
- File ini **nggak dilemahin** demi bikin sebuah perubahan lolos

## Enforced with numbers

| Dimension | Rule | Checked by | Runs at |
|-----------|------|-----------|---------|
| Types | Nol analyzer error | `fvm flutter analyze` | setiap edit |
| Lint | Nol issue dari `flutter_lints` | `fvm flutter analyze` | setiap edit |
| Tests | Semua test lolos | `fvm flutter test` | akhir task |
| Data domain | Nol tabel data tanpa sumber | `fvm flutter test test/no_invented_data_test.dart` | setiap edit |
| A11y kontras | Teks ≥ 4.5:1, komponen UI ≥ 3:1 | `fvm flutter test test/a11y_contrast_test.dart` | setiap edit |
| A11y semantics | Tiap input punya semantic label | `fvm flutter test test/ordering_information_a11y_test.dart` | setiap edit |
| PII di log | Nilai form nggak boleh masuk log | `fvm flutter test test/ordering_information_logging_test.dart` | setiap edit |
| Build | APK debug & release bisa dibuild | `fvm flutter build apk --release` | sebelum release |

Tiap baris nyebutin command yang ngasih verdict. Dimensi dengan angka tapi
nggak ada command-nya cumacita-cita, bukan constraint.

## Sumber kebenaran

| Data | Sumber |
|------|--------|
| Status tinggal (在留資格) → kode BE | `lib/core/constant/visa_status_mapping.dart` (ikut `caseVisaStatus()` host app) |
| Kode status tinggal/kode izin/limit kerja | `Liquid POC Docs/4. Connector API Specification (Common)/6. ...G05_APIマスターコード（APIGenericCode）_v1.4.3.pdf` |
| Kebangsaan (ISO alpha-2/alpha-3) | `lib/core/constant/liquid_mappings.dart` (tabel canonical Liquid, refs D5) |
| Field applicant ke BE (016) | `documents/SDK Function/[E]LIQUID_eKYC_016_RegisterApplicationInfoAPI_v1.3.2 (1).pdf` — + `Liquid POC Docs/5. .../17. Application Information Registration API v1.3.4.pdf` |
| Field OCR (013) | `documents/SDK Function/[E]LIQUID_eKYC_013_GetOCRResultsAPI_v1.8.8.pdf` — + `Liquid POC Docs/5. .../14. OCR result acquisition API v1.9.0.pdf` |
| Data dokumen dari Manager (007) | `Liquid POC Docs/5. .../8. API for obtaining identity verification document information v1.6.8.pdf` |
| Romanisasi nama server (027) | `Liquid POC Docs/5. .../27. KYC Additional Data Acquisition API v1.0.0.pdf` |
| Register hasil KYC (014) | `documents/SDK Function/[E]LIQUID_eKYC_014_RegisterKYCResultAPI_v1.4.2.pdf` |
| Field IC card (022) | `documents/SDK Function/[E]LIQUID_eKYC_022_GetICCardInfo_API_v1.3.9.pdf` |
| Kode dokumen & master code | `Liquid POC Docs/4. .../2. ...G01_API一覧（APIList）_v1.2.6.pdf` + `.../6. ...G05...pdf` |
| Aturan form host app | `mobileremittance2_upgrade_refactor_liquidekyc/lib/src/presentation/screens/register_account_screen/ordering_information_screen.dart` |
| Data uji nyata | `Result OCR NFC Digiremit.pptx` / `Result OCR NFC Digiremit v2.pptx` (log + screenshot 3 jenis kartu) |

## Pengecualian

| ID | Rule | Path | Alasan | Owner | Expires |
|----|------|------|--------|-------|---------|
| E1 | Tabel data domain wajib ada sumber | `lib/core/constant/app_colors.dart`, `lib/persentation/styles/app_theme.dart` | Token desain, bukan data domain | @admin | — |
| E2 | Tabel data domain wajib ada sumber | `lib/core/services/log_sanitizer.dart` | Daftar key sensitif, bukan nilai domain | @admin | — |
