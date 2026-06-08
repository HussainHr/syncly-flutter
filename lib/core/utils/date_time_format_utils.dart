import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String convertDateFormat(String inputDate) {
  try {
    // Convert input date to title case (to handle DEC -> Dec)
    String formattedInput = inputDate.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    // Parse the input date using the known format
    DateTime parsedDate = DateFormat('dd MMM yyyy').parse(formattedInput);

    // Format to desired output format
    return DateFormat('yyyy-MM-dd').format(parsedDate);
  } catch (e) {
    debugPrint('Date parse error: $e');
    return '';
  }
}

DateTime parseDateFromState(String dateString) {
  try {
    // Assuming the dateString is in format "yyyy-MM-dd"
    return DateTime.parse(dateString);
  } catch (e) {
    // Fallback to current date if parsing fails
    return DateTime.now();
  }
}


bool checkLastTicketingTime(String timeString){
  DateTime parsedDateTime = DateTime.parse(timeString).toLocal(); // Local time e convert korchi
  DateTime now = DateTime.now();

  Duration difference = now.difference(parsedDateTime);

  if (difference.inMinutes < 15) {
    print("DateTime is within 15 minutes from now.");
    return true;
  } else {
    print("DateTime is more than 15 minutes ago.");
    return false;
  }
}