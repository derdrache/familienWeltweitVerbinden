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
  List choosenList;
  bool allSelected;
  var confirmFunction;
  String hintText;


  CustomMultiTextForm({
    required this.auswahlList,
    required this.choosenList,
    required this.hintText,
    this.allSelected = false,
    this.confirmFunction
  });

  @override
  _CustomMultiTextFormState createState() => _CustomMultiTextFormState();
}

class _CustomMultiTextFormState extends State<CustomMultiTextForm> {

  @override
  void initState() {
    if(widget.allSelected){
      widget.choosenList = widget.auswahlList;
    }
    super.initState();

    if (widget.confirmFunction == null){
      widget.confirmFunction = (list){};
    }
  }



  @override
  Widget build(BuildContext context) {
    List<MultiSelectItem> auswahlListSelectItem = widget.auswahlList.map((e) => MultiSelectItem(e, e)).toList();
    var textColor = Colors.black;

    String createDropdownText(){
      String dropdownText = "";

      if (widget.choosenList.isEmpty){
        dropdownText = widget.hintText;
        textColor = Colors.grey;
      } else if(widget.allSelected){
        dropdownText =  "alles";
      } else{
        dropdownText = widget.choosenList.join(" , ");
      }

      return dropdownText;
    }

    changeSelectToList(select){
      widget.choosenList = [];

      for(var i = 0; i< select.length; i++){
        setState(() {
          widget.choosenList = select;
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
          initialValue: widget.choosenList,
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
          onConfirm: widget.confirmFunction,
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

