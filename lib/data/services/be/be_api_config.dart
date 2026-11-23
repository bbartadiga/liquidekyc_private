// Konstanta endpoint Liquid Connector API (BE).
//
// Dipisah dari class biar bisa dipakai tanpa qualify dari mana pun
// tanpa memicu lint `unqualified_reference_to_non_local_static_member`.

import '../../../core/constant/liquid_constants.dart';

/// Timeout tiap request ke BE.
const Duration beRequestTimeout = Duration(seconds: 60);

/// Jumlah retry di luar percobaan pertama.
const int beMaxRetries = 3;

/// Delay backoff awal (ms) sebelum retry.
const int beBaseRetryDelayMs = 1000;

// Endpoint paths - sesuai APM Collection Liquid Postman
const String bePathInboundLiquid = '/inbound-liquid';
const String bePathSdkApplications = '/v1/sdk/applications';
const String bePathApplicants = '/v1/applicants';
const String bePathKycRequestInformations = '/v1/kyc_request_informations';

// 014 RegisterKYCResult — spec "014_RegisterKYCResultAPI v1.4.2" hal.1:
//   Staging/Production: https://{Unique URL for each organization}/v1/kyc_results
// Path lama `/v1/applicants/{id}/kyc-result` Nggak ada di spec → BE balas
// 403 "Missing Authentication Token".
const String bePathKycResults = '/v1/kyc_results';
const String bePathOrchestration = '/v1/orchestration';

// Applicant sub-resource paths - sesuai APM Collection Liquid Postman
const String beSubOcrResults = 'ocr_results';
const String beSubIcInfo = 'id_document_ic_information';
const String beSubPhotos = 'photos';
const String beSubLivenessImages = 'liveness_images';
const String beSubVerificationResults = 'verification_results';
const String beSubKycResult = 'kyc-result';

// 007 本人確認書類情報取得 — spec "LIQUID_eKYC_007_本人確認書類情報取得API
// v1.6.8" hal.5: GET /v1/applicants/{applicant_id}/id_document_information
// Ngasih data yang di-register/di-koreksi di eKYC Manager (name, birthday,
// address, stay_expire_date, resident_status).
const String beSubIdDocumentInformation = 'id_document_information';

// 027 kyc追加データ取得 — spec "LIQUID_eKYC_027_kyc追加データ取得API v1.0.0"
// hal.3: GET /v1/applicants/{applicant_id}/processed_information
// Ngasih romanisasi nama yang dihitung server Liquid.
const String beSubProcessedInformation = 'processed_information';

/// Base URL lengkap BE — dipakai KycBeApi dan KycQueueWorker
/// supaya URL retry konsisten dengan request pertama.
String get beBaseUrl => '${LiquidConfig.beUrl}$bePathInboundLiquid';
