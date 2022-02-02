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
  final _formKey = GlobalKey<FormState>();
  var nameTextcontroller = TextEditingController();
  var ortTextcontroller = TextEditingController();
  var sprachenAuswahlBox = CustomMultiTextForm(
    hintText: "Sprachen auswählen",
    auswahlList: globalVariablen.sprachenListe,
    validator: globalFunctions.checkValidationMultiTextForm(),
  );
  var reiseArtenAuswahlBox = CustomDropDownButton(
      items: globalVariablen.reisearten);
  var interessenAuswahlBox = CustomMultiTextForm(
    hintText: "Interessen auswählen",
    auswahlList: globalVariablen.interessenListe,
      validator: globalFunctions.checkValidationMultiTextForm()
  );
  var childrenAgePickerBox = ChildrenBirthdatePickerBox();




  saveFunction()async {
    if(_formKey.currentState!.validate()){
      var userExist = await ProfilDatabaseKontroller()
          .getProfil(nameTextcontroller.text) != null;

      if(checkAllValidation(userExist)){
        var email = await FirebaseAuth.instance.currentUser?.email;
        var userName = nameTextcontroller.text;
        var locationData = await LocationService()
            .getLocationData(ortTextcontroller.text);
        if(locationData != null){
          var data = {
            "email": email,
            "emailAnzeigen": false,
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
            "friendlist": ["empty"]
          };

          ProfilDatabaseKontroller().addNewProfil(data);
          FirebaseAuth.instance.currentUser?.updateDisplayName(userName);
          globalFunctions.changePage(context, StartPage(registered: true));
        } else{
          customSnackbar(context, "Stadt nicht gefunden");
        }


      }
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

  checkAllValidation(userExist){
    bool allGood = true;
    String errorString = "Bitte Eingaben korrigieren: \n";

    if (userExist){
      errorString += "- Username wird schon verwendet \n";
    }
    if(reiseArtenAuswahlBox.getSelected().isEmpty){
      errorString += "- Reiseart auswählen \n";
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
          child: Form(
            key: _formKey,
            child: ListView(
                children: [
                  pageTitle(),
                  customTextInput("Benutzername", nameTextcontroller,
                      validator: globalFunctions.checkValidatorEmpty()),
                  customTextInput("Aktuelle Stadt eingeben", ortTextcontroller,
                      validator: globalFunctions.checkValidatorEmpty()),
                  reiseArtenAuswahlBox,
                  sprachenAuswahlBox,
                  interessenAuswahlBox,
                  childrenAgePickerBox,
                ],
              ),
          ),
      ),
    );
  }
}

