import 'dart:ui';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import '../../global/custom_widgets.dart';
import '../../../global/global_functions.dart' as global_functions;
import '../../global/search_autocomplete.dart';
import '../../global/variablen.dart' as global_var;

// Wo ? Ort wählen => Adresse eingeben => neue php Datei => Adresse + Stadt + Land + Geodaten
// einmalig oder wöchentlich


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
  var iconAuswahl;
  var sprachenAuswahlBox = CustomMultiTextForm();
  var eventArtDropdown = CustomDropDownButton(
    hintText: "Eventart auswählen",
    items: const ["Privat", "Öffentlich"],
  );
  var ortTypAuswahl = CustomDropDownButton();
  var eventInterval = CustomDropDownButton(
    hintText: "Häufigkeit des Events eingeben",
    items: const ["einmalig", "wöchentlich", "monatlich"],
  );
  var ortAuswahlBox = SearchAutocomplete(googleAutocomplete: true);




  @override
  void initState() {
    sprachenAuswahlBox = CustomMultiTextForm(
      icon: Icon(Icons.arrow_downward, color: Colors.black,),
      hintText: "Sprache auswählen",
      auswahlList: isGerman ?
      global_var.sprachenListe : global_var.sprachenListeEnglisch
    );

    ortTypAuswahl = CustomDropDownButton(
      hintText: "Orttyp auswählen",
      items: const ["offline", "online"],
      onChange: () {
        setState(() {

        });
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    dateAndTimeBox(){
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: Text(eventDatum == null ? "Datum auswählen" : eventDatum),
            onPressed: () async {
              eventDatum = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 1)
              );
              setState(() {
                eventDatum = eventDatum.day.toString() + "." +
                    eventDatum.month.toString() + "." + eventDatum.year.toString();
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
      if(ortTypAuswahl.selected == "online"){
        return customTextInput("Link vom Event eingeben", eventOrtKontroller,
            validator: global_functions.checkValidatorEmpty(context)
        );
      } else if(ortTypAuswahl.selected == "offline"){
        return ortAuswahlBox;
      } else{
        return SizedBox.shrink();
      }

    }


    return Scaffold(
      appBar: customAppBar(
          title: "Event erstellen"
      ),
      body: Container(
          child: ListView(
            children: [
              customTextInput("Eventname", eventNameKontroller,
                  validator: global_functions.checkValidatorEmpty(context)
              ),
              eventArtDropdown,
              sprachenAuswahlBox,
              ortTypAuswahl,
              ortEingabeBox(),
              eventInterval,
              customTextInput(
                  "Event Beschreibung",
                  eventBeschreibungKontroller,
                  moreLines: 8
              ),
              dateAndTimeBox(),
              Container(
                margin: EdgeInsets.only(left:10, right: 10),
                child: ElevatedButton(
                  child: iconAuswahl == null ? Text("Event Icon auswählen") : iconAuswahl,
                  onPressed: () async {
                    var iconData = await FlutterIconPicker.showIconPicker(context);
                    setState(() {
                      iconAuswahl = Icon(iconData);
                    });
                  },
                ),
              )
            ],
          )
      ),
    );
  }
}


