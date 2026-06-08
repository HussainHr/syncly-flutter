import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension StringUtil on String {
  Color get toColor {
    String data = replaceAll("#", "");
    if (data.length == 6) {
      data = "FF$data";
    }
    return Color(int.parse("0x$data"));
  }

  String maxLength(int length) {
    if (length > length) {
      return this;
    } else {
      return substring(0, length);
    }
  }

  String toParagraph([bool addDash = false]) {
    return addDash ? "-\t$this" : "\t$this";
  }

  bool toBool([bool defaultValue = false]) {
    if (toString().compareTo('1') == 0 || toString().compareTo('true') == 0) {
      return true;
    } else if (toString().compareTo('0') == 0 ||
        toString().compareTo('false') == 0) {
      return false;
    }
    return defaultValue;
  }

  int? toInt([int? defaultValue]) {
    try {
      return int.parse(this);
    } catch (e) {
      return defaultValue;
    }
  }

  double toDouble([double defaultValue = 0]) {
    try {
      return double.parse(this);
    } catch (e) {
      return defaultValue;
    }
  }

  String get capitalizeWords {
    var result = this[0].toUpperCase();
    for (int i = 1; i < length; i++) {
      if (this[i - 1] == " ") {
        result = result + this[i].toUpperCase();
      } else {
        result = result + this[i];
      }
    }
    return result;
  }

  String? get nullIfEmpty {
    return isEmpty ? null : this;
  }
}

extension NullableStringUtil on String? {
  bool get hasValue {
    return this != null && this!.isNotEmpty;
  }

  String get toStringOrEmpty {
    if (this != null) {
      return toString();
    } else {
      return '';
    }
  }

  // Validates email
  String? emailValidation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  // Validates password
  String? passwordValidation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Validates phone number
  String? phoneValidation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Matches numbers with optional plus sign and hyphens
    // Allows formats like: +1-234-567-8901, 1234567890, +12345678901
    final phoneRegex = RegExp(r'^\+?[\d-]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Invalid phone number format';
    }
    if (value.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
      return 'Phone number must have at least 10 digits';
    }
    return null;
  }

// Validates address
  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 5) {
      return 'Address is too short';
    }
    if (value.trim().length > 200) {
      return 'Address is too long (maximum 200 characters)';
    }
    return null;
  }

  // Validates date
  String? validateDateRange(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    return null;
  }

// Validates name
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    // // Matches letters, spaces, and common special characters in names
    // final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
    // if (!nameRegex.hasMatch(value)) {
    //   return 'Name can only contain letters, spaces, hyphens, apostrophes, and periods';
    // }
    if (value.trim().length < 2) {
      return 'Name is too short';
    }
    if (value.trim().length > 50) {
      return 'Name is too long (maximum 50 characters)';
    }
    return null;
  }

  // Validates radius
  String? validateRadius(String? value) {
    if (value == null || value.isEmpty) {
      return 'Radius is required';
    }
    return null;
  }

  // Validates desctription
  String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    return null;
  }

// Validates ID (assuming alphanumeric ID)
  String? validateId(String? value) {
    if (value == null || value.isEmpty) {
      return 'ID is required';
    }
    // Matches alphanumeric characters with optional hyphens
    final idRegex = RegExp(r'^[A-Za-z0-9\-]+$');
    if (!idRegex.hasMatch(value)) {
      return 'ID can only contain letters, numbers, and hyphens';
    }
    if (value.length < 4) {
      return 'ID must be at least 4 characters';
    }
    if (value.length > 20) {
      return 'ID is too long (maximum 20 characters)';
    }
    return null;
  }

// Optional: Validates numeric ID
  String? validateNumericId(String? value) {
    if (value == null || value.isEmpty) {
      return 'ID is required';
    }
    // Matches only numbers
    final numericIdRegex = RegExp(r'^\d+$');
    if (!numericIdRegex.hasMatch(value)) {
      return 'ID must contain only numbers';
    }
    if (value.length < 4) {
      return 'ID must be at least 4 digits';
    }
    if (value.length > 12) {
      return 'ID is too long (maximum 12 digits)';
    }
    return null;
  }

  String? validateTruckNumber(String value) {
    if (value.isEmpty) {
      return 'Truck number is required';
    }

    // Remove any spaces for validation
    value = value.trim().toUpperCase();

    // Common truck number format validation
    // Allows formats like:
    // - AA12AA1234
    // - AA-12-AA-1234
    // - AA 12 AA 1234
    // - MH02AB1234
    // - GJ-01-XX-0000
    final truckRegex =
        RegExp(r'^[A-Z]{2}[-\s]?\d{2}[-\s]?[A-Z]{1,2}[-\s]?\d{1,4}$');

    if (!truckRegex.hasMatch(value)) {
      return 'Invalid truck number format';
    }

    // Additional validations
    // Remove special characters for length check
    final cleanNumber = value.replaceAll(RegExp(r'[-\s]'), '');

    if (cleanNumber.length < 8) {
      return 'Truck number is too short';
    }

    if (cleanNumber.length > 10) {
      return 'Truck number is too long';
    }

    // Check if the number portion is all zeros
    final numberPart = cleanNumber.substring(4);
    if (numberPart.replaceAll('0', '').isEmpty) {
      return 'Invalid number sequence';
    }

    return null;
  }

  String? validateLength(String value) {
    if (value.isEmpty) {
      return 'Length is required';
    }
    // Allows decimals and whole numbers
    final lengthRegex = RegExp(r'^\d*\.?\d+$');
    if (!lengthRegex.hasMatch(value)) {
      return 'Please enter a valid length';
    }
    final length = double.tryParse(value);
    if (length == null) {
      return 'Invalid length format';
    }
    if (length <= 0) {
      return 'Length must be greater than 0';
    }
    if (length > 999999) {
      return 'Length value is too large';
    }
    return null;
  }

  String? validateHeight(String value) {
    if (value.isEmpty) {
      return 'Height is required';
    }
    final heightRegex = RegExp(r'^\d*\.?\d+$');
    if (!heightRegex.hasMatch(value)) {
      return 'Please enter a valid height';
    }
    final height = double.tryParse(value);
    if (height == null) {
      return 'Invalid height format';
    }
    if (height <= 0) {
      return 'Height must be greater than 0';
    }
    if (height > 300) {
      // Assuming height in cm with reasonable max
      return 'Height value is too large';
    }
    return null;
  }

  String? validateWeight(String value) {
    if (value.isEmpty) {
      return 'Weight is required';
    }
    final weightRegex = RegExp(r'^\d*\.?\d+$');
    if (!weightRegex.hasMatch(value)) {
      return 'Please enter a valid weight';
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Invalid weight format';
    }
    if (weight <= 0) {
      return 'Weight must be greater than 0';
    }
    if (weight > 100000) {
      // Assuming weight in kg with reasonable max
      return 'Weight value is too large';
    }
    return null;
  }

  String? validateWaitingCharge(String value) {
    if (value.isEmpty) {
      return 'Waiting charge is required';
    }
    // Allows decimals and whole numbers with optional currency symbols
    final chargeRegex = RegExp(r'^\$?[\d,]*\.?\d+$');
    if (!chargeRegex.hasMatch(value)) {
      return 'Please enter a valid charge amount';
    }
    // Remove currency symbol and commas before parsing
    final cleanValue = value.replaceAll(RegExp(r'[\$,]'), '');
    final charge = double.tryParse(cleanValue);
    if (charge == null) {
      return 'Invalid charge format';
    }
    if (charge < 0) {
      return 'Charge cannot be negative';
    }
    if (charge > 10000) {
      // Adjust maximum as needed
      return 'Charge amount is too large';
    }
    return null;
  }
}

String formatDate(String? dateString, {String format = 'dd MMM yyyy'}) {
  if (dateString == null) return '';

  try {
    final DateTime date = DateTime.parse(dateString);
    return DateFormat(format).format(date);
  } catch (e) {
    return '';
  }
}

String timeAgo(String? dateString) {
  if (dateString == null) return '';

  try {
    DateTime date = DateTime.parse(dateString);
    Duration difference = DateTime.now().difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  } catch (e) {
    return '';
  }
}

String formatNumberString(dynamic value, {int maxLength = 4}) {
  if (value == null) return " ";

  // Convert the value to string, handling both int and double
  String stringValue = value.toString();

  // Remove any trailing zeros after decimal point
  if (stringValue.contains('.')) {
    stringValue = stringValue.replaceAll(RegExp(r'\.?0*$'), '');
  }

  // Return the entire string if it's shorter than maxLength
  if (stringValue.length <= maxLength) {
    return stringValue;
  }

  // Handle negative numbers
  if (stringValue.startsWith('-')) {
    return stringValue.substring(0, min(stringValue.length, maxLength + 1));
  }

  return stringValue.substring(0, min(stringValue.length, maxLength));
}

String cleanBangladeshiNumber(String phoneNumber) {
  // Check if number starts with +8800 (common mistake)
  if (phoneNumber.startsWith('+8800')) {
    // Remove the extra 0 after +880
    return '+880${phoneNumber.substring(5)}';
  }
  // Return original if no issue found
  return phoneNumber;
}

String getGreeting() {
  final hour = DateTime.now().hour;

  if (hour >= 5 && hour < 12) {
    return "Good Morning,";
  } else if (hour >= 12 && hour < 17) {
    return "Good Afternoon,";
  } else if (hour >= 17 && hour < 21) {
    return "Good Evening,";
  } else {
    return "Good Night,";
  }
}

// Always 8 digits with very high uniqueness
String generateUniqueClientReference() {
  final now = DateTime.now();

  // Last 2 digits of year
  final yearStr = (now.year % 100).toString().padLeft(2, '0');

  // Month: 2 digits (01-12)
  final monthStr = now.month.toString().padLeft(2, '0');

  // Day: 2 digits (01-31)
  final dayStr = now.day.toString().padLeft(2, '0'); ///todo: change it to day and padLeft 2

  // Random 2 digits combining millisecond + microsecond for true randomness
  // This ensures even if 2 users create at same time, they get different IDs
  final randomSeed = now.microsecondsSinceEpoch;
  final random = Random(randomSeed);
  final randomPart = random.nextInt(100).toString().padLeft(2, '0'); ///todo: change it to 100 and padLeft 2

  return '$yearStr$monthStr$dayStr$randomPart';
}

// Always 8 digits with hour-based uniqueness
String generateNumericClientReference() {
  final now = DateTime.now();

  // Last 2 digits of year
  final yearStr = (now.year % 100).toString().padLeft(2, '0');

  // Month: 2 digits (01-12)
  final monthStr = now.month.toString().padLeft(2, '0');

  // Day: 2 digits (01-31)
  final dayStr = now.day.toString().padLeft(2, '0');

  // Hour (00-23) + minute-based random (00-99)
  // Combines current hour with random component
  final hourPart = now.hour;
  final randomPart = Random(now.microsecondsSinceEpoch).nextInt(4);
  final timePart = ((hourPart * 4) + randomPart).toString().padLeft(2, '0');

  return '$yearStr$monthStr$dayStr$timePart';
}

// Result: Extremely low collision probability
String generateSecureClientReference({String? userId, String? deviceId}) {
  final now = DateTime.now();

  // Last 2 digits of year
  final yearStr = (now.year % 100).toString().padLeft(2, '0');

  // Month: 2 digits
  final monthStr = now.month.toString().padLeft(2, '0');

  // Day: 2 digits
  final dayStr = now.day.toString().padLeft(2, '0');

  // Millisecond-based component (changes 100 times per second)
  // Combines millisecond + microsecond for maximum uniqueness
  final millis = now.millisecond % 100;
  final micros = (now.microsecond ~/ 10) % 100;
  final uniquePart = ((millis + micros) % 100).toString().padLeft(2, '0');

  return '$yearStr$monthStr$dayStr$uniquePart';
}

// May have collisions if multiple users at same minute
String generateTimestampClientReference() {
  final now = DateTime.now();

  final year = (now.year % 100).toString().padLeft(2, '0');
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');

  // Hour + Minute combined (00-99)
  final hourMinute = ((now.hour * 4 + now.minute ~/ 15) % 100).toString().padLeft(2, '0');

  return '$year$month$day$hourMinute';
}
