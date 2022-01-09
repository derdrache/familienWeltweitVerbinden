import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

import '../../custom_widgets.dart';
import '../../global_functions.dart' as globalFunctions;
import '../../database.dart';
import '../start_page.dart';
import 'locationsService.dart';


class ProfilChangePage extends StatefulWidget {
  var newProfil;

  ProfilChangePage({this.newProfil});

  State<ProfilChangePage> createState() => _ProfilChangePageState();
}

class _ProfilChangePageState extends State<ProfilChangePage>{
  int dropdownValue = 5;
  int childrenCount = 1;
  final nameController = TextEditingController();
  final ortController = TextEditingController();
  List childAgeAuswahlList = [null];
  var readDatabase = false;
  var searchMultiForm = CustomMultiTextForm(auswahlList: []);

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
            childrenCount += 1;
          });
        },
      ),
    );
  }

  void transferDataToDatabase(data) async {
    if(widget.newProfil == false){
      var docID = await dbGetProfilDocumentID("dominik.mast.11@gmail.com");
      dbChangeProfil(docID, data);

    } else {
      FirebaseAuth.instance.currentUser!.updateDisplayName(nameController.text);
      dbAddNewProfil(data);
    }
  }

  checkChangeChildrenList(){
    var newChildList = [];
    childAgeAuswahlList.forEach((child) {
      if(child != null){
        newChildList.add(child);
      }
    });

    setState(() {
      childAgeAuswahlList =newChildList;
    });
  }

  Widget saveButton(){
    return FloatingActionButton.extended(
      heroTag: "speichern",
      label: Text("speichern"),
      icon: Icon(Icons.save),
      onPressed: () async{
        var locationData = await LocationService().getLocationMapDataGoogle(ortController.text);

        if(locationData != null){
          checkChangeChildrenList();
          var data = {
            "email": FirebaseAuth.instance.currentUser!.email,
            "name": nameController.text,
            "ort": locationData["city"],
            "interessen": searchMultiForm.auswahlList,
            "kinder": childAgeAuswahlList,
            "land": locationData["countryname"],
            "longt": locationData["longt"],
            "latt":  locationData["latt"]
          };
          transferDataToDatabase(data);
          globalFunctions.changePage(context, StartPage());
        }else{
          customSnackbar(context, "Stadt nicht gefunden");
        }

      },
    );
  }

  getProfilFromDatabase() async {
    var userEmail = FirebaseAuth.instance.currentUser!.email;
    var docID = await dbGetProfilDocumentID(userEmail);
    var profil = await dbGetProfil(docID);

    return profil;
  }

  void changeTextFormHintText() async {
    if(!readDatabase){
      var userProfil = await getProfilFromDatabase();

      setState(() {
        readDatabase = true;
        nameController.text = userProfil["name"];
        ortController.text = userProfil["ort"];
        searchMultiForm = CustomMultiTextForm(auswahlList: userProfil["interessen"]);
        childAgeAuswahlList = userProfil["kinder"];
        childrenCount = userProfil["kinder"].length;

      });
    }

  }

  Widget build(BuildContext context) {
    String pageName = widget.newProfil == false? "Profil bearbeiten" : "Profil Anlegen";
    double screenWidth = MediaQuery.of(context).size.width;
    List<Widget> containerList = [
      nameContainer("Benutztername"),
      customTextfield("Benutzername eingeben", nameController),
      nameContainer("Aktuelle Stadt"),
      customTextfield("Stadt eingeben", ortController),
      nameContainer("Interessen"),
      searchMultiForm,
      nameContainer("Alter der Kinder"),
    ];

    if (!widget.newProfil){
      changeTextFormHintText();
    }

    for(var i = 0 ; i < childrenCount; i++ ) {
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
