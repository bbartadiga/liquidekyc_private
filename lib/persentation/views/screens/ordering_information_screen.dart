import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/liquid_document_type.dart';
import '../../../core/constant/visa_status_mapping.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/japanese_romaji_helper.dart';
import '../../../data/models/chip_data.dart';
import '../../../data/models/ic_card_info_response.dart';
import '../../../data/models/id_document_information_response.dart';
import '../../../data/models/ocr_result.dart';
import '../../../data/models/ocr_results_response.dart';
import '../../../data/models/processed_information_response.dart';
import '../../../data/models/ordering_information_draft.dart';
import '../../styles/app_theme.dart';
import '../../viewmodels/ordering_information_viewmodel.dart';
import '../widgets/app_action_buttons.dart';
import '../widgets/app_date_field.dart';
import '../widgets/app_dropdown_field.dart';
import '../widgets/app_text_field.dart';

/// Halaman "Ordering Information".
///
/// Berdiri sendiri (nggak ada stepper) — purpose-nya nampilin data yang
/// sudah dibaca dari IC chip lalu form yang bisa diedit user.
///
/// Sumber data tiap field (urutan prioritas):
///
/// - Residence Card Number → id number kartu
/// - Expired Date           → tanggal kadaluarsa kartu
/// - Nationality            → kewarganegaraan pemilik kartu
/// - Visa Status            → status tinggal (在留資格)
/// - Permission to Land     → berlaku sampai izin masuk
/// - Period to Stay         → berlaku sampai masa tinggal
class OrderingInformationScreen extends StatefulWidget {
  const OrderingInformationScreen({
    super.key,
    this.chipData,
    this.sdkOcr,
    this.beOcr,
    this.beIcCardInfo,
    this.idDocumentInformation,
    this.processedInformation,
    this.documentType,
    this.initialNationality,
  });

  /// Data yang dibaca langsung dari IC chip (SDK).
  final LiquidChipDataModel? chipData;

  /// Hasil OCR dari SDK.
  final OcrResult? sdkOcr;

  /// Hasil OCR dari BE.
  final OcrResultsBeResponse? beOcr;

  /// Fallback kalau data chip & OCR nggak ada.
  final ICCardInfoResponse? beIcCardInfo;

  /// API 007 — data dokumen dari eKYC Manager.
  final IdDocumentInformationResponse? idDocumentInformation;

  /// API 027 — data yang sudah diproses Liquid (nama latin).
  final ProcessedInformationResponse? processedInformation;

  /// Jenis dokumen yang dipilih user di layar konfigurasi.
  final LiquidDocumentType? documentType;

  /// Kebangsaan yang dipilih user di layar konfigurasi — dipakai kalau
  /// kartu nggak nyediain kebangsaan (mis. My Number Card).
  final String? initialNationality;

  @override
  State<OrderingInformationScreen> createState() =>
      _OrderingInformationScreenState();
}

class _OrderingInformationScreenState extends State<OrderingInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final OrderingInformationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    appLogger.i(
      '[OrderingInfo] dibuka | chip=${widget.chipData != null} | '
      'sdkOcr=${widget.sdkOcr != null} | '
      'beOcr=${widget.beOcr?.isSuccess ?? false} | '
      'beIc=${widget.beIcCardInfo != null}',
      tag: kOrderingInfoLogTag,
    );
    _viewModel = OrderingInformationViewModel(
      documentType: widget.documentType,
      draft: OrderingInformationMapper.fromKycData(
        chipData: widget.chipData,
        sdkOcr: widget.sdkOcr,
        beOcr: widget.beOcr,
        beIcCardInfo: widget.beIcCardInfo,
        idDocumentInformation: widget.idDocumentInformation,
        processedInformation: widget.processedInformation,
        fallbackNationality: widget.initialNationality,
      ),
    );
    _resolveNameRomaji();
  }

  /// Nama kanji → romaji butuh jp_transliterate (async, ~50-100ms).
  ///
  /// Kana bisa dikonversi sinkron (kana_kit), tapi kanji nggak — jadi field
  /// "Ordering Customer Name (ENGLISH)" diisi setelah konversi selesai.
  void _resolveNameRomaji() {
    final raw = _viewModel.orderingCustomerNameRaw;
    if (raw == null || raw.isEmpty) return;

    // Kalau nama latin udah ada (mis. dari API 027 atau kartu yang nulis
    // nama half-width) → transliterasi lokal nggak perlu jalan.
    if (!_containsJapaneseCharacters(
      _viewModel.orderingCustomerNameEnglishController.text,
    )) {
      return;
    }

    // Helper-nya sudah catch error-nya sendiri (balikin null kalau gagal),
    // jadi di sini cukup dijaga null + mounted.
    JapaneseRomajiHelper.toTitleCaseRomajiAsync(raw).then((romaji) {
      if (!mounted || romaji == null || romaji.isEmpty) return;
      _viewModel.setOrderingCustomerName(romaji);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OrderingInformationViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Account Registrations',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
            iconSize: AppDimens.backIcon,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
            // Builder supaya context-nya di bawah provider, jadi
            // context.watch di [_buildForm] ketemu viewmodel.
            child: Builder(builder: _buildForm),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final vm = context.watch<OrderingInformationViewModel>();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Text(
            'Ordering Information',
            style: AppTheme.sectionTitleStyle,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: vm.idNumberFieldLabel,
            required: true,
            source: vm.sourceOf(OrderingField.residenceCardNumber),
            controller: vm.residenceCardNumberController,
            hintText: vm.idNumberFieldLabel,
            textCapitalization: TextCapitalization.characters,
            validator: (value) =>
                _required(value, OrderingField.residenceCardNumber),
            onChanged: (_) =>
                vm.notifyFieldEdited(OrderingField.residenceCardNumber),
          ),
          const SizedBox(height: AppDimens.fieldGap),
          AppDateField(
            label: 'Expired Date',
            required: true,
            source: vm.sourceOf(OrderingField.expiredDate),
            yearController: vm.expiredYearController,
            monthController: vm.expiredMonthController,
            dayController: vm.expiredDayController,
            onPickDate: () => _pickDate(
              initialDate: vm.lastExpiredDate,
              firstDate: DateTime(2015, 1, 1),
              lastDate: DateTime(2032, 12, 31),
              onPicked: vm.setExpiredDate,
            ),
          ),
          const SizedBox(height: AppDimens.fieldGap),
          AppDropdownField<String>(
            label: 'Nationality',
            required: true,
            source: vm.sourceOf(OrderingField.nationality),
            hintText: 'Choose Nationality',
            items: vm.nationalityOptions,
            value: vm.nationality,
            onChanged: vm.setNationality,
            validator: (value) => _required(value, OrderingField.nationality),
          ),
          const SizedBox(height: AppDimens.fieldGap),
          // Field di bawah ini cuma relevan buat WNA. Aturan sama dengan
          // host app (ordering_information_screen.dart): nationality ==
          // 'Indonesian' → tampilkan visa status + permission to land/stay.
          if (vm.nationality == liquidNationalityIndonesian) ...[
            AppDropdownField<String>(
              label: 'Visa Status',
                required: true,
                source: vm.sourceOf(OrderingField.visaStatus),
                hintText: 'Choose Visa Status',
                items: vm.visaStatusOptions,
                value: vm.visaStatus,
                onChanged: vm.setVisaStatus,
                validator: (value) =>
                    _required(value, OrderingField.visaStatus),
              ),
              const SizedBox(height: AppDimens.fieldGap),
              AppDateField(
                label: 'Permission to Land',
                required: true,
                source: vm.sourceOf(OrderingField.permissionToLandDate),
                yearController: vm.permissionToLandYearController,
                monthController: vm.permissionToLandMonthController,
                dayController: vm.permissionToLandDayController,
                onPickDate: () => _pickDate(
                  initialDate: vm.lastPermissionToLandDate,
                  firstDate: DateTime(2015, 1, 1),
                  lastDate: DateTime(2045, 12, 31),
                  onPicked: vm.setPermissionToLandDate,
                ),
              ),
              const SizedBox(height: AppDimens.fieldGap),
              AppDateField(
                label: 'Period to Stay',
                source: vm.sourceOf(OrderingField.periodToStayDate),
                yearController: vm.periodToStayYearController,
                monthController: vm.periodToStayMonthController,
                dayController: vm.periodToStayDayController,
                onPickDate: () => _pickDate(
                  initialDate: vm.lastPeriodToStayDate,
                  firstDate: DateTime(2015, 1, 1),
                  lastDate: DateTime(2045, 12, 31),
                  onPicked: vm.setPeriodToStayDate,
                ),
              ),
              const SizedBox(height: AppDimens.fieldGap),
            ],
          AppTextField(
            label: 'Ordering Customer Name (ENGLISH)',
            required: true,
            source: vm.sourceOf(OrderingField.orderingCustomerNameEnglish),
            controller: vm.orderingCustomerNameEnglishController,
            hintText: 'Ordering Customer Name (ENGLISH)',
            // Batas 150 char (spec 016 hal. 5).
            maxLength: 150,
            textCapitalization: TextCapitalization.characters,
            validator: (value) => _required(
              value,
              OrderingField.orderingCustomerNameEnglish,
            ),
            onChanged: (_) => vm.notifyFieldEdited(
              OrderingField.orderingCustomerNameEnglish,
            ),
          ),
          const SizedBox(height: AppDimens.fieldGap),
          AppDateField(
            label: 'Date of Birth',
            required: true,
            source: vm.sourceOf(OrderingField.dateOfBirth),
            yearController: vm.dateOfBirthYearController,
            monthController: vm.dateOfBirthMonthController,
            dayController: vm.dateOfBirthDayController,
            onPickDate: () => _pickDate(
              initialDate: vm.lastDateOfBirth,
              firstDate: DateTime(1900, 1, 1),
              lastDate: DateTime.now(),
              onPicked: vm.setDateOfBirth,
            ),
          ),
          const SizedBox(height: AppDimens.fieldGap),
          AppDropdownField<String>(
            label: 'Gender',
            required: true,
            source: vm.sourceOf(OrderingField.gender),
            hintText: 'Choose Gender',
            items: vm.genderOptions,
            value: vm.gender,
            onChanged: vm.setGender,
            validator: (value) => _required(value, OrderingField.gender),
          ),
          const SizedBox(height: AppDimens.fieldGap),
          AppTextField(
            label: 'Postal Code',
            required: true,
            source: vm.sourceOf(OrderingField.postalCode),
            controller: vm.postalCodeController,
            hintText: 'Postal Code',
            keyboardType: TextInputType.number,
            validator: (value) => _required(value, OrderingField.postalCode),
            onChanged: (_) => vm.notifyFieldEdited(OrderingField.postalCode),
          ),
          const SizedBox(height: AppDimens.fieldGap),
          // Field alamat: multi-line + batas karakter sesuai spec 016
          // (address1 = 300, address2 = 100, address3 = 100). Kalau 1 baris,
          // alamat panjang kepotong di tepi field (catatan tester di PPT).
          AppTextField(
            label: 'Address 1 Town / City',
            required: true,
            source: vm.sourceOf(OrderingField.address1),
            controller: vm.address1Controller,
            hintText: 'Town/City',
            maxLines: 3,
            maxLength: 300,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            validator: (value) => _required(value, OrderingField.address1),
            onChanged: (_) => vm.notifyFieldEdited(OrderingField.address1),
          ),
          const SizedBox(height: AppDimens.fieldGap),
          AppTextField(
            label: 'Address 2 Street or other details',
            required: true,
            source: vm.sourceOf(OrderingField.address2),
            controller: vm.address2Controller,
            hintText: 'Street or other details',
            maxLines: 3,
            maxLength: 100,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            validator: (value) => _required(value, OrderingField.address2),
            onChanged: (_) => vm.notifyFieldEdited(OrderingField.address2),
          ),
          const SizedBox(height: AppDimens.fieldGap),
          AppTextField(
            label: 'Address 3 Building / Room No',
            source: vm.sourceOf(OrderingField.address3),
            controller: vm.address3Controller,
            hintText: 'Building / Room No',
            maxLines: 3,
            maxLength: 100,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => vm.notifyFieldEdited(OrderingField.address3),
          ),
          const SizedBox(height: 40),
          AppFinishButton(
            onPressed: () {
              final valid = _formKey.currentState?.validate() ?? false;
              appLogger.i(
                valid
                    ? '[OrderingInfo] selesai | form valid'
                    : '[OrderingInfo] selesai dibatalkan | form tidak valid',
                tag: kOrderingInfoLogTag,
              );
              if (!valid) return;
              // TODO: submit data form ke BE, lalu tutup flow.
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(height: 16),
          const AppLogButton(),
        ],
      ),
    );
  }

  /// True kalau teksnya masih mengandung huruf kana/kanji.
  static bool _containsJapaneseCharacters(String value) =>
      RegExp(r'[\u3040-\u30ff\u4e00-\u9faf]').hasMatch(value);

  String? _required(String? value, OrderingField field) {
    if (value == null || value.trim().isEmpty) {
      _viewModel.logValidationFailed(field);
      return AppTheme.requiredMessage;
    }
    return null;
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: AppTheme.datePickerTheme(context),
        child: child!,
      ),
    );

    if (picked == null) return;
    onPicked(picked);
  }
}
