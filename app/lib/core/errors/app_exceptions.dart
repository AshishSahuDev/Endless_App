class DatabaseException implements Exception {
  final String message;
  final Object? cause;
  const DatabaseException(this.message, {this.cause});
  @override
  String toString() => 'DatabaseException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}

class AlarmException implements Exception {
  final String message;
  final Object? cause;
  const AlarmException(this.message, {this.cause});
  @override
  String toString() => 'AlarmException: $message';
}

class PermissionException implements Exception {
  final String message;
  const PermissionException(this.message);
  @override
  String toString() => 'PermissionException: $message';
}
