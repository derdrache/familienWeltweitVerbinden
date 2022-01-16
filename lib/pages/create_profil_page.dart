import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../global/custom_widgets.dart';
import '../global/global_functions.dart' as globalFunctions;
import '../global/variablen.dart' as globalVariablen;
import '../services/locationsService.dart';
import '../services/database.dart';
import 'start_page.dart';

class CreateProfilPage extends StatefulWidget {
  const CreateProfilPage({Key? key}) : super(key: key);

  @override
  _CreateProfilPageState createState() => _CreateProfilPageState();
}

class _CreateProfilPageState extends State<CreateProfilPage> {
  var nameTextcontroller = TextEditingController();
  var ortTextcontroller = TextEditingController();
  var sprachenAuswahlBox = CustomMultiTextForm(
    hintText: "Sprachen auswählen",
    auswahlList: globalVariablen.sprachenListe,
  );
  var reiseArtenAuswahlBox = CustomDropDownButton(
      items: globalVariablen.reisearten);
  var interessenAuswahlBox = CustomMultiTextForm(
    hintText: "Interessen auswählen",
    auswahlList: globalVariablen.interessenListe,
  );
  int childrens = 1;
  List childrensBirthDatePickerList = [CustomDatePicker(
      hintText: "Kind Geburtsdatum",
  )];



  saveFunction()async {
    var locationData = await LocationService().getLocationMapDataGeocode(ortTextcontroller.text);
    var firebaseUser = await FirebaseAuth.instance.currentUser;

    if(checkAllValidation(locationData)){
      var data = {
        "email": firebaseUser?.email,
        "name": nameTextcontroller.text,
        "ort": locationData["city"], //groß und kleinschreibung?
        "interessen": interessenAuswahlBox.getSelected(),
        "kinder": getChildrenData(),
        "land": locationData["countryname"],
        "longt": double.parse(locationData["longt"]),
        "latt":  double.parse(locationData["latt"]),
        "reiseart": reiseArtenAuswahlBox.getSelected(),
        "aboutme": "",
        "sprachen": sprachenAuswahlBox.getSelected()
      };

      dbAddNewProfil(data);
      globalFunctions.changePage(context, StartPage());

    }
  }

  checkAllValidation(locationData){
    bool allGood = true;
    String errorString = "Bitte Eingaben korrigieren: \n";

    if(nameTextcontroller.text.isEmpty){
      errorString += "- Name eingeben \n";
    }
    if(locationData == null || locationData["city"] == ""){
      errorString += "- Stadt eingeben \n";
    }
    if(reiseArtenAuswahlBox.getSelected().isEmpty){
      errorString += "- Reiseart auswählen \n";
    }
    if(sprachenAuswahlBox.getSelected().isEmpty){
      errorString += "- Sprachen auswählen \n";
    }
    if(interessenAuswahlBox.getSelected().isEmpty){
      errorString += "- Interessen auswählen \n";
    }
    if(getChildrenData().length == 0 ||
        childrensBirthDatePickerList.length > getChildrenData().length){
      errorString += "- Geburtsdatum vom Kind eingeben \n";
    }

    if(errorString.length > 29){
      allGood = false;

      customSnackbar(context, errorString);
    }

    return allGood;
  }

  getChildrenData(){
    var childrenAgeList = [];

    childrensBirthDatePickerList.forEach((child) {
      if(child.getPickedDate() != null){
        childrenAgeList.add(child.getPickedDate());
      }
    });

    return childrenAgeList;
  }

  @override
  Widget build(BuildContext context) {


    pageTitle(){
      return Container(
        margin: EdgeInsets.all(10),
        child: Center(
          child: Text(
            "Profil erstellen",
            style: TextStyle(
                fontSize: 30
            ),
          ),
        ),
      );
    }

    addChildrensBirthDatePickerList(childrenCount){

      if(childrenCount <=6){
        deleteFunction(){
          return (){
            setState(() {
              childrens -= 1;
              childrensBirthDatePickerList.removeLast();
            });

          };
        }

        childrensBirthDatePickerList.add(
            CustomDatePicker(
                hintText: "Kind Geburtsdatum",
                deleteFunction: deleteFunction()
            )
        );
      }

    }

    birthDateChildrenInput(){

      return Container(
          child: Wrap(
              children: [...childrensBirthDatePickerList]
          )
      );
    }

    childrenAddAndSaveButton(){
      return Container(
          margin: EdgeInsets.only(top: 10),
          child: childrens < 6? Row(
            children:[
              SizedBox(width: 10),
              FloatingActionButton.extended(
                label: Text("weiteres Kind"),
                heroTag: "add children",
                onPressed: (){
                  setState(() {
                    childrens += 1;
                    addChildrensBirthDatePickerList(childrens);
                  });
                },
              ),
              Expanded(child: SizedBox()),
              SizedBox(width: 10),
              FloatingActionButton.extended(
                  label: Text("Profil speichern"),
                  onPressed: () => saveFunction()
              ),
            ] ,
          ) :
          FloatingActionButton.extended(
            label: Text("Profil speichern"),
            onPressed: () => saveFunction()
          )
      );
    }

    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 30),
          child: ListView(
              children: [
                pageTitle(),
                customTextfield("Benutzername", nameTextcontroller),
                customTextfield("Aktuelle Stadt eingeben", ortTextcontroller),
                reiseArtenAuswahlBox,
                sprachenAuswahlBox,
                interessenAuswahlBox,
                birthDateChildrenInput(),
                childrenAddAndSaveButton()
              ],
            ),
      ),
    );
  }
}

