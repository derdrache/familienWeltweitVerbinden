import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/database.dart';
import '../../global/custom_widgets.dart';
import '../../../global/global_functions.dart' as global_functions;
import '../../global/google_autocomplete.dart';
import '../../global/variablen.dart' as global_var;


class EventErstellen extends StatefulWidget {
  const EventErstellen({Key key}) : super(key: key);

  @override
  _EventErstellenState createState() => _EventErstellenState();
}

class _EventErstellenState extends State<EventErstellen> {
  var isGerman = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";
  var eventNameKontroller = TextEditingController();
  var eventDatum;
  var eventUhrzeit;
  var eventBeschreibungKontroller = TextEditingController();
  var eventOrtKontroller = TextEditingController();
  var sprachenAuswahlBox = CustomMultiTextForm();
  var eventArtDropdown = CustomDropDownButton();
  var ortTypDropdown = CustomDropDownButton();
  var ortAuswahlBox = GoogleAutoComplete();



  @override
  void initState() {
    sprachenAuswahlBox = CustomMultiTextForm(
      icon: Icon(Icons.arrow_downward, color: Colors.black,),
      hintText: "Sprache auswählen",
      auswahlList: isGerman ?
      global_var.sprachenListe : global_var.sprachenListeEnglisch
    );

    ortTypDropdown = CustomDropDownButton(
      hintText: "Offline oder Online Event ?",
      items: global_var.eventTyp,
      onChange: () {
        setState(() {

        });
      },
    );

    eventArtDropdown = CustomDropDownButton(
      hintText: "Öffentliches oder Privates Event ?",
      items: global_var.eventArt,
    );

    super.initState();
  }

  saveEvent(){
    var locationData = ortAuswahlBox.getGoogleLocationData();
    var allFilled = checkAllValidations(locationData);
    if(!allFilled) return;


    var date = DateTime(eventDatum.year, eventDatum.month, eventDatum.day,
        eventUhrzeit.hour, eventUhrzeit.minute);

    var eventData = {
      "name" : eventNameKontroller.text, //maximal 20 zeichen, dann ...
      "erstelltAm": DateTime.now().toString(),
      "erstelltVon": FirebaseAuth.instance.currentUser.uid,
      "beschreibung": eventBeschreibungKontroller.text,
      "stadt": locationData["city"],
      "art": eventArtDropdown.getSelected(),
      "wann" : date.toString(),
      "typ": ortTypDropdown.getSelected(),
      "sprache": json.encode(sprachenAuswahlBox.getSelected())   ,
      "link": ortTypDropdown.getSelected() == "online" ? eventOrtKontroller.text : "",
      "land": locationData["countryname"],
      "longt": locationData["longt"],
      "latt": locationData["latt"],
    };

    EventDatabase().addNewEvent(eventData);
    // in die Event Detail ansicht
  }

  checkAllValidations(locationData){
    var validationFailText = "";

    if(eventNameKontroller.text.isEmpty){
      validationFailText = "Bitte einen Namen eingeben";
    } else if(eventArtDropdown.getSelected().isEmpty){
      validationFailText = "Bitte wählen ob privates oder öffentliches Event";
    } else if(ortTypDropdown.getSelected().isEmpty){
      validationFailText = "Bitte wählen: offline oder Online Event";
    } else if(ortTypDropdown.getSelected() == "offline" && locationData["city"] == null){
      validationFailText = "Bitte Stadt eingeben";
    } else if (ortTypDropdown.getSelected() == "online" && eventOrtKontroller.text.isEmpty) {
      validationFailText = "Bitte Link zum Event eingeben";
    }else if(sprachenAuswahlBox.getSelected().isEmpty){
      validationFailText = "Bitte Sprache auswählen";
    } else if(eventDatum == null){
      validationFailText = "Bitte Datum des Events eingeben";
    } else if(eventUhrzeit == null){
      validationFailText = "Bitte Uhrzeit des Events eingeben";
    } else if(eventBeschreibungKontroller.text.isEmpty){
      validationFailText = "Bitte Beschreibung zum Event eingeben";
    }

    if(validationFailText.isEmpty) return true;

    customSnackbar(context, validationFailText);
    return false;

  }

  @override
  Widget build(BuildContext context) {
    ortAuswahlBox.hintText = AppLocalizations.of(context).stadtEingeben;

    dateAndTimeBox(){
      var dateString = "Datum auswählen";
      if(eventDatum != null){
        var dateFormat = DateFormat('dd-MM-yyyy');
        var dateTime = DateTime(eventDatum.year, eventDatum.month, eventDatum.day);
        dateString = dateFormat.format(dateTime);
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: Text(dateString),
            onPressed: () async {
              eventDatum = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 1)
              );

              setState(() {
              });
            },
          ),
          SizedBox(width: 20),
          ElevatedButton(
            child: Text(eventUhrzeit == null ? "Uhrzeit auswählen" : eventUhrzeit.format(context)),
            onPressed: () async {
              eventUhrzeit = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: 12, minute: 00),
              );
              setState(() {
              });
            },
          )
        ],
      );
    }

    ortEingabeBox(){
      if(ortTypDropdown.selected == "online"){
        return customTextInput("Link vom Event eingeben", eventOrtKontroller,
            validator: global_functions.checkValidatorEmpty(context)
        );
      } else if(ortTypDropdown.selected == "offline"){
        return ortAuswahlBox;
      } else{
        return SizedBox.shrink();
      }

    }


    return Scaffold(
      appBar: customAppBar(
        title: "Event erstellen",
        buttons: [
          IconButton(
              onPressed: () => saveEvent(),
              icon: Icon(Icons.done, color: Colors.green)
          )
        ]
      ),
      body: Container(
          child: ListView(
            children: [
              customTextInput("Eventname", eventNameKontroller,
                  validator: global_functions.checkValidatorEmpty(context)
              ),
              eventArtDropdown,
              ortTypDropdown,
              ortEingabeBox(),
              sprachenAuswahlBox,
              dateAndTimeBox(),
              customTextInput(
                  "Event Beschreibung",
                  eventBeschreibungKontroller,
                  moreLines: 8
              ),
            ],
          )
      ),
    );
  }
}


