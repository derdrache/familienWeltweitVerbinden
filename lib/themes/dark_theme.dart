import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
    fontFamily: "Sarabun",
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.dark(
      background: Colors.black,
      primary: Colors.grey[900]!,
      secondary: Colors.grey[800]!
    ),
  brightness: Brightness.dark
);