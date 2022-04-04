import 'dart:ui';

import 'package:familien_suche/global/year_picker.dart';
import 'package:familien_suche/pages/events/event_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'month_picker.dart';
import 'global_functions.dart' as global_functions;

double sideSpace = 10;
double borderRounding = 5;
double boxHeight = 50;
double webWidth = 600;

Widget customTextInput(text, controller, {validator, passwort = false,
  moreLines = 1,TextInputAction textInputAction = TextInputAction.done,
  onSubmit, informationWindow}){
  return Align(
    child: Stack(
      children: [
        Container(
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
                  alignLabelWithHint: true,
                  labelText: text,
                  labelStyle: const TextStyle(fontSize: 15, color: Colors.grey),
                  //floatingLabelStyle: const TextStyle(fontSize: 15, color: Colors.blue)
                ),
                validator: validator
            ),
        ),
        if (informationWindow != null) Positioned(
            left:5,
            top: 2,
            child: Container(
              alignment: Alignment.topCenter,
              margin: EdgeInsets.only(bottom: 10),
              width: 20,
              height: 20,
              child: IconButton(
                  padding: EdgeInsets.all(0),
                  alignment: Alignment.topCenter,
                  iconSize: 20,
                  icon: Icon(Icons.info),
                  onPressed: () => informationWindow()
              ),
            )
        )
      ]
    ),
  );
}

Widget customFloatbuttonExtended(text, function){
  return Align(
    child: Container(
      width: webWidth,
      margin: EdgeInsets.only(top:sideSpace,bottom: sideSpace),
      padding: EdgeInsets.only(left: sideSpace, right:sideSpace),
      child: FloatingActionButton.extended(
        heroTag: text,
          label: Text(text),
          onPressed: function
      )
    ),
  );
}

customSnackbar(context, text, {color = Colors.red}){
  var snackbar = SnackBar(
        duration: Duration(seconds: 5),
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
                Container(
                    height: 50,
                    child: Center(child: Text(title, style: const TextStyle(color: Colors.black)))
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


class CustomDatePicker extends StatefulWidget {
  var pickedDate;
  var hintText;
  var deleteFunction;
  bool dateIsSelected;

  getPickedDate(){
    return pickedDate;
  }

  setDate(date){
    pickedDate = date;
  }

  CustomDatePicker({
    Key key,
    this.hintText,
    this.pickedDate,
    this.deleteFunction,
    this.dateIsSelected = false
  }) : super(key: key);

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {

  datePicker() async{
    return showYearPicker(
        context: context,
        firstDate: DateTime(DateTime.now().year - 18, DateTime.now().month),
        lastDate: DateTime(DateTime.now().year, DateTime.now().month),
        initialDate: DateTime.now()
    );
  }

  showDate(){
    return () async{
      widget.pickedDate = await datePicker();
      var dateList = widget.pickedDate.toString().split(" ")[0].split("-");
      String newHintText = dateList[0];

      setState(() {
        if(widget.pickedDate != null){
          widget.hintText = newHintText;
          widget.dateIsSelected = true;
        }

      });
    };
  }

  @override
  Widget build(BuildContext context) {
    
    differentText(){
      if (widget.dateIsSelected){
        return Text(widget.hintText, style: const TextStyle(fontSize: 16, color: Colors.black));
      } else{
        return Text("Year", style: const TextStyle(fontSize: 13, color: Colors.grey));
      }
    }

    return GestureDetector(
      onTap: showDate(),
      child: FractionallySizedBox(
        widthFactor: 0.25,
        child: Stack(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          children: [
            Container(
              height: boxHeight,
              margin: EdgeInsets.all(sideSpace),
              padding: EdgeInsets.only(left: sideSpace, right: sideSpace/2),
              decoration: BoxDecoration(
                  border: Border.all(width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(borderRounding))
              ),
              child: Row(
                  children: [
                    differentText(),
                    const Expanded(child: SizedBox.shrink()),
                  ]
              )
          ),
            widget.deleteFunction == null ? const SizedBox.shrink() : Positioned(
            width: 20,
            right: 1.0,
            top: -5.0,
            child: InkResponse(
              onTap: widget.deleteFunction,
              child: const CircleAvatar(
                child: Icon(Icons.close, size: 10,),
                backgroundColor: Colors.red,
              ),
            ),
          ),
        ]
        ),
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
    return Align(
      child: Container(
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
            hint: Text(widget.hintText, style: TextStyle(color: Colors.grey)),
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
      ),
    );
  }
}


class ChildrenBirthdatePickerBox extends StatefulWidget {
  List childrensBirthDatePickerList = [];
  String hintText = "Year";

  getDates({bool years = false}){
    List dates = [];

    for (var datePicker in childrensBirthDatePickerList) {
      var date = datePicker.getPickedDate();

      if(date != null) date = date.toString();

      dates.add(date);

    }

    if(years){
      dates.sort();

      List converted = [];
      for (var element in dates) {

        var dateTime = DateTime.parse(element.toString().split(" ")[0]);
        var yearsFromDateTime = DateTime.now().difference(dateTime).inDays ~/ 365;

        converted.add(yearsFromDateTime);
      }

      dates = converted;
    }

    return dates;
  }

  setSelected(childrenBirthDates){
    childrensBirthDatePickerList = [];

    childrenBirthDates.forEach((date){
      var birthDate = date.toString().split(" ")[0].split("-");
      birthDate.removeLast();

      childrensBirthDatePickerList.add(
          CustomDatePicker(
              hintText: birthDate.reversed.join("-"),
              pickedDate: date,
              dateIsSelected: true
          )
      );
    });
  }

  ChildrenBirthdatePickerBox({Key key, hintText}) : super(key: key);

  @override
  _ChildrenBirthdatePickerBoxState createState() => _ChildrenBirthdatePickerBoxState();
}

class _ChildrenBirthdatePickerBoxState extends State<ChildrenBirthdatePickerBox> {
  var childrens = 1;
  var maxChildrens = 8;

  @override
  void initState() {
    if(widget.childrensBirthDatePickerList.isEmpty){
      widget.childrensBirthDatePickerList.add(
        CustomDatePicker(hintText: widget.hintText)
      );
    }

    super.initState();
  }

  deleteFunction(){
    return (){
      setState(() {
        childrens -= 1;
        widget.childrensBirthDatePickerList.removeLast();
      });
    };
  }

  addChildrensBirthDatePickerList(childrenCount){
    if(childrenCount <=8){
      widget.childrensBirthDatePickerList.add(
          CustomDatePicker(
              hintText: widget.hintText,
              deleteFunction: deleteFunction()
          )
      );
    }
  }

  childrenAddButton(){
    return Container(
        margin: EdgeInsets.all(sideSpace),
        child: childrens < maxChildrens?
        FloatingActionButton(
          mini: true,
          heroTag: "add children",
          child: const Icon(Icons.add),
          onPressed: (){
            setState(() {
              childrens += 1;
              addChildrensBirthDatePickerList(childrens);
            });
          },
        ) :
        const SizedBox()
    );
  }

  checkAndSetDeleteFunction(){
    List dates = widget.getDates();
    List newPicker = [];

    for(var i = 0;i < widget.childrensBirthDatePickerList.length; i++){
      var hintText = dates[i] == null? widget.hintText : dates[i].toString();

      if(i == 0 || i < widget.childrensBirthDatePickerList.length -1 ){
        var date = hintText.split(" ")[0].split("-");
        date.removeLast();
        hintText = date.join("-");

        newPicker.add(
            CustomDatePicker(
                hintText: hintText.split(" ")[0].split("-")[0],
                pickedDate: dates[i],
                dateIsSelected: dates[i] != null
            )
        );
      } else{
        newPicker.add(
            CustomDatePicker(
                hintText: hintText.split(" ")[0].split("-")[0],
                pickedDate: dates[i],
                deleteFunction: deleteFunction(),
                dateIsSelected: dates[i] != null
            )
        );
      }
    }

    widget.childrensBirthDatePickerList = newPicker;
  }

  @override
  Widget build(BuildContext context) {
    checkAndSetDeleteFunction();

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: webWidth,
        child: Wrap(
          children: [
            ...widget.childrensBirthDatePickerList,
            childrenAddButton()
          ],
        ),
      ),
    );
  }
}

class WindowTopbar extends StatelessWidget {
  var title;

  WindowTopbar({Key key,this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold

                  ),
                )
            ),
          )
        ],
      ),
    );
  }
}

CustomWindow({context, title = "",List<Widget> children, double height = double.maxFinite}){

  _closeWindow(){
    Navigator.pop(context);
  }

  return showDialog(
      context: context,
      builder: (BuildContext buildContext){
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))
          ),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
              height: height,
              width: 600,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    }),
                    child: Container(
                      margin: EdgeInsets.only(left: 10, right: 10),
                      child: ListView(
                          children: [
                            WindowTopbar(title: title),
                            const SizedBox(height: 10),
                            ...children
                          ],
                      ),
                    ),
                  ),
                  Positioned(
                    height: 30,
                    right: -13,
                    top: -7,
                    child: InkResponse(
                        onTap: () => _closeWindow(),
                        child: const CircleAvatar(
                          child: Icon(Icons.close, size: 16,),
                          backgroundColor: Colors.red,
                        )
                    ),
                  ),
                ] ,
              ),
            ),

        );
      }
  );
}


