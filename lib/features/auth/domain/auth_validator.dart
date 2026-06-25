class AuthValidator {
  static const allowedDomain = '@iut-dhaka.edu';

  static String? validateIutEmail(String value) {
    final email = value.trim().toLowerCase();
    if (email.isEmpty) return 'IUT email is required.';
    if (!email.contains('@')) return 'Enter a valid email address.';
    if (!email.endsWith(allowedDomain)) {
      return 'Use your $allowedDomain email.';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  static String? validateStrongPassword(
    String value, {
    required String name,
    required String email,
    String? studentId,
  }) {
    final baseMessage = validatePassword(value);
    if (baseMessage != null) return baseMessage;
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Add at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Add at least one lowercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Add at least one number.';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=~`/\\;[\]]').hasMatch(value)) {
      return 'Add at least one special character.';
    }

    final password = value.toLowerCase();
    final nameParts = name
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((part) => part.length >= 3);
    for (final part in nameParts) {
      if (password.contains(part)) return 'Do not use your name in password.';
    }

    final emailName = email.split('@').first.toLowerCase();
    if (emailName.length >= 3 && password.contains(emailName)) {
      return 'Do not use your email name in password.';
    }

    final id = studentId?.trim().toLowerCase();
    if (id != null && id.length >= 3 && password.contains(id)) {
      return 'Do not use your student ID in password.';
    }

    return null;
  }

  static String? validateDisplayName(String value) {
    if (value.trim().isEmpty) return 'Name is required.';
    if (value.trim().length < 2) return 'Name is too short.';
    return null;
  }

  static String? validateRequired(String value, String label) {
    if (value.trim().isEmpty) return '$label is required.';
    return null;
  }
}
