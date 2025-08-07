import 'package:flutter/material.dart';
import 'dart:math' as math;

class ColorHelpers {
  static Color getTextColor(Color bgColor) {
    return checkDarkColor(bgColor) ? Colors.white : Colors.black;
  }

  static bool checkDarkColor(Color bgColor) {
    var r = bgColor.red.toInt();
    var g = bgColor.green.toInt();
    var b = bgColor.blue.toInt();
    var colorVal = (r * 0.299 + g * 0.587 + b * 0.114);
    return colorVal <= 186;
  }

  static Color invert(Color color) {
    final r = 255 - color.red;
    final g = 255 - color.green;
    final b = 255 - color.blue;

    return Color.fromARGB((color.opacity * 255).round(), r, g, b);
  }

  static Color getInvertColor(Color bgColor) {
    return invert(bgColor);
  }

  static Color generateColor({int? seed}) {
    return Color((math.Random(seed).nextDouble() * 0xFFFFFF).toInt())
        .withOpacity(1.0);
  }
}
