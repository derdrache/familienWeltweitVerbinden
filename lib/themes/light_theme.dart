import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  fontFamily: "Sarabun",
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.light(
    background: Colors.white,
    primary: const Color(0xFFBF1D53),
    secondary: const Color(0xFF3CB28F),
  ),
  iconTheme: const IconThemeData(color: Color(0xAA3CB28F)),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    foregroundColor: Colors.white
  ),
  brightness: Brightness.light
);