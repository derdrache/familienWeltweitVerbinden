import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../custom_widgets.dart';
import '../global_functions.dart' as globalFunctions;
import '../global/variablen.dart' as globalVariablen;
import '../locationsService.dart';
import '../database.dart';
import 'start_page.dart';

//1. Page => Ort, Reiseart, über mich
//2. Page => Geburtsdatum der Kinder , Interessen

class CreateProfilPage extends StatefulWidget {
  const CreateProfilPage({Key? key}) : super(key: key);

  @override
  _CreateProfilPageState createState() => _CreateProfilPageState();
}

class _CreateProfilPageState extends State<CreateProfilPage> {
  var nameTextcontroller = TextEditingController();
  var ortTextcontroller = TextEditingController();
  var bioTextcontroller = TextEditingController();
  var reiseartChoosen = "";
  var interessenChoosenListe = [];
  var interessenAuswahlBox;
  int childrens = 1;
  List childrensBirthDatePickerList = [CustomDatePicker(
      hintText: "Kind Geburtsdatum",
  )];



  void initState() {
    interessenAuswahlBox = CustomMultiTextForm(
      auswahlList: globalVariablen.interessenListe,
      choosenList: [],
      confirmFunction: (selected){
        interessenChoosenListe = selected;
      },
    );

    super.initState();
  }

  saveFunction()async {
    var locationData = await LocationService().getLocationMapDataGeocode(ortTextcontroller.text);
    var firebaseUser = await FirebaseAuth.instance.currentUser;

    if(checkAllValidation(locationData)){
      var data = {
        "email": firebaseUser?.email,
        "name": nameTextcontroller.text,
        "ort": locationData["city"], //groß und kleinschreibung?
        "interessen": interessenChoosenListe,
        "kinder": getChildrenData(),
        "land": locationData["countryname"],
        "longt": locationData["longt"],
        "latt":  locationData["latt"],
        "reiseart": reiseartChoosen,
        "aboutme": bioTextcontroller.text
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
    if(reiseartChoosen.isEmpty){
      errorString += "- Reiseart eingeben \n";
    }
    if(interessenChoosenListe.isEmpty){
      errorString += "- Interessen eingeben \n";
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

    reiseartInput(){
      return Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.only(left: 10, right: 10),
        decoration: BoxDecoration(
            border: Border.all(width: 1)
        ),
        child: DropdownButton<String>(
          isExpanded: true,
          value: reiseartChoosen == ""? null: reiseartChoosen,
          hint: Text("Art der Reise auswählen", style: TextStyle(color: Colors.grey)),
          elevation: 16,
          style: const TextStyle(color: Colors.deepPurple),
          onChanged: (String? newValue) {
            setState(() {
              reiseartChoosen = newValue!;
            });
          },
          items: globalVariablen.reisearten.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      );
    }

    bioInput(){
      return Container(
          child: customTextfield("Über mich (optional)",bioTextcontroller )
      );
    }

    addChildrensBirthDatePickerList(childrenCount){
      if(childrenCount <=6){
        deleteFunction(i){
          return (){
            setState(() {
              childrens -= 1;
              childrensBirthDatePickerList.removeAt(i);
            });

          };
        }

        childrensBirthDatePickerList.add(
            CustomDatePicker(
                hintText: "Kind Geburtsdatum",
                deleteFunction: deleteFunction(childrenCount-1)
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

    return Container(
      margin: EdgeInsets.only(top: 30),
        child: ListView(
            children: [
              pageTitle(),
              customTextfield("Benutzername", nameTextcontroller),
              customTextfield("Aktuelle Stadt eingeben", ortTextcontroller),
              reiseartInput(),
              interessenAuswahlBox,
              bioInput(),
              birthDateChildrenInput(),
              childrenAddAndSaveButton()
            ],
          ),
    );
  }
}

