import 'package:flutter/material.dart';

getResponsiveFontSize(context, fontType){
  double unitHeightValue = MediaQuery.of(context).size.width * 0.01;
  double size;

  if(fontType == "h1"){
    size = 5 * unitHeightValue;

    if(size > 30) size = 30;

    return size;
  } else if(fontType == "p"){
    size = 3.75 * unitHeightValue;

    if(size > 22.5) size = 22.5;

    return 3.75 * unitHeightValue;
  }
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