
import 'package:triing/Core/NetWork/ErrorMessageModel.dart';

class ServerException implements Exception
{
  final ErrorMessageModel errorMessageModel;

  ServerException({required this.errorMessageModel});
}


class NetworkException implements Exception {
  final String errorMessage;
  NetworkException({required this.errorMessage});
}

class UnknownException implements Exception {
  final String errorMessage;
  UnknownException({required this.errorMessage});
}
