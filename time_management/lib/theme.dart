import 'package:flutter/material.dart';

abstract class BaseTheme {
  abstract Color text;
  abstract Color lightText;
  abstract Color hintText;
  abstract Color background;
  abstract Color textBackground;
  abstract Color splashEffect;
  abstract Color shadowEffect;
  abstract Color shadowElevation;
  abstract Color button;
  abstract Color darkButton;
  abstract Color listItemBackground;
  abstract Color removeColor;
  abstract List<Color> priorityColors;
}

class LightTheme extends BaseTheme {
  static const Color white = Color(0xFFFAFAFA);
  static const Color black = Color(0xFF100F41);
  static const Color lightGrey = Color(0xFFEFE8E8);
  static const Color grey = Color(0xFF918989);
  static const Color lightBlue = Color(0xFFECF2FF);
  static const Color blue = Color.fromARGB(255, 177, 202, 255);

  @override
  Color background = white;
  @override
  Color textBackground = lightGrey;

  @override
  Color hintText = grey;

  @override
  Color text = black;
  @override
  Color lightText = white;

  @override
  Color shadowEffect = black.withOpacity(0.25);

  @override
  Color splashEffect = black;

  @override
  Color button = white;

  @override
  Color darkButton = black;

  @override
  Color shadowElevation = black.withOpacity(0.5);

  @override
  Color listItemBackground = white;

  @override
  Color removeColor = Colors.red;

  @override
  List<Color> priorityColors = [Colors.red, Colors.green, Colors.blue];
}
