import 'package:flutter/material.dart';

class NumberLocalizer {
  static const Map<String, String> _englishToBengaliDigits = {
    '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
    '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
  };

  static String localizeNumbers(BuildContext context, String text) {
    final locale = Localizations.localeOf(context).languageCode;

    if (locale != 'bn') return text; // Return original if not Bengali

    return text.replaceAllMapped(RegExp(r'[0-9]'), (match) {
      return _englishToBengaliDigits[match.group(0)] ?? match.group(0)!;
    });
  }

  static String localizeNumber(BuildContext context, String number) {
    return localizeNumbers(context, number.toString());
  }
}


class NumberFormatter {
  static String format(BuildContext context, num number, {
    int fractionDigits = 1,
    String? currencySymbol,
    bool useLocale = true,
  }) {
    final locale = Localizations.localeOf(context).languageCode;
    final formattedNumber = number.toStringAsFixed(fractionDigits);

    if (useLocale && locale == 'bn') {
      return '${_toBengali(formattedNumber)}${currencySymbol != null ? ' $currencySymbol' : ''}';
    }
    return '$formattedNumber${currencySymbol != null ? ' $currencySymbol' : ''}';
  }

  static double parseCurrencyString(String value) {
    // Remove all non-numeric characters except dots and commas
    final numericString = value.replaceAll(RegExp(r'[^0-9.,]'), '');
    return double.parse(numericString.replaceAll(',', ''));
  }

  static String _toBengali(String englishNumber) {
    const Map<String, String> englishToBengaliDigits = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
      '.': '.', ',': ',',
    };

    return englishNumber.split('').map((digit) {
      return englishToBengaliDigits[digit] ?? digit;
    }).join();
  }
}

class TimeLocalization {
  static String formatTime(BuildContext context, String timeString) {
    try {
      final timeFormat = TimeOfDayFormat.HH_colon_mm; // Default format
      final locale = Localizations.localeOf(context).languageCode;

      // For Bengali locale, convert digits
      if (locale == 'bn') {
        return _convertDigitsToBengali(timeString);
      }

      return timeString; // Return original for other locales
    } catch (e) {
      return timeString; // Fallback to original if parsing fails
    }
  }

  static String _convertDigitsToBengali(String time) {
    const englishToBengali = {
      '0': '০',
      '1': '১',
      '2': '২',
      '3': '৩',
      '4': '৪',
      '5': '৫',
      '6': '৬',
      '7': '৭',
      '8': '৮',
      '9': '৯',
      ':': ':',
    };

    return time.split('').map((char) => englishToBengali[char] ?? char).join();
  }
}