// lib/Core/AppNotifications/AppNotifications.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

typedef NotificationActionHandler = Future<void> Function(String actionId);

class AppNotifications {
  static const int idGeneral   = 1000;
  static const int idFirestore = 1001;
  static const int idExcel     = 1002;

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'gen_code_channel', // غير قناة foreground
    'GenCode Progress',
    description: 'إشعارات تقدم توليد/رفع الأكواد',
    importance: Importance.high,
    showBadge: true,
  );

  static int _lastProgressInt = -1;
  static DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  static NotificationActionHandler? _actionHandler;

  /// للاستعمال داخل startService
  static const String _fgChannelId   = 'fg_service_channel';
  static const String _fgChannelName = 'Foreground Service';
  static const String _fgChannelDesc = 'Running background tasks';

  static Future<void> initNotificationsOnly({NotificationActionHandler? onAction}) async {
    _actionHandler = onAction;

    // 1) صلاحية الإشعارات (Android 13+)
    if (Platform.isAndroid) {
      final st = await Permission.notification.status;
      if (!st.isGranted) {
        await Permission.notification.request();
      }
    }

    // 2) تهيئة flutter_local_notifications فقط
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );
    final initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        final id = resp.actionId ?? '';
        if (id.isNotEmpty && _actionHandler != null) {
          try {
            await _actionHandler!(id);
          } catch (e, st) {
            if (kDebugMode) print('[AppNotifications] action handler error: $e\n$st');
          }
        }
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }




  // ————— إشعارات عادية/تقدّم —————

  static Future<void> showSimple({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool bigText = false,
  }) async {
    final android = AndroidNotificationDetails(
      _channel.id, _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high, priority: Priority.high,
      onlyAlertOnce: true,
      styleInformation: bigText ? BigTextStyleInformation(body) : null,
    );

    final details = NotificationDetails(
      android: android,
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  static Future<void> showOrUpdateProgress({
    required int id,
    required String title,
    required String body,
    required double progress, // 0..1
    bool ongoing = true,
    String? tag,
    List<AndroidNotificationAction>? actions,
  }) async {
    final now = DateTime.now();
    final value = (progress * 100).clamp(0, 100).toInt();

    if (value == _lastProgressInt &&
        now.difference(_lastUpdate).inMilliseconds < 300) {
      return;
    }
    _lastProgressInt = value;
    _lastUpdate = now;

    final android = AndroidNotificationDetails(
      _channel.id, _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high, priority: Priority.high,
      onlyAlertOnce: true,
      ongoing: ongoing,
      showProgress: true, maxProgress: 100, progress: value,
      playSound: false,
      tag: tag,
      actions: actions,
    );

    final details = NotificationDetails(
      android: android,
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(id, title, '$body ($value%)', details);
  }

  static AndroidNotificationAction get stopAction =>
      const AndroidNotificationAction(
        'stop', 'إيقاف',
        showsUserInterface: false,
        cancelNotification: false,
      );

  static Future<void> showSuccessDone({
    String title = 'تمت العملية',
    String body = 'تم الرفع والحفظ بنجاح ✅',
  }) async {
    resetProgressCache();
    await showSimple(id: idGeneral, title: title, body: body);
    await cancel(idFirestore);
    await cancel(idExcel);
  }

  static Future<void> showErrorDone(String error) async {
    resetProgressCache();
    await showSimple(
      id: idGeneral,
      title: 'فشل العملية',
      body: error,
      bigText: true,
    );
    await cancel(idFirestore);
    await cancel(idExcel);
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);
  static Future<void> cancelAll() => _plugin.cancelAll();

  static void resetProgressCache() {
    _lastProgressInt = -1;
    _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
