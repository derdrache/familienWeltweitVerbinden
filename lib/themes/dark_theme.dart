import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
    fontFamily: "Sarabun",
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.dark(
      background: Colors.black,
      primary: Colors.grey[900]!,
      secondary: Colors.grey[800]!,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white24
    ),
    brightness: Brightness.dark
);