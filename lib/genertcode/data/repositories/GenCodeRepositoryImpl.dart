// lib/genertcode/data/repositories/gen_code_repository_impl.dart
import 'package:dartz/dartz.dart';

import 'package:triing/Core/Error/Failure.dart';
import 'package:triing/genertcode/data/data_sources/Genert_code_data_soures.dart';
import 'package:triing/genertcode/data/models/BatchResultModel.dart';
import 'package:triing/genertcode/data/models/IdModel.dart';
import 'package:triing/genertcode/domain/entities/IdEntity.dart'; // BatchResultEntity
import 'package:triing/genertcode/domain/entities/IdInfo.dart';
import 'package:triing/genertcode/domain/repositories/Base_generate_code.dart';

typedef ProgressCallback = void Function(double progress);
typedef StopRequested   = bool Function();

class GenCodeRepositoryImpl implements BaseGenCodeRepository {
  final BaseGenCodeDataSource dataSource;

  GenCodeRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, BatchResultEntity>> runBatch({
    required List<IdModel> ids,
    required IdInfo target,
    ProgressCallback? onFirestoreProgress,
    ProgressCallback? onExcelProgress,
    StopRequested? isStopped,
  }) async {
    print('[Repo] ENTER runBatch: '
        'ids=${ids.length}, '
        'collection="${target.idCollection}", '
        'file="${target.idFile}", '
        'doc="${target.idDocument}"');

    // تحقّق سريع من المدخلات (اختياري)
    if (ids.isEmpty) {
      final failure = ServerFailure(message: 'قائمة المعرفات فارغة.');
      print('[Repo] ABORT: ${failure.message}');
      return Left(failure);
    }
    if (target.idCollection.trim().isEmpty) {
      final failure = ServerFailure(message: 'idCollection لا يجب أن يكون فارغًا.');
      print('[Repo] ABORT: ${failure.message}');
      return Left(failure);
    }

    try {
      // 1) Firestore
      print('[Repo] -> saving to Firestore ...');
      final uploaded = await dataSource.saveIdsToFirestore(
        ids: ids,
        target: target,
        onProgress: (p) {
          // مرر التقدّم إلى أعلى (UI) لو مطلوب
          onFirestoreProgress?.call(p);
          // وسجّل رقم تقريبي كل 10%
          if ((p * 100).round() % 10 == 0 || p == 1.0) {
            print('[Repo][FS] progress ${(p * 100).toStringAsFixed(0)}%');
          }
        },
        isStopped: isStopped,
      );
      print('[Repo] Firestore done: uploaded=$uploaded/${ids.length}');

      // 2) Excel
      print('[Repo] -> saving to Excel ...');
      final rows = ids
          .map((e) => {
        'id': e.id,
        'timestamp': e.timestamp.toIso8601String(),
      })
          .toList();

      final savedPath = await dataSource.saveIdsToExcel(
        rows: rows,
        target: target,
        onProgress: (p) {
          onExcelProgress?.call(p);
          if ((p * 100).round() % 10 == 0 || p == 1.0) {
            print('[Repo][XL] progress ${(p * 100).toStringAsFixed(0)}%');
          }
        },
        isStopped: isStopped,
      );
      print('[Repo] Excel done: path="${savedPath ?? '-'}"');

      // 3) النتيجة
      final result = BatchResultModel(
        requestedCount: ids.length,
        uploadedToFirestore: uploaded,
        savedExcelPath: savedPath,
        stopped: isStopped?.call() == true,
      );

      print('[Repo] SUCCESS -> '
          'requested=${result.requestedCount}, '
          'uploaded=${result.uploadedToFirestore}, '
          'path="${result.savedExcelPath}", '
          'stopped=${result.stopped}');

      return Right(result);
    } catch (e, st) {
      final failure = ServerFailure(message: e.toString());
      print('[Repo] ERROR: ${failure.message}');
      print(st);
      return Left(failure);
    }
  }
}
