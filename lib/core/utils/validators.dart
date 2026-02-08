/// Validation utilities for input fields
class Validators {
  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates phone number (allows various formats)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove common formatting characters
    final cleaned = value.replaceAll(RegExp(r'[-\s()]'), '');
    
    // Check if it contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Phone number must contain only digits';
    }
    
    // Check minimum length (at least 7 digits, maximum 15)
    if (cleaned.length < 7 || cleaned.length > 15) {
      return 'Phone number must be between 7 and 15 digits';
    }
    
    return null;
  }

  /// Validates name (non-empty)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }

  /// Validates price (must be positive number)
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    final price = double.tryParse(value);
    
    if (price == null) {
      return 'Please enter a valid number';
    }
    
    if (price <= 0) {
      return 'Price must be greater than 0';
    }
    
    return null;
  }

  /// Validates duration (must be positive integer)
  static String? validateDuration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Duration is required';
    }
    
    final duration = int.tryParse(value);
    
    if (duration == null) {
      return 'Please enter a valid number';
    }
    
    if (duration <= 0) {
      return 'Duration must be greater than 0';
    }
    
    return null;
  }
}

