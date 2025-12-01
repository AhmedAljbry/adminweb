// lib/Core/TaskHandler/GenCodeBackgroundRunner.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import 'package:triing/Core/TaskHandler/BgStateStore.dart';
import 'package:triing/Core/TaskHandler/bg_keys.dart'; // لو حاب تستخدم BgKeys، أو احذفه لو ما تحتاجه

import 'package:triing/Core/TaskHandler/IGenCodeBackgroundRunner.dart';

import 'package:triing/genertcode/data/models/IdModel.dart';
import 'package:triing/genertcode/domain/entities/IdInfo.dart';

class GenCodeBackgroundRunner implements IGenCodeBackgroundRunner {
  static const _TAG = 'GenCodeFGRunner';

  final _ctrl = StreamController<Map<String, dynamic>>.broadcast();
  bool _cancelled = false;
  bool _running = false;

  // نفس الفكرة السابقة، لكن بدون Foreground Service
  static const int _chunkSize = 500;
  static const Duration _tickDelay = Duration(milliseconds: 120);

  void _log(String msg, {Object? error, StackTrace? stack}) {
    final ts = DateTime.now().toIso8601String();
    dev.log('[$ts] $msg', name: _TAG, error: error, stackTrace: stack);
    if (kDebugMode) {
      debugPrint('$_TAG | $ts | $msg${error != null ? ' | ERROR: $error' : ''}');
    }
  }

  @override
  Stream<Map<String, dynamic>> get progress$ => _ctrl.stream;

  @override
  Future<void> start({
    required List<IdModel> ids,
    required IdInfo target,
  }) async {
    if (_running) {
      _log('start() called while already running → ignoring');
      return;
    }

    _running = true;
    _cancelled = false;

    _log('start() BEGIN | ids=${ids.length} | '
        'target={col:${target.idCollection}, file:${target.idFile}, doc:${target.idDocument}}');

    try {
      // 1) جهّز الحمولة وخزّنها في BgStateStore (نفس منطقك القديم)
      final payloadMap = {
        'ids': ids
            .map((e) => {
          'id': e.id,
          'timestamp': e.timestamp.toIso8601String(),
        })
            .toList(),
        'idInfo': {
          'idCollection': target.idCollection,
          'idFile': target.idFile,
          'idDocument': target.idDocument,
        },
      };
      final payloadJson = jsonEncode(payloadMap);
      _log('payload prepared (len=${payloadJson.length})');

      await BgStateStore.saveStatus('running');
      await BgStateStore.savePayload(payloadMap);
      await BgStateStore.saveProgress(fs: 0.0, ex: 0.0);
      await BgStateStore.saveProcessedCount(0);
      await BgStateStore.saveExcelPath(null);
      _log('BgStateStore initial state saved');

      // 2) شغّل المعالجة في Future منفصل بحيث ما يوقف UI
      unawaited(_run(ids: ids, idInfo: target));
      _log('start() END (scheduled _run)');
    } catch (e, st) {
      _log('start() ERROR', error: e, stack: st);
      _running = false;
      rethrow;
    }
  }

  Future<void> _run({
    required List<IdModel> ids,
    required IdInfo idInfo,
  }) async {
    _log('_run() START | totalIds=${ids.length}');

    try {
      await BgStateStore.saveProgress(fs: 0.0, ex: 0.0);
      await BgStateStore.saveProcessedCount(0);
      await BgStateStore.saveExcelPath(null);

      final rows = ids
          .map((e) => {
        'id': e.id,
        'timestamp': e.timestamp.toIso8601String(),
      })
          .toList();

      final total = rows.length.clamp(1, 1 << 30);
      int processed = 0;

      while (processed < total && !_cancelled) {
        final remain = total - processed;
        final take = remain > _chunkSize ? _chunkSize : remain;
        processed += take;

        final ex = (processed / total).clamp(0.0, 1.0);
        await BgStateStore.saveProgress(ex: ex);
        await BgStateStore.saveProcessedCount(processed);

        // بث التقدم للـ UI
        _ctrl.add({'excel': ex});

        _log('_run() chunk processed: $processed/$total -> ${(ex * 100).toInt()}%');

        // تأخير بسيط حتى لا نحرق الـ UI thread
        await Future.delayed(_tickDelay);
      }

      if (_cancelled) {
        _log('_run() cancelled by user');
        await BgStateStore.saveStatus('paused');
        _ctrl.add({'done': 'error', 'msg': 'تم الإيقاف من المستخدم'});
      } else {
        _log('_run() completed successfully');
        await BgStateStore.saveStatus('done');

        _ctrl.add({
          'done': 'excel_ok',
          'requested': ids.length,
          'path': null,
          'rows': rows,
          'idInfo': {
            'idCollection': idInfo.idCollection,
            'idFile': idInfo.idFile,
            'idDocument': idInfo.idDocument,
          },
        });
      }
    } catch (e, st) {
      _log('_run() ERROR', error: e, stack: st);
      await BgStateStore.saveStatus('error');
      _ctrl.add({'done': 'error', 'msg': e.toString()});
    } finally {
      _running = false;
      _log('_run() END');
    }
  }

  @override
  Future<void> stop() async {
    _log('stop() called → setting _cancelled=true');
    _cancelled = true;
  }

  Future<void> dispose() async {
    _log('dispose()');
    await _ctrl.close();
  }
}
