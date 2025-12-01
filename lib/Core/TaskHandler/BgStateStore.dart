// lib/Core/TaskHandler/BgStateStore.dart
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BgStateStore {
  static const _TAG        = 'BgStateStore';

  static const _kStatus     = 'gen_state_status';      // idle | running | paused | done | error
  static const _kPayload    = 'gen_state_payload';     // JSON ids + idInfo
  static const _kExcelPath  = 'gen_state_excel_path';  // آخر مسار لملف الإكسل (إن وُجد)
  static const _kFsProgress = 'gen_state_fs_progress'; // 0..1
  static const _kExProgress = 'gen_state_ex_progress'; // 0..1
  static const _kProcessed  = 'gen_state_processed';   // كم ID رُفع/تم

  static void _log(String msg, {Object? error, StackTrace? stack}) {
    final ts = DateTime.now().toIso8601String();
    dev.log('[$ts] $msg', name: _TAG, error: error, stackTrace: stack);
    if (kDebugMode) {
      debugPrint('$_TAG | $ts | $msg${error != null ? ' | ERROR: $error' : ''}');
    }
  }

  // ---------- Status ----------
  static Future<void> saveStatus(String status) async {
    _log('saveStatus("$status")');
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kStatus, status);
  }

  static Future<String> loadStatus() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_kStatus) ?? 'idle';
    if (v != 'idle' && v != 'running' && v != 'paused' && v != 'done' && v != 'error') {
      _log('loadStatus(): unexpected value "$v", defaulting maybe upstream logic needs check');
    }
    _log('loadStatus() -> "$v"');
    return v;
  }

  // ---------- Payload ----------
  static Future<void> savePayload(Map<String, dynamic> payload) async {
    final sp = await SharedPreferences.getInstance();
    final s = jsonEncode(payload);
    _log('savePayload(len=${s.length})');
    await sp.setString(_kPayload, s);
  }

  static Future<Map<String, dynamic>?> loadPayload() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kPayload);
    if (s == null || s.isEmpty) {
      _log('loadPayload() -> null (empty)');
      return null;
    }
    try {
      final map = jsonDecode(s) as Map<String, dynamic>;
      _log('loadPayload() -> ok (len=${s.length})');
      return map;
    } catch (e, st) {
      _log('loadPayload() JSON parse ERROR', error: e, stack: st);
      return null;
    }
  }

  // ---------- Excel path ----------
  static Future<void> saveExcelPath(String? path) async {
    final sp = await SharedPreferences.getInstance();
    if (path == null) {
      _log('saveExcelPath(null) -> remove');
      await sp.remove(_kExcelPath);
    } else {
      _log('saveExcelPath("$path")');
      await sp.setString(_kExcelPath, path);
    }
  }

  static Future<String?> loadExcelPath() async {
    final sp = await SharedPreferences.getInstance();
    final p = sp.getString(_kExcelPath);
    _log('loadExcelPath() -> ${p == null ? "null" : "\"$p\""}');
    return p;
  }

  // ---------- Progress (Firestore/Excel) ----------
  static Future<void> saveProgress({double? fs, double? ex}) async {
    final sp = await SharedPreferences.getInstance();
    if (fs != null) {
      final v = (fs.clamp(0.0, 1.0)) as double;
      _log('saveProgress(fs=$v)');
      await sp.setDouble(_kFsProgress, v);
    }
    if (ex != null) {
      final v = (ex.clamp(0.0, 1.0)) as double;
      _log('saveProgress(ex=$v)');
      await sp.setDouble(_kExProgress, v);
    }
  }

  static Future<(double fs, double ex)> loadProgress() async {
    final sp = await SharedPreferences.getInstance();
    final fs = sp.getDouble(_kFsProgress) ?? 0.0;
    final ex = sp.getDouble(_kExProgress) ?? 0.0;
    _log('loadProgress() -> (fs=$fs, ex=$ex)');
    return (fs, ex);
  }

  // ---------- Processed count ----------
  static Future<void> saveProcessedCount(int n) async {
    _log('saveProcessedCount($n)');
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kProcessed, n);
  }

  static Future<int> loadProcessedCount() async {
    final sp = await SharedPreferences.getInstance();
    final n = sp.getInt(_kProcessed) ?? 0;
    _log('loadProcessedCount() -> $n');
    return n;
  }

  // ---------- Clear ----------
  static Future<void> clearAll() async {
    _log('clearAll()');
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kStatus);
    await sp.remove(_kPayload);
    await sp.remove(_kExcelPath);
    await sp.remove(_kFsProgress);
    await sp.remove(_kExProgress);
    await sp.remove(_kProcessed);
    _log('clearAll() -> done');
  }
}
