import 'package:flutter/material.dart';

getResponsiveFontSize(context, fontType){
  double unitHeightValue = MediaQuery.of(context).size.width * 0.01;

  if(fontType == "h1") return 5 * unitHeightValue;
  if(fontType == "p") return 3.75 * unitHeightValue;
}

textButtonStyle(){
  return ButtonStyle(
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          )
      )
  );
}