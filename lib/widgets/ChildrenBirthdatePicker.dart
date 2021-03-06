import 'package:familien_suche/widgets/year_picker.dart';
import 'package:flutter/material.dart';

double sideSpace = 10;


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
  CustomDatePickerState createState() => CustomDatePickerState();
}

class CustomDatePickerState extends State<CustomDatePicker> {
  double boxHeight = 50;
  double borderRounding = 5;

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
        return const Text("Year", style: TextStyle(fontSize: 13, color: Colors.grey));
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
  double webWidth = 600;

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