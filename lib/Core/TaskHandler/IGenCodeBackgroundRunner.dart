// lib/Core/TaskHandler/IGenCodeBackgroundRunner.dart
import 'dart:async';
import 'package:triing/genertcode/data/models/IdModel.dart';
import 'package:triing/genertcode/domain/entities/IdInfo.dart';

/// ⚠️ هذه هي الواجهة الوحيدة المعتمدة. لا تنشئ نسخة ثانية في أي مسار آخر.
abstract class IGenCodeBackgroundRunner {
  /// بث تقدّم/نتائج الخدمة الخلفية:
  /// {'excel':0..1} أو {'done':'excel_ok', rows:[...], path:String?} أو {'done':'error','msg':...}
  Stream<Map<String, dynamic>> get progress$;

  Future<void> start({required List<IdModel> ids, required IdInfo target});
  Future<void> stop();
}
