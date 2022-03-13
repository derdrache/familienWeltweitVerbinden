import 'dart:ui';
import 'dart:io';

import 'package:familien_suche/global/search_autocomplete.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/custom_widgets.dart';
import '../global/global_functions.dart' as global_functions;
import '../global/variablen.dart' as global_variablen;
import '../services/database.dart';
import 'start_page.dart';

class CreateProfilPage extends StatefulWidget {


  const CreateProfilPage({Key key}) : super(key: key);

  @override
  _CreateProfilPageState createState() => _CreateProfilPageState();
}

class _CreateProfilPageState extends State<CreateProfilPage> {
  final _formKey = GlobalKey<FormState>();
  var userNameKontroller = TextEditingController();
  var ortAuswahlBox = SearchAutocomplete(googleAutocomplete: true);
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

    ortMapData = ortAuswahlBox.getGoogleLocationData();

    if(_formKey.currentState.validate()){
      var userName = userNameKontroller.text;
      userName = userName.replaceAll("'" , "\\'");
      var userExist = await ProfilDatabase().getOneData("id", "name", userName) != false;


      if(userName.length > 40){
        customSnackbar(context, AppLocalizations.of(context).usernameZuLang);
        return;
      }

      if(checkAllValidation(userExist)){
        var userID = FirebaseAuth.instance.currentUser?.uid;
        var email = FirebaseAuth.instance.currentUser?.email;

        if(ortMapData != null){
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


  @override
  Widget build(BuildContext context) {
    sprachenAuswahlBox.validator = global_functions.checkValidationMultiTextForm(context);
    sprachenAuswahlBox.hintText = AppLocalizations.of(context).spracheAuswaehlen;
    interessenAuswahlBox.validator = global_functions.checkValidationMultiTextForm(context);
    interessenAuswahlBox.hintText = AppLocalizations.of(context).interessenAuswaehlen;
    reiseArtenAuswahlBox.hintText = AppLocalizations.of(context).artDerReiseAuswaehlen;
    childrenAgePickerBox.hintText = AppLocalizations.of(context).geburtsdatum;
    ortAuswahlBox.hintText = AppLocalizations.of(context).ortEingeben ;

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
                      Align(child: ortAuswahlBox),
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


