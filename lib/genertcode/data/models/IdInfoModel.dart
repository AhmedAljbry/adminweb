import 'package:triing/genertcode/domain/entities/IdInfo.dart';

class IdInfoModel extends IdInfo {
  const IdInfoModel({
    required String idCollection,
    required String idFile,
    required String idDocument,
  }) : super(
    idCollection: idCollection,
    idFile: idFile,
    idDocument: idDocument,
  );

  /// تحويل من Map (Firestore/JSON) إلى Model
  factory IdInfoModel.fromMap(Map<String, dynamic> map) {
    return IdInfoModel(
      idCollection: map['idCollection'] as String,
      idFile: map['idFile'] as String,
      idDocument: map['idDocument'] as String,
    );
  }

  /// تحويل من Model إلى Map (لتخزين في Firestore أو JSON)
  Map<String, dynamic> toMap() {
    return {
      'idCollection': idCollection,
      'idFile': idFile,
      'idDocument': idDocument,
    };
  }
}
