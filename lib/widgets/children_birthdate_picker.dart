import 'package:flutter/material.dart';

import '../widgets/flexible_date_picker.dart';

double sideSpace = 10;


class ChildrenBirthdatePickerBox extends StatefulWidget {
  List childrensBirthDatePickerList = [];
  EdgeInsets? margin;

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
          _CustomDatePicker(
              datePicker: FlexibleDatePicker(
                startYear: DateTime.now().year-18,
                endYear: DateTime.now().year,
                selectedDate: date,
              ),
              dateIsSelected: true
          )
      );
    });
  }

  ChildrenBirthdatePickerBox({Key? key, this.margin}) : super(key: key);

  @override
  State<ChildrenBirthdatePickerBox> createState() => _ChildrenBirthdatePickerBoxState();
}

class _ChildrenBirthdatePickerBoxState extends State<ChildrenBirthdatePickerBox> {
  int childrens = 1;
  int maxChildrens = 8;
  double webWidth = 600;

  @override
  void initState() {
    if(widget.childrensBirthDatePickerList.isEmpty){
      widget.childrensBirthDatePickerList.add(
          const _CustomDatePicker()
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
          _CustomDatePicker(
              deleteFunction: deleteFunction()
          )
      );
    }
  }

  childrenAddButton(){
    return Container(
        margin: widget.margin ?? EdgeInsets.all(sideSpace),
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
      var hintText = dates[i] == null? "Year" : dates[i].toString();

      if(i == 0 || i < widget.childrensBirthDatePickerList.length -1 ){
        var date = hintText.split(" ")[0].split("-");
        date.removeLast();
        hintText = date.join("-");

        newPicker.add(
            _CustomDatePicker(
                datePicker: FlexibleDatePicker(
                  startYear: DateTime.now().year-18,
                  endYear: DateTime.now().year,
                  selectedDate: dates[i] == null ? null :DateTime.parse(dates[i]),
                ),
                dateIsSelected: dates[i] != null
            )
        );
      } else{
        newPicker.add(
            _CustomDatePicker(
                datePicker: FlexibleDatePicker(
                  startYear: DateTime.now().year-18,
                  endYear: DateTime.now().year,
                  selectedDate: dates[i] == null ? null : DateTime.parse(dates[i]),
                ),
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
      child: SizedBox(
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

class _CustomDatePicker extends StatefulWidget {
  final Function()? deleteFunction;
  final bool dateIsSelected;
  final FlexibleDatePicker? datePicker;

  getPickedDate(){
    if(datePicker == null) return;

    return datePicker!.getDate();
  }

  const _CustomDatePicker({
    Key? key,
    this.datePicker,
    this.deleteFunction,
    this.dateIsSelected = false,
  }) : super(key: key);

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<_CustomDatePicker> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.25,
      child: Stack(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: widget.datePicker,
          ),
          widget.deleteFunction == null ? const SizedBox.shrink() : Positioned(
            width: 20,
            right: 10.0,
            top: -5.0,
            child: InkResponse(
              onTap: widget.deleteFunction,
              child: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 10,),
              ),
            ),
          )
        ],
      ),
    );

  }
}