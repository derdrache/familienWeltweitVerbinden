import 'package:flutter/material.dart';
import '../../global/style.dart' as style;

customSnackbar(context, text, {color = Colors.red, duration = const Duration(seconds: 3)}){
  var snackbar = SnackBar(
      duration: duration,
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(style.roundedCorners),
            color: color
          ),
          child: Text(text,style: TextStyle(fontWeight: FontWeight.bold),)
      )
  );

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  return ScaffoldMessenger.of(context).showSnackBar(snackbar);
}