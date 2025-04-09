import 'package:calendar_app/component/theme/theme.dart';
import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final String label;
  final Function()? tap;
  const Button({Key? key, required this.label, required this.tap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          width: 100,
          height: 40,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), color: primaryClr),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ));
  }
}
