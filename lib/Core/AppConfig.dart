import 'package:flutter/material.dart';

/// -------- 1) نموذج إعدادات ديناميكي --------
class AppConfig {
  final String appTitle;      // العنوان الكبير وسط الصفحة
  final String brandName;     // اسم التطبيق في الـ AppBar
  final String logoUrl;       // رابط الشعار
  final Color primaryColor;   // اللون الرئيسي
  final bool useDark;         // وضع داكن/فاتح
  final String countStr;      // نص عداد
  late  String collection;    // اسم مجموعة Firestore
  late  String file;          // اسم ملف
  late  String document;      // اسم الوثيقة
  final String count;         // قيمة عداد

   AppConfig({
    required this.appTitle,
    required this.brandName,
    required this.logoUrl,
    required this.primaryColor,
    required this.useDark,
    required this.countStr,
    required this.collection,
    required this.file,
    required this.document,
    required this.count,
  });

  /// نسخة افتراضية (Default Config)
  factory AppConfig.defaultConfig() {
    return  AppConfig(
      appTitle: "الزيت الأفغاني - توليد الأكواد",
      brandName: "الزيت الأفغاني",
      logoUrl: "https://afghanioil.com/cdn/shop/files/325168988_547710190630949_2238189094490287597_n__1_-removebg-preview.png?v=1712944413&width=300",
      primaryColor: Color(0xFF2E7D32),
      useDark: false,
      countStr: "عدد الأكواد",
      collection: "codes",
      file: "default.xlsx",
      document: "defaultDoc",
      count: "0",
    );
  }

  /// لإنشاء نسخة جديدة مع تعديلات
  AppConfig copyWith({
    String? appTitle,
    String? brandName,
    String? logoUrl,
    Color? primaryColor,
    bool? useDark,
    String? countStr,
    String? collection,
    String? file,
    String? document,
    String? count,
  }) {
    return AppConfig(
      appTitle: appTitle ?? this.appTitle,
      brandName: brandName ?? this.brandName,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      useDark: useDark ?? this.useDark,
      countStr: countStr ?? this.countStr,
      collection: collection ?? this.collection,
      file: file ?? this.file,
      document: document ?? this.document,
      count: count ?? this.count,
    );
  }
}

/// -------- 2) مزوّد بسيط للإعدادات (ديناميكي) --------
class AppConfigController extends ChangeNotifier {
  AppConfig _config = AppConfig.defaultConfig();
  AppConfig get config => _config;

  void update(AppConfig newConfig) {
    _config = newConfig;
    notifyListeners();
  }

  void toggleTheme() {
    _config = _config.copyWith(useDark: !_config.useDark);
    notifyListeners();
  }
}
