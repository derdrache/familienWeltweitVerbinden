import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../global/style.dart' as style;

Widget customTextInput(text, controller, {validator, passwort = false,
  moreLines = 1,TextInputAction textInputAction = TextInputAction.done,
  onSubmit, informationWindow, hintText, focusNode, keyboardType, maxLength, onlyNumbers = false}){

  List<TextInputFormatter>? inputFormater;

  if(onlyNumbers){
    keyboardType = TextInputType.number;
    inputFormater = [FilteringTextInputFormatter.digitsOnly];
  }

  return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            constraints: BoxConstraints(maxWidth: style.webWidth),
            color: Colors.white,
            margin: EdgeInsets.all(style.sideSpace),
            child: TextFormField(
                inputFormatters: inputFormater,
                focusNode: focusNode,
                onFieldSubmitted: (string) {
                  if(onSubmit != null)onSubmit();
                },
                keyboardType: keyboardType ?? TextInputType.emailAddress,
                textInputAction: textInputAction,
                textAlignVertical: TextAlignVertical.top,
                maxLines: moreLines,
                obscureText: passwort,
                controller: controller,
                decoration: InputDecoration(
                  isDense: true,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  floatingLabelBehavior: hintText==null ? FloatingLabelBehavior.auto : FloatingLabelBehavior.always,
                  hintText: hintText,
                  labelText: text,
                  labelStyle: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
                maxLength: maxLength,
                validator: validator
            ),
          ),
        ),
        if (informationWindow != null) Positioned(
            left:5,
            top: 2,
            child: Container(
              alignment: Alignment.topCenter,
              margin: const EdgeInsets.only(bottom: 10),
              width: 20,
              height: 20,
              child: IconButton(
                  padding: const EdgeInsets.all(0),
                  alignment: Alignment.topCenter,
                  iconSize: 20,
                  icon: const Icon(Icons.info),
                  onPressed: () => informationWindow()
              ),
            )
        )
      ]
  );
}