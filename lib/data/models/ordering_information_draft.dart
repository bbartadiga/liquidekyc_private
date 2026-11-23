import '../../core/constant/liquid_mappings.dart';
import '../../core/constant/visa_status_mapping.dart';
import '../../core/services/japanese_date_parser.dart';
import '../../core/services/japanese_romaji_helper.dart';
import 'chip_data.dart';
import 'ic_card_info_response.dart';
import 'id_document_information_response.dart';
import 'ocr_result.dart';
import 'ocr_results_response.dart';
import 'processed_information_response.dart';

/// Dari mana sebuah field form ngambild nilainya.
///
/// Satu field bisa punya beberapa sumber (mis. IC chip nggak nyediain
/// "Permission to Land", tapi OCR SDK nyediain) — field itu ambil dari
/// sumber pertama yang datanya ada.
enum OrderingFieldSource {
  chip('IC CHIP'),
  sdkOcr('SDK OCR'),
  beOcr('BE OCR'),
  beIcCard('BE IC'),
  beIdDocumentInfo('BE 007'),
  beProcessed('BE 027'),
  initialSelection('INITIAL'),
  manual('');

  const OrderingFieldSource(this.label);

  /// Label singkat buat badge di UI.
  final String label;
}

/// Key setiap field form — dipakai nyimpen sumber datanya.
enum OrderingField {
  residenceCardNumber,
  expiredDate,
  nationality,
  visaStatus,
  permissionToLandDate,
  periodToStayDate,
  orderingCustomerNameEnglish,
  dateOfBirth,
  gender,
  postalCode,
  address1,
  address2,
  address3,
}

/// Nilai form "Ordering Information" yang sudah diterjemahkan dari data
/// IC chip / OCR.
class OrderingInformationDraft {
  final String residenceCardNumber;
  final DateTime? expiredDate;
  final String? nationality;
  final String? visaStatus;
  final DateTime? permissionToLandDate;
  final DateTime? periodToStayDate;
  final String orderingCustomerNameEnglish;

  /// Nama asli yang masih kanji — perlu konversi async (jp_transliterate)
  /// supaya bisa jadi romaji.
  final String? orderingCustomerNameRaw;
  final DateTime? dateOfBirth;
  final String? gender;
  final String postalCode;
  final String address1;
  final String address2;
  final String address3;

  /// Sumber data per field. Field yang nggak ada di map → belum ada data
  /// (harus diisi manual user).
  final Map<OrderingField, OrderingFieldSource> sources;

  const OrderingInformationDraft({
    this.residenceCardNumber = '',
    this.expiredDate,
    this.nationality,
    this.visaStatus,
    this.permissionToLandDate,
    this.periodToStayDate,
    this.orderingCustomerNameEnglish = '',
    this.orderingCustomerNameRaw,
    this.dateOfBirth,
    this.gender,
    this.postalCode = '',
    this.address1 = '',
    this.address2 = '',
    this.address3 = '',
    this.sources = const <OrderingField, OrderingFieldSource>{},
  });

  static const OrderingInformationDraft empty = OrderingInformationDraft();

  /// Sumber data untuk [field], null kalau field itu nggak terisi dari data.
  OrderingFieldSource? sourceOf(OrderingField field) => sources[field];
}

/// Terjemahkan data IC chip / OCR jadi nilai form.
///
/// Setiap field dicoba dari beberapa sumber, berurutan dari yang paling
/// otoritatif, dan ambil yang pertama yang datanya ada:
///
/// 1. Chip yang dibaca SDK (`chipData`) — data fisik kartu
/// 2. OCR SDK (`sdkOcr`) — hasil baca dokumen
/// 3. OCR BE (`beOcr`) — hasil OCR server
/// 4. IC Card Info BE (`beIcCardInfo`) — fallback kalau OCR nggak ada
///
/// Kalau semua sumber kosong, field dibiarkan kosong buat diisi user manual.
class OrderingInformationMapper {
  const OrderingInformationMapper._();

  /// Susun draft dari semua sumber data yang tersedia.
  static OrderingInformationDraft fromKycData({
    LiquidChipDataModel? chipData,
    OcrResult? sdkOcr,
    OcrResultsBeResponse? beOcr,
    ICCardInfoResponse? beIcCardInfo,
    IdDocumentInformationResponse? idDocumentInformation,
    ProcessedInformationResponse? processedInformation,
    String? fallbackNationality,
  }) {
    final gen2 = chipData?.residenceDocumentGen2;

    final cardNumber = _pick(<_Candidate<String?>>[
      _text(
        idDocumentInformation?.idNumber,
        OrderingFieldSource.beIdDocumentInfo,
      ),
      _text(chipData?.idNumber, OrderingFieldSource.chip),
      _text(sdkOcr?.idNumber, OrderingFieldSource.sdkOcr),
      _text(beOcr?.idNumber, OrderingFieldSource.beOcr),
      _text(beIcCardInfo?.idNumber, OrderingFieldSource.beIcCard),
    ]);

    final expired = _pick(<_Candidate<DateTime?>>[
      _date(
        idDocumentInformation?.expireDate,
        OrderingFieldSource.beIdDocumentInfo,
      ),
      _date(chipData?.expireDate, OrderingFieldSource.chip),
      _date(sdkOcr?.expireDate, OrderingFieldSource.sdkOcr),
      _date(beOcr?.expireDate, OrderingFieldSource.beOcr),
      _date(beIcCardInfo?.expireDate, OrderingFieldSource.beIcCard),
    ]);

    // Kebangsaan: dari kartu dulu, kalau kartu nggak nyediain (mis. My Number
    // Card) → pakai pilihan awal user di layar konfigurasi.
    final nationality = _pick(<_Candidate<String?>>[
      _nationality(gen2?.nationalityCode, OrderingFieldSource.chip),
      _nationality(sdkOcr?.nationality, OrderingFieldSource.sdkOcr),
      _nationality(beOcr?.nationality, OrderingFieldSource.beOcr),
      _nationality(
        beOcr?.nationalityCode3,
        OrderingFieldSource.beOcr,
      ),
      _nationality(
        beIcCardInfo?.nationalityCode3,
        OrderingFieldSource.beIcCard,
      ),
      _text(fallbackNationality, OrderingFieldSource.initialSelection),
    ]);

    final visaStatus = _pick(<_Candidate<String?>>[
      // API 007: nilai yang di-koreksi di eKYC Manager (prioritas tertinggi).
      _visaStatus(
        idDocumentInformation?.residentStatus,
        OrderingFieldSource.beIdDocumentInfo,
      ),
      _visaStatus(gen2?.residenceStatusCode, OrderingFieldSource.chip),
      _visaStatus(sdkOcr?.residentStatus, OrderingFieldSource.sdkOcr),
      _visaStatus(beOcr?.residentStatus, OrderingFieldSource.beOcr),
      _visaStatus(
        beOcr?.residentStatusCode,
        OrderingFieldSource.beOcr,
      ),
      _visaStatus(
        beIcCardInfo?.residentStatusCode,
        OrderingFieldSource.beIcCard,
      ),
    ]);

    final permissionToLand = _pick(<_Candidate<DateTime?>>[
      _date(sdkOcr?.permittedDate, OrderingFieldSource.sdkOcr),
      _date(gen2?.permittedDate, OrderingFieldSource.chip),
      _date(gen2?.expireDateOfComprehensivePermission,
          OrderingFieldSource.chip),
    ]);

    final periodToStay = _pick(<_Candidate<DateTime?>>[
      // API 007: stay_expire_date dari eKYC Manager.
      _date(
        idDocumentInformation?.stayExpireDate,
        OrderingFieldSource.beIdDocumentInfo,
      ),
      _date(gen2?.stayExpireDate, OrderingFieldSource.chip),
      _date(sdkOcr?.stayExpireDate, OrderingFieldSource.sdkOcr),
      _date(beOcr?.stayExpireDate, OrderingFieldSource.beOcr),
      _date(beOcr?.stayPeriod, OrderingFieldSource.beOcr),
    ]);

    // Nama: pilih sumber yang paling bisa jadi latin. Chip (JPKI signed)
    // paling otoritatif, tapi `nameKana` (katakana) menghasilkan
    // romaji yang lebih kasar daripada `name` (latin full-width).
    // Nama latin: API 027 (romanisasi yang dihitung server Liquid) paling
    // akurat → dipakai dulu, baru fallback ke transliterasi lokal.
    final nameEnglish = _resolveName(<_Candidate<String?>>[
      _text(processedInformation?.latinFullName, OrderingFieldSource.beProcessed),
      _text(chipData?.name, OrderingFieldSource.chip),
      _text(sdkOcr?.name, OrderingFieldSource.sdkOcr),
      _text(beOcr?.name, OrderingFieldSource.beOcr),
      _text(beIcCardInfo?.name, OrderingFieldSource.beIcCard),
      _text(chipData?.nameKana, OrderingFieldSource.chip),
    ]);

    final dateOfBirth = _pick(<_Candidate<DateTime?>>[
      _date(
        idDocumentInformation?.birthday,
        OrderingFieldSource.beIdDocumentInfo,
      ),
      _date(chipData?.birthday, OrderingFieldSource.chip),
      _date(sdkOcr?.birthday, OrderingFieldSource.sdkOcr),
      _date(beOcr?.birthday, OrderingFieldSource.beOcr),
      _date(beIcCardInfo?.birthday, OrderingFieldSource.beIcCard),
    ]);

    final gender = _pick(<_Candidate<String?>>[
      _gender(chipData?.sex?.name, OrderingFieldSource.chip),
      _gender(sdkOcr?.sex, OrderingFieldSource.sdkOcr),
      _gender(beOcr?.sex, OrderingFieldSource.beOcr),
      _gender(beIcCardInfo?.sex, OrderingFieldSource.beIcCard),
    ]);

    final postalCode = _pick(<_Candidate<String?>>[
      _text(chipData?.zipCode, OrderingFieldSource.chip),
      _text(sdkOcr?.zipCode, OrderingFieldSource.sdkOcr),
      _text(beOcr?.zipCode, OrderingFieldSource.beOcr),
    ]);

    // AlamatJapan dipecah jadi 4 bagian: pref / city / other / building.
    // Form cuma punya 3 slot, jadi:
    //   Address 1 (Town / City)     = pref + city
    //   Address 2 (Street / other)  = other
    //   Address 3 (Building / Room) = opsional, dibiarkan kosong
    final addressPref = _pick(<_Candidate<String?>>[
      _text(chipData?.addressPref, OrderingFieldSource.chip),
      _text(sdkOcr?.addressPref, OrderingFieldSource.sdkOcr),
      _text(beOcr?.addressPref, OrderingFieldSource.beOcr),
      _text(beIcCardInfo?.addressPref, OrderingFieldSource.beIcCard),
    ]);

    final addressCity = _pick(<_Candidate<String?>>[
      _text(chipData?.addressCity, OrderingFieldSource.chip),
      _text(sdkOcr?.addressCity, OrderingFieldSource.sdkOcr),
      _text(beOcr?.addressCity, OrderingFieldSource.beOcr),
      _text(beIcCardInfo?.addressCity, OrderingFieldSource.beIcCard),
    ]);

    final addressOther = _pick(<_Candidate<String?>>[
      _text(chipData?.addressOther, OrderingFieldSource.chip),
      _text(sdkOcr?.addressOther, OrderingFieldSource.sdkOcr),
      _text(beOcr?.addressOther, OrderingFieldSource.beOcr),
      _text(beIcCardInfo?.addressOther, OrderingFieldSource.beIcCard),
    ]);

    // Kartu yang address-nya nggak dipecah (My Number / Driving License)
    // cuma punya satu string penuh — taruh di Address 1 biar nggak kosong.
    final addressFull = _pick(<_Candidate<String?>>[
      _text(
        idDocumentInformation?.address,
        OrderingFieldSource.beIdDocumentInfo,
      ),
      _text(chipData?.address, OrderingFieldSource.chip),
      _text(sdkOcr?.address, OrderingFieldSource.sdkOcr),
      _text(beOcr?.address, OrderingFieldSource.beOcr),
      _text(beIcCardInfo?.address, OrderingFieldSource.beIcCard),
    ]);

    final address1 = _Candidate<String?>(
      _joinAddressParts(addressPref.value, addressCity.value) ??
          addressFull.value,
      addressCity.value != null ? addressCity.source : addressPref.source,
    );

    final address2 = addressOther;

    // Address 3 = building / room — opsional, dibiarkan kosong.
    final address3 = _Candidate<String?>(null, OrderingFieldSource.manual);

    final sources = <OrderingField, OrderingFieldSource>{
      OrderingField.residenceCardNumber: cardNumber.source,
      OrderingField.expiredDate: expired.source,
      OrderingField.nationality: nationality.source,
      OrderingField.visaStatus: visaStatus.source,
      OrderingField.permissionToLandDate: permissionToLand.source,
      OrderingField.periodToStayDate: periodToStay.source,
      OrderingField.orderingCustomerNameEnglish: nameEnglish.source,
      OrderingField.dateOfBirth: dateOfBirth.source,
      OrderingField.gender: gender.source,
      OrderingField.postalCode: postalCode.source,
      OrderingField.address1: address1.source,
      OrderingField.address2: address2.source,
      OrderingField.address3: address3.source,
    };

    return OrderingInformationDraft(
      residenceCardNumber: cardNumber.value ?? '',
      expiredDate: expired.value,
      nationality: nationality.value,
      visaStatus: visaStatus.value,
      permissionToLandDate: permissionToLand.value,
      periodToStayDate: periodToStay.value,
      orderingCustomerNameEnglish: nameEnglish.value ?? '',
      orderingCustomerNameRaw: nameEnglish.kanjiRaw,
      dateOfBirth: dateOfBirth.value,
      gender: gender.value,
      postalCode: postalCode.value ?? '',
      address1: address1.value ?? '',
      address2: address2.value ?? '',
      address3: address3.value ?? '',
      sources: sources,
    );
  }

  // --------------------------------------------------------------------------
  // Kandidat per sumber
  // --------------------------------------------------------------------------

  static _Candidate<String?> _text(String? raw, OrderingFieldSource source) {
    if (raw == null) return _Candidate(null, source);
    final value = raw.trim();
    return _Candidate(value.isEmpty ? null : value, source);
  }

  static _Candidate<DateTime?> _date(String? raw, OrderingFieldSource source) {
    return _Candidate(JapaneseDateParser.parse(raw), source);
  }

  /// Nama latin (ENGLISH). Kana bisa langsung jadi romaji; kanji ditampilkan
  /// apa adanya supaya field nggak kosong.
  static _Candidate<String?> _name(String? raw, OrderingFieldSource source) {
    if (raw == null) return _Candidate(null, source);
    final value = raw.trim();
    if (value.isEmpty) return _Candidate(null, source);

    final romaji = JapaneseRomajiHelper.toRomajiSync(value);
    if (romaji != null && romaji.trim().isNotEmpty) {
      return _Candidate(_normalizeName(romaji), source);
    }
    if (!_hasJapaneseCharacters(value)) {
      return _Candidate(_normalizeName(value), source);
    }
    return _Candidate(value, source);
  }

  /// Pilih nama paling bagus dari beberapa sumber.
  ///
  /// Skor (kecil = lebih bagus):
  /// 1. Sudah latin (mis. "DHIKA PRATAMA") — langsung dipakai
  /// 2. Kana → bisa di-romaji sinkron (kana_kit)
  /// 3. Kanji → cuma bisa di-romaji ASYNC (jp_transliterate), jadi
  ///    nilai kanjinya dikembalikan terpisah untuk diproses asynchronous
  static _NameResult _resolveName(List<_Candidate<String?>> candidates) {
    _Candidate<String?>? bestSync;
    var bestSyncScore = 99;
    _Candidate<String?>? kanji;

    for (final candidate in candidates) {
      final raw = candidate.value;
      if (raw == null || raw.trim().isEmpty) continue;

      final score = _nameScore(raw);
      if (score == 3) {
        // Kanji → butuh jp_transliterate (async).
        kanji ??= candidate;
        continue;
      }
      if (score < bestSyncScore) {
        bestSyncScore = score;
        bestSync = candidate;
      }
    }

    final chosen = bestSync ?? kanji;
    if (chosen == null) {
      return const _NameResult(null, null, OrderingFieldSource.manual);
    }

    // Kanji cuma dikonversi async kalau nilai sync-nya belum latin sempurna
    // — kalau sudah latin (mis. dari chip), nggak perlu ditimpa romaji.
    final kanjiRaw = bestSyncScore == 1 ? null : kanji?.value;

    return _NameResult(
      _name(chosen.value, chosen.source).value,
      kanjiRaw,
      chosen.source,
    );
  }

  static int _nameScore(String raw) {
    final value = raw.trim();
    if (!_hasJapaneseCharacters(value)) return 1;
    if (JapaneseRomajiHelper.toRomajiSync(value) != null) return 2;
    return 3;
  }

  /// Normalisasi nama latin (half-width + rapi spasi + huruf besar).
  ///
  /// Dipakai juga setelah konversi romaji async, biar hasilnya konsisten
  /// dengan hasil sync.
  static String toEnglishName(String value) => _normalizeName(value);

  /// Rapikan nama latin:
  ///
  /// - NFKC: huruf & spasi full-width jadi half-width
  ///   ("ＤＨＩＫＡ　ＰＲＡＴＡＭＡ" → "DHIKA PRATAMA")
  /// - Kartu My Number nyimpen nama dengan spasi di tiap karakter
  ///   ("D H I K A  P R A T A M A") → "DHIKA PRATAMA". Spasi GANDA jadi
  ///   batas nama keluarga & nama depan, jadi preserved.
  static String _normalizeName(String value) {
    final nfk = _toHalfWidth(value).trim();
    if (nfk.isEmpty) return '';

    final parts = nfk
        .split(RegExp(r'\s{2,}'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final cleaned = parts.map((part) {
      final tokens = part
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();
      if (tokens.length > 1 && tokens.every((token) => token.length == 1)) {
        // "D H I K A" → "DHIKA"
        return tokens.join();
      }
      return tokens.join(' ');
    }).toList();

    return cleaned.join(' ').toUpperCase();
  }

  /// Gabung pref + city tanpa spasi (gaya alamat Japan).
  static String? _joinAddressParts(String? pref, String? city) {
    final parts = <String>[
      if (pref != null && pref.trim().isNotEmpty) pref.trim(),
      if (city != null && city.trim().isNotEmpty) city.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join();
  }

  /// Huruf & spasi full-width → half-width.
  ///
  /// Kartu (dan OCR) sering nulis nama dalam full-width:
  /// "ＤＨＩＫＡ　ＰＲＡＴＡＭＡ" → "DHIKA PRATAMA".
  static String _toHalfWidth(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune == 0x3000) {
        // IDEOGRAPHIC SPACE → spasi biasa
        buffer.write(' ');
      } else if (rune >= 0xFF01 && rune <= 0xFF5E) {
        // FULLWIDTH ASCII → ASCII
        buffer.write(String.fromCharCodes(<int>[rune - 0xFEE0]));
      } else {
        buffer.write(String.fromCharCodes(<int>[rune]));
      }
    }
    return buffer.toString();
  }

  /// Kode kebangsaan (alpha-2 / alpha-3 / numeric / nama) → label English.
  static _Candidate<String?> _nationality(
    String? raw,
    OrderingFieldSource source,
  ) {
    if (raw == null) return _Candidate(null, source);
    final value = raw.trim();
    if (value.isEmpty) return _Candidate(null, source);

    final label = resolveNationalityLabelEn(value) ?? _titleCase(value);
    return _Candidate(label, source);
  }

  /// Status tinggal → kode yang dipakai BE.
  ///
  /// Sumber mapping: [visa_status_mapping.dart] (ikut `caseVisaStatus()`
  /// di host app). Kalau nilainya udah berupa kode BE, dipakai apa adanya.
  static _Candidate<String?> _visaStatus(
    String? raw,
    OrderingFieldSource source,
  ) {
    if (raw == null) return _Candidate(null, source);
    final value = raw.trim();
    if (value.isEmpty) return _Candidate(null, source);

    final mapped = _lookupVisaStatus(value) ??
        (liquidVisaStatusOptions.contains(value) ? value : null) ??
        value;
    return _Candidate(mapped, source);
  }

  /// Cari kode status tinggal dari nilai kartu (bentuk Japan).
  ///
  /// besides the exact match, try matching again after removing spaces —
  /// the card prints "護 (介護)" while the OCR sometimes gives "護(介護)".
  static String? _lookupVisaStatus(String value) {
    final direct = liquidVisaStatusValues[value] ??
        liquidVisaStatusValuesShort[value];
    if (direct != null) return direct;

    final compact = value.replaceAll(RegExp(r'\s+'), '');
    for (final table in <Map<String, String>>[
      liquidVisaStatusValues,
      liquidVisaStatusValuesShort,
    ]) {
      for (final entry in table.entries) {
        if (entry.key.replaceAll(RegExp(r'\s+'), '') == compact) {
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Jenis kelamin → format form (`01: MALE`).
  ///
  /// Chip pakai `MALE`/`FEMALE`/`OTHERS`, OCR pakai `1`/`2`/`3`.
  static _Candidate<String?> _gender(
    String? raw,
    OrderingFieldSource source,
  ) {
    final label = resolveGenderLabel(raw);
    return _Candidate(label, source);
  }

  // --------------------------------------------------------------------------
  // Helper
  // --------------------------------------------------------------------------

  /// Ambil kandidat pertama yang beneran punya nilai.
  static _Candidate<T?> _pick<T>(List<_Candidate<T?>> candidates) {
    for (final candidate in candidates) {
      if (candidate.value != null) return candidate;
    }
    return _Candidate<T?>(null, OrderingFieldSource.manual);
  }

  static bool _hasJapaneseCharacters(String value) =>
      RegExp(r'[\u3040-\u30ff\u4e00-\u9faf]').hasMatch(value);

  static String _normalizeSpaces(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Format nilai mentah yang nggak ada di tabel jadi label enak dibaca:
  /// `FILIPINO` → `Filipino`.
  static String _titleCase(String raw) {
    final cleaned = _normalizeSpaces(raw.replaceAll('_', ' '));
    if (cleaned.isEmpty) return cleaned;
    return cleaned
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

/// Hasil resolusi nama: nilai latin (sync) + nilai kanji asli (buat async).
class _NameResult {
  final String? value;
  final String? kanjiRaw;
  final OrderingFieldSource source;

  const _NameResult(this.value, this.kanjiRaw, this.source);
}

/// Kandidat nilai dari satu sumber data.
class _Candidate<T> {
  final T? value;
  final OrderingFieldSource source;

  const _Candidate(this.value, this.source);
}
