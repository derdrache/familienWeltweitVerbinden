import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

import '../../setting_appbar.dart';

class ProfilChangePage extends StatefulWidget {
  State<ProfilChangePage> createState() => _ProfilChangePageState();
}

class _ProfilChangePageState extends State<ProfilChangePage>{
  int dropdownValue = 5;
  int children = 1;
  final nameController = TextEditingController();
  final ortController = TextEditingController();
  final interessenController = TextEditingController();
  List<String> interessenList = ["Freilerner", "Weltreise"];
  List interessenAuswahlList = [];
  List childAgeAuswahlList = [];

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
            border: OutlineInputBorder(),
            hintText: hintText,
          )
      ),
    );
  }

  Widget multiDropTest(){
    return Container(
      child: GFMultiSelect(
        items: interessenList,
        onSelect: (value) {
          interessenAuswahlList = value;
        },
        dropdownTitleTileText: 'Welche Themen interessieren dich?',
        dropdownTitleTileColor: Colors.grey[200],
        dropdownTitleTileMargin: EdgeInsets.only(
            top: 22, left: 18, right: 18, bottom: 5),
        dropdownTitleTilePadding: EdgeInsets.all(10),
        dropdownUnderlineBorder: const BorderSide(
            color: Colors.transparent, width: 2),
        dropdownTitleTileBorder:
        Border.all(color: Colors.grey, width: 1),
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
            fontSize: 14, color: Colors.black54),
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.all(6),
        type: GFCheckboxType.basic,
        activeBgColor: Colors.green.withOpacity(0.5),
        inactiveBorderColor: Colors.grey,
      ),
    );
  }

  Widget interessenDropdown(){
    return Container(
      height: 50,
      margin: EdgeInsets.only(top: 10, bottom:10),
      padding: EdgeInsets.only(left: 10, right:10),
      child: InputDecorator(
        decoration: const InputDecoration(border: OutlineInputBorder()),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: null,
            hint: Text("Welche Themen interessieren dich?"),
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.black),
            underline: Container(
              height: 2,
              color: Colors.deepPurpleAccent,
            ),
            onChanged: (String? newValue) {
              setState(() {
                interessenAuswahlList.add(newValue);
              });
            },
            items: interessenList
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
      ),
    ));
  }

  Widget ageDropdown(id){
    return Container(
      height: 50,
      margin: EdgeInsets.only(top: 10, bottom:10),
      padding: EdgeInsets.only(left: 10, right:10),
      child: InputDecorator(
        decoration: const InputDecoration(border: OutlineInputBorder()),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: childAgeAuswahlList.length == id ? null : childAgeAuswahlList[id],
            hint: Text("Wie alt ist dein Kind?"),
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.black),
            underline: Container(
              height: 2,
              color: Colors.deepPurpleAccent,
            ),
            onChanged: (int? newValue) {
              setState(() {
                if(childAgeAuswahlList.length == id){
                  childAgeAuswahlList.add(newValue);
                } else{
                  childAgeAuswahlList[id] = newValue;
                }
              });
            },
            items: <int>[0,1, 2, 3, 4, 5, 6, 7, 8, 9, 10,11,12,13,14,15,16,17]
                .map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(value.toString()),
              );
            }).toList(),
          ),
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
      onPressed: (){
        print(nameController.text);
        print(ortController.text);
        print(interessenController.text);
        print(childAgeAuswahlList);
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
      multiDropTest(),
      nameContainer("Alter der Kinder")
    ];

    for(var i = 0 ; i < children; i++ ) {
      containerList.add(ageDropdown(i));
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
