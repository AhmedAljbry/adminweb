// lib/genertcode/presentation/manager/gen_code_bloc.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:triing/Core/utils/enum.dart';

// كياناتك
import 'package:triing/genertcode/data/models/IdModel.dart';
import 'package:triing/genertcode/domain/entities/IdEntity.dart'; // BatchResultEntity
import 'package:triing/genertcode/domain/entities/IdInfo.dart';

// Runner واجهة
abstract class IGenCodeBackgroundRunner {
  Stream<Map<String, dynamic>> get progress$;
  Future<void> start({required List<IdModel> ids, required IdInfo target});
  Future<void> stop();
}

/// FakeRunner للاختبار — يُرسل تقدّم وهمي
class FakeRunner implements IGenCodeBackgroundRunner {
  final _ctrl = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _t;
  double _p = 0.0;

  @override
  Stream<Map<String, dynamic>> get progress$ => _ctrl.stream;

  @override
  Future<void> start({required List<IdModel> ids, required IdInfo target}) async {
    _p = 0;
    _t?.cancel();
    _t = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _p += 0.02;
      if (_p <= 0.7) {
        _ctrl.add({'firestore': _p / 0.7});
      } else if (_p < 1.0) {
        _ctrl.add({'excel': (_p - 0.7) / 0.3});
      } else {
        _ctrl.add({
          'done': 'ok',
          'uploaded': ids.length,
          'requested': ids.length,
          'path': '/fake/generated_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        });
        timer.cancel();
      }
    });
  }

  @override
  Future<void> stop() async {
    _t?.cancel();
    _ctrl.add({'done': 'error', 'msg': 'تم الإيقاف من المستخدم'});
  }
}
