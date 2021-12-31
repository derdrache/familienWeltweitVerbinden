import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

import '../../custom_widgets.dart';
import '../../database.dart';
import '../start_page.dart';

class ProfilChangePage extends StatefulWidget {
  var newProfil;

  ProfilChangePage({this.newProfil});

  State<ProfilChangePage> createState() => _ProfilChangePageState();
}

class _ProfilChangePageState extends State<ProfilChangePage>{
  int dropdownValue = 5;
  int children = 1;
  final nameController = TextEditingController();
  final ortController = TextEditingController();
  List<String> interessenList = ["Freilerner", "Weltreise"];
  List interessenDBList = [];
  List childAgeAuswahlList = [null];



  Widget nameContainer(title){
    return Container(
        margin: EdgeInsets.only(top: 15, bottom: 15),
        child:Center(
            child:Text(
                title,
                style: TextStyle(fontSize: 21)
            )
        )
    );
  }

  Widget customTextfield(hintText, controller){
    return Container(
      padding: EdgeInsets.only(left: 10, right:10),
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

  Widget interessenDropdown(){

    changeSelectToList(select){
      interessenDBList = [];
      for(var i = 0; i< select.length; i++){
        interessenDBList.add(interessenList[select[i]]);
      }
    }

    return Container(
      child: GFMultiSelect(
        items: interessenList,
        onSelect: (value) {
          changeSelectToList(value);
        },
        dropdownTitleTileText: 'Welche Themen interessieren dich?',
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
        dropdownTitleTileTextStyle: const TextStyle(
            fontSize: 14, color: Colors.grey),
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.all(6),
        type: GFCheckboxType.basic,
        activeBgColor: Colors.green.withOpacity(0.5),
        inactiveBorderColor: Colors.grey,
      ),
    );
  }

  Widget ageDropdownButton(id) {
    return Container(
      height: 50,
      margin: EdgeInsets.all(10),
      child: DropdownButtonHideUnderline(
        child: GFDropdown(
          padding: const EdgeInsets.all(15),
          borderRadius: BorderRadius.circular(5),
          border: const BorderSide(
              color: Colors.black, width: 1),
          dropdownButtonColor: Colors.purple,
          icon: const Icon(Icons.keyboard_arrow_down),
          iconEnabledColor: Colors.black54,
          hint: Text(
              "Alter der Kinder ?",
              style: TextStyle(color: Colors.grey)
          ),
          style: const TextStyle(color: Colors.black, fontSize: 14,),
          value: childAgeAuswahlList.length == id
              ? null
              : childAgeAuswahlList[id],
          onChanged: (newValue) {
            setState(() {
              if (childAgeAuswahlList.length == id) {
                childAgeAuswahlList.add(newValue);
              } else {
                childAgeAuswahlList[id] = newValue;
              }
            });
          },
          items: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
              .map((value) =>
              DropdownMenuItem(
                value: value,
                child: Text(value.toString()),
              ))
              .toList(),
        ),
      ),
    );
  }

  Widget newDropdownButton(){
    return Container(
      margin: EdgeInsets.only(right: 20, bottom: 10),
      child: FloatingActionButton(
        heroTag: 1,
        mini: true,
        child: Icon(Icons.add),
        onPressed: (){
          setState((){
            childAgeAuswahlList.add(null);
            children += 1;
          });
        },
      ),
    );
  }

  void transferDataToDatabase() async {
    var data = {
    "name": nameController.text,
    "ort": ortController.text,
    "interessen": interessenDBList,
    "kinder": childAgeAuswahlList
    };

    if(widget.newProfil == false){
      var docID = await dbGetProfilDocumentID("dominik.mast.11@gmail.com");
      dbChangeProfil(docID, data);

    } else {
      dbAddNewProfil(data);
      FirebaseAuth.instance.currentUser!.updateDisplayName(nameController.text);
    }
  }

  Widget saveButton(){
    return FloatingActionButton.extended(
      heroTag: "speichern",
      label: Text("speichern"),
      icon: Icon(Icons.save),
      onPressed: () {
        transferDataToDatabase();
        //change Page
      },
    );
  }

  Widget build(BuildContext context) {
    String pageName = widget.newProfil == false? "Profil bearbeiten" : "Profil Anlegen";
    double screenWidth = MediaQuery.of(context).size.width;
    List<Widget> containerList = [
      nameContainer("Benutztername"),
      customTextfield('Placeholder - alter Name', nameController),
      nameContainer("Ort"),
      customTextfield('Placeholder - alter Ort', ortController),
      nameContainer("Interessen"),
      interessenDropdown(),
      nameContainer("Alter der Kinder"),
    ];

    for(var i = 0 ; i < children; i++ ) {
      containerList.add(ageDropdownButton(i));
    }
    containerList.add(newDropdownButton());
    containerList.add(saveButton());

    return Scaffold(
        appBar: widget.newProfil == false ? CustomAppbar(pageName, StartPage(selectedIndex: 4)): null,
        body: Container(
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.all(Radius.circular(10))
              ),
              width: screenWidth,
              child: ListView(
                  children: containerList
              )
          )
    );
  }
}
