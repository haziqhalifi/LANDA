import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

String indonesianText(String en) {
  const map = <String, String>{
    'Home': 'Beranda',
    'Reports': 'Laporan',
    'Map': 'Peta',
    'Profile': 'Profil',
    'Admin': 'Admin',
    'Warnings': 'Peringatan',
    'Quick Actions': 'Aksi Cepat',
    'Checklist': 'Daftar Periksa',
    'Safe Routes': 'Rute Aman',
    'Learn': 'Belajar',
    'Disaster Assistant': 'Asisten Bencana',
    'Report': 'Lapor',
    'Custom': 'Kustom',
    'Change': 'Ubah',
    'Retry': 'Coba Lagi',
    'Nearby Activity': 'Aktivitas Terdekat',
    'NEARBY ACTIVITY': 'AKTIVITAS TERDEKAT',
    'No nearby activity yet.': 'Belum ada aktivitas terdekat.',
    'Unable to load nearby activity.': 'Tidak dapat memuat aktivitas terdekat.',
    'Submit Report': 'Kirim Laporan',
    'WHAT ARE YOU OBSERVING?': 'APA YANG ANDA AMATI?',
    'Rising Water': 'Air Meningkat',
    'Cracks in Soil': 'Retakan Tanah',
    'Land Movement': 'Pergerakan Tanah',
    'Other Concern': 'Kekhawatiran Lainnya',
    'Vulnerable Person Help': 'Bantuan Kelompok Rentan',
    'Priority rescue alert': 'Peringatan prioritas penyelamatan',
    'CHOOSE LOCATION': 'PILIH LOKASI',
    'Pinned': 'Disematkan',
    'EVIDENCE': 'BUKTI',
    'ADD EVIDENCE': 'TAMBAH BUKTI',
    'Add Photo': 'Tambah Foto',
    'Add Photos': 'Tambah Foto',
    'Add Video': 'Tambah Video',
    'REPORT DETAILS': 'RINCIAN LAPORAN',
    'Title (optional)': 'Judul (opsional)',
    'Describe what happened, where, and how severe it is.':
        'Jelaskan apa yang terjadi, di mana, dan seberapa parah kondisinya.',
    'Choose Location': 'Pilih Lokasi',
    'Use my current location': 'Gunakan lokasi saya saat ini',
    'Use Pinned Location': 'Gunakan Lokasi Disematkan',
    'Tap map to pin exact location.':
        'Ketuk peta untuk menyematkan lokasi tepat.',
    'Search city or state in Malaysia...':
        'Cari kota atau provinsi di Malaysia...',
    'Settings': 'Pengaturan',
    'Language': 'Bahasa',
    'Notifications': 'Notifikasi',
    'Test Notification': 'Uji Notifikasi',
    'Family': 'Keluarga',
    'Dark Mode': 'Mode Gelap',
    'Log Out': 'Keluar',
    'Emergency Contacts': 'Kontak Darurat',
    'Emergency Contact': 'Kontak Darurat',
    'Add emergency contact': 'Tambah kontak darurat',
    'Add New': 'Tambah Baru',
    'Not Set': 'Belum Diatur',
    'Contacts': 'Kontak',
    'Ask about disasters...': 'Tanyakan tentang bencana...',
    'Assistant Chatbot': 'Asisten Chatbot',
    'Address': 'Alamat',
    'Contact name': 'Nama kontak',
    'Contact phone': 'Nomor telepon kontak',
    'Relationship': 'Hubungan',
    'Save Contact': 'Simpan Kontak',
    'Edit Profile': 'Sunting Profil',
    'Save': 'Simpan',
    'Cancel': 'Batal',
    'Name / Location': 'Nama / Lokasi',
    'Center name': 'Nama pusat',
    'Local Community Center': 'Pusat Komunitas Lokal',
    'Saved locally (not synced to backend yet).':
        'Disimpan secara lokal (belum disinkronkan ke backend).',
    'Use this language across the app':
        'Gunakan bahasa ini di seluruh aplikasi',
    'Choose Language': 'Pilih Bahasa',
    'Location unavailable': 'Lokasi tidak tersedia',
    'Updating location...': 'Memperbarui lokasi...',
    'Fetching live community updates for your area.':
        'Mengambil pembaruan komunitas langsung untuk area Anda.',
    'Unable to load warning feed right now. Pull down to retry.':
        'Tidak dapat memuat feed peringatan saat ini. Tarik ke bawah untuk mencoba lagi.',
    'View All': 'Lihat Semua',
    'Community Feed': 'Feed Komunitas',
    'Your Status': 'Status Anda',
    'Safety Status': 'Status Keamanan',
    'Preparedness': 'Kesiapsiagaan',
    'Secure': 'Aman',
    'Advisory': 'Imbauan',
    'Observe': 'Waspada',
    'Warning': 'Peringatan',
    'Evacuate': 'Evakuasi',
    '1 Active': '1 Aktif',
    'Active Hazards': 'Bahaya Aktif',
    'Local Weather Update': 'Pembaruan Cuaca Lokal',
    'Pull down to refresh the latest weather status for your location.':
        'Tarik ke bawah untuk menyegarkan status cuaca terbaru untuk lokasi Anda.',
    'AI Flood Risk Assessment': 'Penilaian Risiko Banjir AI',
    'Analysing flood risk…': 'Menganalisis risiko banjir…',
    'Checking': 'Memeriksa',
    'flood probability': 'probabilitas banjir',
    'Why did I get this result?': 'Mengapa saya mendapatkan hasil ini?',
    'What affected this result most':
        'Apa yang paling memengaruhi hasil ini',
    'Heavy rainfall risk can shift quickly. Check your nearest safe route now.':
        'Risiko hujan lebat dapat berubah cepat. Periksa rute aman terdekat Anda sekarang.',
    'Rainfall': 'Curah hujan',
    'Past floods nearby': 'Riwayat banjir di sekitar',
    'Distance to river': 'Jarak ke sungai',
    'Ground height': 'Ketinggian tanah',
    'People living nearby': 'Jumlah penduduk sekitar',
    'How wet the soil is': 'Tingkat kelembapan tanah',
    'Land steepness': 'Kemiringan tanah',
    'Model: ': 'Model: ',
    'SOS': 'SOS',
    'Medical support • Emergency line': 'Dukungan medis • Jalur darurat',
    'Manage family & live location sharing':
        'Kelola keluarga & berbagi lokasi langsung',
    'Primary contact • Not available':
        'Kontak utama • Tidak tersedia',
    'None': 'Tidak ada',
    'Unknown': 'Tidak diketahui',
    'Last verified: 2 days ago': 'Terakhir diverifikasi: 2 hari lalu',
    'IoT Siren Management': 'Manajemen Sirene IoT',
    'Register New Siren': 'Daftarkan Sirene Baru',
    'IoT Endpoint URL (optional)': 'URL Endpoint IoT (opsional)',
    'Endpoint URL must start with http:// or https://':
        'URL endpoint harus dimulai dengan http:// atau https://',
    'Please fill name, latitude, and longitude.':
        'Harap isi nama, latitude, dan longitude.',
    'Radius (km)': 'Radius (km)',
    'Radius must be between 0 and 100 km.':
        'Radius harus di antara 0 dan 100 km.',
    'Latitude must be between -90 and 90.':
        'Latitude harus di antara -90 dan 90.',
    'Longitude must be between -180 and 180.':
        'Longitude harus di antara -180 dan 180.',
    'Register': 'Daftar',
    'No sirens registered yet': 'Belum ada sirene yang terdaftar',
    'Tap + to register a community siren':
        'Ketuk + untuk mendaftarkan sirene komunitas',
    'Siren': 'Sirene',
    'Bring Online': 'Aktifkan',
    'Stop': 'Hentikan',
    'IoT endpoint configured': 'Endpoint IoT dikonfigurasi',
    'New Community Report': 'Laporan Komunitas Baru',
    'Share what you\'re observing to help LANDA predict local risks.':
        'Bagikan apa yang Anda amati untuk membantu LANDA memprediksi risiko lokal.',
    'Reset to my location': 'Atur ulang ke lokasi saya',
    'No questions available': 'Tidak ada pertanyaan tersedia',
    'Quiz': 'Kuis',
    'Before': 'Sebelum',
    'During': 'Saat',
    'After': 'Sesudah',
    'Easy': 'Mudah',
    'Medium': 'Sedang',
    'Hard': 'Sulit',
    'Correct: ': 'Benar: ',
    'Your answer: ': 'Jawaban Anda: ',
    'Answer Review': 'Tinjauan Jawaban',
    'Submit Quiz': 'Kirim Kuis',
    'Previous': 'Sebelumnya',
    'Next': 'Berikutnya',
    'Retake Quiz': 'Ulangi Kuis',
    'Back to Module': 'Kembali ke Modul',
    'Take Quiz': 'Ikuti Kuis',
    'AI Learning Progress': 'Progres Belajar AI',
    'Overall Mastery': 'Penguasaan Keseluruhan',
    'quizzes': 'kuis',
    'modules mastered': 'modul dikuasai',
    'Weak areas': 'Area lemah',
    'AI Recommendations': 'Rekomendasi AI',
    'Test notification sent': 'Notifikasi uji terkirim',
    'Send a test alert to verify notifications work':
        'Kirim peringatan uji untuk memastikan notifikasi berfungsi',
    'Notifications are not supported on this platform':
        'Notifikasi tidak didukung di platform ini',
    'Emergency contact updated successfully.':
        'Kontak darurat berhasil diperbarui.',
  };

  final direct = map[en];
  if (direct != null) return direct;

  if (en.startsWith('Local Weather: ')) {
    return 'Cuaca Lokal: ${en.substring('Local Weather: '.length)}';
  }
  if (en.startsWith('Connection issue • ')) {
    return 'Masalah koneksi • ${en.substring('Connection issue • '.length)}';
  }
  if (en.startsWith('Updating • ')) {
    return 'Memperbarui • ${en.substring('Updating • '.length)}';
  }
  if (en.startsWith('Model: ')) {
    return 'Model: ${en.substring('Model: '.length)}';
  }
  if (en.startsWith('Error loading profile: ')) {
    return 'Gagal memuat profil: ${en.substring('Error loading profile: '.length)}';
  }
  if (en.startsWith('Unable to update emergency contact: ')) {
    return 'Tidak dapat memperbarui kontak darurat: ${en.substring('Unable to update emergency contact: '.length)}';
  }
  if (en.startsWith('Siren "') && en.endsWith('" triggered')) {
    final name = en.substring(7, en.length - 10);
    return 'Sirene "$name" diaktifkan';
  }
  if (en.startsWith('Siren "') && en.endsWith('" stopped')) {
    final name = en.substring(7, en.length - 8);
    return 'Sirene "$name" dihentikan';
  }
  if (en.endsWith(' Nearby')) {
    return '${en.substring(0, en.length - 7)} di Sekitar';
  }

  return en;
}

enum AppLanguage {
  english('en', 'English'),
  indonesian('id', 'Bahasa Indonesia'),
  malay('ms', 'Bahasa Melayu'),
  chinese('zh', 'Chinese (Simplified)');

  const AppLanguage(this.code, this.displayLabel);

  final String code;
  final String displayLabel;

  static AppLanguage fromCode(String? code) {
    if (code == null || code.isEmpty) return AppLanguage.english;
    for (final lang in AppLanguage.values) {
      if (lang.code == code) return lang;
    }
    return AppLanguage.english;
  }
}

class AppLanguageController extends ChangeNotifier {
  AppLanguageController({required AppLanguage language}) : _language = language;

  static const _prefKey = 'app_language';
  AppLanguage _language;

  AppLanguage get language => _language;

  Locale get locale => switch (_language) {
    AppLanguage.english => const Locale('en'),
    AppLanguage.indonesian => const Locale('id'),
    AppLanguage.malay => const Locale('ms'),
    AppLanguage.chinese => const Locale('zh'),
  };

  static Future<AppLanguage> loadInitialLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return AppLanguage.fromCode(prefs.getString(_prefKey));
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, language.code);
  }

  String get label => _language.displayLabel;
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope not found in context');
    return scope!.notifier!;
  }

  static String tr(
    BuildContext context, {
    required String en,
    required String ms,
    String? zh,
  }) {
    return switch (of(context).language) {
      AppLanguage.english => en,
      AppLanguage.indonesian => (() {
        final id = indonesianText(en);
        return id == en ? ms : id;
      })(),
      AppLanguage.malay => ms,
      AppLanguage.chinese => zh ?? en,
    };
  }
}
