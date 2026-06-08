import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:syncly/core/constants/app_colors.dart';

class AppLoading extends StatelessWidget {
  final Color? color;
  const AppLoading({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(child: SpinKitCircle(color: color ?? AppColors.primaryColor));
  }
}
