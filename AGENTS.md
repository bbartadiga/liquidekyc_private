# AGENTS.md

> **Read `CONSTRAINTS.md` before writing code. Do not weaken it to make a change pass.**

Project ini: module Liquid eKYC (Flutter, Android-only) — wrapper SDK Liquid
untuk flow registrasi akun + eKYC Digiremit.

## Peta singkat

| Area | Lokasi |
|------|--------|
| Public API module | `lib/module_liquid.dart` |
| Entry point app | `lib/main.dart`, `lib/app/app.dart` |
| Screens | `lib/persentation/views/screens/` |
| Widgets form registrasi | `lib/persentation/views/widgets/app_*.dart` |
| ViewModel | `lib/persentation/viewmodels/` |
| Konstanta & mapping domain | `lib/core/constant/` |
| Spec PDF Liquid | `documents/SDK Function/` |

## Yang wajib dicek sebelum commit

```bash
fvm flutter analyze          # nol issue
fvm flutter test             # semua lolos
```

Guard tambahan yang sudah otomatis (ada di `test/`):
- `no_invented_data_test.dart` — tabel data domain wajib ada sumber
- `a11y_contrast_test.dart` — kontras warna WCAG AA
- `ordering_information_a11y_test.dart` — semantic label tiap input
- `ordering_information_logging_test.dart` — nilai form nggak boleh masuk log

## Aturan yang paling sering dilanggar

1. **Nggak ngarang data domain.** Kode status tinggal, label kebangsaan,
   daftar dropdown — semua harus nyontek dari spec PDF / API BE / kode host app,
   dan sumbernya ditulis di doc comment tabelnya.
2. **Nggak ngarang API host app.** Modul ini cuma ngomong ke Liquid Connector
   API (`LiquidConfig.beUrl`). Endpoint host app (Digiremit) itu urusan host
   app — kalau butuh, kirim datanya lewat callback, jangan bikin koneksi
   sendiri.
3. **PII nggak boleh masuk log.** Nilai form (nama, alamat, no. kartu, DOB)
   nggak ditulis ke `appLogger`.
