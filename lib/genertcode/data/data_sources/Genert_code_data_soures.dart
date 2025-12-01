// lib/genertcode/data/data_sources/genert_code_data_soures.dart
// imports الصحيحة
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import 'package:triing/genertcode/data/models/IdModel.dart';
// ملاحظة: المستوردين أدناه غير مستخدمين هنا فعليًا، لكن لو عندك تحويلات/اختبارات مستقبلية اتركهم.
// import 'package:triing/genertcode/data/models/BatchResultModel.dart';
import 'package:triing/genertcode/data/models/IdInfoModel.dart'; // لو عندك Model موازي
import 'package:triing/genertcode/domain/entities/IdInfo.dart';

/// Callbacks عامة
typedef ProgressCallback = void Function(double progress);
typedef StopRequested = bool Function();

/// في طبقة الـ Data: تعيد Models أو قيم مباشرة، وترمي استثناءات عند الفشل.
/// الـ Repository يلفّ الاستثناءات إلى Either<Failure, Entity>
abstract class BaseGenCodeDataSource {
  /// يحفظ مجموعة من المعرفات في Firestore داخل collection محدد في IdInfo.idCollection
  /// يعيد عدد العناصر التي تم رفعها فعلاً.
  Future<int> saveIdsToFirestore({
    required List<IdModel> ids,
    required IdInfo target, // يحدد collection/file/document (نستخدم collection هنا)
    ProgressCallback? onProgress,
    StopRequested? isStopped,
  });

  /// يحفظ مجموعة المعرفات في ملف Excel. يعيد مسار الملف إن وُجد.
  Future<String?> saveIdsToExcel({
    required List<Map<String, dynamic>> rows,
    required IdInfo target, // نستخدم idFile و idDocument لتكوين الاسم
    ProgressCallback? onProgress,
    StopRequested? isStopped,
  });
}

/// تنفيذ فعلي لـ Firestore + Excel
class GenertCodeDataSource implements BaseGenCodeDataSource {
  final FirebaseFirestore firestore;

  GenertCodeDataSource(this.firestore);

  @override
  Future<int> saveIdsToFirestore({
    required List<IdModel> ids,
    required IdInfo target,
    ProgressCallback? onProgress,
    StopRequested? isStopped,
  }) async {
    print('[DS][FS] ENTER saveIdsToFirestore '
        'ids=${ids.length}, collection="${target.idCollection}"');

    if (ids.isEmpty) {
      print('[DS][FS] WARN: ids.isEmpty => return 0');
      onProgress?.call(1.0);
      return 0;
    }
    if (target.idCollection.trim().isEmpty) {
      final msg = '[DS][FS] ERROR: target.idCollection is empty';
      print(msg);
      throw ArgumentError(msg);
    }

    try {
      final col = firestore.collection(target.idCollection);
      int uploaded = 0;

      // تحديث progress = 0
      onProgress?.call(0.0);

      // ملاحظة: بإمكانك استخدام WriteBatch لسرعة أعلى (خاصة للأعداد الكبيرة)
      // هنا نحافظ على تحديث التقدم سطرًا بسطر، لذلك نكتب مباشرة.
      for (int i = 0; i < ids.length; i++) {
        if (isStopped?.call() == true) {
          print('[DS][FS] STOP requested at i=$i (uploaded=$uploaded)');
          break;
        }

        final item = ids[i];
        try {
          print('[DS][FS] writing doc("${item.id}") ...');
          await col.doc(item.id).set({
            'id': item.id,
            'timestamp': FieldValue.serverTimestamp(),
          });
          uploaded = i + 1;
          final p = uploaded / ids.length;
          onProgress?.call(p);
          // طباعة كل 10% أو كل 100 عنصر لعدم إغراق السجل
          if (uploaded == ids.length || uploaded % 100 == 0 || (p * 100).round() % 10 == 0) {
            print('[DS][FS] progress: ${(p * 100).toStringAsFixed(0)}% '
                'uploaded=$uploaded/${ids.length}');
          }
        } catch (e, st) {
          // لا نوقف العملية بالكامل بسبب عنصر واحد — سجّل واستمر
          print('[DS][FS] ERROR writing "${item.id}": $e');
          print(st);
        }
      }

      // تأكيد اكتمال التقدم = 1.0 لو لم يتم الإيقاف
      if (uploaded == ids.length) {
        onProgress?.call(1.0);
      }

      print('[DS][FS] DONE: uploaded=$uploaded/${ids.length}');
      return uploaded;
    } catch (e, st) {
      print('[DS][FS] FATAL ERROR: $e');
      print(st);
      rethrow; // اترك الـRepository يلفّه إلى Failure
    }
  }

  @override
  Future<String?> saveIdsToExcel({
    required List<Map<String, dynamic>> rows,
    required IdInfo target,
    ProgressCallback? onProgress,
    StopRequested? isStopped,
  }) async {
    print('[DS][XL] ENTER saveIdsToExcel rows=${rows.length} '
        'file="${target.idFile}", doc="${target.idDocument}"');

    if (rows.isEmpty) {
      print('[DS][XL] WARN: rows.isEmpty => return null');
      onProgress?.call(1.0);
      return null;
    }
    if (target.idFile.trim().isEmpty || target.idDocument.trim().isEmpty) {
      final msg = '[DS][XL] ERROR: idFile/idDocument must not be empty';
      print(msg);
      throw ArgumentError(msg);
    }

    xlsio.Workbook? workbook;
    try {
      onProgress?.call(0.0);

      workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];

      // رؤوس الأعمدة
      sheet.getRangeByName('A1').setText('ID');
      sheet.getRangeByName('B1').setText('Timestamp');

      // كتابة الصفوف + تقدّم
      for (int i = 0; i < rows.length; i++) {
        if (isStopped?.call() == true) {
          print('[DS][XL] STOP requested at i=$i');
          workbook.dispose();
          return null;
        }
        final r = rows[i];
        sheet.getRangeByIndex(i + 2, 1).setText(r['id']?.toString() ?? '');
        sheet.getRangeByIndex(i + 2, 2).setText(r['timestamp']?.toString() ?? '');

        final p = (i + 1) / rows.length;
        onProgress?.call(p);

        if ((i + 1) == rows.length ||
            (i + 1) % 1000 == 0 ||
            (p * 100).round() % 10 == 0) {
          print('[DS][XL] progress: ${(p * 100).toStringAsFixed(0)}% '
              'written=${i + 1}/${rows.length}');
        }
      }

      // حفظ الملف: إلى /storage/emulated/0/Download/code/<idFile>/
      final bytes = workbook.saveAsStream();
      workbook.dispose();
      workbook = null;

      final uint8list = Uint8List.fromList(bytes);
      final millis = DateTime.now().millisecondsSinceEpoch;

      // مسار التنزيلات + المجلدات
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final targetDir = Directory('${downloadsDir.path}/code/${target.idFile}');
      if (!await targetDir.exists()) {
        print('[DS][XL] creating dir: ${targetDir.path}');
        await targetDir.create(recursive: true);
      }

      final filePath = '${targetDir.path}/generated_ids_${millis}_${target.idDocument}.xlsx';
      print('[DS][XL] writing file: $filePath (size=${uint8list.lengthInBytes} bytes)');

      final file = File(filePath);
      await file.writeAsBytes(uint8list, flush: true);

      onProgress?.call(1.0);
      print('[DS][XL] DONE. savedPath=$filePath');

      try {
        await OpenFilex.open(filePath);
        print('[DS][XL] OpenFilex.open done (may be ignored if no app).');
      } catch (e, st) {
        print('[DS][XL] OpenFilex.open error: $e');
        print(st);
      }

      return filePath;
    } catch (e, st) {
      print('[DS][XL] FATAL ERROR: $e');
      print(st);
      try { workbook?.dispose(); } catch (_) {}
      rethrow;
    }
  }

}
