class ApiConstance {
  // ------------------- Base URLs -------------------
  static const String baseUrlQuran = "https://www.mp3quran.net/api/v3";
  static const String baseUrlAladhan = 'https://api.aladhan.com/v1/';
  static const String baseUrlHadith = 'https://hadithapi.com/api/';

  // ------------------- Local Database -------------------
  static const String localDbName = "database.db";
  static const String localDbazkar = "'azkar-db'";


  // ------------------- Quran API Endpoints -------------------
  static const String ayatTiming = "ayat_timing";
  static const String ayatTimingReads = "ayat_timing/reads";
  static const String reciters = "reciters";
  static const String soar = "soar";
  static const String radios = "radios";
  static const String liveTv = "live-tv";
  static const String suwar = "suwar";
  static const String tadabor = "tadabor";
  static const String tafsir = "tafsir";
  static const String riwayat = "riwayat";



  // ------------------- Local Database Table Names -------------------
  static const String tableAsmaAllah = "asmaallah";
  static const String tableQuranDua = "prayer";
  static const String tableTasbih = "tasbih";

  // Azkar Tables
  static const String tableAzkarCategory = 'azkar_category';
  static const String tableFavoriteCategory = 'favorite_category';
  static const String tableAzkar = 'azkar';
  static const String tableFavoriteAzkar = 'favorite_azkar';
  static const String tablePrayer = 'prayer';
  static const String tableFavoritePrayer = 'favorite_prayer';
  static const String tableAzkarSections = 'sections';



  // ------------------- Local Database Table Names -------------------
  static const String azkarCategoryTable = 'category';
  static const String azkarItemTable = 'azkar';



  // ------------------- Aladhan API Calendar  -------------------
  static const String gToHCalendar = 'gToHCalendar';
  static const String gregorianCalendar = 'hToGCalendar';
  static const String gToH = 'gToH';
  static const String hToG = 'hToG';
  static const String holidays = 'holidays';
  static const String nextHoliday = 'nextHijriHoliday';
  static const String currentIslamicYear = 'currentIslamicYear';
  static const String holidayByHijriDay = 'islamicHolidaysByHijriYear';
  static const String specialDays = 'specialDays';

  // ------------------- Paryer Time API -------------------
  static String prayerTimeByDate(String prayerDate) {
    return '/timingsByCity/$prayerDate';
  }

  // دالة لإرجاع رابط اتجاه القبلة
  static String qiblaDirection(double latitude, double longitude) {
    return '/qibla/$latitude/$longitude';
  }

  // ------------------- Paryer Time API -------------------
  static const String apiKey = r'$2y$10$KmTCEEmBR9KWMIQj9wyHeufXOdtyynXsy8PRG5fNrAaZ2PkwqJGG';

  static const String booksEndpoint = 'books';
  static String chapterEndpoint(String bookSlug) => '$bookSlug/chapters';
  static const String hadithPageEndpoint = 'hadiths/';
}
