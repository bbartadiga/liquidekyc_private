import 'package:flutter/material.dart';
import '../../core/constant/liquid_document_type.dart';
import '../../core/constant/visa_status_mapping.dart';
import '../../core/services/app_logger.dart';
import '../../data/models/ordering_information_draft.dart';

/// Tag untuk semua log halaman Ordering Information.
const String kOrderingInfoLogTag = 'OrderingInfo';

/// State + logic form "Ordering Information".
///
/// Semua state field form ada di sini supaya layar cuma merender dan
/// validasinya didelegasikan ke viewmodel.
class OrderingInformationViewModel extends ChangeNotifier {
  OrderingInformationViewModel({
    OrderingInformationDraft? draft,
    LiquidDocumentType? documentType,
  }) {
    _documentType = documentType;
    final source = draft ?? OrderingInformationDraft.empty;
    _sources = Map<OrderingField, OrderingFieldSource>.from(source.sources);

    residenceCardNumberController =
        TextEditingController(text: source.residenceCardNumber);

    expiredYearController = TextEditingController();
    expiredMonthController = TextEditingController();
    expiredDayController = TextEditingController();

    permissionToLandYearController = TextEditingController();
    permissionToLandMonthController = TextEditingController();
    permissionToLandDayController = TextEditingController();

    periodToStayYearController = TextEditingController();
    periodToStayMonthController = TextEditingController();
    periodToStayDayController = TextEditingController();

    orderingCustomerNameEnglishController =
        TextEditingController(text: source.orderingCustomerNameEnglish);
    _orderingCustomerNameRaw = source.orderingCustomerNameRaw;
    dateOfBirthYearController = TextEditingController();
    dateOfBirthMonthController = TextEditingController();
    dateOfBirthDayController = TextEditingController();
    postalCodeController = TextEditingController(text: source.postalCode);
    address1Controller = TextEditingController(text: source.address1);
    address2Controller = TextEditingController(text: source.address2);
    address3Controller = TextEditingController(text: source.address3);

    _nationality = source.nationality;
    _visaStatus = source.visaStatus;
    _gender = source.gender;
    _nationalityOptions = _mergeOptions(
      baseNationalityOptions,
      source.nationality,
    );
    _visaStatusOptions = _mergeOptions(
      baseVisaStatusOptions,
      source.visaStatus,
    );
    _genderOptions = _mergeOptions(baseGenderOptions, source.gender);

    expiredDate = source.expiredDate;
    permissionToLandDate = source.permissionToLandDate;
    periodToStayDate = source.periodToStayDate;
    dateOfBirth = source.dateOfBirth;

    _syncDateControllers();
    _logDraftSummary();
  }

  /// Log ringkasan sumber data per field.
  ///
  /// Cuma nulis field + sumber (bukan nilainya) — nilai form ini PII, jadi
  /// nggak boleh masuk log.
  void _logDraftSummary() {
    final empty = <String>[];
    final sourceSummary = <String>[];

    for (final field in OrderingField.values) {
      if (!isFilled(field)) empty.add(field.name);
      final source = sourceOf(field);
      final label = (source == null || source == OrderingFieldSource.manual)
          ? '-'
          : source.label;
      sourceSummary.add('${field.name} -> $label');
    }

    appLogger.i(
      '[OrderingInfo] draft | filled=${OrderingField.values.length - empty.length}'
      '/${OrderingField.values.length} | kosong=[${empty.join(', ')}]',
      tag: kOrderingInfoLogTag,
    );
    appLogger.d(
      '[OrderingInfo] source | ${sourceSummary.join(' | ')}',
      tag: kOrderingInfoLogTag,
    );
  }

  /// True kalau [field] punya nilai (dari data maupun dari user).
  bool isFilled(OrderingField field) {
    switch (field) {
      case OrderingField.residenceCardNumber:
        return residenceCardNumberController.text.trim().isNotEmpty;
      case OrderingField.expiredDate:
        return expiredDate != null;
      case OrderingField.nationality:
        return _nationality != null;
      case OrderingField.visaStatus:
        return _visaStatus != null;
      case OrderingField.permissionToLandDate:
        return permissionToLandDate != null;
      case OrderingField.periodToStayDate:
        return periodToStayDate != null;
      case OrderingField.orderingCustomerNameEnglish:
        return orderingCustomerNameEnglishController.text.trim().isNotEmpty;
      case OrderingField.dateOfBirth:
        return dateOfBirth != null;
      case OrderingField.gender:
        return _gender != null;
      case OrderingField.postalCode:
        return postalCodeController.text.trim().isNotEmpty;
      case OrderingField.address1:
        return address1Controller.text.trim().isNotEmpty;
      case OrderingField.address2:
        return address2Controller.text.trim().isNotEmpty;
      case OrderingField.address3:
        return address3Controller.text.trim().isNotEmpty;
    }
  }

  /// Log saat user ngubah field manual (nilai nggak dicatet).
  void notifyFieldEdited(OrderingField field) {
    appLogger.d(
      '[OrderingInfo] diubah manual | field=${field.name}',
      tag: kOrderingInfoLogTag,
    );
  }

  /// Log saat validasi field gagal — nama field aja, nilainya nggak.
  void logValidationFailed(OrderingField field) {
    appLogger.w(
      '[OrderingInfo] validasi gagal | field=${field.name}',
      tag: kOrderingInfoLogTag,
    );
  }

  /// Opsi dropdown bawaan. Nilai dari IC chip yang nggak ada di daftar ini
  /// tetap bakal nampil sebagai opsi tambahan.
  static const List<String> baseNationalityOptions = liquidNationalityOptions;

  /// Opsi dropdown status tinggal = kode-kode yang ada di BE host app
  /// (sumber: [visa_status_mapping.dart]).
  static final List<String> baseVisaStatusOptions = liquidVisaStatusOptions;

  /// Format gender sesuai form registrasi.
  static const List<String> baseGenderOptions = <String>[
    '01: MALE',
    '02: FEMALE',
    '03: OTHERS',
  ];

  late final TextEditingController residenceCardNumberController;

  late final TextEditingController expiredYearController;
  late final TextEditingController expiredMonthController;
  late final TextEditingController expiredDayController;

  late final TextEditingController permissionToLandYearController;
  late final TextEditingController permissionToLandMonthController;
  late final TextEditingController permissionToLandDayController;

  late final TextEditingController periodToStayYearController;
  late final TextEditingController periodToStayMonthController;
  late final TextEditingController periodToStayDayController;

  late final TextEditingController orderingCustomerNameEnglishController;
  late final TextEditingController dateOfBirthYearController;
  late final TextEditingController dateOfBirthMonthController;
  late final TextEditingController dateOfBirthDayController;
  late final TextEditingController postalCodeController;
  late final TextEditingController address1Controller;
  late final TextEditingController address2Controller;
  late final TextEditingController address3Controller;

  DateTime? expiredDate;
  DateTime? permissionToLandDate;
  DateTime? periodToStayDate;
  DateTime? dateOfBirth;

  String? _nationality;
  String? _visaStatus;
  String? _gender;

  /// Jenis dokumen yang dipilih user di layar konfigurasi.
  LiquidDocumentType? _documentType;

  /// Nama kanji asli — dibikin romaji sama layar (async, jp_transliterate).
  String? _orderingCustomerNameRaw;

  late final List<String> _nationalityOptions;
  late final List<String> _visaStatusOptions;
  late final List<String> _genderOptions;

  late Map<OrderingField, OrderingFieldSource> _sources;

  /// Sumber data untuk [field] — null kalau fieldnya nggak terisi dari data
  /// (diisi manual user).
  OrderingFieldSource? sourceOf(OrderingField field) => _sources[field];

  /// Label kebangsaan di form (bahasa Inggris).
  ///
  /// Nilainya sama dengan kebangsaan di BE ('Indonesian' / 'Japanese') —
  /// ini yang bikin field visa status cuma muncul buat WNA Indonesia.
  static String? nationalityLabel(Nationality? nationality) {
    switch (nationality) {
      case Nationality.indonesia:
        return 'Indonesian';
      case Nationality.japan:
        return 'Japanese';
      case null:
        return null;
    }
  }

  /// Judul field nomor kartu — ikut jenis dokumen yang dipilih user.
  ///
  /// Residence Card → "Residence Card Number", Driver's Licence →
  /// "Driver's Licence Number", National Identity Card → "National Identity
  /// Card Number".
  String get idNumberFieldLabel {
    final type = _documentType;
    if (type == null) return 'ID Number';
    return '${type.displayName} Number';
  }

  String? get nationality => _nationality;

  String? get visaStatus => _visaStatus;

  String? get gender => _gender;

  /// Nama kanji asli yang belum bisa di-romaji sinkron.
  String? get orderingCustomerNameRaw => _orderingCustomerNameRaw;

  List<String> get nationalityOptions => List.unmodifiable(_nationalityOptions);

  List<String> get visaStatusOptions => List.unmodifiable(_visaStatusOptions);

  List<String> get genderOptions => List.unmodifiable(_genderOptions);

  void setNationality(String? value) {
    if (_nationality == value) return;
    _nationality = value;
    notifyFieldEdited(OrderingField.nationality);
    notifyListeners();
  }

  void setVisaStatus(String? value) {
    if (_visaStatus == value) return;
    _visaStatus = value;
    notifyFieldEdited(OrderingField.visaStatus);
    notifyListeners();
  }

  /// Isi field nama dengan hasil konversi romaji async.
  void setOrderingCustomerName(String value) {
    final normalized = OrderingInformationMapper.toEnglishName(value);
    if (normalized.isEmpty) return;
    orderingCustomerNameEnglishController.text = normalized;
    notifyListeners();
  }

  void setGender(String? value) {
    if (_gender == value) return;
    _gender = value;
    notifyFieldEdited(OrderingField.gender);
    notifyListeners();
  }

  void setDateOfBirth(DateTime value) {
    dateOfBirth = value;
    _writeDate(
      dateOfBirthYearController,
      dateOfBirthMonthController,
      dateOfBirthDayController,
      value,
    );
    notifyFieldEdited(OrderingField.dateOfBirth);
    notifyListeners();
  }

  void setExpiredDate(DateTime value) {
    expiredDate = value;
    _writeDate(
      expiredYearController,
      expiredMonthController,
      expiredDayController,
      value,
    );
    notifyFieldEdited(OrderingField.expiredDate);
    notifyListeners();
  }

  void setPermissionToLandDate(DateTime value) {
    permissionToLandDate = value;
    _writeDate(
      permissionToLandYearController,
      permissionToLandMonthController,
      permissionToLandDayController,
      value,
    );
    notifyFieldEdited(OrderingField.permissionToLandDate);
    notifyListeners();
  }

  void setPeriodToStayDate(DateTime value) {
    periodToStayDate = value;
    _writeDate(
      periodToStayYearController,
      periodToStayMonthController,
      periodToStayDayController,
      value,
    );
    notifyFieldEdited(OrderingField.periodToStayDate);
    notifyListeners();
  }

  /// Tanggal terakhir yang dipilih per field, dipakai buat inisialisasi
  /// date picker.
  DateTime get lastExpiredDate => expiredDate ?? DateTime.now();

  DateTime get lastPermissionToLandDate =>
      permissionToLandDate ?? DateTime.now();

  DateTime get lastPeriodToStayDate => periodToStayDate ?? DateTime.now();

  DateTime get lastDateOfBirth => dateOfBirth ?? DateTime(1990, 1, 1);

  /// Gabung opsi bawaan dengan nilai dari chip (kalau belum ada di daftar).
  static List<String> _mergeOptions(List<String> base, String? value) {
    final options = List<String>.from(base);
    if (value != null && value.trim().isNotEmpty && !options.contains(value)) {
      options.add(value);
    }
    return options;
  }

  void _syncDateControllers() {
    final expired = expiredDate;
    if (expired != null) {
      _writeDate(
        expiredYearController,
        expiredMonthController,
        expiredDayController,
        expired,
      );
    }

    final permissionToLand = permissionToLandDate;
    if (permissionToLand != null) {
      _writeDate(
        permissionToLandYearController,
        permissionToLandMonthController,
        permissionToLandDayController,
        permissionToLand,
      );
    }

    final periodToStay = periodToStayDate;
    if (periodToStay != null) {
      _writeDate(
        periodToStayYearController,
        periodToStayMonthController,
        periodToStayDayController,
        periodToStay,
      );
    }

    final dob = dateOfBirth;
    if (dob != null) {
      _writeDate(
        dateOfBirthYearController,
        dateOfBirthMonthController,
        dateOfBirthDayController,
        dob,
      );
    }
  }

  void _writeDate(
    TextEditingController year,
    TextEditingController month,
    TextEditingController day,
    DateTime value,
  ) {
    year.text = '${value.year}';
    month.text = '${value.month}';
    day.text = '${value.day}';
  }

  @override
  void dispose() {
    residenceCardNumberController.dispose();
    expiredYearController.dispose();
    expiredMonthController.dispose();
    expiredDayController.dispose();
    permissionToLandYearController.dispose();
    permissionToLandMonthController.dispose();
    permissionToLandDayController.dispose();
    periodToStayYearController.dispose();
    periodToStayMonthController.dispose();
    periodToStayDayController.dispose();
    orderingCustomerNameEnglishController.dispose();
    dateOfBirthYearController.dispose();
    dateOfBirthMonthController.dispose();
    dateOfBirthDayController.dispose();
    postalCodeController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
    address3Controller.dispose();
    super.dispose();
  }
}
