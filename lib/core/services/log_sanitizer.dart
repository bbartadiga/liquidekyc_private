/// Mask data sensitif dari teks log sebelum dikirim / di-export.
///
/// Dipakai dua tempat:
/// - [TelegramLogUploader] → sebelum dikirim ke Telegram
/// - debug log screen → sebelum file .txt di-share ke orang lain
///
/// Tanpa ini, file export APP log berisi token BE dan applicantId mentah —
/// dan file itu rutin dikirim ke CS / user.
class LogSanitizer {
  /// Key yang nilainya perlu disensor.
  static const Set<String> sensitiveKeys = {
    // Identitas
    'name',
    'name_kana',
    'nameKana',
    'last_name',
    'lastName',
    'first_name',
    'firstName',
    'last_name_kana',
    'lastNameKana',
    'first_name_kana',
    'firstNameKana',
    'full_name',
    'fullName',
    'previous_name',
    'previousName',
    'former_name',
    'formerName',
    'birthday',
    'dateOfBirth',
    'date_of_birth',
    'address',
    'full_address',
    'fullAddress',
    'address_pref',
    'addressPref',
    'addressPrefecture',
    'address_city',
    'addressCity',
    'address_other',
    'addressOther',
    'address1',
    'address2',
    'address3',
    'address4',
    'zipCode',
    'zip_code',
    'expireDate',
    'expiredDate',
    'expire_date',
    'permissionToLand',
    'permissionToLandDate',
    'periodToStay',
    'periodToStayDate',
    'gender',
    'sex',
    'id_number',
    'idNumber',
    'id_document_number',
    'nationality',
    'my_number',
    'myNumber',
    'serialNumber',
    'municipalityName',
    'resident_status',
    'residentStatus',
    'stay_period',
    'stayPeriod',
    'phoneNumber',
    'phone_number',
    'email',
    'mailAddress',
    'idFacePhoto',
    'id_face_photo',
    'face_photo',
    'documentImage',
    'document_image',
    // Auth credentials
    'token',
    'access_token',
    'refresh_token',
    'x-api-key',
    'x_ekyc_api_key',
    'X-Ekyc-Api-key',
    'api_key',
    'apikey',
    'apiKey',
    'authorization',
    'Authorization',
    'password',
    'secret',
  };

  /// Sensor nilai sensitif di dalam teks bebas.
  static String sanitize(String text) {
    if (text.isEmpty) return text;
    var out = text;

    // Email
    out = out.replaceAllMapped(
      RegExp(r'[\w._%+-]+@[\w.-]+\.[A-Za-z]{2,}'),
      (m) => '***@***',
    );

    // Deretan digit panjang (kartu, My Number, applicantId)
    out = out.replaceAllMapped(
      RegExp(r'\b\d{12,}\b'),
      (m) => '****',
    );

    // Pola key=value / "key":"value" / 'key':'value'
    for (final key in sensitiveKeys) {
      out = out.replaceAllMapped(
        RegExp('"$key"\\s*:\\s*"[^"]*"', caseSensitive: false),
        (m) => '"$key":"***"',
      );
      out = out.replaceAllMapped(
        RegExp("'$key'\\s*:\\s*'[^']*'", caseSensitive: false),
        (m) => "'$key':'***'",
      );
      // Nilai dimask sampai delimiter berikutnya (`,`, `|`, `}`, atau baris
      // baru) — bukan cuma spasi. Kalau berhenti di spasi, sisa nilainya
      // (mis. "MINISTRY OF JUSTICE") tetap bocor.
      out = out.replaceAllMapped(
        RegExp('$key\\s*[:=]\\s*[^,|}\n]+', caseSensitive: false),
        (m) => '$key=***',
      );
    }

    return out;
  }
}
