import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
    fontFamily: "Sarabun",
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.dark(
      background: Colors.black,
      primary: Colors.grey[800]!,
      secondary: Colors.grey[700]!,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.grey
    ),
    brightness: Brightness.dark
);