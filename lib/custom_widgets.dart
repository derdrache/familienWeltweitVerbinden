import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

double sideSpace = 10;
double borderRounding = 10;
var buttonColor = Colors.purple;

Widget customTextForm(text, controller, {validator = null, obsure = false}){
  return Container(
    margin: EdgeInsets.only(top:sideSpace,bottom: sideSpace),
    padding: EdgeInsets.only(left: sideSpace, right:sideSpace),
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
    padding: EdgeInsets.only(left: sideSpace, right:sideSpace),
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

Widget customMultiTextForm(dropdownText, interessenList, function){
  //var color = interessenDBList.isEmpty ? Colors.grey : Colors.black;


  return Container(
    child: GFMultiSelect(
      items: interessenList,
      onSelect: function,
      dropdownTitleTileText: dropdownText,
      dropdownTitleTileColor: Colors.purple,
      dropdownTitleTileMargin: EdgeInsets.only(left: 10, right: 10),
      dropdownTitleTilePadding: EdgeInsets.all(10),
      dropdownUnderlineBorder: const BorderSide(
          color: Colors.transparent, width: 2),
      dropdownTitleTileBorder:
      Border.all(color: Colors.black, width: 1),
      dropdownTitleTileBorderRadius: BorderRadius.circular(5),
      expandedIcon: const Icon(
        Icons.keyboard_arrow_down,
        color: Colors.black54,
      ),
      collapsedIcon: const Icon(
        Icons.keyboard_arrow_up,
        color: Colors.black54,
      ),
      submitButton: Text('OK'),
      dropdownTitleTileTextStyle: TextStyle(
          fontSize: 14),
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.all(6),
      type: GFCheckboxType.basic,
      activeBgColor: Colors.green.withOpacity(0.5),
      inactiveBorderColor: Colors.grey,
    ),
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
  bool allSelected;
  var confirmFunction = (select){};

  CustomMultiTextForm({
    required this.auswahlList,
    this.allSelected = false,
  });

  @override
  _CustomMultiTextFormState createState() => _CustomMultiTextFormState();
}

class _CustomMultiTextFormState extends State<CustomMultiTextForm> {
  var interessenList = ["Freilerner", "Weltreise"];

  @override
  void initState() {
    if(widget.allSelected){
      widget.auswahlList = interessenList;
    }
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    List<MultiSelectItem> auswahlListe = interessenList.map((e) => MultiSelectItem(e, e)).toList();

    String createDropdownText(){
      String dropdownText = "";

      if (widget.auswahlList.isEmpty){
        dropdownText = "Interessen eingeben";
      } else if(widget.allSelected){
        dropdownText =  "alles";
      } else{
        dropdownText = widget.auswahlList.join(" , ");
      }

      return dropdownText;
    }

    changeSelectToList(select){
      widget.auswahlList = [];

      for(var i = 0; i< select.length; i++){
        setState(() {
          widget.auswahlList = select;
          if(interessenList.length == select.length){
            widget.allSelected = true;
          } else{
            widget.allSelected = false;
          }
        });
      }
    }


    return Padding(
      padding: EdgeInsets.all(sideSpace),
      child:MultiSelectBottomSheetField (
        initialValue: widget.auswahlList,
        buttonText: Text(createDropdownText()),
        chipDisplay: MultiSelectChipDisplay.none(),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.all(Radius.circular(borderRounding))
        ),
        items: auswahlListe,
        onSelectionChanged: changeSelectToList,
        onConfirm: widget.confirmFunction,
      )
    );
  }
}



/*
class CustomMultiTextForm extends StatefulWidget {
  List auswahlList;
  bool allSelected;
  CustomMultiTextForm({required this.auswahlList, this.allSelected = false});

  @override
  _CustomMultiTextFormState createState() => _CustomMultiTextFormState();
}

class _CustomMultiTextFormState extends State<CustomMultiTextForm> {
  List<String> interessenList = ["Freilerner", "Weltreise"];

  @override
  void initState() {
    if(widget.allSelected){
      widget.auswahlList = interessenList;
    }
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    var dropdownText = widget.auswahlList.isEmpty ?
    "Interessen eingeben": widget.auswahlList.join(" , ");


    changeSelectToList(select){
      widget.auswahlList = [];
      for(var i = 0; i< select.length; i++){
        widget.auswahlList.add(interessenList[select[i]]);
      }
    }

    return Container(
      child: GFMultiSelect(
        items: interessenList,
        onSelect: changeSelectToList,
        dropdownTitleTileText: dropdownText,
        dropdownTitleTileColor: Colors.purple,
        dropdownTitleTileMargin: EdgeInsets.only(left: 10, right: 10),
        dropdownTitleTilePadding: EdgeInsets.all(10),
        dropdownUnderlineBorder: const BorderSide(
            color: Colors.transparent, width: 2),
        dropdownTitleTileBorder:
        Border.all(color: Colors.black, width: 1),
        dropdownTitleTileBorderRadius: BorderRadius.circular(5),
        expandedIcon: const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.black54,
        ),
        collapsedIcon: const Icon(
          Icons.keyboard_arrow_up,
          color: Colors.black54,
        ),
        submitButton: Text('OK'),
        dropdownTitleTileTextStyle: TextStyle(
            fontSize: 14),
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.all(6),
        type: GFCheckboxType.basic,
        activeBgColor: Colors.green.withOpacity(0.5),
        inactiveBorderColor: Colors.grey,
      ),
    );
  }
}


 */
