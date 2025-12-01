import 'package:flutter/material.dart';

// ✔ خدمات المشروع
import 'package:triing/Core/servies/services_locator.dart';

// ✔ الإشعارات
import 'package:triing/Core/AppNotifications/AppNotifications.dart';

// ✔ إعدادات التطبيق
import 'package:triing/Core/AppConfig.dart';

// ✔ بوابة الصلاحيات
import 'package:triing/Core/PermissionGate/PermissionGate.dart';

// ✔ الصفحة الرئيسية
import 'package:triing/genertcode/presentation/pages/Home/Home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 بدء تشغيل التطبيق...');

  // تهيئة الـ Service Locator
  await GenCodeServicesLocator().init();

  // تهيئة الإشعارات فقط (بدون أي Foreground Service)
  await AppNotifications.initNotificationsOnly(
    onAction: (id) async {
      print('🔔 Notification action tapped: $id');
      // هنا لاحقًا لو حبيت تتعامل مع أكشن الإشعار
    },
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final AppConfigController configController = AppConfigController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Code Generator BG',
      home: PermissionGate(
        config: const AppPermissionsConfig(
          askNotifications: true,
          askLocation: false,
          askLegacyStorage: false,
        ),
        child: Home(configController: configController),
      ),
    );
  }
}
