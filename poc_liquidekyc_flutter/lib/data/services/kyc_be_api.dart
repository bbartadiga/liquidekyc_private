import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constant/liquid_constants.dart';
import '../../core/services/http_logger.dart';
import '../../core/widgets/debug_http_overlay.dart';
import 'kyc_retry_queue.dart';
import 'kyc_queue_worker.dart';

// Callback untuk progress update
typedef ProgressCallback = void Function(String step, bool isLoading);

class KycBeApi {
  static const String _beUrl = 'http://192.168.1.41:8080';
  static const Duration _timeout = Duration(seconds: 60);
  static const int _maxRetries = 3;
  static const int _baseRetryDelayMs = 1000;
  static const String _apiKey = 'DJhJDEwJENQem1xTFB3NlJodFZ1MEt0THYyMC5XVEEwNEdQc3dDT0RXY0NEYmpmL053WjVIaUt6ZnFD';
  
  ProgressCallback? onProgress;

  // Endpoint paths - sesuai Postman collection v3
  static const String _pathSdkApplications = '/v1/sdk/applications';
  static const String _pathApplications = '/v1/applications';
  static const String _pathOrchestration = '/v1/orchestration';

  // Applicant sub-resource paths - sesuai Postman collection
  static const String _subOcrResults = 'ocr-results';
  static const String _subIcInfo = 'ic-card-info';
  static const String _subPhotos = 'photos';
  static const String _subLivenessImages = 'live-verification-photos';
  static const String _subVerificationResults = 'verification-results';
  static const String _subKycResult = 'kyc-result';

  String get _baseUrl => _beUrl;

  String _applicationUrl(String applicantId, String subPath) =>
      '$_baseUrl$_pathApplications/$applicantId/$subPath';
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'api-key': _apiKey,
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

  Future<void> _enqueueFailedRequest({
    required String applicantId,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = KycQueuedRequest(
        applicantId: applicantId,
        endpoint: endpoint,
        method: method,
        body: body,
      );
      
      await KycRetryQueue.enqueue(request);
      _log('Enqueued failed request: $method $endpoint');
    } catch (e) {
      _log('Failed to enqueue request: $e');
    }
  }

  Future<KycTokenResponse?> applyForSdkToken({
    required String applicantId,
    int operationPriority = 1,
  }) async {
    _log('Fetching token from BE...');

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl$_pathSdkApplications'),
        headers: _headers,
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
        Uri.parse('$_baseUrl$_pathSdkApplications'),
        headers: _headers,
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
    String? email,
  }) async {
    _log('Registering applicant info to BE...');
    _log('URL: ${_applicationUrl(applicantId, 'info')}');

    final nameParts = applicantName.split(' ');
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final firstName = nameParts.isNotEmpty ? nameParts.first : applicantName;

    for (int attempt = 1; attempt <= _maxRetries + 1; attempt++) {
      try {
        final response = await _client.post(
          Uri.parse(_applicationUrl(applicantId, 'info')),
          headers: _headers,
          body: jsonEncode({
            'first_name': firstName,
            'last_name': lastName,
            'birthday': dateOfBirth.replaceAll('-', ''),
            'address1': address,
            if (phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
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
        _log('ERROR (attempt $attempt): $e');
        if (attempt <= _maxRetries) {
          _log('Retrying...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    return ApplicantInfoResponse.error(statusCode: 0, message: 'Failed after retries');
  }

  Future<ICCardInfoResponse?> getICCardInfo(String applicantId) async {
    _log('Getting IC Card Info from BE...');
    _log('URL: ${_applicationUrl(applicantId, _subIcInfo)}');
    onProgress?.call('IC Card Info', true);

    final url = _applicationUrl(applicantId, _subIcInfo);
    final endpoint = '$_pathApplications/$applicantId/$_subIcInfo';
    int attempt = 0;
    int delayMs = _baseRetryDelayMs;
    final random = Random();

    while (attempt <= _maxRetries) {
      try {
        onProgress?.call('IC Card Info (attempt ${attempt + 1})', true);
        
        final response = await _client.get(
          Uri.parse(url),
          headers: _headers,
        ).timeout(_timeout);

        _log('Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _log('IC Card Info received: name=${data['name']}');
          onProgress?.call('IC Card Info', false);
          return ICCardInfoResponse.fromMap(data);
        } else {
          _log('ERROR: ${response.statusCode} - ${response.body}');
          onProgress?.call('IC Card Info', false);
          
          if (attempt < _maxRetries) {
            _log('Retrying in ${delayMs}ms...');
            await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
            delayMs *= 2;
            attempt++;
            continue;
          }
          
          await _enqueueFailedRequest(
            applicantId: applicantId,
            endpoint: endpoint,
            method: 'GET',
          );
          
          return ICCardInfoResponse.error(
            statusCode: response.statusCode,
            message: response.body,
          );
        }
      } catch (e) {
        _log('ERROR (attempt ${attempt + 1}): $e');
        
        if (attempt < _maxRetries) {
          _log('Retrying in ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
        } else {
          onProgress?.call('IC Card Info', false);
          
          await _enqueueFailedRequest(
            applicantId: applicantId,
            endpoint: endpoint,
            method: 'GET',
          );
          
          return ICCardInfoResponse.error(statusCode: 0, message: e.toString());
        }
      }
    }

    onProgress?.call('IC Card Info', false);
    return ICCardInfoResponse.error(statusCode: 0, message: 'Failed after retries');
  }

  Future<VerificationResultsResponse?> getVerificationResults(String applicantId) async {
    _log('Getting Verification Results from BE...');
    final url = _applicationUrl(applicantId, _subVerificationResults);
    final endpoint = '$_pathApplications/$applicantId/$_subVerificationResults';
    int attempt = 0;
    int delayMs = _baseRetryDelayMs;
    final random = Random();

    while (attempt <= _maxRetries) {
      try {
        onProgress?.call('Verification Results (attempt ${attempt + 1})', true);
        
        final response = await _client.get(
          Uri.parse(url),
          headers: _headers,
        ).timeout(_timeout);

        if (response.statusCode == 200) {
          onProgress?.call('Verification Results', false);
          return VerificationResultsResponse.fromMap(jsonDecode(response.body));
        }
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
          continue;
        }
        
        await _enqueueFailedRequest(
          applicantId: applicantId,
          endpoint: endpoint,
          method: 'GET',
        );
        
        onProgress?.call('Verification Results', false);
        return VerificationResultsResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      } catch (e) {
        _log('ERROR (attempt ${attempt + 1}): $e');
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
        } else {
          onProgress?.call('Verification Results', false);
          
          await _enqueueFailedRequest(
            applicantId: applicantId,
            endpoint: endpoint,
            method: 'GET',
          );
          
          return VerificationResultsResponse.error(statusCode: 0, message: e.toString());
        }
      }
    }

    onProgress?.call('Verification Results', false);
    return VerificationResultsResponse.error(statusCode: 0, message: 'Failed after retries');
  }

  Future<RegisterApplicationInfoResponse?> registerApplicationInfo({
    required String applicantId,
    required String applicantName,
    required String dateOfBirth,
    required String address,
    String? phoneNumber,
    String? email,
  }) async {
    _log('RegisterApplicationInfo - applicantId: $applicantId');
    final url = _applicationUrl(applicantId, 'info');
    final endpoint = '$_pathApplications/$applicantId/info';
    int attempt = 0;
    int delayMs = _baseRetryDelayMs;
    final random = Random();

    while (attempt <= _maxRetries) {
      try {
        onProgress?.call('Register App Info (attempt ${attempt + 1})', true);
        
        final nameParts = applicantName.split(' ');
        final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        final firstName = nameParts.isNotEmpty ? nameParts.first : applicantName;

        final body = {
          'first_name': firstName,
          'last_name': lastName,
          'birthday': dateOfBirth.replaceAll('-', ''),
          'address1': address,
          if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        };

        final response = await _client.post(
          Uri.parse(url),
          headers: _headers,
          body: jsonEncode(body),
        ).timeout(_timeout);

        _log('Response status: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          _log('RegisterApplicationInfo SUCCESS');
          onProgress?.call('Register App Info', false);
          return RegisterApplicationInfoResponse.fromMap(data);
        }
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
          continue;
        }
        
        await _enqueueFailedRequest(
          applicantId: applicantId,
          endpoint: endpoint,
          method: 'POST',
          body: body,
        );
        
        onProgress?.call('Register App Info', false);
        return RegisterApplicationInfoResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      } catch (e) {
        _log('ERROR (attempt ${attempt + 1}): $e');
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
        } else {
          onProgress?.call('Register App Info', false);
          
          await _enqueueFailedRequest(
            applicantId: applicantId,
            endpoint: endpoint,
            method: 'POST',
          );
          
          return RegisterApplicationInfoResponse.error(statusCode: 0, message: e.toString());
        }
      }
    }

    onProgress?.call('Register App Info', false);
    return RegisterApplicationInfoResponse.error(statusCode: 0, message: 'Failed after retries');
  }

Future<OcrResultsBeResponse?> getOcrResultsFromBe(String applicantId) async {
    _log('getOcrResultsFromBe - applicantId: $applicantId');
    final url = _applicationUrl(applicantId, _subOcrResults);
    final endpoint = '$_pathApplications/$applicantId/$_subOcrResults';
    int attempt = 0;
    int delayMs = _baseRetryDelayMs;
    final random = Random();

    while (attempt <= _maxRetries) {
      try {
        onProgress?.call('OCR Results (attempt ${attempt + 1})', true);
        
        final response = await _client.get(
          Uri.parse(url),
          headers: _headers,
        ).timeout(_timeout);

        _log('Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _log('getOcrResultsFromBe SUCCESS');
          onProgress?.call('OCR Results', false);
          return OcrResultsBeResponse.fromMap(data);
        }
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
          continue;
        }
        
        await _enqueueFailedRequest(
          applicantId: applicantId,
          endpoint: endpoint,
          method: 'GET',
        );
        
        onProgress?.call('OCR Results', false);
        return OcrResultsBeResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      } catch (e) {
        _log('ERROR (attempt ${attempt + 1}): $e');
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
        } else {
          onProgress?.call('OCR Results', false);
          
          await _enqueueFailedRequest(
            applicantId: applicantId,
            endpoint: endpoint,
            method: 'GET',
          );
          
          return OcrResultsBeResponse.error(statusCode: 0, message: e.toString());
        }
      }
    }

    onProgress?.call('OCR Results', false);
    return OcrResultsBeResponse.error(statusCode: 0, message: 'Failed after retries');
  }

  Future<PhotosResponse?> getPhotos(String applicantId) async {
    _log('getPhotos - applicantId: $applicantId');
    final url = _applicationUrl(applicantId, _subPhotos);
    final endpoint = '$_pathApplications/$applicantId/$_subPhotos';
    int attempt = 0;
    int delayMs = _baseRetryDelayMs;
    final random = Random();

    while (attempt <= _maxRetries) {
      try {
        onProgress?.call('Document Photos (attempt ${attempt + 1})', true);
        
        final response = await _client.get(
          Uri.parse(url),
          headers: _headers,
        ).timeout(_timeout);

        _log('Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _log('getPhotos SUCCESS');
          onProgress?.call('Document Photos', false);
          return PhotosResponse.fromMap(data);
        }
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
          continue;
        }
        
        await _enqueueFailedRequest(
          applicantId: applicantId,
          endpoint: endpoint,
          method: 'GET',
        );
        
        onProgress?.call('Document Photos', false);
        return PhotosResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      } catch (e) {
        _log('ERROR (attempt ${attempt + 1}): $e');
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
        } else {
          onProgress?.call('Document Photos', false);
          
          await _enqueueFailedRequest(
            applicantId: applicantId,
            endpoint: endpoint,
            method: 'GET',
          );
          
          return PhotosResponse.error(statusCode: 0, message: e.toString());
        }
      }
    }

    onProgress?.call('Document Photos', false);
    return PhotosResponse.error(statusCode: 0, message: 'Failed after retries');
  }

  Future<LivenessImagesResponse?> getLivenessImages(String applicantId) async {
    _log('getLivenessImages - applicantId: $applicantId');
    final url = _applicationUrl(applicantId, _subLivenessImages);
    final endpoint = '$_pathApplications/$applicantId/$_subLivenessImages';
    int attempt = 0;
    int delayMs = _baseRetryDelayMs;
    final random = Random();

    while (attempt <= _maxRetries) {
      try {
        onProgress?.call('Liveness Images (attempt ${attempt + 1})', true);
        
        final response = await _client.get(
          Uri.parse(url),
          headers: _headers,
        ).timeout(_timeout);

        _log('Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _log('getLivenessImages SUCCESS');
          onProgress?.call('Liveness Images', false);
          return LivenessImagesResponse.fromMap(data);
        }
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
          continue;
        }
        
        await _enqueueFailedRequest(
          applicantId: applicantId,
          endpoint: endpoint,
          method: 'GET',
        );
        
        onProgress?.call('Liveness Images', false);
        return LivenessImagesResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      } catch (e) {
        _log('ERROR (attempt ${attempt + 1}): $e');
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
        } else {
          onProgress?.call('Liveness Images', false);
          
          await _enqueueFailedRequest(
            applicantId: applicantId,
            endpoint: endpoint,
            method: 'GET',
          );
          
          return LivenessImagesResponse.error(statusCode: 0, message: e.toString());
        }
      }
    }

    onProgress?.call('Liveness Images', false);
    return LivenessImagesResponse.error(statusCode: 0, message: 'Failed after retries');
  }

  Future<bool> registerKycResult({
    required String applicantId,
    required String kycResult,
    required bool hasSensitiveInfo,
  }) async {
    _log('registerKycResult - applicantId: $applicantId, result: $kycResult');
    final url = _applicationUrl(applicantId, _subKycResult);
    final endpoint = '$_pathApplications/$applicantId/$_subKycResult';
    final body = {
      'result': kycResult,
      'reason': hasSensitiveInfo ? 'has_sensitive_info' : 'All verification passed',
    };
    int attempt = 0;
    int delayMs = _baseRetryDelayMs;
    final random = Random();

    while (attempt <= _maxRetries) {
      try {
        onProgress?.call('Register KYC Result (attempt ${attempt + 1})', true);
        
        final response = await _client.post(
          Uri.parse(url),
          headers: _headers,
          body: jsonEncode(body),
        ).timeout(_timeout);

        _log('Response status: ${response.statusCode}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          onProgress?.call('Register KYC Result', false);
          return true;
        }
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
          continue;
        }
        
        await _enqueueFailedRequest(
          applicantId: applicantId,
          endpoint: endpoint,
          method: 'POST',
          body: body,
        );
        
        onProgress?.call('Register KYC Result', false);
        return false;
      } catch (e) {
        _log('ERROR (attempt ${attempt + 1}): $e');
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: delayMs + random.nextInt(500)));
          delayMs *= 2;
          attempt++;
        } else {
          onProgress?.call('Register KYC Result', false);
          
          await _enqueueFailedRequest(
            applicantId: applicantId,
            endpoint: endpoint,
            method: 'POST',
            body: body,
          );
          
          return false;
        }
      }
    }

    onProgress?.call('Register KYC Result', false);
    return false;
  }

  Future<KycOrchestrationResponse?> processKycOrchestration({
    required String applicantId,
    required String firstName,
    required String lastName,
    required String birthday,
    String? nationality,
    String? sex,
    String? zipCode,
    String? phoneNumber,
    String? address1,
  }) async {
    _log('processKycOrchestration - applicantId: $applicantId');
    _log('URL: $_baseUrl$_pathOrchestration/$applicantId/process-kyc');
    onProgress?.call('KYC Orchestration', true);

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl$_pathOrchestration/$applicantId/process-kyc'),
        headers: _headers,
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'birthday': birthday,
          if (nationality != null) 'nationality': nationality,
          if (sex != null) 'sex': sex,
          if (zipCode != null) 'zip_code': zipCode,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (address1 != null) 'address1': address1,
        }),
      ).timeout(_timeout);

      onProgress?.call('KYC Orchestration', false);

      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _log('processKycOrchestration SUCCESS');
        return KycOrchestrationResponse.fromMap(data);
      } else {
        _log('processKycOrchestration ERROR: ${response.statusCode} - ${response.body}');
        return KycOrchestrationResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      }
    } catch (e) {
      _log('ERROR: $e');
      onProgress?.call('KYC Orchestration', false);
      return KycOrchestrationResponse.error(statusCode: 0, message: e.toString());
    }
  }
}

class KycOrchestrationResponse {
  final bool isSuccess;
  final String? applicantId;
  final Map<String, dynamic>? registerInfo;
  final Map<String, dynamic>? icCardInfo;
  final List<dynamic>? photos;
  final List<dynamic>? livenessImages;
  final Map<String, dynamic>? verificationResults;
  final int? statusCode;
  final String? errorMessage;

  KycOrchestrationResponse({
    required this.isSuccess,
    this.applicantId,
    this.registerInfo,
    this.icCardInfo,
    this.photos,
    this.livenessImages,
    this.verificationResults,
    this.statusCode,
    this.errorMessage,
  });

  factory KycOrchestrationResponse.fromMap(Map<String, dynamic> map) {
    return KycOrchestrationResponse(
      isSuccess: true,
      applicantId: map['applicant_id'],
      registerInfo: map['register_info'] as Map<String, dynamic>?,
      icCardInfo: map['ic_card_info'] as Map<String, dynamic>?,
      photos: map['photos'] as List<dynamic>?,
      livenessImages: map['liveness_images'] as List<dynamic>?,
      verificationResults: map['verification_results'] as Map<String, dynamic>?,
      statusCode: map['status_code'],
    );
  }

  factory KycOrchestrationResponse.error({
    required int statusCode,
    required String message,
  }) => KycOrchestrationResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
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
    return parts.isNotEmpty ? parts.join(' ') : (address ?? '');
  }

  // Getters untuk display - return null kalau kosong (agar placeholder bisa tampil)
  String? get displayName => name;
  String? get displayNameKana => nameKana;
  String? get displayBirthday {
    if (birthday == null || birthday!.isEmpty) return null;
    if (birthday!.length == 8) {
      return '${birthday!.substring(0, 4)}-${birthday!.substring(4, 6)}-${birthday!.substring(6, 8)}';
    }
    return birthday;
  }
  String? get displayExpireDate {
    if (expireDate == null || expireDate!.isEmpty) return null;
    if (expireDate!.length == 8) {
      return '${expireDate!.substring(0, 4)}-${expireDate!.substring(4, 6)}-${expireDate!.substring(6, 8)}';
    }
    return expireDate;
  }
  String? get displayIssueDate {
    if (issueDate == null || issueDate!.isEmpty) return null;
    if (issueDate!.length == 8) {
      return '${issueDate!.substring(0, 4)}-${issueDate!.substring(4, 6)}-${issueDate!.substring(6, 8)}';
    }
    return issueDate;
  }
  String? get displaySex => sex?.toUpperCase();
  String? get displayIdNumber => idNumber;

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

class RegisterApplicationInfoResponse {
  final bool isSuccess;
  final String? applicationId;
  final String? status;
  final String? registeredAt;
  final int? statusCode;
  final String? errorMessage;

  RegisterApplicationInfoResponse({
    required this.isSuccess,
    this.applicationId,
    this.status,
    this.registeredAt,
    this.statusCode,
    this.errorMessage,
  });

  factory RegisterApplicationInfoResponse.fromMap(Map<String, dynamic> map) {
    return RegisterApplicationInfoResponse(
      isSuccess: true,
      applicationId: map['application_id'] ?? map['id'],
      status: map['status'],
      registeredAt: map['registered_at'],
      statusCode: map['status_code'],
    );
  }

  factory RegisterApplicationInfoResponse.error({
    required int statusCode,
    required String message,
  }) => RegisterApplicationInfoResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}

class OcrResultsBeResponse {
  final bool isSuccess;
  final String? name;
  final String? birthday;
  final String? sex;
  final String? address;
  final String? addressPref;
  final String? addressCity;
  final String? addressOther;
  final String? zipCode;
  final String? expireDate;
  final String? idNumber;
  final String? issueDate;
  final String? nationality;
  final String? residentStatus;
  final String? stayPeriod;
  final String? stayExpireDate;
  final int? statusCode;
  final String? errorMessage;

  OcrResultsBeResponse({
    required this.isSuccess,
    this.name,
    this.birthday,
    this.sex,
    this.address,
    this.addressPref,
    this.addressCity,
    this.addressOther,
    this.zipCode,
    this.expireDate,
    this.idNumber,
    this.issueDate,
    this.nationality,
    this.residentStatus,
    this.stayPeriod,
    this.stayExpireDate,
    this.statusCode,
    this.errorMessage,
  });

  String get fullAddress {
    final parts = [addressPref, addressCity, addressOther, address]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : address ?? '-';
  }

  factory OcrResultsBeResponse.fromMap(Map<String, dynamic> map) {
    return OcrResultsBeResponse(
      isSuccess: true,
      name: map['name'],
      birthday: map['birthday'],
      sex: map['sex'],
      address: map['address'],
      addressPref: map['address_pref'],
      addressCity: map['address_city'],
      addressOther: map['address_other'],
      zipCode: map['zip_code'],
      expireDate: map['expire_date'],
      idNumber: map['id_number'],
      issueDate: map['issue_date'],
      nationality: map['nationality'],
      residentStatus: map['resident_status'],
      stayPeriod: map['stay_period'],
      stayExpireDate: map['stay_expire_date'],
      statusCode: map['status_code'],
    );
  }

  factory OcrResultsBeResponse.error({
    required int statusCode,
    required String message,
  }) => OcrResultsBeResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}

class PhotosResponse {
  final bool isSuccess;
  final String? faceFrontPhoto;
  final List<IdDocumentPhoto>? idDocumentPhotos;
  final int? statusCode;
  final String? errorMessage;

  PhotosResponse({
    required this.isSuccess,
    this.faceFrontPhoto,
    this.idDocumentPhotos,
    this.statusCode,
    this.errorMessage,
  });

  factory PhotosResponse.fromMap(Map<String, dynamic> map) {
    final List<IdDocumentPhoto> photos = [];

    if (map['id_document_photos'] != null) {
      for (final item in map['id_document_photos'] as List) {
        photos.add(IdDocumentPhoto.fromMap(item));
      }
    }

    return PhotosResponse(
      isSuccess: true,
      faceFrontPhoto: map['face_front_photo'] as String?,
      idDocumentPhotos: photos.isNotEmpty ? photos : null,
      statusCode: map['status_code'],
    );
  }

  factory PhotosResponse.error({
    required int statusCode,
    required String message,
  }) => PhotosResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}

class IdDocumentPhoto {
  final String? fileName;
  final String? image;
  final String? idDocumentType;
  final String? photoType;
  final bool? isMasked;
  final bool? isWaitingMasked;

  IdDocumentPhoto({
    this.fileName,
    this.image,
    this.idDocumentType,
    this.photoType,
    this.isMasked,
    this.isWaitingMasked,
  });

  factory IdDocumentPhoto.fromMap(Map<String, dynamic> map) {
    return IdDocumentPhoto(
      fileName: map['file_name'] as String?,
      image: map['image'] as String?,
      idDocumentType: map['id_document_type'] as String?,
      photoType: map['photo_type'] as String?,
      isMasked: map['is_masked'] as bool?,
      isWaitingMasked: map['is_waiting_masked'] as bool?,
    );
  }
}

class LivenessImagesResponse {
  final bool isSuccess;
  final List<LivenessImage>? livenessImages;
  final int? statusCode;
  final String? errorMessage;

  LivenessImagesResponse({
    required this.isSuccess,
    this.livenessImages,
    this.statusCode,
    this.errorMessage,
  });

  factory LivenessImagesResponse.fromMap(Map<String, dynamic> map) {
    final List<LivenessImage> images = [];

    if (map['liveness_images'] != null) {
      for (final item in map['liveness_images'] as List) {
        images.add(LivenessImage.fromMap(item));
      }
    }

    return LivenessImagesResponse(
      isSuccess: true,
      livenessImages: images.isNotEmpty ? images : null,
      statusCode: map['status_code'],
    );
  }

  factory LivenessImagesResponse.error({
    required int statusCode,
    required String message,
  }) => LivenessImagesResponse(
    isSuccess: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}

class LivenessImage {
  final String? fileName;
  final String? image;

  LivenessImage({
    this.fileName,
    this.image,
  });

  factory LivenessImage.fromMap(Map<String, dynamic> map) {
    return LivenessImage(
      fileName: map['file_name'] as String?,
      image: map['image'] as String?,
    );
  }
}