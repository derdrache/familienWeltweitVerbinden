import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

double sideSpace = 10;
double borderRounding = 5;
double boxHeight = 50;
double webWidth = 600;


Widget customTextInput(text, controller, {validator, passwort = false,
  moreLines = 1,TextInputAction textInputAction = TextInputAction.done,
  onSubmit, informationWindow, hintText, focusNode}){

  return Stack(
    children: [
      Align(
        alignment: Alignment.center,
        child: Container(
            width: webWidth,
            margin: EdgeInsets.all(sideSpace),
            child: TextFormField(
                focusNode: focusNode,
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
                  alignLabelWithHint: true,
                  floatingLabelBehavior: hintText==null ? FloatingLabelBehavior.auto : FloatingLabelBehavior.always,
                  hintText: hintText,
                  labelText: text,
                  labelStyle: const TextStyle(fontSize: 15, color: Colors.grey),
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

class CustomMultiTextForm extends StatefulWidget {
  List auswahlList;
  List selected;
  String hintText;
  Function onConfirm;
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
    widget.onConfirm ??= (){};
    widget.selected ??= [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    changeSelectToList(select){
      widget.selected = select;
      widget.onConfirm();
    }


    return Container(
      width: webWidth,
      margin: EdgeInsets.all(sideSpace),
      decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(5)
      ),
      child: MultiSelectDialogField(
        initialValue: widget.selected,
        items: widget.auswahlList.map((e) => MultiSelectItem(e, e)).toList(),
        listType: MultiSelectListType.LIST,
        searchable: true,
        onConfirm: changeSelectToList,
        onSelectionChanged: changeSelectToList,
        buttonText: Text(widget.hintText),
        chipDisplay: MultiSelectChipDisplay(
          onTap: (value){
            widget.selected.remove(value);
            widget.onConfirm();
            return widget.selected;
          },
        ),
      ),
    );
  }
}


class CustomDropDownButton extends StatefulWidget {
  List<String> items;
  String hintText;
  String labelText;
  String selected;
  double width;
  var onChange;

  CustomDropDownButton({Key key,
    this.items,
    this.hintText = "",
    this.selected = "",
    this.labelText = "",
    this.onChange,
    this.width
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
    return Container(
      width: widget.width ?? webWidth,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.only(left: 10),
      constraints: new BoxConstraints(
        minHeight: 50.0,
        maxHeight: 70.0,
      ),
      decoration: BoxDecoration(
          border: Border.all(width: 1),
          borderRadius: const BorderRadius.all(Radius.circular(5))
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          value: widget.selected == "" ? null : widget.selected,
          hint: Text(widget.hintText, style: const TextStyle(color: Colors.grey)),
          elevation: 16,
          style: const TextStyle(color: Colors.black),
          decoration: widget.labelText != "" ? InputDecoration(
            labelText: widget.labelText,
          ) :const InputDecoration() ,
          onChanged: (newValue){

            setState(() {
              widget.selected = newValue;
            });
            if(widget.onChange != null) widget.onChange();
          },
          items: createDropdownItems(),
        ),
      ),
    );



  }
}



