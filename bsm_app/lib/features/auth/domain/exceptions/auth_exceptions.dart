abstract class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}


class InvalidCredentialException extends AuthException {
  InvalidCredentialException()
      : super('invalid-credential', 'Invalid email or password.');
}

class EmailAlreadyInUseException extends AuthException {
  EmailAlreadyInUseException()
      : super('email-already-in-use', 'An account already exists with this email.');
}

class WeakPasswordException extends AuthException {
  WeakPasswordException()
      : super('weak-password', 'Password must be at least 6 characters.');
}


class UserNotFoundException extends AuthException {
  UserNotFoundException()
      : super('user-not-found', 'No account found with this email.');
}


class UnknownAuthException extends AuthException {
  UnknownAuthException()
      : super('unknown', 'An authentication error occurred. Please try again.');
}