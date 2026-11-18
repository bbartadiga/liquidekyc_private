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

    String? faceFrontPhoto;
    final facePhotoData = map['face_front_photo'];
    if (facePhotoData is Map) {
      faceFrontPhoto = facePhotoData['image'] as String?;
    } else if (facePhotoData is String) {
      faceFrontPhoto = facePhotoData;
    }

    return PhotosResponse(
      isSuccess: true,
      faceFrontPhoto: faceFrontPhoto,
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
