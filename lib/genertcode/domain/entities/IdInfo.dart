import 'package:equatable/equatable.dart';

class IdInfo extends Equatable {
  final String idCollection;
  final String idFile;
  final String idDocument;

  const IdInfo({
    required this.idCollection,
    required this.idFile,
    required this.idDocument, required ,
  });



  @override
  List<Object?> get props => [idCollection, idFile, idDocument];

  @override
  String toString() =>
      'IdInfo(idCollection: $idCollection, idFile: $idFile, idDocument: $idDocument)';
}
