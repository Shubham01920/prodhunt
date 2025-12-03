/// Base exception class for the app
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message';
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.details});
}

/// Authentication related exceptions
class AuthenticationException extends AppException {
  AuthenticationException(super.message, {super.code, super.details});
}

/// Authorization/Permission related exceptions
class AuthorizationException extends AppException {
  AuthorizationException(super.message, {super.code, super.details});
}

/// Database/Firestore related exceptions
class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.details});
}

/// Validation related exceptions
class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.details});
}

/// File upload/storage related exceptions
class StorageException extends AppException {
  StorageException(super.message, {super.code, super.details});
}

/// User not found exception
class UserNotFoundException extends AppException {
  UserNotFoundException(super.message, {super.code, super.details});
}

/// Product not found exception
class ProductNotFoundException extends AppException {
  ProductNotFoundException(super.message, {super.code, super.details});
}

/// Rate limiting exception
class RateLimitException extends AppException {
  RateLimitException(super.message, {super.code, super.details});
}

/// Custom exception handler utility
class ExceptionHandler {
  static String getErrorMessage(Exception exception) {
    if (exception is AppException) {
      return exception.message;
    } else if (exception.toString().contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (exception.toString().contains('permission')) {
      return 'Permission denied. Please check your access rights.';
    } else if (exception.toString().contains('auth')) {
      return 'Authentication error. Please login again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  static AppException parseFirebaseException(Exception exception) {
    String errorMessage = exception.toString().toLowerCase();

    if (errorMessage.contains('network')) {
      return NetworkException('Network connection failed');
    } else if (errorMessage.contains('permission-denied')) {
      return AuthorizationException('Permission denied');
    } else if (errorMessage.contains('unauthenticated')) {
      return AuthenticationException('User not authenticated');
    } else if (errorMessage.contains('not-found')) {
      return DatabaseException('Document not found');
    } else if (errorMessage.contains('already-exists')) {
      return ValidationException('Resource already exists');
    } else {
      return AppException('Unknown error occurred');
    }
  }
}
