import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

double sideSpace = 10;
double borderRounding = 5;
double boxHeight = 50;
var buttonColor = Colors.purple;

Widget customTextInput(text, controller, {validator = null, passwort = false}){
  return Container(
    height: boxHeight,
    margin: EdgeInsets.all(sideSpace),
    child: TextFormField(
      obscureText: passwort,
      controller: controller,
      decoration: InputDecoration(
        isDense: true,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
        border: OutlineInputBorder(),
        labelText: text,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey),
        floatingLabelStyle: TextStyle(fontSize: 15, color: Colors.blue)
      ),
      validator: validator
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

customSnackbar(context, text){
  return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(text)
      )
  );
}

customAppBar({title, button, elevation = 4.0}){
  if(button == null){ button = Container();}
  return AppBar(
    title: Center(child: Text(title, style: TextStyle(color: Colors.black),)),
    backgroundColor: Colors.white,
    elevation: elevation,
    iconTheme: IconThemeData(
      color: Colors.black
    ),
    actions: [
      button
    ],
  );
}

class CustomMultiTextForm extends StatefulWidget {
  List auswahlList;
  var selected;
  String hintText;
  var onConfirm;
  var validator;

  getSelected(){
    return selected;
  }



  CustomMultiTextForm({
    required this.auswahlList,
    this.selected,
    this.hintText = "",
    this.onConfirm,
    this.validator = null
  });

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



  @override
  Widget build(BuildContext context) {
    List<MultiSelectItem> auswahlListSelectItem = widget.auswahlList.map((e) => MultiSelectItem(e, e)).toList();
    var textColor = Colors.black;

    String createDropdownText(){
      String dropdownText = "";

      if (widget.selected.isEmpty){
        dropdownText = widget.hintText;
        textColor = Colors.grey;
      } else{
        dropdownText = widget.selected.join(" , ");
      }

      if (dropdownText.length > 50){
        dropdownText = dropdownText.substring(0,47) + "...";
      }

      return dropdownText;
    }

    changeSelectToList(select){
      widget.selected = [];

      for(var i = 0; i< select.length; i++){
        setState(() {
          widget.selected = select;
        });
      }
    }


    return Container(
      margin: EdgeInsets.all(sideSpace),
      child: MultiSelectDialogField (
          initialValue: widget.selected,
          buttonText: Text(
            createDropdownText(),
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
    );
  }
}


class CustomDatePicker extends StatefulWidget {
  DateTime? pickedDate;
  String hintText;
  var deleteFunction;
  bool dateIsSelected;

  getPickedDate(){
    return pickedDate;
  }

  setDate(date){
    pickedDate = date;
  }

  CustomDatePicker({
    Key? key,
    required this.hintText,
    this.pickedDate,
    this.deleteFunction,
    this.dateIsSelected = false
  }) : super(key: key);

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {


  datePicker() async{
    return await showDatePicker(
        context: context,
        initialDate: DateTime.now().subtract(Duration(days: 365*9)),
        firstDate: DateTime.now().subtract(Duration(days: 365*18)),
        lastDate: DateTime.now()
    );
  }

  showDate(){
    return () async{
      widget.pickedDate = await datePicker();
      String newHintText = widget.pickedDate.toString().split(" ")[0].split("-").reversed.join("-");
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
    var _deleteFunction = widget.deleteFunction;

    differentText(){
      if (widget.dateIsSelected){
        return Text(widget.hintText, style: TextStyle(fontSize: 16, color: Colors.black));
      } else{
        return Text(widget.hintText, style: TextStyle(fontSize: 13, color: Colors.grey));
      }
    }

    return GestureDetector(
      onTap: showDate(),
      child: FractionallySizedBox(
        widthFactor: 0.5,
        child: Stack(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          children: [
            Container(
              height: boxHeight,
              margin: EdgeInsets.all(sideSpace),
              padding: EdgeInsets.only(left: sideSpace/2, right: sideSpace/2),
              decoration: BoxDecoration(
                  border: Border.all(width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(borderRounding))
              ),
              child: Row(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: differentText(),
                    ),
                    Expanded(child: SizedBox()),
                  ]
              )
          ),
          _deleteFunction == null? SizedBox():Positioned(
            width: 20,
            right: 1.0,
            top: -5.0,
            child: InkResponse(
              onTap: _deleteFunction,
              child: CircleAvatar(
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
  String selected;

  getSelected(){
    return selected;
  }

  CustomDropDownButton({Key? key,required this.items,
    this.selected = ""}) : super(key: key);

  @override
  _CustomDropDownButtonState createState() => _CustomDropDownButtonState();
}

class _CustomDropDownButtonState extends State<CustomDropDownButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
          border: Border.all(width: 1),
          borderRadius: BorderRadius.all(Radius.circular(5))
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: widget.selected == ""? null: widget.selected,
          hint: Text("Art der Reise auswählen", style: TextStyle(color: Colors.grey)),
          elevation: 16,
          style: const TextStyle(color: Colors.black),
          icon: Icon(Icons.arrow_downward, color: Colors.black,),
          onChanged: (newValue){
            setState(() {
              widget.selected = newValue!;
            });

          },
          items: widget.items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
}


class ChildrenBirthdatePickerBox extends StatefulWidget {
  List childrensBirthDatePickerList = [];

  getDates({bool years = false}){
    List dates = [];
/*
    if (childrensBirthDatePickerList.length == 0 && childrenBirthDates != null){
      dates = childrenBirthDates;
    }

 */

    childrensBirthDatePickerList.forEach((datePicker) {
      dates.add(datePicker.getPickedDate());
    });



    if(years){
      dates.sort();

      List converted = [];
      dates.forEach((element) {
        String dateTimeString = element.toString();

        var dateTime = DateTime.parse(dateTimeString.split(" ")[0]);
        dateTimeString = dateTimeString.split(" ")[0].toString();

        var yearsFromDateTime = DateTime.now().difference(dateTime).inDays ~/ 365;

        converted.add(yearsFromDateTime);
      });

      dates = converted;
    }

    return dates;
  }

  setSelected(childrenBirthDates){
    childrenBirthDates.forEach((date){
      childrensBirthDatePickerList.add(
          CustomDatePicker(
              hintText: date.toString().split(" ")[0].split("-").reversed.join("-"),
              //deleteFunction: deleteFunction(),
              pickedDate: date,
              dateIsSelected: true
          )
      );
    });
  }

  ChildrenBirthdatePickerBox({Key? key}) : super(key: key);

  @override
  _ChildrenBirthdatePickerBoxState createState() => _ChildrenBirthdatePickerBoxState();
}

class _ChildrenBirthdatePickerBoxState extends State<ChildrenBirthdatePickerBox> {
  var childrens = 1;


  @override
  void initState() {
    if(widget.childrensBirthDatePickerList.length == 0){
      widget.childrensBirthDatePickerList.add(CustomDatePicker(
        hintText: "Datum")
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


  @override
  Widget build(BuildContext context) {

    addChildrensBirthDatePickerList(childrenCount){

      if(childrenCount <=8){
        widget.childrensBirthDatePickerList.add(
            CustomDatePicker(
                hintText: "Datum",
                deleteFunction: deleteFunction()
            )
        );
      }

    }

    childrenAddButton(){
      return Container(
        margin: EdgeInsets.all(sideSpace),
          child: childrens < 8?
              FloatingActionButton(
                mini: true,
                heroTag: "add children",
                child: Icon(Icons.add),
                onPressed: (){
                  setState(() {
                    childrens += 1;
                    addChildrensBirthDatePickerList(childrens);
                  });
                },
              ) :
          SizedBox()
      );
    }

    checkAndSetDeleteFunction(){
      List dates = widget.getDates();
      List newPicker = [];

      for(var i = 0;i < widget.childrensBirthDatePickerList.length; i++){
        var hintText = dates[i] == null? "Datum" : dates[i].toString();

        if(i == 0 || i < widget.childrensBirthDatePickerList.length -1 ){

          newPicker.add(
              CustomDatePicker(
                  hintText: hintText.split(" ")[0].split("-").reversed.join("-"),
                  pickedDate: dates[i],
                  dateIsSelected: dates[i] != null
              )
          );
        } else{
          newPicker.add(
              CustomDatePicker(
                  hintText: hintText.split(" ")[0].split("-").reversed.join("-"),
                  pickedDate: dates[i],
                  deleteFunction: deleteFunction(),
                  dateIsSelected: dates[i] != null
              )
          );
        }
      }

      widget.childrensBirthDatePickerList = newPicker;
    }

    checkAndSetDeleteFunction();

    return Container(
      child: Wrap(
        children: [
          ...widget.childrensBirthDatePickerList,
          childrenAddButton()
        ],
      )
    );
  }
}
