// lib/genertcode/domain/usecases/run_batch_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:triing/Core/Error/Failure.dart';
import 'package:triing/Core/use_case/base_usecase.dart';

import 'package:triing/genertcode/data/models/IdModel.dart';
import 'package:triing/genertcode/domain/entities/IdEntity.dart'; // BatchResultEntity
import 'package:triing/genertcode/domain/entities/IdInfo.dart';
import 'package:triing/genertcode/domain/repositories/Base_generate_code.dart' as repo;

// ✅ استخدم العقد الصحيحة والtypedefs منها (لا تعرّف typedefs مكررة هنا)



/// UseCase: تشغيل الدفعة (حفظ إلى Firestore + حفظ Excel) عبر الـRepository
class RunBatchUseCase
    extends BaseUseCase<BatchResultEntity, RunBatchParameters> {
  final repo.BaseGenCodeRepository repository;

  RunBatchUseCase({required this.repository});

  @override
  Future<Either<Failure, BatchResultEntity>> call(
      RunBatchParameters params) async {
    // لوج تشخيصي
    print('[UseCase] ENTER RunBatchUseCase: '
        'ids=${params.ids.length}, '
        'collection="${params.target.idCollection}", '
        'file="${params.target.idFile}", '
        'doc="${params.target.idDocument}"');

    final result = await repository.runBatch(
      ids: params.ids,
      target: params.target,
      onFirestoreProgress: params.onFirestoreProgress,
      onExcelProgress: params.onExcelProgress,
      isStopped: params.isStopped,
    );

    // لوج لنتيجة الاستدعاء
    result.fold(
          (failure) => print('[UseCase] RESULT = FAILURE: ${failure.message}'),
          (ok) => print('[UseCase] RESULT = SUCCESS: '
          'requested=${ok.requestedCount}, '
          'uploaded=${ok.uploadedToFirestore}, '
          'path="${ok.savedExcelPath}", '
          'stopped=${ok.stopped}'),
    );

    return result;
  }
}

/// باراميترات الـUseCase
class RunBatchParameters extends Equatable {
  final List<IdModel> ids;
  final IdInfo target;

  /// اختياري: تحديث تقدّم Firestore/Excel (0..1)
  final repo.ProgressCallback? onFirestoreProgress;
  final repo.ProgressCallback? onExcelProgress;

  /// اختياري: فحص الإيقاف
  final repo.StopRequested? isStopped;

  const RunBatchParameters({
    required this.ids,
    required this.target,
    this.onFirestoreProgress,
    this.onExcelProgress,
    this.isStopped,
  });

  @override
  List<Object?> get props => [
    ids,
    target,
    onFirestoreProgress,
    onExcelProgress,
    isStopped,
  ];
}
