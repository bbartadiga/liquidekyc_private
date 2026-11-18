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
const String bePathOrchestration = '/v1/orchestration';

// Applicant sub-resource paths - sesuai APM Collection Liquid Postman
const String beSubOcrResults = 'ocr_results';
const String beSubIcInfo = 'id_document_ic_information';
const String beSubPhotos = 'photos';
const String beSubLivenessImages = 'liveness_images';
const String beSubVerificationResults = 'verification_results';
const String beSubKycResult = 'kyc-result';

/// Base URL lengkap BE — dipakai KycBeApi dan KycQueueWorker
/// supaya URL retry konsisten dengan request pertama.
String get beBaseUrl => '${LiquidConfig.beUrl}$bePathInboundLiquid';
