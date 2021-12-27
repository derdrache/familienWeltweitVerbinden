import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

import '../../setting_appbar.dart';
import '../../database.dart';

class ProfilChangePage extends StatefulWidget {
  State<ProfilChangePage> createState() => _ProfilChangePageState();
}

class _ProfilChangePageState extends State<ProfilChangePage>{
  int dropdownValue = 5;
  var testdropdown;
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
        print(select[i]);
        print(interessenList[1]);
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

  Widget saveButton(){
    return FloatingActionButton.extended(
      label: Text("speichern"),
      icon: Icon(Icons.save),
      onPressed: () async{
        /*
        print(nameController.text);
        print(ortController.text);
        print(interessenDBList);
        print(childAgeAuswahlList);

         */

        /*
        dbAddNewProfil(
          name: nameController.text,
          ort: ortController.text,
          interessen: interessenDBList,
          kinder: childAgeAuswahlList
        );

         */
        var docID = await dbGetProfilDocumentID("2");
        print(await dbGetProfil(docID));
        //MongoDatabase
      },
    );
  }

  Widget build(BuildContext context) {
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
    appBar: SettingAppBar("Profil bearbeiten"),
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
