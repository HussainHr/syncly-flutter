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
  String? validateEmail(String? value) {
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
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // // Validates phone number
  // String? validatePhone(String? value) {
  //   if (value == null || value.isEmpty) {
  //     return 'Phone number is required';
  //   }
  //   // Matches numbers with optional plus sign and hyphens
  //   // Allows formats like: +1-234-567-8901, 1234567890, +12345678901
  //   final phoneRegex = RegExp(r'^\+?[\d-]{10,}$');
  //   if (!phoneRegex.hasMatch(value)) {
  //     return 'Invalid phone number format';
  //   }
  //   if (value.replaceAll(RegExp(r'\D'), '').length < 10) {
  //     return 'Phone number must have at least 10 digits';
  //   }
  //   return null;
  // }

  String? validatePhone(String? value, {String? countryCode}) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Check for minimum length (varies by country)
    if (digitsOnly.length < 8) {
      return 'Phone number too short';
    }

    // Check for maximum length (15 digits is E.164 standard max)
    if (digitsOnly.length > 15) {
      return 'Phone number too long';
    }

    // Country-specific validation if country code is provided
    if (countryCode != null) {
      final validationResult = _validateForCountry(digitsOnly, countryCode);
      if (validationResult != null) return validationResult;
    }

    // General international format validation
    if (!_isValidInternationalNumber(digitsOnly)) {
      return 'Invalid phone number format';
    }

    return null;
  }

  bool _isValidInternationalNumber(String digits) {
    // E.164 format validation
    if (digits.startsWith('+')) {
      // International format with country code
      return RegExp(r'^\+\d{1,3}\d{4,14}$').hasMatch(digits);
    } else {
      // National format - basic digit check
      return RegExp(r'^\d{8,15}$').hasMatch(digits);
    }
  }

  String? _validateForCountry(String digits, String countryCode) {
    // Remove leading '+' if present
    final cleanDigits = digits.startsWith('+') ? digits.substring(1) : digits;

    switch (countryCode.toUpperCase()) {
      case 'US': // United States
      case 'CA': // Canada
        if (!RegExp(r'^1?\d{10}$').hasMatch(cleanDigits)) {
          return 'US/CA numbers must be 10 digits';
        }
        break;

      case 'GB': // United Kingdom
        if (!RegExp(r'^44\d{9,10}$').hasMatch(cleanDigits)) {
          return 'UK numbers must be 9-10 digits after +44';
        }
        break;

      case 'IN': // India
        if (!RegExp(r'^91\d{10}$').hasMatch(cleanDigits)) {
          return 'Indian numbers must be 10 digits after +91';
        }
        break;

      case 'BD': // Bangladesh
        if (!RegExp(r'^8801[3-9]\d{8}$').hasMatch(cleanDigits)) {
          return 'Bangladesh numbers must start with 01 and be 11 digits total';
        }
        break;

      // Add more country-specific validations as needed
    }

    return null;
  }

  String? validateLoginIdentifier(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email or phone number is required';
    }

    // Check if input is an email
    if (value.contains('@')) {
      return validateEmailNo(value);
    }
    // Otherwise treat as phone number
    else {
      return validatePhoneNo(value);
    }
  }

  // Validates phone number
  String? validatePhoneNo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters first
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check length (adjust based on your requirements)
    if (digitsOnly.length < 10) {
      return 'Phone number must have at least 10 digits';
    }

    // Optionally check for valid phone number patterns
    final phoneRegex = RegExp(
      r'^[\d+]{10,15}$',
    ); // Allows 10-15 digits with optional +
    if (!phoneRegex.hasMatch(value)) {
      return 'Invalid phone number format';
    }

    return null;
  }

  // Validates email
  String? validateEmailNo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
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
    // Matches letters, spaces, and common special characters in names
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, apostrophes, and periods';
    }
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

  // Validates desctription
  String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
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
    final truckRegex = RegExp(
      r'^[A-Z]{2}[-\s]?\d{2}[-\s]?[A-Z]{1,2}[-\s]?\d{1,4}$',
    );

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

String getOrdinalNumber(int number) {
  if (number >= 11 && number <= 13) {
    return '${number}th';
  }
  switch (number % 10) {
    case 1:
      return '${number}st';
    case 2:
      return '${number}nd';
    case 3:
      return '${number}rd';
    default:
      return '${number}th';
  }
}

String getNationalityName(String code) {
  final Map<String, String> nationalities = {
    'BD': 'Bangladeshi',
    'US': 'American',
    'GB': 'British',
    'IN': 'Indian',
    'PK': 'Pakistani',
    'SA': 'Saudi Arabian',
    'AE': 'Emirati',
    'QA': 'Qatari',
    'KW': 'Kuwaiti',
    'OM': 'Omani',
    'MY': 'Malaysian',
    'SG': 'Singaporean',
    'TH': 'Thai',
  };
  return nationalities[code] ?? code;
}

// String ago(Timestamp timestamp) {
//   final now = DateTime.now();
//   final dateTime =
//   DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
//   final difference = now.difference(dateTime);
//
//   if (difference.inSeconds < 60) {
//     return '${difference.inSeconds} seconds ago';
//   } else if (difference.inMinutes < 60) {
//     final minutes = difference.inMinutes;
//     return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
//   } else if (difference.inHours < 24) {
//     final hours = difference.inHours;
//     return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
//   } else if (difference.inDays < 30) {
//     final days = difference.inDays;
//     return '$days ${days == 1 ? 'day' : 'days'} ago';
//   } else if (difference.inDays < 365) {
//     final months = (difference.inDays / 30).floor();
//     return '$months ${months == 1 ? 'month' : 'months'} ago';
//   } else {
//     final years = (difference.inDays / 365).floor();
//     return '$years ${years == 1 ? 'year' : 'years'} ago';
//   }
// }

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
