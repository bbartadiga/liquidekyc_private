# eKYC WebView Flow

## Overview

App Flutter membuka halaman eKYC milik ProTech via WebView. Proses ini melibatkan download app tambahan (ProTech IC Authentication) dan autentikasi kartu IC via NFC.

---

## User Flow

```
[App Flutter]
     │
     ▼
[WebView: kycpoc.duckdns.org/kycpoc.html]
     │
     ├─ Step 1: Klik tombol Google Play
     │    └─► Play Store dibuka (install ProTech IC Authentication)
     │
     └─ Step 2: Klik tombol Continue (setelah install)
          │
          ▼
     [window.open() → android.html]
          │
          ▼
     [Chrome Custom Tab: app.protechidchecker.com/jpki/android.html]
          │
          ▼
     [ProTech IC Authentication App dibuka]
          │
          ▼
     [User tap kartu IC ke NFC]
          │
          ▼
     [Autentikasi selesai → user kembali ke app]
```

---

## Masalah & Solusi

### Masalah 1: Play Store terbuka di dalam WebView

**Sebab:** `shouldOverrideUrlLoading` default membiarkan semua URL https di-load di WebView, termasuk `play.google.com`.

**Solusi:** Intercept URL Play Store dan `market://` → launch via `url_launcher` dengan `LaunchMode.externalApplication`.

---

### Masalah 2: Tombol "Continue" tidak membuka ProTech app

**Sebab:** Halaman `android.html` menggunakan `window.open()` untuk membuka halaman launcher ProTech. `window.open()` tidak tertangkap oleh `shouldOverrideUrlLoading` — perlu handler `onCreateWindow` dengan child WebView bertindak sebagai popup receiver.

**Solusi:** Tambah `onCreateWindow` handler + buat invisible popup WebView menggunakan `windowId` dari event tersebut.

---

### Masalah 3: ProTech app tidak terlaunched dari popup WebView

**Sebab:** Header HTTP `Sec-CH-UA` selalu berisi `"Android WebView"` saat berjalan di WebView engine — tidak bisa di-override meski User-Agent string diubah. Halaman ProTech mendeteksi ini dan **mematikan** fitur deep link ke native app.

```
// Header yang dikirim WebView (tidak bisa diubah dari Flutter)
sec-ch-ua: "Chromium";v="146", "Not-A.Brand";v="24", "Android WebView";v="146"

// Header yang dikirim Chrome (yang dibutuhkan ProTech)
sec-ch-ua: "Chromium";v="124", "Not-A.Brand";v="24", "Google Chrome";v="124"
```

**Solusi:** Buka `android.html` di **Chrome Custom Tab** (`LaunchMode.inAppBrowserView`) bukan di WebView. Chrome Custom Tab berjalan di proses Chrome asli sehingga `Sec-CH-UA` menunjukkan `"Google Chrome"`.

---

## Arsitektur Kode

```
EkycWebViewPage (StatefulWidget)
│
├─ InAppWebView (main)
│   ├─ userAgent: Chrome UA (hilangkan "(wv)")
│   ├─ supportMultipleWindows: true
│   ├─ shouldOverrideUrlLoading
│   │   ├─ market:// / play.google.com → launchUrl (external)
│   │   ├─ non http/https → launchUrl (external)
│   │   └─ redirect signal URL → Navigator.pop (verifikasi selesai)
│   └─ onCreateWindow → buat _PopupWebView dengan windowId
│
└─ _PopupWebView (invisible, dialog)
    ├─ windowId: (dari onCreateWindow)
    └─ shouldOverrideUrlLoading
        ├─ app.protechidchecker.com → Chrome Custom Tab ← KUNCI
        ├─ market:// / play.google.com → launchUrl (external)
        └─ https lain → ALLOW
```

---

## Konfigurasi AndroidManifest.xml

```xml
<queries>
    <!-- Play Store -->
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="market"/>
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="https" android:host="play.google.com"/>
    </intent>
    <!-- Deep link ke native app (custom scheme) -->
    <intent>
        <action android:name="android.intent.action.VIEW"/>
    </intent>
</queries>
```

---

## Dependencies

```yaml
flutter_inappwebview: ^6.1.5   # WebView dengan onCreateWindow support
url_launcher: ^6.3.2           # Launch external URL / Chrome Custom Tab
```