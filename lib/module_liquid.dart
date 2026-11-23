// --- 1. Entry Point Widget ---
// Widget utama yang akan dipanggil oleh project utama
export 'app/app.dart';

// --- 2. Data Models (Hasil eKYC) ---
// Supaya project utama bisa membaca data yang dihasilkan (Nama, NIK, Liveness score, dll)
export 'data/models/kyc_result.dart';
export 'data/models/document_result.dart';
export 'data/models/face_results.dart';
export 'data/models/chip_result.dart';

// --- 3. ViewModels / State Management ---
// Jika project utama ingin memantau loading state atau status proses secara manual
export 'persentation/viewmodels/kyc_viewmodel.dart';

// --- 4. Konfigurasi ---
// Untuk menyeting API Key, URL, atau parameter SDK dari project utama
export 'core/constant/liquid_constants.dart';

// --- 5. Screens (Opsional) ---
// Jika project utama ingin langsung lompat ke screen tertentu (misal: Result Screen)
export 'persentation/views/screens/kyc_home_screen.dart';
export 'persentation/views/screens/kyc_result_screen.dart';
export 'persentation/views/screens/kyc_config_screen.dart';
export 'persentation/views/screens/ordering_information_screen.dart';
export 'persentation/viewmodels/ordering_information_viewmodel.dart';
export 'data/models/ordering_information_draft.dart';
