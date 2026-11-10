import 'package:flutter/material.dart';

/// Pill visual reutilizable para estados de alerta médica ('ALTO ▲', 'BAJO ▼', 'NORMAL', 'PENDIENTE', etc.).
class ParameterBadgePill extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final Widget? icon;

  const ParameterBadgePill({
    super.key,
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: icon == null
          ? textWidget
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon!,
                const SizedBox(width: 3.5),
                textWidget,
              ],
            ),
    );
  }
}
