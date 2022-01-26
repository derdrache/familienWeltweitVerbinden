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
  var childrenAgePickerBox = ChildrenBirthdatePickerBox();




  saveFunction()async {
    var locationData;
    while(locationData == null){
      locationData = await LocationService().getLocationMapDataGeocode(ortTextcontroller.text);
    }
    var firebaseUser = await FirebaseAuth.instance.currentUser;
    var userExist = await dbGetProfil(nameTextcontroller.text) != null;
    var email = firebaseUser?.email;
    var userName = nameTextcontroller.text;

    print(locationData);

    if(checkAllValidation(userExist, locationData)){
      var data = {
        "email": email,
        "name": userName,
        "ort": locationData["city"], //groß und kleinschreibung?
        "interessen": interessenAuswahlBox.getSelected(),
        "kinder": childrenAgePickerBox.getDates(),
        "land": locationData["countryname"],
        "longt": locationData["longt"],
        "latt":  locationData["latt"],
        "reiseart": reiseArtenAuswahlBox.getSelected(),
        "aboutme": "",
        "sprachen": sprachenAuswahlBox.getSelected(),
        "friendlist": []
      };

      dbAddNewProfil(data);
      FirebaseAuth.instance.currentUser?.updateDisplayName(userName);
      globalFunctions.changePage(context, StartPage(registered: true));

    }
  }

  childrenInputValidation(){
    bool allFilled = true;

    childrenAgePickerBox.getDates().forEach((date){
      if(date == null){
        allFilled = false;
      }
    });
    return allFilled;
  }

  checkAllValidation(userExist, locationData){
    bool allGood = true;
    String errorString = "Bitte Eingaben korrigieren: \n";

    if(nameTextcontroller.text.isEmpty){
      errorString += "- Name eingeben \n";
    } else if (userExist){
      errorString += "- Username wird schon verwendet \n";
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
    if(childrenAgePickerBox.getDates().length == 0 || !childrenInputValidation()){
      errorString += "- Geburtsdatum vom Kind eingeben \n";
    }


    if(errorString.length > 29){
      allGood = false;

      customSnackbar(context, errorString);
    }

    return allGood;
  }

  @override
  Widget build(BuildContext context) {


    pageTitle(){
      return Container(
        height: 60,
        child: Row(
          children: [
            Expanded(child: SizedBox()),
            Text(
              "Profil erstellen",
              style: TextStyle(
                  fontSize: 30
              ),
            ),
            Expanded(child: SizedBox()),
            TextButton(
                onPressed: saveFunction,
                child: Icon(Icons.done, size: 35),
            )
        ]),
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
                childrenAgePickerBox
              ],
            ),
      ),
    );
  }
}

