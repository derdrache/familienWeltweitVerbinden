import 'package:firebase_messaging/firebase_messaging.dart';
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
  var userNameKontroller = TextEditingController();
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
      var userExist = await ProfilDatabase()
          .getProfilId("name", userNameKontroller.text) != null;

      if(checkAllValidation(userExist)){
        var userID = FirebaseAuth.instance.currentUser?.uid;
        var email = FirebaseAuth.instance.currentUser?.email;
        var userName = userNameKontroller.text;
        var locationData = await LocationService()
            .getLocationMapDataGoogle(ortTextcontroller.text);
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
            "friendlist": {"empty": true},
            "token": await FirebaseMessaging.instance.getToken()
          };

          ProfilDatabase().addNewProfil(userID, data);
          globalFunctions.changePageForever(context, StartPage(registered: true));
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
    bool noError = true;
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
      noError = false;

      customSnackbar(context, errorString);
    }

    return noError;
  }

  @override
  Widget build(BuildContext context) {

    pageTitle(){
      return SizedBox(
        height: 60,
        child: Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            const Text(
              "Profil erstellen",
              style: TextStyle(
                  fontSize: 30
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
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
                  customTextInput("Benutzername", userNameKontroller,
                      validator: globalFunctions.checkValidatorEmpty()),
                  customTextInput("Aktuelle Stadt eingeben", ortTextcontroller,
                      validator: globalFunctions.checkValidatorEmpty()),
                  reiseArtenAuswahlBox,
                  sprachenAuswahlBox,
                  interessenAuswahlBox,
                  Container(
                    padding: const EdgeInsets.all(10),
                      child: const Text(
                        "Anzahl und Alter der Kinder:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                        ),
                      )
                  ),
                  childrenAgePickerBox,
                ],
              ),
          ),
      ),
    );
  }
}

