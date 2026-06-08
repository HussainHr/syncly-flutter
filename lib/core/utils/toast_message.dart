import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:syncly/core/constants/app_colors.dart';

void showToast(String message) {
  toastMessage(
    message,
    AppColors.primaryColor,
    AppColors.whiteColor,
    ToastGravity.BOTTOM,
  );
}

Future<bool?> toastMessage(
  String toastMessage,
  Color toastBackgroundColor,
  Color textColor,
  ToastGravity toastGravity,
) {
  return Fluttertoast.showToast(
    msg: toastMessage,
    toastLength: Toast.LENGTH_SHORT,
    gravity: toastGravity,
    timeInSecForIosWeb: 1,
    backgroundColor: toastBackgroundColor,
    textColor: textColor,
    fontSize: 16.0,
  );
}
