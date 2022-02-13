import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

double sideSpace = 10;
double borderRounding = 5;
double boxHeight = 50;

Widget customTextInput(text, controller, {validator, passwort = false,
  moreLines = 1,TextInputAction textInputAction = TextInputAction.done,
  onSubmit}){
  return Container(
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
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        floatingLabelStyle: const TextStyle(fontSize: 15, color: Colors.blue)
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
        onPressed: function
    )
  );
}

customSnackbar(context, text, {color = Colors.red}){
  return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: color,
          content: Text(text)
      )
  );
}

customAppBar({title, button, elevation = 4.0}){

  button ??= const SizedBox.shrink();

  return AppBar(
    title: Text(title, style: const TextStyle(color: Colors.black)),
    backgroundColor: Colors.white,
    elevation: elevation,
    iconTheme: const IconThemeData(
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
    //widget.auswahlList.map((e) => MultiSelectItem(e, e)).toList()


    return multiSelectItems;
  }


  @override
  Widget build(BuildContext context) {
    List<MultiSelectItem> auswahlListSelectItem = _createMultiselectItems();
    var textColor = Colors.black;

    String createDropdownText(){
      String dropdownText = "";
      var textMaxLength = 30;

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

    return Container(
      margin: EdgeInsets.all(sideSpace),
      child: MultiSelectDialogField (
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
    );
  }
}


class CustomDatePicker extends StatefulWidget {
  var pickedDate;
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
    this.hintText = "Datum eingeben",
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
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 365*18)),
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

    differentText(){
      if (widget.dateIsSelected){
        return Text(widget.hintText, style: const TextStyle(fontSize: 16, color: Colors.black));
      } else{
        return Text(widget.hintText, style: const TextStyle(fontSize: 13, color: Colors.grey));
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
  String selected;

  CustomDropDownButton({Key? key,required this.items,
    this.selected = ""}) : super(key: key);


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
          hint: const Text("Art der Reise auswählen", style: TextStyle(color: Colors.grey)),
          elevation: 16,
          style: const TextStyle(color: Colors.black),
          icon: const Icon(Icons.arrow_downward, color: Colors.black,),
          onChanged: (newValue){
            setState(() {
              widget.selected = newValue!;
            });
          },
          items: createDropdownItems(),
        ),
      ),
    );
  }
}


class ChildrenBirthdatePickerBox extends StatefulWidget {
  List childrensBirthDatePickerList = [];

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
    childrenBirthDates.forEach((date){
      childrensBirthDatePickerList.add(
          CustomDatePicker(
              hintText: date.toString().split(" ")[0].split("-").reversed.join("-"),
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
  var maxChildrens = 6;


  @override
  void initState() {
    if(widget.childrensBirthDatePickerList.isEmpty){
      widget.childrensBirthDatePickerList.add(
        CustomDatePicker(hintText: "Geburtsdatum")
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
              hintText: "Geburtsdatum",
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
      var hintText = dates[i] == null? "Geburtsdatum" : dates[i].toString();

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

  @override
  Widget build(BuildContext context) {

    checkAndSetDeleteFunction();

    return Wrap(
      children: [
        ...widget.childrensBirthDatePickerList,
        childrenAddButton()
      ],
    );
  }
}

class WindowTopbar extends StatelessWidget {
  var title;

  WindowTopbar({Key? key,required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Center(
                child: Text(
                  title,
                  style: TextStyle(
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


CustomWindow({required context,required title,required List<Widget> children}){
  children.insert(0,WindowTopbar(title: title));
  children.insert(1, SizedBox(height: 10));


  _closeWindow(){
    Navigator.pop(context);
  }


  return showDialog(
      context: context,
      builder: (BuildContext buildContext){
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))
          ),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
              height: double.maxFinite,
              width: double.maxFinite,
              child: Stack(
                overflow: Overflow.visible,
                children: [
                  ListView(
                    children: children,
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


