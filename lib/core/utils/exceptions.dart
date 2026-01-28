/// Exception handling utilities.
library;

/// Base class for application-specific exceptions.
sealed class AppException implements Exception {
  const AppException(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => message;
}

/// Exception thrown when Service Account operations fail.
class ServiceAccountException extends AppException {
  const ServiceAccountException(super.message);
}

/// Exception thrown when FCM operations fail.
class FcmException extends AppException {
  const FcmException(super.message);
}

/// Exception thrown when Supabase operations fail.
class SupabaseException extends AppException {
  const SupabaseException(super.message);
}

/// Exception thrown when database operations fail.
class DatabaseException extends AppException {
  const DatabaseException(super.message);
}
