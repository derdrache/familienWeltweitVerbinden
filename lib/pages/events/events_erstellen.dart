import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:familien_suche/pages/events/event_details.dart';
import 'package:familien_suche/pages/start_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../services/database.dart';
import '../../global/custom_widgets.dart';
import '../../../global/global_functions.dart' as global_functions;
import '../../widgets/dialogWindow.dart';
import '../../widgets/google_autocomplete.dart';
import '../../global/variablen.dart' as global_var;


class EventErstellen extends StatefulWidget {
  const EventErstellen({Key key}) : super(key: key);

  @override
  _EventErstellenState createState() => _EventErstellenState();
}

class _EventErstellenState extends State<EventErstellen> {
  var isGerman = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";
  var eventNameKontroller = TextEditingController();
  var eventWannDatum;
  var eventBisDatum;
  var eventWannUhrzeit;
  var eventBisUhrzeit;
  var eventBeschreibungKontroller = TextEditingController();
  var eventOrtKontroller = TextEditingController();
  var sprachenAuswahlBox = CustomMultiTextForm();
  var eventArtDropdown = CustomDropDownButton();
  var ortTypDropdown = CustomDropDownButton();
  var ortAuswahlBox = GoogleAutoComplete();
  var eventIntervalDropdown = CustomDropDownButton();



  @override
  void initState() {
    sprachenAuswahlBox = CustomMultiTextForm(
      icon: const Icon(Icons.arrow_downward, color: Colors.black,),
      auswahlList: isGerman ?
      global_var.sprachenListe : global_var.sprachenListeEnglisch
    );

    ortTypDropdown = CustomDropDownButton(
      selected: "offline",
      hintText: "offline / online",
      items: isGerman ? global_var.eventTyp : global_var.eventTypEnglisch,
      onChange: () {
        setState(() {

        });
      },
    );

    eventArtDropdown = CustomDropDownButton(
      items: isGerman ? global_var.eventArt : global_var.eventArtEnglisch,
    );

    eventIntervalDropdown = CustomDropDownButton(
      items: isGerman ? global_var.eventInterval : global_var.eventIntervalEnglisch,
      onChange: () {
        setState(() {
         });
      }
    );

    super.initState();
  }

  isSeveralDays(eventInterval){
    return eventInterval == global_var.eventInterval[2] ||
        eventInterval == global_var.eventIntervalEnglisch[2];
  }

  saveEvent() async {
    var locationData = ortAuswahlBox.getGoogleLocationData();
    var uuid = const Uuid();
    var eventId = uuid.v4();
    var userID = FirebaseAuth.instance.currentUser?.uid;
    var allFilled = checkAllValidations(locationData);
    var interval = eventIntervalDropdown.getSelected();
    var bisDate;

    FocusManager.instance.primaryFocus?.unfocus();

    if(!allFilled) {
      customSnackbar(context, allFilled);
      return;

    }
    var wannDate = DateTime(eventWannDatum.year, eventWannDatum.month, eventWannDatum.day,
        eventWannUhrzeit.hour, eventWannUhrzeit.minute);
    if(isSeveralDays(interval)) {
      bisDate = DateTime(eventBisDatum.year, eventBisDatum.month, eventBisDatum.day,
        eventBisUhrzeit.hour, eventBisUhrzeit.minute);
    }

    var eventData = {
      "id": eventId,
      "name" : eventNameKontroller.text,
      "erstelltAm": DateTime.now().toString(),
      "erstelltVon": FirebaseAuth.instance.currentUser.uid,
      "beschreibung": eventBeschreibungKontroller.text,
      "stadt": locationData["city"],
      "art": eventArtDropdown.getSelected(),
      "wann" : wannDate.toString(),
      "bis": bisDate.toString(),
      "typ": ortTypDropdown.getSelected(),
      "sprache": json.encode(sprachenAuswahlBox.getSelected()),
      "interval": interval,
      "link": ortTypDropdown.getSelected() == "online" ? eventOrtKontroller.text : "",
      "land": locationData["countryname"],
      "longt": locationData["longt"],
      "latt": locationData["latt"],
      "zeitzone": DateTime.now().timeZoneOffset.inHours.toString(),
      "interesse": json.encode([userID]),
      "bild": "assets/bilder/strand.jpg",
    };

    await EventDatabase().addNewEvent(eventData);
    StadtinfoDatabase().addNewCity(locationData);
    var dbEventData = await EventDatabase().getData("*", "WHERE id = '$eventId'");

    if(dbEventData == false) return;

    global_functions.changePage(context, StartPage(selectedIndex: 1));
    global_functions.changePage(context, EventDetailsPage(event: dbEventData));
  }

  checkAllValidations(locationData){
    var validationFailText = "";

    if(eventNameKontroller.text.isEmpty){
      validationFailText = AppLocalizations.of(context).bitteNameEingeben;
    } else if(eventNameKontroller.text.length > 40){
      validationFailText = AppLocalizations.of(context).usernameZuLang;
    } else if(eventArtDropdown.getSelected().isEmpty) {
      validationFailText = AppLocalizations.of(context).bitteEventArtEingeben;
    }else if(eventIntervalDropdown.getSelected().isEmpty){
      validationFailText = AppLocalizations.of(context).bitteEventIntervalEingeben;
    } else if(ortTypDropdown.getSelected().isEmpty){
      validationFailText = AppLocalizations.of(context).bitteEventTypEingeben;
    } else if(ortTypDropdown.getSelected() == "offline" && locationData["city"] == null){
      validationFailText = AppLocalizations.of(context).bitteStadtEingeben;
    //} else if (ortTypDropdown.getSelected() == "online" && eventOrtKontroller.text.isEmpty) {
    //  validationFailText = AppLocalizations.of(context).bitteLinkEingeben;
    }else if(sprachenAuswahlBox.getSelected().isEmpty){
      validationFailText = AppLocalizations.of(context).bitteSpracheEingeben;
    } else if(eventWannDatum == null){
      validationFailText = AppLocalizations.of(context).bitteEventDatumEingeben;
    } else if (eventBisDatum == null && isSeveralDays(eventIntervalDropdown.getSelected())){
      validationFailText = AppLocalizations.of(context).bitteEnddatumEventEingeben;
    }else if(eventWannUhrzeit == null){
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
    double screenWidth = MediaQuery. of(context). size. width;
    sprachenAuswahlBox.hintText = AppLocalizations.of(context).spracheAuswaehlen;
    eventArtDropdown.hintText = AppLocalizations.of(context).eventArten;
    eventIntervalDropdown.hintText = isGerman ? global_var.eventInterval.join(", ") :
        global_var.eventIntervalEnglisch.join(", ");
    ortAuswahlBox.hintText = AppLocalizations.of(context).stadtEingeben;

    wannDatetimeBox(){
      var dateString = AppLocalizations.of(context).datumAuswaehlen;
      if(eventWannDatum != null){
        var dateFormat = DateFormat('dd-MM-yyyy');
        var dateTime = DateTime(eventWannDatum.year, eventWannDatum.month, eventWannDatum.day);
        dateString = dateFormat.format(dateTime);
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Event start: "),
          const SizedBox(width: 20),
          ElevatedButton(
            child: Text(dateString),
            onPressed: () async {
              eventWannDatum = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 1)
              );

              setState(() {
              });
            },
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            child: Text(eventWannUhrzeit == null ? AppLocalizations.of(context).uhrzeitAuswaehlen : eventWannUhrzeit.format(context)),
            onPressed: () async {
              eventWannUhrzeit = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 12, minute: 00),
              );
              setState(() {
              });
            },
          )
        ],
      );
    }

    bisDatetimeBox(){
      // @Zukunfts-Dominik - Sorry, aber mir viel nichts besseres ein
      var dateString = AppLocalizations.of(context).datumAuswaehlen;
      if(eventBisDatum != null){
        var dateFormat = DateFormat('dd-MM-yyyy');
        var dateTime = DateTime(eventBisDatum.year, eventBisDatum.month, eventBisDatum.day);
        dateString = dateFormat.format(dateTime);
      }

      return !isSeveralDays(eventIntervalDropdown.getSelected()) ? SizedBox.shrink(): Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(AppLocalizations.of(context).eventEnde),
          const SizedBox(width: 20),
          ElevatedButton(
            child: Text(dateString),
            onPressed: () async {
              eventBisDatum = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 1)
              );

              setState(() {
              });
            },
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            child: Text(eventBisUhrzeit == null ? AppLocalizations.of(context).uhrzeitAuswaehlen : eventBisUhrzeit.format(context)),
            onPressed: () async {
              eventBisUhrzeit = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 12, minute: 00),
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
        return const SizedBox.shrink();
      }

    }

    eventArtInformation(){
      return Positioned(
          top: -5,
          left: screenWidth <640 ? -5 : ((screenWidth - 640) / 2) +5,
          child: IconButton(
            icon: const Icon(Icons.help,size: 15),
            onPressed: () => showDialog(
                context: context,
                builder: (BuildContext buildContext) {
                  return CustomAlertDialog(
                    height: 500,
                    title: AppLocalizations.of(context).informationEventArt,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        margin: const EdgeInsets.only(left: 5, right: 5),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("privat       ", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(AppLocalizations.of(context).privatInformationText,
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.only(left: 5, right: 5),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(
                              width: 70,
                              child: Text(AppLocalizations.of(context).halbOeffentlich,style: const TextStyle(fontWeight: FontWeight.bold))
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(AppLocalizations.of(context).halbOeffentlichInformationText,
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.only(left: 5, right: 5),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(AppLocalizations.of(context).oeffentlich, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(AppLocalizations.of(context).oeffentlichInformationText,
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      )
                    ]
                  );
                }
            )
          )
      );
    }


    return Scaffold(
      appBar: customAppBar(
        title: AppLocalizations.of(context).eventErstellen,
        buttons: [
          IconButton(
              onPressed: () => saveEvent(),
              icon: const Icon(Icons.done, color: Colors.green)
          )
        ]
      ),
      body: ListView(
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
          //ortTypDropdown,
          Align(child: ortEingabeBox()),
          sprachenAuswahlBox,
          eventIntervalDropdown,
          wannDatetimeBox(),
          bisDatetimeBox(),
          customTextInput(
            AppLocalizations.of(context).eventBeschreibung,
            eventBeschreibungKontroller,
            moreLines: 8,
            textInputAction: TextInputAction.newline
          ),
        ],
      ),
    );
  }
}


