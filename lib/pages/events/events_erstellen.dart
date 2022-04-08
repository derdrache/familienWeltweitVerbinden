import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:familien_suche/pages/events/event_card_details.dart';
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

    super.initState();
  }

  saveEvent() async {
    var locationData = ortAuswahlBox.getGoogleLocationData();
    var uuid = const Uuid();
    var eventId = uuid.v4();
    var userID = FirebaseAuth.instance.currentUser?.uid;
    var allFilled = checkAllValidations(locationData);


    if(!allFilled) return;

    var date = DateTime(eventDatum.year, eventDatum.month, eventDatum.day,
        eventUhrzeit.hour, eventUhrzeit.minute);

    var eventData = {
      "id": eventId,
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
      "zeitzone": DateTime.now().timeZoneOffset.inHours.toString(),
      "interesse": json.encode([userID]),
      "bild": "assets/bilder/strand.jpg",
    };

    await EventDatabase().addNewEvent(eventData);
    var dbEventData = await EventDatabase().getData("*", "WHERE id = '$eventId'");

    if(dbEventData == false){
      print("error");
      return;
    }

    global_functions.changePage(context, StartPage(selectedIndex: 1));
    global_functions.changePage(context, EventDetailsPage(event: dbEventData));
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
    //} else if (ortTypDropdown.getSelected() == "online" && eventOrtKontroller.text.isEmpty) {
    //  validationFailText = AppLocalizations.of(context).bitteLinkEingeben;
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
    double screenWidth = MediaQuery. of(context). size. width;
    sprachenAuswahlBox.hintText = AppLocalizations.of(context).spracheAuswaehlen;
    eventArtDropdown.hintText = AppLocalizations.of(context).eventArten;
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
          const SizedBox(width: 20),
          ElevatedButton(
            child: Text(eventUhrzeit == null ? AppLocalizations.of(context).uhrzeitAuswaehlen : eventUhrzeit.format(context)),
            onPressed: () async {
              eventUhrzeit = await showTimePicker(
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
          ortEingabeBox(),
          sprachenAuswahlBox,
          dateAndTimeBox(),
          customTextInput(
              AppLocalizations.of(context).eventBeschreibung,
              eventBeschreibungKontroller,
              moreLines: 8
          ),
        ],
      ),
    );
  }
}


