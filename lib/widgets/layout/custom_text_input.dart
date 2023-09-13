import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../global/style.dart' as style;

class CustomTextInput extends StatelessWidget {
  final String text;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool hideInput;
  final int moreLines;
  final TextInputAction textInputAction;
  final Function? onSubmit;
  final Function? informationWindow;
  final String? hintText;
  final FocusNode? focusNode;
  TextInputType? keyboardType;
  final int? maxLength;
  final bool onlyNumbers;
  final EdgeInsetsGeometry? margin;
  Color? borderColor;
  Color? maxLengthColor;


  CustomTextInput(
      this.text,
      this.controller, {
        super.key,
        this.validator,
        this.hideInput = false,
        this.moreLines = 1,
        this.textInputAction = TextInputAction.done,
        this.onSubmit,
        this.informationWindow,
        this.hintText,
        this.focusNode,
        this.keyboardType,
        this.maxLength,
        this.onlyNumbers = false,
        this.margin,
        this.borderColor,
        this.maxLengthColor
  });

  @override
  Widget build(BuildContext context) {
    List<TextInputFormatter>? inputFormater;
    borderColor ??= Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black;

    if(onlyNumbers){
      keyboardType = TextInputType.number;
      inputFormater = [FilteringTextInputFormatter.digitsOnly];
    }

    return Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              constraints: const BoxConstraints(maxWidth: style.webWidth),
              margin: margin ?? const EdgeInsets.all(style.sideSpace),
              child: TextFormField(
                  inputFormatters: inputFormater,
                  focusNode: focusNode,
                  onFieldSubmitted: (string) {
                    if(onSubmit != null) onSubmit!();
                  },
                  keyboardType: keyboardType ?? TextInputType.emailAddress,
                  textInputAction: textInputAction,
                  textAlignVertical: TextAlignVertical.top,
                  maxLines: moreLines,
                  obscureText: hideInput,
                  controller: controller,

                  decoration: InputDecoration(
                    counterStyle: TextStyle(color: maxLengthColor),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide:  BorderSide(color: borderColor!),
                      borderRadius: BorderRadius.circular(style.roundedCorners)
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(style.roundedCorners)
                    ),
                    alignLabelWithHint: true,
                    floatingLabelBehavior: hintText==null ? FloatingLabelBehavior.auto : FloatingLabelBehavior.always,
                    hintText: hintText,
                    labelText: text,
                    labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
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
                    onPressed: () => informationWindow!()
                ),
              )
          )
        ]
    );
  }
}
