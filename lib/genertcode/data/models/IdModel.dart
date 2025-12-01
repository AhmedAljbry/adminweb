import 'package:triing/genertcode/domain/entities/IdEntity.dart';

class IdModel extends IdEntity {
  const IdModel({
    required String id,
    required DateTime timestamp,
  }) : super(id: id, timestamp: timestamp);

  /// من Map (Firestore/JSON) إلى Model
  factory IdModel.fromMap(Map<String, dynamic> map) {
    return IdModel(
      id: map['id'] as String,
      timestamp: (map['timestamp'] is DateTime)
          ? map['timestamp'] as DateTime
          : DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now(),
    );
  }

  /// من Model إلى Map (لتخزين في Firestore أو Excel)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
