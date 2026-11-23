/// Mapping status tinggal (在留資格) → nilai yang dipakai BE.
///
/// SUMBER: host app `mobileremittance2_upgrade_refactor_liquidekyc`
/// → `lib/src/presentation/screens/register_account_screen/ordering_information_screen.dart`
/// → fungsi `caseVisaStatus()`.
///
/// Kunci = string yang tercetak di kartu, nilai = kode yang dikirim ke BE
/// (huruf kapital). BE host app menyimpan list visa status-nya di
/// `POST /v2.1/list/visa-status` dengan `value` = kode di bawah ini dan
/// `key` = label yang nicer.
///
/// JANGAN nambah status di sini tanpa sumber yang jelas — daftar ini harus
/// sinkron dengan list BE.
const Map<String, String> liquidVisaStatusValues = <String, String>{
  '交(外交)': 'DIPLOMAT',
  '用(公用)': 'OFFICIAL',
  '授(教授)': 'PROFESSOR',
  '術(芸術)': 'ARTIST',
  '教(宗教)': 'RELIGIOUS ACTIVITIES',
  '道(報道)': 'JOURNALIST',
  '1号(高度専門職1号)': 'HIGHLY SKILLED PROFESSIONAL 1',
  '2号(高度専門職2号)': 'HIGHLY SKILLED PROFESSIONAL 2',
  '理(経営・管理)': 'BUSINESS MANAGER',
  '務(法律・会計業務)': 'LEGAL/ACCOUNTING SERVICES',
  '療(医療)': 'MEDICAL SERVICES',
  '究（研究)': 'RESEARCHER',
  '育(教育)': 'INSTRUCTOR',
  '技術・人文知識・国際業務':
      'ENGINEER/SPECIALIST IN HUMANITIES/INTERNATIONAL SERVICES',
  '転勤(企業内転勤)': 'INTRA-COMPANY TRANSFEREE',
  '護 (介護)': 'CARE WORKER',
  '行(興行)': 'ENTERTAINER',
  '能(技能)': 'SKILLED WORKER',
  '能1号(特定技能1号)': 'SPECIFIED SKILLED WORKER 1',
  '能2号(特定技能2号)': 'SPECIFIED SKILLED WORKER 2',
  '習1号(技能実習1号)': 'TECHNICAL INTERN TRAINING 1',
  '習2号・3号(技能実習2号・3号)': 'TECHNICAL INTERN TRAINING 2 and 3',
  '文化活動': 'CULTURAL ACTIVITIES',
  '学(留学)': 'STUDENT',
  '修(研修)': 'TRAINEE',
  '家族滞在': 'DEPENDENT',
  '特定活動': 'DESIGNATED ACTIVITIES',
  '永住者': 'PERMANENT RESIDENT',
  '日本人の配偶者等': 'SPOUSE/CHILD OF JAPANESE',
  '永住者の配偶者等': 'SPOUSE/CHILD of PERMANENT RESIDENT',
  '定住者': 'LONG-TERM RESIDENT',
};

/// Bentuk polos (tanpa kategori induk) yang Sometimes dikasih OCR.
///
/// Data nyata di PPT "Result OCR NFC Digiremit": OCR SDK ngasih
/// `resident_status: "企業内転勤"` (bentuk polos), sementara host app ngecek
/// bentuk berkategori `"転勤(企業内転勤)"`. Dua-duanya dipetakan ke kode
/// yang sama.
const Map<String, String> liquidVisaStatusValuesShort = <String, String>{
  '企業内転勤': 'INTRA-COMPANY TRANSFEREE',
  '高度専門職': 'HIGHLY SKILLED PROFESSIONAL',
};

/// Opsi dropdown status tinggal = seluruh kode yang ada di BE.
///
/// Urutan mengikuti [liquidVisaStatusValues] (urutan di source).
List<String> get liquidVisaStatusOptions {
  final seen = <String>{};
  return <String>[
    for (final value in liquidVisaStatusValues.values)
      if (seen.add(value)) value,
  ];
}

/// Opsi dropdown kebangsaan.
///
/// SUMBER: host app `ordering_information_screen.dart` →
/// `nationalityTypeList = ['INDONESIA', 'JAPANESE']` (hardcoded di sana).
///
/// Bentuknya dilemma ke huruf kapital biar sama dengan nilai BE
/// (`state.data.nationality == 'Indonesian'` di host app) dan sama dengan
/// mockup halaman Ordering Information.
const List<String> liquidNationalityOptions = <String>['Indonesian', 'Japanese'];

/// Label dropdown kebangsaan yang dipakai host app untuk menentukan field
/// visa status mana yang relevan.
const String liquidNationalityIndonesian = 'Indonesian';
