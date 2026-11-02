// All form validation rules in one place.
// Each method returns an error message, or null when the value is valid.
// (Same rules and style as Project 1 — Forms.)
class Validators {
  static String? nameValidator(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Name is required';
    }
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(name.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  static String? emailValidation(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Accepts 01XXXXXXXXX, +8801XXXXXXXXX or 8801XXXXXXXXX
  static String? bangladeshNumberValidator(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Phone number is required';
    }
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.startsWith('880')) {
      cleanPhone = cleanPhone.substring(2); // keep the leading 0
    }
    if (cleanPhone.length != 11) {
      return 'Phone number must be 11 digits (e.g. 01712345678)';
    }
    const validPrefixes = ['013', '014', '015', '016', '017', '018', '019'];
    if (!validPrefixes.contains(cleanPhone.substring(0, 3))) {
      return 'Please enter a valid Bangladesh mobile number';
    }
    return null;
  }

  // Sign-in field: either an email or a Bangladesh mobile number
  static String? emailOrPhoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or phone number is required';
    }
    final looksLikePhone = RegExp(r'^[\d+\s-]+$').hasMatch(value.trim());
    return looksLikePhone ? bangladeshNumberValidator(value) : emailValidation(value);
  }

  static String? passwordValidator(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  static String? confirmPasswordValidator(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? minLengthValidator(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    return null;
  }

  // Bangladesh postcodes are 4 digits (e.g. 1229)
  static String? postcodeValidator(String? code) {
    if (code == null || code.trim().isEmpty) {
      return 'Postcode is required';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(code.trim())) {
      return 'Postcode must be 4 digits';
    }
    return null;
  }

  // Card number: 16 digits that pass the Luhn check
  static String? cardNumberValidator(String? number) {
    if (number == null || number.trim().isEmpty) {
      return 'Card number is required';
    }
    final digits = number.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{16}$').hasMatch(digits)) {
      return 'Card number must be 16 digits';
    }
    int sum = 0;
    for (int i = 0; i < digits.length; i++) {
      int d = int.parse(digits[digits.length - 1 - i]);
      if (i.isOdd) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
    }
    if (sum % 10 != 0) {
      return 'Please enter a valid card number';
    }
    return null;
  }

  // Expiry as MM/YY, not in the past
  static String? expiryValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry is required';
    }
    final m = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$').firstMatch(value.trim());
    if (m == null) {
      return 'Use MM/YY';
    }
    final month = int.parse(m.group(1)!);
    final year = 2000 + int.parse(m.group(2)!);
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      return 'Card has expired';
    }
    return null;
  }

  static String? cvvValidator(String? cvv) {
    if (cvv == null || cvv.trim().isEmpty) {
      return 'CVV is required';
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvv.trim())) {
      return 'CVV must be 3 or 4 digits';
    }
    return null;
  }

  // Password strength from 0 (empty) to 5 (meets every rule)
  static int passwordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'))) score++;
    return score;
  }
}
