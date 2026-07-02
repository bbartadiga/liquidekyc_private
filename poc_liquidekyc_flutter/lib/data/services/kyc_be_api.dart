import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constant/liquid_constants.dart';
import '../../core/services/http_logger.dart';
import '../../core/widgets/debug_http_overlay.dart';

class KycBeApi {
  static const String _stagingUrl = 'https://connector-bni.stg-liquid-ekyc.com';
  static const String _localUrl = 'http://192.168.1.41:8080';
  static const Duration _timeout = Duration(seconds: 30);
  static const String _apiKey = 'JDJhJDEwJENQem1xTFB3NlJodFZ1MEt0THYyMC5XVEEwNEdQc3dDT0RXY0NEYmpmL053WjVIaUt6ZnFD';
  
  String get _baseUrl {
    return LiquidConfig.isDebugMode ? _localUrl : _stagingUrl;
  }
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-Ekyc-Api-Key': _apiKey,
  };
  
  late final http.Client _client;

  KycBeApi() {
    if (kDebugMode) {
      _client = HttpLoggingClient();
    } else {
      _client = http.Client();
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[KycBeApi] $message');
    }
  }

  Future<KycTokenResponse?> applyForSdkToken({
    required String applicantId,
    int operationPriority = 1,
  }) async {
    _log('Fetching token from BE...');

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/v1/sdk/applications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'applicant_id': applicantId,
          'operation_assignment_priority': operationPriority.toString(),
        }),
      ).timeout(_timeout);

      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return KycTokenResponse.fromMap(data);
      } else {
        return KycTokenResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      }
    } catch (e) {
      _log('ERROR: $e');
      return KycTokenResponse.error(statusCode: 0, message: e.toString());
    }
  }

  Future<KycTokenResponse?> applyNewApplicant() async {
    _log('Creating new applicant via BE...');

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/v1/sdk/applications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'operation_assignment_priority': '1'}),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return KycTokenResponse.fromMap(jsonDecode(response.body));
      } else {
        return KycTokenResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      }
    } catch (e) {
      _log('ERROR: $e');
      return KycTokenResponse.error(statusCode: 0, message: e.toString());
    }
  }

  Future<ApplicantInfoResponse?> registerApplicantInfo({
    required String applicantId,
    required String applicantName,
    required String dateOfBirth,
    required String address,
    required String phoneNumber,
    required String email,
  }) async {
    _log('Registering applicant info to BE...');

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/v1/kyc_request_informations'),
        headers: _headers,
        body: jsonEncode({
          'applicant_id': applicantId,
          'applicant_name': applicantName,
          'date_of_birth': dateOfBirth,
          'address': address,
          'phone_number': phoneNumber,
          'email': email,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApplicantInfoResponse.fromMap(jsonDecode(response.body));
      } else {
        return ApplicantInfoResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      }
    } catch (e) {
      _log('ERROR: $e');
      return ApplicantInfoResponse.error(statusCode: 0, message: e.toString());
    }
  }

  Future<ICCardInfoResponse?> getICCardInfo(String applicantId) async {
    _log('Getting IC Card Info from BE...');
    _log('URL: $_baseUrl/v1/applicants/$applicantId/id_document_ic_information');

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/v1/applicants/$applicantId/id_document_ic_information'),
        headers: _headers,
      ).timeout(_timeout);

      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log('IC Card Info received: name=${data['name']}');
        return ICCardInfoResponse.fromMap(data);
      } else {
        _log('ERROR: ${response.statusCode} - ${response.body}');
        return ICCardInfoResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      }
    } catch (e) {
      _log('ERROR: $e');
      return ICCardInfoResponse.error(statusCode: 0, message: e.toString());
    }
  }

  Future<VerificationResultsResponse?> getVerificationResults(String applicantId) async {
    _log('Getting Verification Results from BE...');

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/v1/applicants/$applicantId/verification_results'),
        headers: _headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return VerificationResultsResponse.fromMap(jsonDecode(response.body));
      } else {
        return VerificationResultsResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      }
    } catch (e) {
      _log('ERROR: $e');
      return VerificationResultsResponse.error(statusCode: 0, message: e.toString());
    }
  }
}

class KycTokenResponse {
  final bool isSuccess;
  final String? applicantId;
  final String? token;
  final int? statusCode;
  final String? errorMessage;

  KycTokenResponse({
    required this.isSuccess,
    this.applicantId,
    this.token,
    this.statusCode,
    this.errorMessage,
  });

  factory KycTokenResponse.fromMap(Map<String, dynamic> map) {
    return KycTokenResponse(
      isSuccess: map['token'] != null,
      applicantId: map['applicant_id'],
      token: map['token'],
      statusCode: map['status_code'],
      errorMessage: map['error_message'],
    );
  }

  factory KycTokenResponse.error({
    required int statusCode,
    required String message,
  }) => KycTokenResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}

class ApplicantInfoResponse {
  final bool isSuccess;
  final String? applicationId;
  final String? status;
  final String? registeredAt;
  final int? statusCode;
  final String? errorMessage;

  ApplicantInfoResponse({
    required this.isSuccess,
    this.applicationId,
    this.status,
    this.registeredAt,
    this.statusCode,
    this.errorMessage,
  });

  factory ApplicantInfoResponse.fromMap(Map<String, dynamic> map) {
    return ApplicantInfoResponse(
      isSuccess: map['application_id'] != null || map['id'] != null,
      applicationId: map['application_id'] ?? map['id'],
      status: map['status'],
      registeredAt: map['registered_at'],
      statusCode: map['status_code'],
      errorMessage: map['error_message'],
    );
  }

  factory ApplicantInfoResponse.error({
    required int statusCode,
    required String message,
  }) => ApplicantInfoResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}

class ICCardInfoResponse {
  final bool isSuccess;
  final String? name;
  final String? nameKana;
  final String? birthday;
  final String? sex;
  final String? address;
  final String? addressPref;
  final String? addressCity;
  final String? addressOther;
  final String? idNumber;
  final String? issueDate;
  final String? expireDate;
  final String? myNumber;
  final int? statusCode;
  final String? errorMessage;

  ICCardInfoResponse({
    required this.isSuccess,
    this.name,
    this.nameKana,
    this.birthday,
    this.sex,
    this.address,
    this.addressPref,
    this.addressCity,
    this.addressOther,
    this.idNumber,
    this.issueDate,
    this.expireDate,
    this.myNumber,
    this.statusCode,
    this.errorMessage,
  });

  String get fullAddress {
    final parts = [addressPref, addressCity, addressOther, address]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : address ?? '-';
  }

  String get displayName => name ?? '-';
  String get displayNameKana => nameKana ?? '-';
  String get displayBirthday => _formatDate(birthday);
  String get displayExpireDate => _formatDate(expireDate);
  String get displayIssueDate => _formatDate(issueDate);
  String get displaySex => sex?.toUpperCase() ?? '-';
  String get displayIdNumber => idNumber ?? '-';

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    if (date.length == 8) {
      return '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)}';
    }
    return date;
  }

  factory ICCardInfoResponse.fromMap(Map<String, dynamic> map) {
    return ICCardInfoResponse(
      isSuccess: true,
      name: map['name'],
      nameKana: map['name_kana'],
      birthday: map['birthday'],
      sex: map['sex'],
      address: map['address'],
      addressPref: map['address_pref'],
      addressCity: map['address_city'],
      addressOther: map['address_other'],
      idNumber: map['id_number'],
      issueDate: map['issue_date'],
      expireDate: map['expire_date'],
      myNumber: map['my_number'],
      statusCode: map['status_code'],
    );
  }

  factory ICCardInfoResponse.error({
    required int statusCode,
    required String message,
  }) => ICCardInfoResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}

class VerificationResultsResponse {
  final bool isSuccess;
  final double? faceMatchScore;
  final String? autoVerificationStatus;
  final String? livenessResult;
  final int? statusCode;
  final String? errorMessage;

  VerificationResultsResponse({
    required this.isSuccess,
    this.faceMatchScore,
    this.autoVerificationStatus,
    this.livenessResult,
    this.statusCode,
    this.errorMessage,
  });

  factory VerificationResultsResponse.fromMap(Map<String, dynamic> map) {
    return VerificationResultsResponse(
      isSuccess: true,
      faceMatchScore: map['face_match_score'] != null
          ? (map['face_match_score'] as num).toDouble()
          : null,
      autoVerificationStatus: map['auto_verification_status'] ?? map['status'],
      livenessResult: map['liveness_result'],
      statusCode: map['status_code'],
    );
  }

  factory VerificationResultsResponse.error({
    required int statusCode,
    required String message,
  }) => VerificationResultsResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}