import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

// Container Text verändert sich nicht

double sideSpace = 10;
double borderRounding = 5;
double boxHeight = 50;
var buttonColor = Colors.purple;

Widget customTextForm(text, controller, {validator = null, obsure = false}){
  return Container(
    height: boxHeight,
    margin: EdgeInsets.all(sideSpace),
    child: TextFormField(
      obscureText: obsure,
      controller: controller,
      decoration: InputDecoration(
        enabledBorder: const OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
        ),
        border: OutlineInputBorder(),
        labelText: text,
      ),
      validator: validator
    ),
  );
}


Widget customTextfield(hintText, controller){
  return Container(
    height: boxHeight,
    margin: EdgeInsets.all(sideSpace),
    child: TextField(
        controller: controller,
        decoration: InputDecoration(
            enabledBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
            ),
            border: OutlineInputBorder(),
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey)
        )
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


class CustomAppbar extends StatelessWidget with PreferredSizeWidget {
  @override
  final Size preferredSize = Size.fromHeight(50.0);
  final String title;
  var backPage;

  CustomAppbar(this.title, this.backPage);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        title: Row(
          children: [
            FloatingActionButton(
              mini: true,
              backgroundColor: buttonColor,
              child: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => backPage),
                );
              }
            ),
            Expanded(
              child: Center(
                  child: Container(
                      padding: EdgeInsets.only(right:40),
                      child: Text(
                          title,
                          style: TextStyle(
                              color: Colors.black
                          )
                      )
                  )
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey,
        elevation: 0.0
    );
  }
}


class CustomMultiTextForm extends StatefulWidget {
  List auswahlList;
  var selected;
  bool allSelected;
  String hintText;
  var onConfirm;

  getSelected(){
    return selected;
  }



  CustomMultiTextForm({
    required this.auswahlList,
    this.selected,
    this.hintText = "",
    this.allSelected = false,
    this.onConfirm
  });

  @override
  _CustomMultiTextFormState createState() => _CustomMultiTextFormState();
}

class _CustomMultiTextFormState extends State<CustomMultiTextForm> {


  @override
  void initState() {
    if(widget.allSelected){
      widget.selected = widget.auswahlList;
    }

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
      } else if(widget.allSelected){
        dropdownText =  "alles";
      } else{
        dropdownText = widget.selected.join(" , ");
      }

      return dropdownText;
    }

    changeSelectToList(select){
      widget.selected = [];

      for(var i = 0; i< select.length; i++){
        setState(() {
          widget.selected = select;
          if(widget.auswahlList.length == select.length){
            widget.allSelected = true;
          } else{
            widget.allSelected = false;
          }
        });
      }
    }


    return Container(
      height: boxHeight,
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

  getPickedDate(){
    return pickedDate;
  }

  CustomDatePicker({
    Key? key,
    required this.hintText,
    this.pickedDate,
    this.deleteFunction
  }) : super(key: key);

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  bool chosseDate = false;

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
          chosseDate = true;
        }

      });
    };
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    differentText(){
      if (chosseDate){
        return Text(widget.hintText, style: TextStyle(fontSize: 20, color: Colors.black));
      } else{
        return Text(widget.hintText, style: TextStyle(fontSize: 14, color: Colors.grey));
      }
    }

    return GestureDetector(
      onTap: showDate(),
      child: Container(
          height: boxHeight,
          width: (screenWidth / 2) - 20,
          margin: EdgeInsets.all(sideSpace),
          padding: EdgeInsets.only(left: sideSpace, right: sideSpace),
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
              widget.deleteFunction == null? SizedBox():
              SizedBox(
                width: 25,
                child: FloatingActionButton(
                  heroTag: widget.hintText,
                  backgroundColor: Colors.red,
                  mini: true,
                  child: Icon(Icons.remove),
                  onPressed: widget.deleteFunction
                ),
              )
            ]


          )
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
  var childrens;

  getDates(){
    List dates = [];
    childrensBirthDatePickerList.forEach((datePicker) {
      dates.add(datePicker.getPickedDate());
    });

    return dates;
  }

  ChildrenBirthdatePickerBox({Key? key,this.childrens = 1}) : super(key: key);

  @override
  _ChildrenBirthdatePickerBoxState createState() => _ChildrenBirthdatePickerBoxState();
}

class _ChildrenBirthdatePickerBoxState extends State<ChildrenBirthdatePickerBox> {

  deleteFunction(){
    return (){
      setState(() {
        widget.childrens -= 1;
        widget.childrensBirthDatePickerList.removeLast();
      });

    };
  }

  @override
  Widget build(BuildContext context) {

    agePickerContainer(){
      return Container(
          child: Wrap(
              children: [...widget.childrensBirthDatePickerList]
          )
      );
    }

    addChildrensBirthDatePickerList(childrenCount){

      if(childrenCount <=6){

        widget.childrensBirthDatePickerList.add(
            CustomDatePicker(
                hintText: "Kind Geburtsdatum",
                deleteFunction: deleteFunction()
            )
        );
      }

    }

    childrenAddAndSaveButton(){
      return Container(
          margin: EdgeInsets.only(top: 10),
          child: widget.childrens < 6? Row(
            children:[
              SizedBox(width: 10),
              FloatingActionButton.extended(
                label: Text("weiteres Kind"),
                heroTag: "add children",
                onPressed: (){
                  setState(() {
                    widget.childrens += 1;
                    addChildrensBirthDatePickerList(widget.childrens);
                  });
                },
              ),
              Expanded(child: SizedBox()),
              SizedBox(width: 10),
            ] ,
          ) :
          SizedBox()
      );
    }



    return Container(
      child: Column(
        children: [
          agePickerContainer(),
          childrenAddAndSaveButton()
        ],
      )
    );
  }
}
