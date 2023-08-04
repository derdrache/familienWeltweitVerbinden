import 'package:flutter/material.dart';

customSnackbar(context, text, {color = Colors.red, duration = const Duration(seconds: 3)}){
  var snackbar = SnackBar(
      duration: duration,
      backgroundColor: color,
      content: Text(text)
  );

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  return ScaffoldMessenger.of(context).showSnackBar(snackbar);
}