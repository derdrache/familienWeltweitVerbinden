import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

double sideSpace = 10;
double borderRounding = 5;
double boxHeight = 50;
double webWidth = 600;


Widget customTextInput(text, controller, {validator, passwort = false,
  moreLines = 1,TextInputAction textInputAction = TextInputAction.done,
  onSubmit, informationWindow, hintText}){

  return Stack(
    children: [
      Align(
        alignment: Alignment.center,
        child: Container(
            width: webWidth,
            margin: EdgeInsets.all(sideSpace),
            child: TextFormField(
                onFieldSubmitted: (string) {
                  if(onSubmit != null)onSubmit();
                },
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
                  //alignLabelWithHint: true,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: hintText,
                  labelText: text,
                  labelStyle: const TextStyle(fontSize: 15, color: Colors.grey),
                  //floatingLabelStyle: const TextStyle(fontSize: 15, color: Colors.blue)
                ),
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

customSnackbar(context, text, {color = Colors.red, duration = const Duration(seconds: 5)}){
  var snackbar = SnackBar(
        duration: duration,
          backgroundColor: color,
          content: Text(text)
      );

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  return ScaffoldMessenger.of(context).showSnackBar(snackbar);
}

customAppBar({title, buttons, elevation = 4.0, var onTap, context}){
  buttons ??= <Widget>[];

    return AppBar(
      leading: null,
      title: InkWell(
          onTap: onTap,
          child: Row(
              children: [
                Flexible(
                  child: SizedBox(
                      height: 50,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            title,
                            overflow: TextOverflow.fade,
                            style: const TextStyle(color: Colors.black, fontSize: 20)
                        ),
                      )
                  ),
                )
              ]
          )
      ),
      backgroundColor: Colors.white,
      elevation: elevation,
      iconTheme: const IconThemeData(
          color: Colors.black
      ),
      actions: buttons,
    );


}

class CustomMultiTextForm extends StatefulWidget {
  List auswahlList;
  var selected;
  String hintText;
  var onConfirm;
  var validator;
  Icon icon;

  getSelected(){
    return selected;
  }



  CustomMultiTextForm({Key key,
    this.auswahlList,
    this.selected,
    this.hintText = "",
    this.onConfirm,
    this.validator,
    this.icon
  }) : super(key: key);

  @override
  _CustomMultiTextFormState createState() => _CustomMultiTextFormState();
}

class _CustomMultiTextFormState extends State<CustomMultiTextForm> {

  @override
  void initState() {
    widget.onConfirm ??= (selected){};
    widget.selected ??= [];

    super.initState();
  }

  List<MultiSelectItem> _createMultiselectItems(){
    List<MultiSelectItem> multiSelectItems = [];

    for(var auswahl in widget.auswahlList){
      multiSelectItems.add(
          MultiSelectItem(auswahl, auswahl)
      );
    }

    return multiSelectItems;
  }


  @override
  Widget build(BuildContext context) {
    List<MultiSelectItem> auswahlListSelectItem = _createMultiselectItems();
    var textColor = Colors.black;

    String createDropdownText(){
      String dropdownText = "";
      var textMaxLength = 55;

      if (widget.selected.isEmpty){
        dropdownText = widget.hintText;
        textColor = Colors.grey;
      } else{
        dropdownText = widget.selected.join(" , ");
      }

      if (dropdownText.length > textMaxLength){
        dropdownText = dropdownText.substring(0,textMaxLength - 3) + "...";
      }

      return dropdownText;
    }

    changeSelectToList(select){
      setState(() {
        widget.selected = select;
      });
    }

    return Align(
      child: Container(
        width: webWidth,
        margin: EdgeInsets.all(sideSpace),
        child: MultiSelectDialogField (
            buttonIcon: widget.icon,
            initialValue: widget.selected,
            buttonText: Text(
              createDropdownText(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor),
            ),
            chipDisplay: MultiSelectChipDisplay.none(),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.all(Radius.circular(borderRounding))
            ),
            items: auswahlListSelectItem,
            validator: widget.validator,
            onSelectionChanged: changeSelectToList,
            onConfirm: widget.onConfirm
          )
      ),
    );
  }
}

class CustomDropDownButton extends StatefulWidget {
  List<String> items;
  String hintText;
  String selected;
  var onChange;

  CustomDropDownButton({Key key,
    this.items,
    this.hintText = "",
    this.selected = "",
    this.onChange
  }) : super(key: key);


  getSelected(){
    return selected;
  }

  @override
  _CustomDropDownButtonState createState() => _CustomDropDownButtonState();
}

class _CustomDropDownButtonState extends State<CustomDropDownButton> {

  createDropdownItems(){
    return widget.items.map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Container(
          width: webWidth,
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.only(left: 10, right: 10),
          decoration: BoxDecoration(
              border: Border.all(width: 1),
              borderRadius: const BorderRadius.all(Radius.circular(5))
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: widget.selected == "" ? null : widget.selected,
              hint: Text(widget.hintText, style: const TextStyle(color: Colors.grey)),
              elevation: 16,
              style: const TextStyle(color: Colors.black),
              icon: const Icon(Icons.arrow_downward, color: Colors.black,),
              onChanged: (newValue){

                setState(() {
                  widget.selected = newValue;
                });
                if(widget.onChange != null) widget.onChange();
              },
              items: createDropdownItems(),
            ),
          ),
        )
      ]),
    );



  }
}



