import 'package:flutter/material.dart';

import '../../global/style.dart' as style;

Widget customFloatbuttonExtended(text, function){
  return Align(
    child: Container(
        width: 250,
        margin: const EdgeInsets.only(top:style.sideSpace,bottom: style.sideSpace),
        padding: const EdgeInsets.only(left: style.sideSpace, right:style.sideSpace),
        child: FloatingActionButton.extended(
            heroTag: text,
            label: Text(text, style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.white
            )
            ),
            onPressed: function
        )
    ),
  );
}