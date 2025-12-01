import 'package:equatable/equatable.dart';

/// يمثل معرّف واحد مخزن في Firestore أو Excel
class IdEntity extends Equatable {
  final String id;
  final DateTime timestamp;

  const IdEntity({
    required this.id,
    required this.timestamp,
  });

  /// تحويل من Map (Firestore Document)


  @override
  List<Object?> get props => [id, timestamp];

  @override
  String toString() => 'IdEntity(id: $id, timestamp: $timestamp)';
}

/// نتيجة تشغيل Batch (تشمل عدد العناصر ونتائج الحفظ)
class BatchResultEntity extends Equatable {
  final int requestedCount;
  final int uploadedToFirestore;
  final String? savedExcelPath;
  final bool stopped;

  const BatchResultEntity({
    required this.requestedCount,
    required this.uploadedToFirestore,
    required this.savedExcelPath,
    required this.stopped,
  });

  @override
  List<Object?> get props =>
      [requestedCount, uploadedToFirestore, savedExcelPath, stopped];

  @override
  String toString() =>
      'BatchResultEntity(requested: $requestedCount, uploaded: $uploadedToFirestore, excel: $savedExcelPath, stopped: $stopped)';
}

