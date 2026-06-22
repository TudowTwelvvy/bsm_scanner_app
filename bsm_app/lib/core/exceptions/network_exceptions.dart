
abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}


class UnauthorizedException extends NetworkException {
  UnauthorizedException() : super('Your session has expired. Please log in again.', code: 'unauthorized');
}


class NotFoundException extends NetworkException {
  NotFoundException() : super('The requested resource was not found.', code: 'not-found');
}


class ServerException extends NetworkException {
  ServerException() : super('Server error. Please try again later.', code: 'server-error');
}


class ConnectionException extends NetworkException {
  ConnectionException() : super('No internet connection. Please check your network.', code: 'no-connection');
}


class ConflictException extends NetworkException {
  ConflictException() : super('This resource already exists.', code: 'conflict');
}


class UnknownApiException extends NetworkException {
  UnknownApiException() : super('An unexpected error occurred.', code: 'unknown');
}