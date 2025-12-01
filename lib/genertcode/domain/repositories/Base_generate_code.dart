// lib/genertcode/domain/repositories/base_gen_code_repository.dart

import 'package:dartz/dartz.dart';
import 'package:triing/Core/Error/Failure.dart';

import 'package:triing/genertcode/data/models/IdModel.dart';
import 'package:triing/genertcode/domain/entities/IdEntity.dart'; // يحتوي BatchResultEntity
import 'package:triing/genertcode/domain/entities/IdInfo.dart';

/// لتحديث شريط التقدّم (0..1)
typedef ProgressCallback = void Function(double progress);

/// تُرجِع true إذا طُلب الإيقاف (من واجهة المستخدم مثلاً)
typedef StopRequested = bool Function();

/// عقد الريبو الخاص بتشغيل دفعة التوليد/الحفظ.
/// - 1) رفع المعرّفات إلى Firestore (مع تحديث تقدّم اختياري)
/// - 2) حفظ المعرّفات في ملف Excel (مع تحديث تقدّم اختياري)
///
/// الناتج: BatchResultEntity داخل Either<Failure, ...>
abstract class BaseGenCodeRepository {
  Future<Either<Failure, BatchResultEntity>> runBatch({
    required List<IdModel> ids,
    required IdInfo target,
    ProgressCallback? onFirestoreProgress,
    ProgressCallback? onExcelProgress,
    StopRequested? isStopped,
  });
}
