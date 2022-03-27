import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:familien_suche/pages/events/event_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../services/database.dart';
import '../../global/custom_widgets.dart';
import '../../../global/global_functions.dart' as global_functions;
import '../../global/google_autocomplete.dart';
import '../../global/variablen.dart' as global_var;
import 'event_page.dart';


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
      hintText: AppLocalizations.of(context).spracheAuswaehlen,
      auswahlList: isGerman ?
      global_var.sprachenListe : global_var.sprachenListeEnglisch
    );

    ortTypDropdown = CustomDropDownButton(
      hintText: "offline / online",
      items: global_var.eventTyp,
      onChange: () {
        setState(() {

        });
      },
    );

    eventArtDropdown = CustomDropDownButton(
      hintText: AppLocalizations.of(context).eventArten,
      items: global_var.eventArt,
    );

    super.initState();
  }

  saveEvent() async {
    var locationData = ortAuswahlBox.getGoogleLocationData();
    var uuid = Uuid();
    var allFilled = checkAllValidations(locationData);
    if(!allFilled) return;


    var date = DateTime(eventDatum.year, eventDatum.month, eventDatum.day,
        eventUhrzeit.hour, eventUhrzeit.minute);

    var eventData = {
      "id": uuid.v4(),
      "name" : eventNameKontroller.text,
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

    await EventDatabase().addNewEvent(eventData);
    global_functions.changePage(context, EventPage());
    global_functions.changePage(context, EventDetailsPage(event: eventData));
  }

  checkAllValidations(locationData){
    var validationFailText = "";

    if(eventNameKontroller.text.isEmpty){
      validationFailText = AppLocalizations.of(context).bitteNameEingeben;
    } else if(eventNameKontroller.text.length > 40){
      validationFailText = AppLocalizations.of(context).usernameZuLang;
    } else if(eventArtDropdown.getSelected().isEmpty){
      validationFailText = AppLocalizations.of(context).bitteEventArtEingeben;
    } else if(ortTypDropdown.getSelected().isEmpty){
      validationFailText = AppLocalizations.of(context).bitteEventTypEingeben;
    } else if(ortTypDropdown.getSelected() == "offline" && locationData["city"] == null){
      validationFailText = AppLocalizations.of(context).bitteStadtEingeben;
    } else if (ortTypDropdown.getSelected() == "online" && eventOrtKontroller.text.isEmpty) {
      validationFailText = AppLocalizations.of(context).bitteLinkEingeben;
    }else if(sprachenAuswahlBox.getSelected().isEmpty){
      validationFailText = AppLocalizations.of(context).bitteSpracheEingeben;
    } else if(eventDatum == null){
      validationFailText = AppLocalizations.of(context).bitteEventDatumEingeben;
    } else if(eventUhrzeit == null){
      validationFailText = AppLocalizations.of(context).bitteEventUhrzeitEingeben;
    } else if(eventBeschreibungKontroller.text.isEmpty){
      validationFailText = AppLocalizations.of(context).bitteEventBeschreibungEingeben;
    }

    if(validationFailText.isEmpty) return true;

    customSnackbar(context, validationFailText);
    return false;

  }

  @override
  Widget build(BuildContext context) {
    ortAuswahlBox.hintText = AppLocalizations.of(context).stadtEingeben;

    dateAndTimeBox(){
      var dateString = AppLocalizations.of(context).datumAuswaehlen;
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
            child: Text(eventUhrzeit == null ? AppLocalizations.of(context).uhrzeitAuswaehlen : eventUhrzeit.format(context)),
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
        return customTextInput(AppLocalizations.of(context).eventLinkEingeben, eventOrtKontroller,
            validator: global_functions.checkValidatorEmpty(context)
        );
      } else if(ortTypDropdown.selected == "offline"){
        return ortAuswahlBox;
      } else{
        return SizedBox.shrink();
      }

    }

    eventArtInformation(){
      return Positioned(
          top: -5,
          left: -5,
          child: IconButton(
            icon: Icon(Icons.help,size: 15),
            onPressed: () => CustomWindow(
                height: 500,
                context: context,
                title: AppLocalizations.of(context).informationEventArt,
                children: [
                  SizedBox(height: 10),
                  Container(
                    margin: EdgeInsets.only(left: 5, right: 5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("privat       ", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(AppLocalizations.of(context).privatInformationText,
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ]),
                  ),
                  SizedBox(height: 20),
                  Container(
                    margin: EdgeInsets.only(left: 5, right: 5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                          width: 70,
                          child: Text(AppLocalizations.of(context).halbOeffentlich,style: TextStyle(fontWeight: FontWeight.bold))
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(AppLocalizations.of(context).halbOeffentlichInformationText,
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ]),
                  ),
                  SizedBox(height: 20),
                  Container(
                    margin: EdgeInsets.only(left: 5, right: 5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(AppLocalizations.of(context).oeffentlich, style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(AppLocalizations.of(context).oeffentlichInformationText,
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  )
                ]
            ),
          )
      );
    }


    return Scaffold(
      appBar: customAppBar(
        title: AppLocalizations.of(context).eventErstellen,
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
              customTextInput("Event Name", eventNameKontroller,
                  validator: global_functions.checkValidatorEmpty(context)
              ),
              Stack(
                children: [
                  eventArtDropdown,
                  eventArtInformation()
                ],
              ),
              ortTypDropdown,
              ortEingabeBox(),
              sprachenAuswahlBox,
              dateAndTimeBox(),
              customTextInput(
                  AppLocalizations.of(context).eventBeschreibung,
                  eventBeschreibungKontroller,
                  moreLines: 8
              ),
            ],
          )
      ),
    );
  }
}


