# Conversion Plan: `module_liquid_ekyc` → Flutter Plugin Package

> Target: Memindahkan native Android plugin (Liquid SDK + 5 AAR + Kotlin handlers) keluar dari
> struktur "app" ke struktur "plugin package" agar `GeneratedPluginRegistrant` di main project
> auto-register `LiquidEkycPlugin` tanpa edit `MainActivity.kt` manual.

---

## 1. Status Quo (Verified)

### Module (`module_liquid_ekyc/`)

| Item | Path | Catatan |
|---|---|---|
| Pub name | `pubspec.yaml` → `name: module_liquid` | ✅ Match import di main project |
| Plugin Kotlin | `android/app/src/main/kotlin/id/co/bni/mobile_remittance_kcln_tokyo/liquid_ekyc/` | ✅ **FIXED 2026-10-02** — 6 files moved + package decl header konsisten |
| MainActivity module | `android/app/src/main/kotlin/com/example/module_liquid_ekyc/MainActivity.kt` extends `FlutterFragmentActivity` | ✅ **FIXED 2026-10-02** — `package` decl + FQCN reference updated ke namespace baru |
| ProGuard keep-rule | `android/app/proguard-rules.pro` | ✅ **FIXED 2026-10-02** — `-keep class id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc.**` |
| Liquid SDK AARs | `android/app/libs/` | 5 file: `Liquid-1.47.0.aar`, `LiquidPluginMl-1.0.0.aar`, `androidtiffbitmapfactory-0.9.8.7.3.aar`, `itrustekyclibrary.aar`, `jp2-android-1.0.2.2.aar` |
| Manifest Liquid activities | `android/app/src/main/AndroidManifest.xml` | 5 activity Liquid termaktub |
| Demo runtime app | `lib/main.dart` + `lib/app/app.dart` (`LiquidEkycApp`) + 5 screens di `lib/persentation/views/screens/` (`kyc_config`, `kyc_home`, `kyc_instruction`, `kyc_result`, `kyc_token`) | Redundant karena main project udah pakai `EkycScreen` sendiri |
| Public API exports | `lib/module_liquid.dart` | Export `LiquidEkycApp`, models, viewmodel, screens |
| Channel name | `com.liquid.ekyc/channel` di `LiquidConfig` | Channel string **tidak berubah** |
| SDK constraint | `pubspec.yaml` → `sdk: ^3.10.0-290.4.beta` (Dart 3) | Lebih longgar dari main project |

### Main Project (`mobileremittance2_upgrade_refactor_liquidekyc/`)

| Item | Path | Catatan |
|---|---|---|
| Import module | `pubspec.yaml` → `module_liquid: path: ../module_liquid_ekyc` | ✅ Sudah |
| Dart import | `lib/src/presentation/screens/register_account_screen/ekyc_screen.dart` → `import 'package:module_liquid/module_liquid.dart'` | ✅ Sudah |
| MainActivity | `android/app/src/main/kotlin/id/co/bni/mobile_remittance_kcln_tokyo/MainActivity.kt` extends `FlutterActivity` | ❌ Tidak register plugin + extend parent salah (perlu `FlutterFragmentActivity` untuk IC Card) |
| Native plugin | — | ❌ File `LiquidEkycPlugin.kt` **tidak ada** (penyebab asli `MissingPluginException`) |
| Manifest Liquid activities | `android/app/src/main/AndroidManifest.xml` | ❌ 5 activity Liquid **tidak ada** (penyebab `ClassNotFoundException` saat launcher dipanggil) |
| Permission NFC | `android/app/src/main/AndroidManifest.xml` | ❌ Tidak ada (penyebab `NFC unavailable` di IC Card flow) |
| SDK constraint | `pubspec.yaml` → `sdk: ">=2.12.0 <3.0.0"` (Dart 2) | Benturan sama module Dart 3 — perlu dilonggarin |
| Application ID / namespace | `co.id.bni.digiremittky` / `id.co.bni.mobile_remittance_kcln_tokyo` | BNI-branded |

---

## 2. Decisions (Locked)

| # | Decision | Value | Rationale |
|---|---|---|---|
| 1 | **Kotlin package namespace baru** | `id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc` | Match main project namespace `id.co.bni.mobile_remittance_kcln_tokyo` + suffix `.liquid_ekyc` agar nested cleanly |
| 2 | **Demo runtime app** | **Pindah ke `example/`** | Best practice Flutter plugin; memungkinkan testing independen via `flutter run -d <device>` di `example/` |
| 3 | **SDK constraint module** | Loosen ke `sdk: ">=3.0.0 <4.0.0"` + `flutter: ">=3.10.0"` | Dart 3 sudah dipakai main project (`flutter_bloc: ^9.1.1` butuh Dart 3) |
| 4 | **iOS scope** | **Android only** | Sesuai scope task saat ini; folder `ios/` di module kosongkan / hapus |
| 5 | **Plugin dependencies** | `androidx.activity:activity-ktx:1.9.3`, `androidx.lifecycle:lifecycle-runtime-ktx:2.8.7`, `com.google.mlkit:text-recognition-japanese:16.0.1`, lokal AAR via `flatDir` | Yang dipakai `SdkManager.kt` + `LiquidEkycPlugin.kt` |
| 6 | **Channel name** | `com.liquid.ekyc/channel` (unchanged) | Konsisten dengan Liquid SDK existing |
| 7 | **`publish_to`** | `'none'` | Tetap private, tidak dipublish ke pub.dev |

---

## 3. Target Structure

```
module_liquid_ekyc/
├── pubspec.yaml                          # DEPS: flutter.plugin.platforms.android.package
├── lib/
│   ├── module_liquid.dart                # public API (unchanged exports)
│   ├── core/                             # core/, data/, persentation/ kept as-is (consumed by example)
│   ├── data/
│   └── persentation/
├── android/
│   ├── build.gradle.kts                  # TOP-LEVEL plugin loader (not app-style)
│   ├── settings.gradle.kts               # include :liquid_ekyc (was :app)
│   ├── gradle.properties
│   └── src/main/
│       ├── AndroidManifest.xml           # 5 Liquid activities + NFC permission (daripada app/ yang lama)
│       ├── kotlin/id/co/bni/mobile_remittance_kcln_tokyo/liquid_ekyc/
│       │   ├── LiquidEkycPlugin.kt       # package id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc
│       │   ├── SdkManager.kt             # (was com.example.poc_liquidekyc_flutter.plugins — to refactor)
│       │   ├── InitHandler.kt
│       │   ├── TermsHandler.kt
│       │   ├── VerificationHandler.kt
│       │   └── FinalizeHandler.kt
│       └── libs/
│           ├── Liquid-1.47.0.aar
│           ├── LiquidPluginMl-1.0.0.aar
│           ├── androidtiffbitmapfactory-0.9.8.7.3.aar
│           ├── itrustekyclibrary.aar
│           └── jp2-android-1.0.2.2.aar
├── example/                              # NEW — pindahan demo runtime
│   ├── pubspec.yaml
│   ├── lib/
│   │   └── main.dart
│   ├── android/                          # standard Flutter app shell
│   └── README.md
└── CONVERSION_PLAN.md                    # this file
```

**Yang dihapus:**
- `android/app/` (seluruh folder app host)
- `lib/main.dart` (pindah ke `example/lib/main.dart`)
- `lib/app/app.dart` bisa tetap (dipakai example + referensi) atau ikut pindah ke `example/lib/`

**Yang berubah:**
- Header `package com.example.poc_liquidekyc_flutter.plugins` di 6 file Kotlin → `package id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc` ✅ Done
- Reference `com.example.poc_liquidekyc_flutter.plugins.LiquidEkycPlugin` di MainActivity module (yang dihapus) — tidak relevan lagi karena auto-register ✅ Done (file moved + FQCN updated)
- SDK constraint pubspec ⬜ pending step 7

---

## 4. Execution Steps

> ✅ = sudah selesai · ⬜ = belum

### Step 1 — Create new `android/app/src/main/kotlin/.../liquid_ekyc/` folder
✅ **Done 2026-10-02.** Note: folder masih di bawah `android/app/src/main/kotlin/...` (bukan `android/src/main/kotlin/...`) karena struktur app host belum dihapus. Path final akan relocate saat Step 7 (delete `android/app/`).

### Step 2 — Move 6 Kotlin source files & fix package declarations
✅ **Done 2026-10-02.**
- 6 files: `LiquidEkycPlugin.kt`, `SdkManager.kt`, `InitHandler.kt`, `TermsHandler.kt`, `VerificationHandler.kt`, `FinalizeHandler.kt`
- Moved: `android/app/src/main/kotlin/com/example/module_liquid_ekyc/plugins/` → `android/app/src/main/kotlin/id/co/bni/mobile_remittance_kcln_tokyo/liquid_ekyc/`
- Edited `package` header: `com.example.poc_liquidekyc_flutter.plugins` → `id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc`
- Side-effect: `MainActivity.kt` FQCN updated dari `com.example.poc_liquidekyc_flutter.plugins.LiquidEkycPlugin` → `id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc.LiquidEkycPlugin`
- Side-effect: `proguard-rules.pro` keep-rule updated untuk package baru
- Folder kosong `com/example/module_liquid_ekyc/plugins/` di-rmdir
- Verified: grep terhadap source files (exclude build/) tidak ada lagi reference ke package lama

### Step 3 — Update `SdkManager.kt` internal reference
Cek apakah ada `internal` reference ke `SdkConfig` yang masih pakai path lama — tidak ada (semua internal class ada di package yang sama, mengikuti). Konfirmasi via compile.

### Step 4 — Move Liquid activities + NFC permission dari app Manifest ke plugin Manifest

**Source:** `android/app/src/main/AndroidManifest.xml` — block:
```xml
<uses-permission android:name="android.permission.NFC"/>
<uses-permission android:name="android.permission.VIBRATE"/>
...
<uses-feature android:name="android.hardware.camera" android:required="true"/>
<uses-feature android:name="android.hardware.nfc" android:required="false"/>
...
<activity android:name="asia.liquidinc.ekyc.applicant.termsofuse.TermsOfUseActivity" .../>
<activity android:name="asia.liquidinc.ekyc.applicant.document.DocumentScanActivity" .../>
<activity android:name="asia.liquidinc.ekyc.applicant.chip.ICCardReadActivity" .../>
<activity android:name="asia.liquidinc.ekyc.applicant.face.FaceCaptureActivity" .../>
<activity android:name="asia.liquidinc.ekyc.applicant.mynumber.MyNumberCardScanActivity" .../>
```

**Target:** `android/src/main/AndroidManifest.xml` — minimal form:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc">
    <uses-permission android:name="android.permission.NFC"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-feature android:name="android.hardware.camera" android:required="true"/>
    <uses-feature android:name="android.hardware.nfc" android:required="false"/>
    <application>
        <activity android:name="asia.liquidinc.ekyc.applicant.termsofuse.TermsOfUseActivity"
            android:exported="false" android:hardwareAccelerated="true"/>
        <activity android:name="asia.liquidinc.ekyc.applicant.document.DocumentScanActivity"
            android:exported="false" android:hardwareAccelerated="true"/>
        <activity android:name="asia.liquidinc.ekyc.applicant.chip.ICCardReadActivity"
            android:exported="false" android:hardwareAccelerated="true"/>
        <activity android:name="asia.liquidinc.ekyc.applicant.face.FaceCaptureActivity"
            android:exported="false" android:hardwareAccelerated="true"/>
        <activity android:name="asia.liquidinc.ekyc.applicant.mynumber.MyNumberCardScanActivity"
            android:exported="false" android:hardwareAccelerated="true"/>
    </application>
</manifest>
```

### Step 5 — Move 5 AAR dari `android/app/libs/` → `android/libs/`
```bash
mv android/app/libs/*.aar android/libs/
```
Atau copy + delete later jika ingin keep backup.

### Step 6 — Replace `android/app/build.gradle.kts` & `android/settings.gradle.kts`

**`android/build.gradle.kts`** (top-level):
```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        flatDir { dirs("libs") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") { delete(rootProject.layout.buildDirectory) }
```

**`android/settings.gradle.kts`**:
```kotlin
pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        properties.getProperty("flutter.sdk")
            ?: throw GradleException("flutter.sdk not set in local.properties")
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    repositories {
        google(); mavenCentral(); gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.library") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":liquid_ekyc")
```

**`android/liquid_ekyc/build.gradle.kts`** (NEW — pengganti `android/app/build.gradle.kts`):
```kotlin
plugins {
    id("com.android.library")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    defaultConfig {
        minSdk = 24
        targetSdk = 34
    }
    packaging {
        jniLibs {
            excludes += listOf(
                "**/libVkLayer_khronos_validation.so",
                "**/libVkLayer_khronos_interceptor.so"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(fileTree("libs") { include("*.aar", "*.jar") })
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.activity:activity-ktx:1.9.3")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
}
```

### Step 7 — Update module `pubspec.yaml`

```yaml
name: module_liquid
description: "Liquid eKYC module for BNI Digiremit (Android)"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  http: ^1.2.0
  share_plus: ^10.1.4
  path_provider: ^2.1.5
  shared_preferences: ^2.3.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  plugin:
    platforms:
      android:
        package: id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc
        pluginClass: LiquidEkycPlugin
```

### Step 8 — Delete old `android/app/` & `lib/main.dart`
```bash
rm -rf android/app/
rm lib/main.dart
```

(`lib/app/app.dart` keep — masih dipakai oleh `module_liquid.dart` sebagai exported widget `LiquidEkycApp`)

### Step 9 — Create `example/` demo app

**`example/pubspec.yaml`:**
```yaml
name: module_liquid_example
description: Demo app untuk module_liquid_ekyc plugin
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  module_liquid:
    path: ../

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
```

**`example/lib/main.dart`:**
```dart
import 'package:flutter/material.dart';
import 'package:module_liquid/module_liquid.dart';

void main() {
  runApp(const LiquidEkycApp());
}
```

**`example/README.md`** — instruksi singkat cara menjalankan: `cd example && flutter pub get && flutter run -d <device>`.

### Step 10 — Update main project (`mobileremittance2_upgrade_refactor_liquidekyc/`)

**a. `pubspec.yaml`** — loosen Dart constraint:
```yaml
environment:
  sdk: ">=3.0.0 <4.0.0"
```

**b. `MainActivity.kt`** — pertahankan parent `FlutterActivity` (existing security channel), plugin di-handle oleh `GeneratedPluginRegistrant`. Tidak ada perubahan structural. Verify: tidak boleh ada line `flutterEngine.plugins.add(...LiquidEkycPlugin())`.

**c. `android/app/build.gradle.kts`** — tambah dependency yang sebelumnya di-handle module's app:
```kotlin
implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
implementation("androidx.activity:activity-ktx:1.9.3")
implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
```
(Mereka sudah transitif ada kalau plugin di-include, tapi eksplisit lebih aman untuk consumer)

**d. `AndroidManifest.xml`** — tambah:
```xml
<uses-permission android:name="android.permission.NFC"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.nfc" android:required="false"/>
```
(5 activity Liquid sudah ter-merge otomatis dari plugin manifest — JANGAN di-duplikasi)

### Step 11 — Verify

```bash
# Module
cd module_liquid_ekyc
flutter clean
flutter pub get
cd example
flutter pub get
flutter build apk --debug  # harus sukses — execute end-to-end plugin load
cd ..

# Main project
cd ../mobileremittance2_upgrade_refactor_liquidekyc
flutter clean
flutter pub get
flutter run -d <android_device>
```

**Expected logcat (golden signal):**
```
D/LiquidEkycPlugin: Method call: startVerify
D/LiquidEkycPlugin: [STEP 8] InitHandler.handleStartVerify() called
D/LiquidEkycPlugin: [STEP 9] Native Plugin received credentials:
```
Jika ini muncul tanpa edit `MainActivity.kt`, konversi sukses.

**Negative signal (jika masih ada bug):**
```
MissingPluginException(No implementation found for method startVerify on channel com.liquid.ekyc/channel)
```
→ Cek `pubspec.yaml` punya `flutter.plugin.platforms.android.package` block.

```
E AndroidRuntime: java.lang.ClassNotFoundException: asia.liquidinc.ekyc.applicant.termsofuse.TermsOfUseActivity
```
→ Cek `android/src/main/AndroidManifest.xml` masih punya 5 activity declarations.

---

## 5. Risk Register

| Risk | Probability | Mitigation |
|---|---|---|
| `pubspec.yaml` syntax error di `flutter.plugin` block | Low | Validate via `flutter pub get` setelah edit |
| AAR dependencies conflict dengan main project | Medium | Pakai `implementation` (bukan `api`) di plugin; isolated ke plugin scope |
| Native plugin class name bentrok (`LiquidEkycPlugin` generic) | Low | Namespace baru `id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc` sudah spesifik |
| Main project Dart 2 → Dart 3 upgrade break existing code | Medium | Run `flutter pub outdated` dan `flutter pub upgrade` di main project setelah sdk constraint dilonggarin |
| Generated manifest lupa merge → activity tidak ke-register | Low | `android/src/main/AndroidManifest.xml` ditulis langsung di plugin, Flutter `manifest merging` auto-handle |
| `FlutterFragmentActivity` di module `MainActivity` jadi hilang referensi setelah `android/app/` dihapus | High | Delete step — module tidak butuh `MainActivity.kt` lagi setelah jadi plugin |

---

## 6. Rollback Plan

Jika setelah Step 11 ada masalah yang tidak recoverable dalam 30 menit:

```bash
# Rollback module
cd module_liquid_ekyc
git checkout -- android/ lib/main.dart pubspec.yaml

# Rollback main project
cd ../mobileremittance2_upgrade_refactor_liquidekyc
git checkout -- pubspec.yaml android/app/src/main/AndroidManifest.xml
git checkout -- android/app/src/main/kotlin/.../MainActivity.kt
```

Setelah rollback, kembali ke state pra-konversi (plugin harus di-wire manual di MainActivity.kt sebagai workaround).

---

## 7. Estimated Effort

| Phase | Time | Status |
|---|---|---|
| Step 1 (new Kotlin dir) | <1 min | ✅ Done (2026-10-02) |
| Step 2 (move 6 files + fix package) | ~5 min | ✅ Done (2026-10-02) |
| Step 3-4 (reorganize Android) | ~10 min | ⬜ |
| Step 5-6 (move AAR & gradle) | ~15 min | ⬜ |
| Step 7 (pubspec) | ~5 min | ⬜ |
| Step 8 (cleanup) | ~2 min | ⬜ |
| Step 9 (example app) | ~15 min | ⬜ |
| Step 10 (main project) | ~10 min | ⬜ |
| Step 11 (verify) | ~15 min | ⬜ |
| **Total** | **~80 min** | **5 min done · ~75 min remaining** |

---

## 8. Out of Scope

- iOS implementation (Liquid SDK mungkin punya iOS variant — di luar scope task ini)
- Migrate `LiquidEkycApp` widget dari `lib/app/app.dart` ke `example/` (akan dipecah di task nanti)
- Refactor ViewModel internal (`KycViewModel` queue worker, dll) — strictly preserve business logic
- Rename Dart package dari `module_liquid` ke `liquid_ekyc` di pubspec — terlalu invasive untuk saat ini, konsumer pakai `import 'package:module_liquid/module_liquid.dart'` yang masih valid

---

## 9. Progress Log

| Date | Step | Action | Result |
|---|---|---|---|
| 2026-10-02 | — | Initial plan written, status quo analyzed | 475-line plan created |
| 2026-10-02 | #2 | Moved 6 Kotlin files + fixed package declarations + updated MainActivity + fixed proguard-rules | Package names fully consistent: source files = `id.co.bni.mobile_remittance_kcln_tokyo.liquid_ekyc`, MainActivity FQCN = matches, proguard keep-rule = matches |

---

**Last updated:** 2026-10-02
**Status:** Steps 1-2 ✅ done · Steps 3-11 ⬜ pending · module masih berupa app, bukan plugin package
