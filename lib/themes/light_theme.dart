import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  fontFamily: "Sarabun",
  scaffoldBackgroundColor: Colors.white,
  colorScheme: const ColorScheme.light(
    background: Colors.white,
    primary: Color(0xFFBF1D53),
    secondary: Color(0xFF3CB28F),
  ),
  iconTheme: const IconThemeData(color: Color(0xAA3CB28F)),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    foregroundColor: Colors.white
  ),
  brightness: Brightness.light
);