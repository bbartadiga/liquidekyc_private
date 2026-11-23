# Ketersediaan Data per Jenis Kartu — Liquid eKYC (COMPLY_HE)

Dokumen ini menjelaskan **field apa yang Available dari sumber mana, untuk tiap jenis kartu**,
supaya tim tahu saat data kosong itu **memang tidak ada** (bukan bug) atau **sumbernya belum dipanggil**.

> Dibuat: 2026-11-23 · Sumber: spec resmi Liquid Connector/Applicant SDK + log uji device user Tokyo (19 Nov 2026)

---

## 0. Ringkasan cepat

| | Residence Card (Gen 1) | Residence Card (Gen 2) | Driver's License | My Number Card |
|---|---|---|---|---|
| Kode dokumen (G05) | `13` (He) / `03` (Ho) | `01036`+ | `11` (He) / `01` (Ho) | `12` (He) / `02` (Ho) |
| OCR (013) | ✅ **lengkap** | ⚠️ hanya nama + DOB | ✅ tapi tanpa kebangsaan & gender | ✅ tapi tanpa no. dokumen & kebangsaan |
| IC Chip (022) | ✅ data standar | ✅ **+ data residence (kode)** | ✅ + data SIM | ✅ + My Number |
| OCR BE (013 via BE) | ✅ | ✅ | ❌ 409 CE00019 | ❌ 409 CE00019 |
| Field form yang keisi | **12 / 13** (tertes) | belum dites device | **5 / 13** (tertes) | **5 / 13** (tertes) |

**Field yang benar-benar TIDAK ADA di kartu DL & MN** (bukan bug, emang nggak ada di kartunya):
`resident_status` (在留資格), `stay_period`, `stay_expire_date`, `permitted_date`,
`kind_of_permission`, `employment_restriction`, `nationality`, dan `id_number` (untuk My Number Card).

Yang **bisa** diisi ulang nanti: `resident_status` + `stay_expire_date` lewat **API 007** (kalau
nilainya sudah didaftarkan/di-koreksi di **eKYC Manager** sisi Liquid).

---

## 1. Matriks OCR — sumber utama form

**Sumber:** `Liquid POC Docs/5. Connector API Specification (Individual)/14. OCR result acquisition API - LIQUID_eKYC_013_OCR結果取得API_v1.9.0.pdf` **hal. 21**

Legenda: **○** wajib · **△** mungkin dikembalikan · **×** tidak dikembalikan

| # | Field (JSON) | 運転免許証 | マイナンバーカード | 在留カード | パスポート | 運転経歴証明書 | 特別永住者証明書 | 学生証/手帳/保険証 | 第2世代在留カード等 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `id_document_type` | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| 2 | `name` | △ | △ | △ | △ | △ | △ | △ | △ |
| 3 | `birthday` | △ | △ | △ | △ | △ | △ | △ | △ |
| 4 | `address` | △ | △ | △ | × | △ | △ | × | **×** |
| 5 | `id_number` | △ | **×** | △ | △ | △ | △ | × | **×** |
| 6 | `expire_date` | △ | △ | △ | △ | × | △ | × | **×** |
| 7 | `nationality` | **×** | **×** | △ | △ | × | △ | × | **×** |
| 8 | `nationality_code3` | **×** | **×** | △ | △ | × | △ | × | **×** |
| 9 | `sex` | **×** | △ | △ | △ | × | △ | × | **×** |
| 10 | `zip_code` | △ | △ | △ | × | △ | △ | × | **×** |
| 11 | `address_pref` | △ | △ | △ | × | △ | △ | × | **×** |
| 12 | `address_city` | △ | △ | △ | × | △ | △ | × | **×** |

**Artinya:**
- **Gen-2**: OCR cuma memberi nama + DOB → semua data residence (status tinggal, stay period,
  permitted date, kebangsaan, zip, alamat pecah) **harus dari IC chip**.
- **Driver's License**: OCR **tidak** memberi kebangsaan maupun jenis kelamin.
  Gender di form cuma bisa dari chip (dan **tidak selalu ada** → kadang kosong, sesuai log 20 Nov).
- **My Number Card**: OCR **tidak** memberi nomor dokumen (identifier-nya My Number) maupun kebangsaan.

---

## 2. Matriks IC Chip (022) — data yang dibaca dari kartu fisik

**Sumber:** `Liquid POC Docs/5. Connector API Specification (Individual)/22. IC Card Reading Information Acquisition API - LIQUID_eKYC_022_ICカード読取情報取得API_v1.4.2.pdf`
**hal. 4** (field Gen-2 yang ditambahkan di v1.4.0) · **hal. 66–68** (format nama per jenis kartu)

| Field (JSON) | RC Gen 1 | RC Gen 2 | DL | MN | Keterangan |
|---|---|---|---|---|---|
| `name`, `name_kana` | ✓ | ✓ | ✓ (half-width latin) | ✓ | Format nama per kartu: hal. 66–68 |
| `birthday` | ✓ | ✓ | ✓ | ✓ | |
| `address` (penuh, **tidak** dipecah) | ✓ | ✓ | ✓ | ✓ | `address_pref/city/other` **tidak** ada di chip |
| `id_number` | ✓ | — | ✓ | **✗** | MN identifier = `my_number` |
| `expire_date` | ✓ | ✓ | ✓ | ✓ | |
| `sex` | ✓ | ✓ | ✓ | ✓ | Satu-satunya sumber gender utk DL |
| `zip_code` | ✓ | ✓ | ✓ | ✓ | |
| `my_number` | ✗ | ✗ | ✗ | ✓ | My Number 12 digit |
| `drivers_license_types` / `_conditions` / `_remarks` / `_obtained_dates` | ✗ | ✗ | ✓ | ✗ | termasuk `普通` |
| `psc_name` (penerbit SIM) | ✗ | ✗ | ✓ | ✗ | 例 `東京都公安委員会` |
| `issue_date` | ✓ | ✓ | ✓ | ✓ | |
| **`residenceDocumentGen2.*`** (sub-object, **Gen-2 saja**) | ✗ | ✓ | ✗ | ✗ | `nationality_code`, `residence_status_code`, `kind_of_permission_code`, `employment_restriction`, `stay_period_year/months/day`, `stay_expire_date`, `permitted_date`, `stay_update_status`, `individual_permission`, `comprehensive_permission_code` |

> Catatan: untuk RC & kartu special-permanent, **nama di IC chip berupa data gambar** (bukan teks)
> → format nilainya mengikuti OCR (hal. 66).

---

## 2b. Kekhususan Residence Card Gen-2

**Sumber utama:**
`Liquid POC Docs/17. 2nd Generation Residence Card_Specified Residence Card/`

| # | File | Halaman | Isi |
|---|---|---|---|
| A | `1. Information on LIQUID eKYC Support Due to System Changes for the 2nd Generation Residence Card and Specified... .pdf` | **4–6** | Perbandingan **data IC** per kartu (**hal. 6 = matriks IC**) & desain券面 (hal. 4–5) |
| | | 2 | "Connector API → butuh dukungan **kode dokumen baru**; SDK → butuh update (**auto-detect** kartu)" |
| B | `2. (Materials for Businesses) Second-Generation Specified Residence Card Overview and Specifications -（事業者様向け資料）第二世代在留特定在留カード全体概要仕様.pdf` | **1** | Kenapa bedanya: 일부 data residence jadi **teks di IC chip (在留AP)**; **券面表面画像 dihapus** → diganti gambar nama & gambar alamat → nama/alamat tetap butuh OCR |
| | | 2 | SDK **auto-detect** 在留/特永/第2世代/特定在留 (jadi app **nggak perlu** pilih manual, kecuali 特定在留/特定特別永住 yang wajib dipilih bisnis) |
| | | 3 | Tabel **data per kartu**: Gen-2 → IC(在留AP) untuk 生年月日/有効期限/在留資格/在留期限/国籍; OCR untuk 氏名/住所 (dari 券面事項入力補助AP) |
| | | 4 | Perubahan request/response `verifyIdChip()` |

### Yang berubah di Gen-2 (dampak ke app)

| Aspek | Gen-1 | Gen-2 |
|---|---|---|
| Sumber data residence | **OCR** | **IC chip (在留AP)** |
| Nama & alamat | OCR (teks) | OCR atau **券面事項入力補助AP** (teks) |
| Gambar券面 depan | Ada (bisa di-OCR) | **DIHAPUS** → ganti gambar nama + gambar alamat |
| Field yang dikirim ke BE (016) | varian **teks** | varian **KODE** (`resident_status_code`, `stay_period_year/month/day`, `kind_of_permission_code`) |
| `nationality` alpha-2 | dari OCR | **tidak ada** di SDK → BE 022 yang mengonversi 3-digit → 2-digit |

### Nama field: SDK vs BE (Dua layer, nama beda!)

| Data | SDK (Kotlin, camelCase — dibaca app) | BE 022 (JSON, snake_case) |
|---|---|---|
| Status tinggal | `residenceStatusCode` | `residence_card_resident_status_code` |
| Stay period | `stayPeriodYear` / `stayPeriodMonths` / `stayPeriodDay` | `residence_card_stay_period_year` / `_month` / `_day` |
| Stay expiry | `stayExpireDate` | `residence_card_stay_expire_date` |
| Permitted date | `permittedDate` | `residence_card_permitted_date` |
| Limit kerja | `employmentRestriction` | `residence_card_employment_restriction_code` |
| Kebangsaan | `nationalityCode` | `nationality` (alpha-2) + `nationality_code3` (alpha-3) |
| Jenis kartu | `liquidDocumentType` / `liquidResidenceCardType` | `residence_card_type` (1/2/5/6/7/8) |

> Verifikasi nama field SDK: AAR `android/app/libs/Liquid-1.47.0.aar` →
> `asia/liquidinc/ekyc/applicant/external/result/chip/ResidenceDocumentGen2Data.class`
> (nama property: `residenceStatusCode`, `stayPeriodYear`, `stayPeriodMonths`,
> `stayPeriodDay`, `permittedDate`, `employmentRestriction`, `stayExpireDate`,
> `stayUpdateStatus`, `nationalityCode`).

---

## 3. Tabel gabungan: per field × per kartu × per sumber

Legend: **✓** tersedia · **✗** tidak ada · **(kosong)** ada tapi isninya belum diimplementasikan

| Field form | OCR SDK | IC Chip SDK | OCR BE | BE 007 | BE IC Card Info | RC Gen1 | RC Gen2 | DL | MN |
|---|---|---|---|---|---|---|---|---|---|
| Residency Card Number | △ | ✓ | △ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Expired Date | △ | ✓ | △ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Nationality | △ | ✗ | △ | ✗ | ✗ | ✓ | ✓ (code 3-digit) | ✗ | ✗ |
| Visa Status (在留資格) | △ | ✓ (Gen-2: kode) | △ | ✓ | ✗ | ✓ | ✓ | ✗ | ✗ |
| Permission to Land (permitted date) | △ | ✓ (Gen-2) | △ | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ |
| Period to Stay (stay expire) | △ | ✓ (Gen-2) | △ | ✓ | ✗ | ✓ | ✓ | ✗ | ✗ |
| Ordering Customer Name (ENGLISH) | △ | ✓ | △ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Date of Birth | △ | ✓ | △ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Gender | △ | ✓ | △ | ✗ | ✗ | ✓ | ✓ | ✓ (tidak selalu) | ✓ |
| Postal Code | △ | ✓ | △ | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ |
| Address 1 (pref + city) | △ | ✗ (tidak dipecah) | △ | ✓ (penuh) | ✗ | ✓ (pref+city) | ? | ✓ (penuh) | ✓ (penuh) |
| Address 2 (other) | △ | ✗ | △ | ✗ | ✗ | ✓ | ? | ✗ | ✗ |
| Address 3 (building) | — | — | — | — | — | (opsional, kosong) | (opsional, kosong) | (opsional, kosong) | (opsional, kosong) |

### Kenapa "Address 2" kosong untuk DL & MN?
Chip & BE IC Card Info **tidak** memecah alamat (hanya satu string penuh) → Address 1 diisi alamat penuh,
Address 2/3 kosong. Lihat `ApplicantInfoPayload._splitAddress` (spec 016 hal. 6, `address1` = pref).

---

## 4. Sumber data lain (BE)

| API | Endpoint | Isi | Dipakai untuk |
|---|---|---|---|
| **016** RegisterApplicationInfo | `POST /v1/kyc_request_informations` | Mendaftarkan applicant + data kartu | Kirim field kartu tinggal (RC/Gen-2) |
| **022** GetICCardInfo | `GET /v1/applicants/{id}/id_document_ic_information` | Salinan data IC card dari BE | Fallback data chip |
| **013** GetOCRResults | `GET /v1/applicants/{id}/ocr_results` | Hasil OCR (kalau client type punya akses) | Fallback OCR |
| **007** GetIDDocumentInfo | `GET /v1/applicants/{id}/id_document_information` | Data yang **di-koreksi di eKYC Manager**: nama, DOB, alamat, `stay_expire_date`, `resident_status` | Mengisi gap DL/MN tanpa input manual |
| **027** GetProcessedInformation | `GET /v1/applicants/{id}/processed_information` | `latin_name` = romanisasi nama **server Liquid** | "Ordering Customer Name (ENGLISH)" akurat |
| **014** RegisterKYCResult | `POST /v1/kyc_results` | Menandai KYC selesai → memicu auto-masking | Dipanggil setelah form selesai |

> **Kenapa OCR BE 409 untuk DL & MN?**
> `CE00019 ocr is not available for client_type=2, id_doc_type=11/12` → OCR **tidak diaktifkan** untuk
> client type BNI pada jenis dokumen itu. Sumber: log user 19–20 Nov + spec 013 hal. 5.

> **007 "data yang di-koreksi di Manager"** — spec 007 hal. 5: *"氏名 / 生年月日 / 住所 / 在留期間の満了日 /
> 在留資格 = Manager データ修正機能で修正した値"*. Kalau belum pernah dikoreksi → `null`.
> Artinya: **gap DL/MN hanya bisa ditutup dari sisi Liquid/operator**, bukan dari app.

---

## 5. Field yang dikirim ke BE (016) — spec 016 v1.3.4

| # | Field | Berlaku untuk | Sumber data app |
|---|---|---|---|
| 18 | `resident_status` | **在留カード saja** | OCR (RC Gen 1) |
| 19 | `resident_status_code` | **Gen-2 saja** | IC Chip (`residenceDocumentGen2`) |
| 20 | `stay_period` (format `Y年M月`/`Y年`/`M月`) | **在留カード saja** | OCR |
| 21–23 | `stay_period_year` / `_month` / `_day` | **Gen-2 saja** | IC Chip |
| 24 | `stay_expire_date` | RC + Gen-2 + 特定在留 | OCR / IC Chip |
| 25 | `permitted_date` | RC + Gen-2 + 特定在留 | OCR / IC Chip |
| 26 | `kind_of_permission` (enum: 上陸許可/永住許可/在留期間更新許可/在留資格変更許可/在留特別許可) | **在留カード saja** | OCR |
| 27 | `kind_of_permission_code` | **Gen-2 + 特定在留** | IC Chip |
| 28 | `employment_restriction` (enum: 就労制限なし/在留資格に基づく就労活動のみ可/…/就労不可) | **在留カード saja** | OCR |

→ Untuk **DL & MN, tidak ada satu pun field di atas yang berlaku** (semua "在留カードのみ").

---

## 6. Referensi dokumen (path → file → halaman)

Semua path relatif ke `Documents/BNI/Digiremit/Liquid POC Docs/` atau `module_liquid_ekyc/documents/`.

| Topik | Path | File | Halaman |
|---|---|---|---|
| Matriks OCR per jenis kartu | `Liquid POC Docs/5. Connector API Specification (Individual)/` | `14. OCR result acquisition API - LIQUID_eKYC_013_OCR結果取得API_v1.9.0.pdf` | **21** (matriks), 5 (URL + CE00019), 6–12 (field response), 13 (contoh JSON) |
| Field IC chip + Gen-2 | `Liquid POC Docs/5. Connector API Specification (Individual)/` | `22. IC Card Reading Information Acquisition API - LIQUID_eKYC_022_ICカード読取情報取得API_v1.4.2.pdf` | **4** (field Gen-2 v1.4.0), 66–68 (format nama), 5–65 (daftar field) |
| Field applicant ke BE (016) | `Liquid POC Docs/5. Connector API Specification (Individual)/` | `17. Application Information Registration API - LIQUID_eKYC_016_申請情報登録API_v1.3.4.pdf` | **7** (field 18–23), **8** (field 24–28), 5–6 (field 1–17 + alamat), 13–14 (contoh) |
| Data dari eKYC Manager (007) | `Liquid POC Docs/5. Connector API Specification (Individual)/` | `8. API for obtaining identity verification document information - LIQUID_eKYC_007_本人確認書類情報取得API_v1.6.8.pdf` | **5** (URL + error), 5–6 (field + contoh) |
| Romanisasi nama server (027) | `Liquid POC Docs/5. Connector API Specification (Individual)/` | `27. KYC Additional Data Acquisition API - LIQUID_eKYC_027_kyc追加データ取得API_v1.0.0.pdf` | 2 (URL), **3–4** (`latin_name` + contoh) |
| Master code (sex, status tinggal, izin, kebangsaan, kode dokumen) | `Liquid POC Docs/4. Connector API Specification (Common)/` | `6. LIQUID_eKYC_G05_APIマスターコード（APIGenericCode）_v1.4.3.pdf` | **4** (sex), **16** (kode dokumen), **37** (在留資格コード表), **39** (許可の種類コード表), **41** (国籍コード表) |
| Daftar API (G01) | `Liquid POC Docs/4. Connector API Specification (Common)/` | `2. LIQUID_eKYC_G01_API一覧（APIList）_v1.2.6.pdf` | — |
| Register hasil KYC (014) | `module_liquid_ekyc/documents/SDK Function/` | `[E]LIQUID_eKYC_014_RegisterKYCResultAPI_v1.4.2.pdf` | **1** (URL `/v1/kyc_results`), 2 (body) |
| Bukti empiris di device | `~/Downloads/` | `liquid_kyc_all_logs_20261120_1843.txt` (RC), `_1850.txt` (DL), `_1903.txt` (MN) | — |
| Bukti visual | `~/Downloads/` | `Result OCR NFC Digiremit v2.pptx` slide 13–16 | — |

---

## 7. Implikasi ke halaman Ordering Information

1. **Field kosong = memang tidak ada**, bukan bug mapping. Kalau user protes "field X kosong", cek tabel di atas.
2. **DL**: `Nationality` & `Visa Status` memang tidak ada di kartu → otomatis disembunyikan kalau nationality bukan Indonesia.
3. **MN**: `Residency Card Number` kosong → identifier-nya **My Number** (`my_number`), tidak ada di form versi sekarang.
4. **DL & MN**: `Gender` dari chip **tidak selalu ada** →(form menampilkan "Choose Gender" → user pilih manual).
5. **Gen-2**: butuh chip **dan** subdomain `residenceDocumentGen2`; `ResidenceDocumentGen2.isEmpty` sempat hanya
   mengecek 4 dari 12 field → Gen-2 terdeteksi "kosong" (sudah dibetulkan).
6. Kalau gap DL/MN mau ditutup tanpa input manual: **daftarkan dulu datanya di eKYC Manager**,
   lalu app ambil lewat **API 007**.

---

## 8. Yang belum terverifikasi / gap yang tersisa

- **Gen-2 belum pernah dites di device.** Semua angka Gen-2 di dokumen ini berasal dari spec
  (017 folder 17 + 022 v1.4.2 + 016 v1.3.4 + 013 v1.9.0), belum dari log device.
  Setelah ada tester Gen-2, update tabel bagian 2 & 2b.
- **`nationality` alpha-2 untuk Gen-2** — chip (SDK 1.47.0) hanya punya `nationalityCode`;
  alpha-2-nya dikonversi oleh **BE 022** (`nationality` ← 3digit→2digit).
 -App memanggil BE-1 (016) **sebelum** BE-4 (022), jadi saat 016 dipanggil alpha-2 belum ada
  → butuh tabel alpha-3 → alpha-2 lokal (sumber: G05 hal. 41). **Belum dikerjakan.**
- **`Address 1` Gen-2** — 013 (hal. 21) bilang `address`/`address_pref`/`address_city` = ×,
  tapi 022 (hal. 6) bilang teks alamat "返却なし（ただし OCR から取得可）" → tidak konsisten, perlu diuji.
- **Kartu `特定在留カード` / `特定特別永住者証明書`** — residence info-nya ada di dalam **MN card**
  (在留AP), dan **wajib dipilih bisnis** sebelum baca (017 folder 17, doc 2 hal. 2).
  Belum ada di scope module sekarang.
