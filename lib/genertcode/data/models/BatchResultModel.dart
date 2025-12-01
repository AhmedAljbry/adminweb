
import 'package:triing/genertcode/domain/entities/IdEntity.dart';

class BatchResultModel extends BatchResultEntity {
  const BatchResultModel({
    required int requestedCount,
    required int uploadedToFirestore,
    required String? savedExcelPath,
    required bool stopped,
  }) : super(
    requestedCount: requestedCount,
    uploadedToFirestore: uploadedToFirestore,
    savedExcelPath: savedExcelPath,
    stopped: stopped,
  );

  /// من Map (Firestore/JSON) إلى Model
  factory BatchResultModel.fromMap(Map<String, dynamic> map) {
    return BatchResultModel(
      requestedCount: map['requestedCount'] ?? 0,
      uploadedToFirestore: map['uploadedToFirestore'] ?? 0,
      savedExcelPath: map['savedExcelPath'] as String?,
      stopped: map['stopped'] ?? false,
    );
  }

  /// من Model إلى Map (لتخزين في Firestore أو Excel)
  Map<String, dynamic> toMap() {
    return {
      'requestedCount': requestedCount,
      'uploadedToFirestore': uploadedToFirestore,
      'savedExcelPath': savedExcelPath,
      'stopped': stopped,
    };
  }
}
