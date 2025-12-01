/*
import 'dart:convert';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:triing/genertcode/data/data_sources/Genert_code_data_soures.dart';
import 'package:triing/genertcode/data/models/IdModel.dart';
import 'package:triing/genertcode/domain/entities/IdInfo.dart';

class BgKeys {
  static const payload = 'gen_code_payload'; // المفتاح المستخدم في saveData/getData
}

@pragma('vm:entry-point')
void startGenCodeTask() {
  // مهم: دالة توب-ليفيل تستدعي setTaskHandler
  FlutterForegroundTask.setTaskHandler(_GenCodeTaskHandler());
}

class _GenCodeTaskHandler extends TaskHandler {
  SendPort? _sendPort;

  Future<void> _updateNotification({
    required String title,
    required String text,
  }) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );
  }

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    try {
      // 1) اقرأ الحمولة من SharedPreferences
      final jsonStr = await FlutterForegroundTask.getData<String>(key: BgKeys.payload);
      if (jsonStr == null || jsonStr.isEmpty) {
        _sendPort?.send({'done': 'error', 'msg': 'No payload'});
        await _updateNotification(title: 'فشل', text: 'لا توجد حمولة');
        await FlutterForegroundTask.stopService();
        return;
      }

      final Map<String, dynamic> data = json.decode(jsonStr);

      // Parse ids
      final List<dynamic> rawIds = (data['ids'] as List?) ?? [];
      final ids = rawIds.cast<Map>().map((m) {
        return IdModel(
          id: m['id'] as String,
          timestamp: DateTime.parse(m['timestamp'] as String),
        );
      }).toList();

      // Parse IdInfo
      final idInfoMap = (data['idInfo'] as Map?) ?? {};
      final idInfo = IdInfo(
        idCollection: idInfoMap['idCollection'] as String,
        idFile: idInfoMap['idFile'] as String,
        idDocument: idInfoMap['idDocument'] as String,
      );

      // 2) شغّل العملية
      await _run(ids: ids, idInfo: idInfo);
    } catch (e) {
      _sendPort?.send({'done': 'error', 'msg': e.toString()});
      await _updateNotification(title: 'فشل العملية', text: e.toString());
      await FlutterForegroundTask.stopService();
    }
  }

  Future<void> _run({
    required List<IdModel> ids,
    required IdInfo idInfo,
  }) async {
    final ds = GenertCodeDataSource(FirebaseFirestore.instance);

    double fsProg = 0.0;
    double exProg = 0.0;

    // Firestore
    final uploaded = await ds.saveIdsToFirestore(
      ids: ids,
      target: idInfo,
      onProgress: (p) async {
        fsProg = p;
        await _updateNotification(
          title: 'توليد وحفظ المعرّفات',
          text: 'Firestore: ${(fsProg * 100).toStringAsFixed(0)}% • Excel: ${(exProg * 100).toStringAsFixed(0)}%',
        );
        _sendPort?.send({'firestore': p});
      },
      isStopped: () => false,
    );

    // Excel rows
    final rows = ids
        .map((e) => {
      'id': e.id,
      'timestamp': e.timestamp.toIso8601String(),
    })
        .toList();

    // Excel
    final savedPath = await ds.saveIdsToExcel(
      rows: rows,
      target: idInfo,
      onProgress: (p) async {
        exProg = p;
        await _updateNotification(
          title: 'توليد وحفظ المعرّفات',
          text: 'Firestore: ${(fsProg * 100).toStringAsFixed(0)}% • Excel: ${(exProg * 100).toStringAsFixed(0)}%',
        );
        _sendPort?.send({'excel': p});
      },
      isStopped: () => false,
    );

    // نهاية
    await _updateNotification(
      title: 'تمت العملية',
      text: 'رفع: $uploaded/${ids.length} • ملف: ${savedPath ?? "-"}',
    );
    _sendPort?.send({
      'done': 'ok',
      'uploaded': uploaded,
      'requested': ids.length,
      'path': savedPath,
    });

    await Future.delayed(const Duration(seconds: 1));
    await FlutterForegroundTask.stopService();
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
    // غير مستخدم
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {
    // تنظيف إن لزم
  }

  @override
  void onNotificationButtonPressed(String id) {
    // أزرار الإشعار إن أردت (إلغاء/إيقاف)
    // _sendPort?.send({'cancel': true});
  }
}
*/
