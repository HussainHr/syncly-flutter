import 'package:flutter/material.dart';
import 'package:syncly/core/services/navigation_service.dart';
import 'package:syncly/core/spacings/space.dart';
import 'package:syncly/core/widgets/app_loading.dart';


final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showSnackBar(String message, {Color textColor = Colors.white, Color snackBarColor = Colors.black87}) {
  scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      backgroundColor: snackBarColor,
      content: Text(
        message,
        style: TextStyle(color: textColor),
      ),
    ),
  );
  debugPrint("showing snackbar");
}

showInfoDialog(
  String bodyText, {
  String title = '',
  String? okayButtonText,
  bool showCancelButton = false,
  bool showOkayButton = false,
  bool showLoading = false,
  Function? onOkClick,
}) {
  return showDialog<void>(
    context: NavigationService.navigatorKey.currentContext!,
    barrierDismissible: false, // This makes the dialog non-cancellable
    builder: (BuildContext context) {
      return PopScope(
        canPop: false, // Prevents dialog from being dismissed by back button
        child: AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 18),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(bodyText),
              (showLoading) ? verticalSpacing(30) : const SizedBox(),
              (showLoading)
                  ? const AppLoading()
                  : const SizedBox(),
            ],
          ),
          actions: <Widget>[
            (showCancelButton)
                ? TextButton(
                    style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                    ),
                    child: Text("Cancel", style: const TextStyle(color: Colors.red)),
                    onPressed: () {
                      dismissDialog();
                    },
                  )
                : const SizedBox(),
            (showOkayButton)
                ? TextButton(
                    style: TextButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.labelLarge,
                    ),
                    child: Text( okayButtonText ?? 'Yes', style: const TextStyle(color: Colors.black)),
                    onPressed: () {
                      dismissDialog();
                      if (onOkClick != null) {
                        onOkClick();
                      }
                    },
                  )
                : const SizedBox(),
          ],
        ),
      );
    },
  );
}

void dismissDialog() {
  if (NavigationService.navigatorKey.currentContext != null) {
    Navigator.of(NavigationService.navigatorKey.currentContext!).pop();
  }
}
