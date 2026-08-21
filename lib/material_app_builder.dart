import 'package:flutter/material.dart';

Widget materialAppBuilder(BuildContext context, Widget? child) {
  final mediaQueryData = MediaQuery.of(context);
  final systemTextScalerFactor = mediaQueryData.textScaler;

  Widget childWidget = child ?? const SizedBox.shrink();

  return MediaQuery(
    data: mediaQueryData.copyWith(
      textScaler: systemTextScalerFactor.clamp(
        minScaleFactor: 0.8,
        maxScaleFactor: 1.2,
      ),
    ),
    child: childWidget,
  );
}
