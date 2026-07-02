# Flow eKYC Liquid - Documentasi

## Overview

Dokumentasi ini menjelaskan alur integrasi eKYC Liquid pada aplikasi mobile (Digiremit/BNI).

## Flow Utama

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   Mobile App    │         │   BE (BNI)      │         │  Liquid Server  │
│  (Digiremit)    │         │  Backend        │         │  (Connector)    │
└────────┬────────┘         └────────┬────────┘         └────────┬────────┘
         │                           │                           │
         │  1. Request Token         │                           │
         │──────────────────────────>│                           │
         │                           │  2. SDK Apply API          │
         │                           │───────────────────────────>│
         │                           │                           │
         │                           │  3. Return Token           │
         │                           │<───────────────────────────│
         │  4. Token                 │                           │
         │<──────────────────────────│                           │
         │                           │                           │
         │  5. Register Applicant    │                           │
         │──────────────────────────>│                           │
         │                           │                           │
         │  6. Init SDK (token)      │                           │
         │───────────────────────────│                           │
         │                           │                           │
         │  7. Show Terms of Use     │                           │
         │  (SDK Screen)             │                           │
         │                           │                           │
         │  8. Result + KYC Flow     │                           │
         │  (IC Card → OCR → Face)   │                           │
         │                           │                           │
```

## Langkah-langkah Detail

### 1. Permintaan Token dari Mobile

- Mobile App mengirim request token ke BE (BNI Backend Server)
- Endpoint: `POST /v1/sdk/applications`
- Body:
```json
{
  "applicant_id": "111902224425",
  "operation_assignment_priority": "1"
}
```

### 2. Backend Memanggil Liquid API

- BE menerima request dari Mobile
- BE meneruskan ke Liquid Server (eKYC Connector)
- Memanggil SDK Apply API

### 3. Liquid Server Mengirim Token

- Liquid Server memproses request
- Mengirimkan Verification Token ke BE
- Response:
```json
{
  "token": "00537fdace63c768ccae642ead69bf2ce4d08c2d6fd7e8230873a111866153e0"
}
```

### 4. BE Meneruskan Token ke Mobile

- BE menerima token dari Liquid Server
- BE meneruskan token ke Mobile App

### 5. Registrasi Applicant Info ke BE

- Mobile App mengirim data applicant ke BE
- Endpoint: `POST /v1/applications/{applicantId}/info`
- Body:
```json
{
  "applicant_name": "TARO YAMADA",
  "date_of_birth": "1990-05-15",
  "address": "Tokyo-to, Chiyoda-ku, Marunouchi 1-1-1",
  "phone_number": "08123456789",
  "email": "taro.yamada@example.com"
}
```
- Response:
```json
{
  "application_id": "APP-111902224425",
  "status": "registered",
  "registered_at": "2026-06-22T13:56:28"
}
```

### 6. Inisialisasi SDK

- Mobile App menerima token
- Mobile App memanggil fungsi inisialisasi pada eKYC SDK Liquid
- Parameter: `applicantId` + `token`

### 7. Persetujuan Syarat & Ketentuan

- Mobile App memanggil fungsi Terms of Use pada SDK
- SDK menampilkan layar syarat dan ketentuan kepada pengguna

### 8. Alur Verifikasi

Setelah user menyetujui syarat, SDK menjalankan alur verifikasi:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   IC Card   │ --> │    OCR      │ --> │    Face     │
│   (NFC)     │     │ (Document)  │     │ (Liveness)  │
└─────────────┘     └─────────────┘     └─────────────┘
```

#### Tahap IC Card (NFC)
- User menempelkan kartu IC ke device
- SDK membaca data dari chip kartu
- Mendapatkan: nama, alamat, tanggal lahir, foto

#### Tahap OCR (Document Scan)
- User memindai bagian belakang kartu
- SDK melakukan optical character recognition
- Mendapatkan: data tambahan dari dokumen

#### Tahap Face Verification
- User mengambil foto wajah
- SDK melakukan liveness detection
- SDK melakukan face matching dengan foto di IC Card

### 9. Hasil Verifikasi

- SDK mengembalikan hasil ke Mobile App
- Mobile App menampilkan hasil ke user
- (Opsional) Mobile App bisa polling ke BE untuk hasil lengkap

## Endpoint BE

### 1. Request Token
```
POST http://192.168.1.41:8080/v1/sdk/applications
Content-Type: application/json

{
  "applicant_id": "111902224425",
  "operation_assignment_priority": "1"
}
```

**Response:**
```json
{
  "token": "00537fdace63c768ccae642ead69bf2ce4d08c2d6fd7e8230873a111866153e0"
}
```

### 2. Register Applicant Info
```
POST http://192.168.1.41:8080/v1/applications/111902224425/info
Content-Type: application/json

{
  "applicant_name": "TARO YAMADA",
  "date_of_birth": "1990-05-15",
  "address": "Tokyo-to, Chiyoda-ku, Marunouchi 1-1-1",
  "phone_number": "08123456789",
  "email": "taro.yamada@example.com"
}
```

**Response:**
```json
{
  "application_id": "APP-111902224425",
  "status": "registered",
  "registered_at": "2026-06-22T13:56:28"
}
```

## Catatan Penting

- Token bersifat unik per session/satu proses KYC
- Jika user cancel atau timeout, perlu request token baru
- Mobile tidak perlu call Liquid Server langsung - hanya melalui SDK
- BE bertanggung jawab untuk generate token dan simpan data applicant
- Step register applicant info bisa dilakukan dengan data dari form user

## Teknologi

- **Mobile**: Flutter (Dart)
- **SDK**: Liquid eKYC SDK (Native iOS/Android)
- **Backend**: BNI Backend Server
- **eKYC Provider**: Liquid (https://liquid-ekyc.com)