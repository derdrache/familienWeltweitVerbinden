import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../global/custom_widgets.dart';
import '../global/global_functions.dart' as global_functions;
import '../global/variablen.dart' as global_variablen;
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
  bool selectedCity = false;
  var userNameKontroller = TextEditingController();
  var ortTextcontroller = TextEditingController();
  bool lookInMaps = false;
  var ortMapData = {};
  var sprachenAuswahlBox = CustomMultiTextForm(
    hintText: "Sprachen auswählen",
    auswahlList: global_variablen.sprachenListe,
    validator: global_functions.checkValidationMultiTextForm(),
  );
  var reiseArtenAuswahlBox = CustomDropDownButton(
      items: global_variablen.reisearten);
  var interessenAuswahlBox = CustomMultiTextForm(
    hintText: "Interessen auswählen",
    auswahlList: global_variablen.interessenListe,
      validator: global_functions.checkValidationMultiTextForm()
  );
  var childrenAgePickerBox = ChildrenBirthdatePickerBox();
  var windowSetState;


  saveFunction()async {
    if(_formKey.currentState!.validate()){
      var userExist = await ProfilDatabase()
          .getProfilId("name", userNameKontroller.text) != null;

      if(!lookInMaps){
        openSelectCityWindow();
        return;
      }

      if(checkAllValidation(userExist)){
        var userID = FirebaseAuth.instance.currentUser?.uid;
        var email = FirebaseAuth.instance.currentUser?.email;
        var userName = userNameKontroller.text;
        if(selectedCity){
          var data = {
            "email": email,
            "emailAnzeigen": false,
            "name": userName,
            "ort": ortMapData["city"], //groß und kleinschreibung?
            "interessen": interessenAuswahlBox.getSelected(),
            "kinder": childrenAgePickerBox.getDates(),
            "land": ortMapData["countryname"],
            "longt": ortMapData["longt"],
            "latt":  ortMapData["latt"],
            "reiseart": reiseArtenAuswahlBox.getSelected(),
            "aboutme": "",
            "sprachen": sprachenAuswahlBox.getSelected(),
            "friendlist": {"empty": true},
            "token": await FirebaseMessaging.instance.getToken()
          };

          ProfilDatabase().addNewProfil(userID, data);
          global_functions.changePageForever(context, StartPage(registered: true));
        } else{
          customSnackbar(context, "Stadt nicht bestätigt");
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

  addCityData(suggestedCities){
    ortMapData = {
      "city" :suggestedCities["city"],
      "countryname" : suggestedCities["countryname"],
      "longt": suggestedCities["longt"],
      "latt": suggestedCities["latt"]
    };
    ortTextcontroller.text = suggestedCities["adress"];
    selectedCity = true;

  }

  openSelectCityWindow() async{
    List<Widget> suggestedCitiesList = [];
    var suggestedCities = await LocationService()
        .getLocationMapDataGoogle2(ortTextcontroller.text);
    lookInMaps = true;

    if(suggestedCities.length == 1){
      addCityData(suggestedCities[0]);
      return;
    }

    for(var i = 0; i<suggestedCities.length; i++){
      suggestedCitiesList.add(
          GestureDetector(
            onTap: () {
              addCityData(suggestedCities[i]);
              Navigator.pop(context);
            },
            child: Container(
                margin: EdgeInsets.only(top:20, left: 10),
                child: Text(
                  suggestedCities[i]["adress"],
                  style: TextStyle(
                      fontSize: 16
                  )
                  ,)
            ),
          )
      );
    }

    return showDialog(
        context: context,
        builder: (BuildContext buildContext){
          return AlertDialog(
            content: Column(
              children: [
                Text("Bitte den genauen Standort wählen:",
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                ),
                SizedBox(height: 15,),
                ...suggestedCitiesList
              ],
            ),
          );
        }
    );
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
                child: const Icon(Icons.done, size: 35),
            )
        ]),
      );
    }

    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 30),
          child: Form(
            key: _formKey,
            child: ListView(
                children: [
                  pageTitle(),
                  customTextInput("Benutzername", userNameKontroller,
                      validator: global_functions.checkValidatorEmpty()),
                  customTextInput("Aktuelle Stadt eingeben", ortTextcontroller,
                      validator: global_functions.checkValidatorEmpty(),
                    onSubmit: () => openSelectCityWindow()

                  ),
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


