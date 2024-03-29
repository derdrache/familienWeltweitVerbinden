import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Color borderColorGrey = const Color(0xFFDFDDDD);
var isWebDesktop = kIsWeb &&
    (defaultTargetPlatform != TargetPlatform.iOS ||
        defaultTargetPlatform != TargetPlatform.android);
const double roundedCorners = 20;
double textSize = isWebDesktop ? 12 : 16;
const double webWidth = 600;
const double sideSpace = 10;
const double iconSizeNormal = 24;
const double iconSizeBig = 32;

getResponsiveFontSize(context, fontType){
  double unitHeightValue = MediaQuery.of(context).size.width * 0.01;
  double size;

  if(fontType == "h1"){
    size = 5 * unitHeightValue;

    if(size > 25) size = 25;

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

