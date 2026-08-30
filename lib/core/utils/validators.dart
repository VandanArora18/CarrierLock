/// Input validation utilities for forms.
class Validators {
  Validators._();

  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validate password (min 6 characters)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate confirm password
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate name
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate phone number (Indian format)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // phone is optional
    }
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex
        .hasMatch(value.trim().replaceAll(RegExp(r'[\s\-\(\)\+]'), ''))) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  /// Validate fleet ID (e.g. FLT-4821)
  static String? fleetId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Fleet ID is required';
    }
    // Accept flexible formats
    if (value.trim().length < 3) {
      return 'Enter a valid fleet ID';
    }
    return null;
  }

  /// Validate OTP digits (4 or 8 digits)
  static String? otp(String? value, {int length = 8}) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != length) {
      return 'OTP must be $length digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP must contain only digits';
    }
    return null;
  }

  /// Validate fleet name
  static String? fleetName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Fleet name is required';
    }
    if (value.trim().length < 3) {
      return 'Fleet name must be at least 3 characters';
    }
    return null;
  }

  /// Generic required field
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
