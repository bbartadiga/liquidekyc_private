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
