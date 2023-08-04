import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'style.dart' as style;

double sideSpace = 10;
double borderRounding = 5;
double boxHeight = 50;


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
            margin: EdgeInsets.all(sideSpace),
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
                  counterText: "",
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

Widget customFloatbuttonExtended(text, function){
  return Align(
    child: Container(
      width: 300,
      margin: EdgeInsets.only(top:sideSpace,bottom: sideSpace),
      padding: EdgeInsets.only(left: sideSpace, right:sideSpace),
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

customSnackbar(context, text, {color = Colors.red, duration = const Duration(seconds: 3)}){
  var snackbar = SnackBar(
        duration: duration,
          backgroundColor: color,
          content: Text(text)
      );

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  return ScaffoldMessenger.of(context).showSnackBar(snackbar);
}

class CustomMultiTextForm extends StatefulWidget {
  List auswahlList;
  List? selected;
  String hintText;
  Function? onConfirm;
  var validator;

  getSelected(){
    return selected;
  }


  CustomMultiTextForm({Key? key,
    required this.auswahlList,
    this.selected,
    this.hintText = "",
    this.onConfirm,
    this.validator
  }) : super(key: key);

  @override
  _CustomMultiTextFormState createState() => _CustomMultiTextFormState();
}

class _CustomMultiTextFormState extends State<CustomMultiTextForm> {

  @override
  void initState() {
    widget.onConfirm ??= (){};
    widget.selected ??= [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    changeSelectToList(select){
      widget.selected = select;
      if(select.isNotEmpty) widget.onConfirm!();
    }

    return Container(
      width: style.webWidth,
      margin: EdgeInsets.all(sideSpace),
      decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(5)
      ),
      child: MultiSelectDialogField(
        initialValue: widget.selected!,
        items: widget.auswahlList.map((e) => MultiSelectItem(e, e)).toList(),
        listType: MultiSelectListType.LIST,
        searchable: true,
        onConfirm: changeSelectToList,
        onSelectionChanged: changeSelectToList,
        buttonText: Text(widget.hintText),
        chipDisplay: MultiSelectChipDisplay(
          onTap: (value){
            widget.selected!.remove(value);
            if(widget.selected!.length > 1) widget.onConfirm!();
            return widget.selected;
          },
        ),
      ),
    );
  }
}





