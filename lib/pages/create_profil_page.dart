import 'dart:ui';
import 'dart:io';

import 'package:familien_suche/global/search_autocomplete.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_google_places/flutter_google_places.dart';

import '../auth/secrets.dart';
import '../global/custom_widgets.dart';
import '../global/global_functions.dart' as global_functions;
import '../global/variablen.dart' as global_variablen;
import '../services/locationsService.dart';
import '../services/database.dart';
import 'start_page.dart';

class CreateProfilPage extends StatefulWidget {


  const CreateProfilPage({Key key}) : super(key: key);

  @override
  _CreateProfilPageState createState() => _CreateProfilPageState();
}

class _CreateProfilPageState extends State<CreateProfilPage> {
  final _formKey = GlobalKey<FormState>();
  bool selectedCity = false;
  var userNameKontroller = TextEditingController();
  var ortTextcontroller = TextEditingController();
  var ortSuche = "";
  bool lookInMaps = false;
  var ortMapData = {};
  var isGerman = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";
  var sprachenAuswahlBox = CustomMultiTextForm();
  var reiseArtenAuswahlBox = CustomDropDownButton();
  var interessenAuswahlBox = CustomMultiTextForm();
  var childrenAgePickerBox = ChildrenBirthdatePickerBox();


  @override
  void initState() {
    sprachenAuswahlBox = CustomMultiTextForm(
        auswahlList: isGerman ?
        global_variablen.sprachenListe : global_variablen.sprachenListeEnglisch
    );
    reiseArtenAuswahlBox = CustomDropDownButton(
      items: isGerman ?
      global_variablen.reisearten : global_variablen.reiseartenEnglisch,
    );
    interessenAuswahlBox = CustomMultiTextForm(
        auswahlList: isGerman ?
        global_variablen.interessenListe : global_variablen.interessenListeEnglisch
    );
    super.initState();
  }


  saveFunction()async {
    var children = childrenAgePickerBox.getDates();

    if(_formKey.currentState.validate()){
      var userName = userNameKontroller.text;
      userName = userName.replaceAll("'" , "\\'");
      var userExist = await ProfilDatabase().getOneData("id", "name", userName) != false;



      if(userName.length > 40){
        customSnackbar(context, AppLocalizations.of(context).usernameZuLang);
        return;
      }

      if(!lookInMaps){
        bool exactCitiy = await openSelectCityWindow();
        if(!exactCitiy) return;
      }


      if(checkAllValidation(userExist)){
        var userID = FirebaseAuth.instance.currentUser?.uid;
        var email = FirebaseAuth.instance.currentUser?.email;

        if(selectedCity){
          var data = {
            "id": userID,
            "email": email,
            "name": userName,
            "ort": ortMapData["city"], //groß und kleinschreibung?
            "interessen": interessenAuswahlBox.getSelected(),
            "kinder": children,
            "land": ortMapData["countryname"],
            "longt": ortMapData["longt"],
            "latt":  ortMapData["latt"],
            "reiseart": reiseArtenAuswahlBox.getSelected(),
            "sprachen": sprachenAuswahlBox.getSelected(),
            "token": !kIsWeb? await  FirebaseMessaging.instance.getToken(): null,
          };

          ProfilDatabase().addNewProfil(data);
          global_functions.changePageForever(context, StartPage(registered: true));
        } else{
          customSnackbar(context, AppLocalizations.of(context).ortNichtBestaetigt);
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
    String errorString = AppLocalizations.of(context).bitteEingabeKorrigieren +  "\n";

    if (userExist){
      errorString += "- "+ AppLocalizations.of(context).usernameInVerwendung +"\n";
    }
    if(reiseArtenAuswahlBox.getSelected().isEmpty){
      errorString += "- "+ AppLocalizations.of(context).reiseartAuswaehlen +"\n";
    }
    if(childrenAgePickerBox.getDates().length == 0 || !childrenInputValidation()){
      errorString += "- " + AppLocalizations.of(context).geburtsdatumEingeben + "\n";
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
      "latt": suggestedCities["latt"],
      "error": suggestedCities["error"] // web workaround
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
      return true;
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
                Text(AppLocalizations.of(context).genauenStandortWaehlen + ": ",
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
    sprachenAuswahlBox.validator = global_functions.checkValidationMultiTextForm(context);
    sprachenAuswahlBox.hintText = AppLocalizations.of(context).spracheAuswaehlen;
    interessenAuswahlBox.validator = global_functions.checkValidationMultiTextForm(context);
    interessenAuswahlBox.hintText = AppLocalizations.of(context).interessenAuswaehlen;
    reiseArtenAuswahlBox.hintText = AppLocalizations.of(context).artDerReiseAuswaehlen;
    childrenAgePickerBox.hintText = AppLocalizations.of(context).geburtsdatum;

    pageTitle(){
      return Align(
        child: SizedBox(
          height: 60,
          width: 600,
          child: Row(
            children: [
              const Expanded(child: SizedBox.shrink()),
              Text(
                AppLocalizations.of(context).profilErstellen,
                style: const TextStyle(
                    fontSize: 30
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
              TextButton(
                  onPressed: saveFunction,
                  child: const Icon(Icons.done, size: 35),
              )
          ]),
        ),
      );
    }

    openInfoWindow(text){
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Information"),
            content: Text(text),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }


    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 30),
          child: Form(
            key: _formKey,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              }),
              child: ListView(
                    children: [
                      pageTitle(),
                      customTextInput(AppLocalizations.of(context).benutzername, userNameKontroller,
                          validator: global_functions.checkValidatorEmpty(context)),
                      SearchAutocomplete(),


                      /*
                      customTextInput(AppLocalizations.of(context).ortEingeben, ortTextcontroller,
                          validator: global_functions.checkValidatorEmpty(context),
                        onSubmit: () => openSelectCityWindow(),
                        informationWindow: () => openInfoWindow(AppLocalizations.of(context).ortEingabeInformation)
                      ),

                       */
                      reiseArtenAuswahlBox,
                      sprachenAuswahlBox,
                      interessenAuswahlBox,
                      Align(
                        child: Container(
                          width: 600,
                          padding: const EdgeInsets.all(10),
                            child: Text(
                              AppLocalizations.of(context).anzahlUndAlterKinder,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                              ),
                            )
                        ),
                      ),
                      childrenAgePickerBox,
                    ],
                  ),
            ),
            ),
          ),
    );
  }
}


