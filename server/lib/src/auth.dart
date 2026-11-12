/// MODULE: Auth — password hashing (PBKDF2-HMAC-SHA256 with a random salt),
/// sign-in tokens, and the same name / email / phone / password rules the
/// app's sign-up form uses, checked again on the server.
///
/// Contains: Passwords, Tokens, Check.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'http.dart';

final _random = Random.secure();

List<int> _randomBytes(int n) => [
  for (var i = 0; i < n; i++) _random.nextInt(256),
];

abstract final class Passwords {
  static const iterations = 20000;

  static String newSalt() => base64Url.encode(_randomBytes(16));

  /// PBKDF2-HMAC-SHA256, one 32-byte block.
  static String hash(String password, String salt) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var u = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
    final out = List<int>.of(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return base64Url.encode(out);
  }

  /// Compares in constant time so the reply time gives nothing away.
  static bool matches(String password, String salt, String expected) {
    final a = utf8.encode(hash(password, salt));
    final b = utf8.encode(expected);
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

abstract final class Tokens {
  /// A new random sign-in token for the client to keep.
  static String create() =>
      base64Url.encode(_randomBytes(32)).replaceAll('=', '');

  /// What the server stores for a token: its SHA-256.
  static String key(String token) =>
      sha256.convert(utf8.encode(token)).toString();
}

/// Input checks. Each returns the cleaned value or throws a 400 [ApiError].
abstract final class Check {
  static String name(Object? value) {
    final s = value is String ? value.trim() : '';
    if (s.length < 2 || s.length > 60) {
      throw const ApiError.badRequest('Enter your name (2 to 60 letters).');
    }
    if (!RegExp(r"^[\p{L}\p{M}\s.'’-]+$", unicode: true).hasMatch(s)) {
      throw const ApiError.badRequest(
        'Use letters, spaces, apostrophes or hyphens in your name.',
      );
    }
    return s;
  }

  /// An email (returned in lower case) or a Bangladesh mobile number
  /// (returned as 01XXXXXXXXX).
  static String login(Object? value) {
    final s = value is String ? value.trim() : '';
    if (s.isEmpty) {
      throw const ApiError.badRequest('Email or phone number is required.');
    }
    if (RegExp(r'^[\d+\s-]+$').hasMatch(s)) {
      var digits = s.replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('880')) digits = digits.substring(2);
      if (digits.length != 11 || !RegExp(r'^01[3-9]').hasMatch(digits)) {
        throw const ApiError.badRequest(
          'Enter a valid Bangladesh mobile number (e.g. 01712345678).',
        );
      }
      return digits;
    }
    final email = s.toLowerCase();
    final local = email.split('@').first;
    if (email.length > 254 ||
        !RegExp(
          r'^[^\s@]+@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,63}$',
        ).hasMatch(email) ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..')) {
      throw const ApiError.badRequest('Enter a valid email address.');
    }
    return email;
  }

  /// Same strength rules as the sign-up form.
  static String newPassword(Object? value) {
    final p = value is String ? value : '';
    String? problem;
    if (p.length < 8) {
      problem = 'at least 8 characters';
    } else if (p.length > 128) {
      problem = 'at most 128 characters';
    } else if (!p.contains(RegExp(r'[A-Z]'))) {
      problem = 'an uppercase letter';
    } else if (!p.contains(RegExp(r'[a-z]'))) {
      problem = 'a lowercase letter';
    } else if (!p.contains(RegExp(r'[0-9]'))) {
      problem = 'a number';
    } else if (!p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'))) {
      problem = 'a special character';
    }
    if (problem != null) {
      throw ApiError.badRequest('Password needs $problem.');
    }
    return p;
  }

  static String address(Object? value) {
    final s = value is String ? value.trim() : '';
    if (s.length < 10 || s.length > 200) {
      throw const ApiError.badRequest(
        'Enter the full delivery address (10 to 200 characters).',
      );
    }
    return s;
  }

  static int qty(Object? value, {int fallback = 1}) {
    if (value == null) return fallback;
    if (value is! int) {
      throw const ApiError.badRequest('Quantity must be a whole number.');
    }
    return value;
  }
}
