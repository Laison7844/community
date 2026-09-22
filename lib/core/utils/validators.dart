/// Utility functions for validating form inputs across the app.
class Validators {
  Validators._();

  /// Validates that a field is not empty or blank.
  static String? requiredField(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates official full name matching church records.
  static String? officialFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Official full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Full name cannot exceed 100 characters';
    }
    return null;
  }

  /// Validates church family number (mandatory, unique per family unit).
  static String? familyNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Church family number is required';
    }
    final clean = value.trim();
    if (clean.length < 2) {
      return 'Family number must be at least 2 characters';
    }
    if (clean.length > 30) {
      return 'Family number cannot exceed 30 characters';
    }
    return null;
  }

  /// Validates standard email address format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password length (at least 6 characters).
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Validates that the confirmation password matches the primary password.
  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Optional phone number validator (allows empty, but validates length if present).
  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (cleanPhone.length < 7 || cleanPhone.length > 15) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validates profile image file size and extension.
  static String? validateImageFile({
    required int sizeInBytes,
    required String fileName,
    int maxSizeBytes = 5 * 1024 * 1024, // 5 MB
  }) {
    if (sizeInBytes <= 0) {
      return 'Selected image file is empty';
    }
    if (sizeInBytes > maxSizeBytes) {
      return 'Photo file size exceeds 5MB limit';
    }
    final ext = fileName.split('.').last.toLowerCase();
    const allowed = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowed.contains(ext)) {
      return 'Only JPG, JPEG, PNG, and WebP images are supported';
    }
    return null;
  }
}
