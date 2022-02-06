import 'package:flutter/material.dart';

textButtonStyle(){
  return ButtonStyle(
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          )
      )
  );
}