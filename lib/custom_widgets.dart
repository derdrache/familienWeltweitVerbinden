import 'package:flutter/material.dart';

double sideSpace = 20;
var buttonColor = Colors.purple;

Widget customTextfield(hintText, controller){
  return Container(
    margin: EdgeInsets.only(top:sideSpace,bottom: sideSpace),
    padding: EdgeInsets.only(left: sideSpace, right:sideSpace),
    child: TextField(
        controller: controller,
        decoration: InputDecoration(
            enabledBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
            ),
            border: OutlineInputBorder(),
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey)
        )
    ),
  );
}


Widget customFloatbuttonExtended(text, function){
  return Container(
    margin: EdgeInsets.only(top:sideSpace,bottom: sideSpace),
    padding: EdgeInsets.only(left: sideSpace, right:sideSpace),
    child: FloatingActionButton.extended(
      heroTag: text,
        label: Text(text),
        backgroundColor: Colors.purple,
        onPressed: function
    )
  );
}