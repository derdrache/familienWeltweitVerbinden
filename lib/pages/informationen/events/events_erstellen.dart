import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:familien_suche/pages/start_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:translator/translator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../services/database.dart';
import '../../../global/custom_widgets.dart';
import '../../../global/global_functions.dart' as global_functions;
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/dialogWindow.dart';
import '../../../widgets/google_autocomplete.dart';
import '../../../global/variablen.dart' as global_var;
import 'event_details.dart';

class EventErstellen extends StatefulWidget {
  const EventErstellen({Key key}) : super(key: key);

  @override
  _EventErstellenState createState() => _EventErstellenState();
}

class _EventErstellenState extends State<EventErstellen> {
  var isGerman = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";
  var eventNameKontroller = TextEditingController();
  DateTime eventWannDatum;
  DateTime eventBisDatum;
  TimeOfDay eventWannUhrzeit;
  TimeOfDay eventBisUhrzeit;
  var eventBeschreibungKontroller = TextEditingController();
  var eventOrtKontroller = TextEditingController();
  var sprachenAuswahlBox = CustomMultiTextForm();
  var eventArtDropdown = CustomDropDownButton();
  var ortTypDropdown = CustomDropDownButton();
  var ortAuswahlBox = GoogleAutoComplete();
  var eventIntervalDropdown = CustomDropDownButton();
  var ownEvent = true;
  final translator = GoogleTranslator();

  @override
  void initState() {
    sprachenAuswahlBox = CustomMultiTextForm(
        icon: const Icon(
          Icons.arrow_downward,
          color: Colors.black,
        ),
        auswahlList: isGerman
            ? global_var.sprachenListe
            : global_var.sprachenListeEnglisch);

    ortTypDropdown = CustomDropDownButton(
      selected: "offline",
      hintText: "offline / online",
      labelText: "Event typ",
      items: isGerman ? global_var.eventTyp : global_var.eventTypEnglisch,
      onChange: () {
        setState(() {});
      },
    );

    eventArtDropdown = CustomDropDownButton(
      items: isGerman ? global_var.eventArt : global_var.eventArtEnglisch,
    );

    eventIntervalDropdown = CustomDropDownButton(
        items: isGerman
            ? global_var.eventInterval
            : global_var.eventIntervalEnglisch,
        onChange: () {
          setState(() {});
        });

    super.initState();
  }

  isMultiDayEvent(eventInterval) {
    return eventInterval == global_var.eventInterval[2] ||
        eventInterval == global_var.eventIntervalEnglisch[2];
  }

  saveEvent() async {
    var locationData = ortAuswahlBox.getGoogleLocationData();
    var uuid = const Uuid();
    var eventId = uuid.v4();
    var userID = FirebaseAuth.instance.currentUser?.uid;
    var allValid = checkValidations(locationData);
    var interval = eventIntervalDropdown.getSelected();
    bool descriptionIsGerman = true;
    String beschreibungGer = "";
    String beschreibungEng = "";
    DateTime bisDate;

    FocusManager.instance.primaryFocus?.unfocus();

    if (!allValid) {
      customSnackbar(context, allValid);
      return;
    }
    var wannDate = DateTime(eventWannDatum.year, eventWannDatum.month,
        eventWannDatum.day, eventWannUhrzeit.hour, eventWannUhrzeit.minute);
    if (isMultiDayEvent(interval)) {
      bisDate = DateTime(eventBisDatum.year, eventBisDatum.month,
          eventBisDatum.day, eventBisUhrzeit.hour, eventBisUhrzeit.minute);
    }

    if (locationData["latt"] == null) {
      locationData = {
        "longt": -50.1,
        "latt": 30.1,
        "countryname": "Online",
        "city": "Online"
      };
    }

    var languageCheck = await translator.translate(eventBeschreibungKontroller.text);
    descriptionIsGerman = languageCheck.sourceLanguage.code == "de";

    if(descriptionIsGerman){
      beschreibungGer = eventBeschreibungKontroller.text;
      beschreibungEng = await descriptionTranslation(beschreibungGer, "auto");
      beschreibungEng += "\n\nThis is an automatic translation";
    }else{
      beschreibungEng = eventBeschreibungKontroller.text;
      beschreibungGer = await descriptionTranslation(
          beschreibungEng + "\n\n Hierbei handelt es sich um eine automatische Übersetzung","de");
      beschreibungGer = beschreibungGer + "\n\nHierbei handelt es sich um eine automatische Übersetzung";
    }

    var eventData = {
      "id": eventId,
      "name": eventNameKontroller.text,
      "erstelltAm": DateTime.now().toString(),
      "erstelltVon": userID,
      "beschreibung": eventBeschreibungKontroller.text,
      "beschreibungGer":beschreibungGer,
      "beschreibungEng": beschreibungEng,
      "stadt": locationData["city"],
      "art": eventArtDropdown.getSelected(),
      "wann": wannDate.toString(),
      "bis": bisDate.toString(),
      "typ": ortTypDropdown.getSelected(),
      "sprache": json.encode(sprachenAuswahlBox.getSelected()),
      "interval": interval,
      "link": ortTypDropdown.getSelected() == "online"
          ? eventOrtKontroller.text
          : "",
      "land": locationData["countryname"],
      "longt": locationData["longt"],
      "latt": locationData["latt"],
      "zeitzone": DateTime.now().timeZoneOffset.inHours.toString(),
      "interesse": json.encode([userID]),
      "bild": "assets/bilder/strand.jpg",
      "ownEvent": ownEvent
    };

    await EventDatabase().addNewEvent(eventData);
    StadtinfoDatabase().addNewCity(locationData);
    var dbEventData =
        await EventDatabase().getData("*", "WHERE id = '$eventId'");
    ChatGroupsDatabase().addNewChatGroup(
        userID, "</event=$eventId"
    );

    if (dbEventData == false) return;

    global_functions.changePage(context, StartPage(selectedIndex: 2, informationPageIndex: 1,));
    global_functions.changePage(context, EventDetailsPage(event: dbEventData));
  }

  descriptionTranslation(text, targetLanguage) async{
    text = text.replaceAll("'", "");

    var translation = await translator.translate(text,
        from: "auto", to: targetLanguage);

    return translation.toString();
  }

  checkValidations(locationData) {
    var validationFailText = "";

    if (eventNameKontroller.text.isEmpty) {
      validationFailText = AppLocalizations.of(context).bitteNameEingeben;
    } else if (eventNameKontroller.text.length > 40) {
      validationFailText = AppLocalizations.of(context).usernameZuLang;
    } else if (eventArtDropdown.getSelected().isEmpty) {
      validationFailText = AppLocalizations.of(context).bitteEventArtEingeben;
    } else if (eventIntervalDropdown.getSelected().isEmpty) {
      validationFailText =
          AppLocalizations.of(context).bitteEventIntervalEingeben;
    } else if (ortTypDropdown.getSelected().isEmpty) {
      validationFailText = AppLocalizations.of(context).bitteEventTypEingeben;
    } else if (ortTypDropdown.getSelected() == "offline" &&
        locationData["city"] == null) {
      validationFailText = AppLocalizations.of(context).bitteStadtEingeben;
    } else if (ortTypDropdown.getSelected() == "online" &&
        eventOrtKontroller.text.isEmpty) {
      validationFailText = AppLocalizations.of(context).bitteLinkEingeben;
    } else if (sprachenAuswahlBox.getSelected().isEmpty) {
      validationFailText = AppLocalizations.of(context).bitteSpracheEingeben;
    } else if (eventWannDatum == null) {
      validationFailText = AppLocalizations.of(context).bitteEventDatumEingeben;
    } else if (eventBisDatum == null &&
        isMultiDayEvent(eventIntervalDropdown.getSelected())) {
      validationFailText =
          AppLocalizations.of(context).bitteEnddatumEventEingeben;
    } else if (eventWannUhrzeit == null) {
      validationFailText =
          AppLocalizations.of(context).bitteEventUhrzeitEingeben;
    } else if (eventBeschreibungKontroller.text.isEmpty) {
      validationFailText =
          AppLocalizations.of(context).bitteEventBeschreibungEingeben;
    }

    if (validationFailText.isEmpty) return true;

    customSnackbar(context, validationFailText);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    sprachenAuswahlBox.hintText =
        AppLocalizations.of(context).spracheAuswaehlen;
    eventArtDropdown.labelText =  AppLocalizations.of(context).eventOeffentlichkeit;
    eventArtDropdown.hintText = AppLocalizations.of(context).eventArten;
    eventIntervalDropdown.labelText = AppLocalizations.of(context).eventWiederholung;
    eventIntervalDropdown.hintText = isGerman
        ? global_var.eventInterval.join(", ")
        : global_var.eventIntervalEnglisch.join(", ");
    ortAuswahlBox.hintText = AppLocalizations.of(context).stadtEingeben;

    dateTimeBox(eventDatum, eventUhrzeit, dateTimeTyp) {
      var dateString = AppLocalizations.of(context).datumAuswaehlen;
      if (eventDatum != null) {
        var dateFormat = DateFormat('dd-MM-yyyy');
        var dateTime =
            DateTime(eventDatum.year, eventDatum.month, eventDatum.day);
        dateString = dateFormat.format(dateTime);
      }

      return !isMultiDayEvent(eventIntervalDropdown.getSelected()) &&
              dateTimeTyp == "bis"
          ? const SizedBox.shrink()
          : Align(
              child: Container(
                width: 600,
                margin: const EdgeInsets.only(left: 20, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      dateTimeTyp == "wann"
                          ? "Event start: "
                          : AppLocalizations.of(context).eventEnde,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      child: Text(dateString),
                      onPressed: () async {
                        var pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(DateTime.now().year + 1));

                        if (dateTimeTyp == "wann") {
                          eventWannDatum = pickedDate;
                        } else {
                          eventBisDatum = pickedDate;
                        }

                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      child: Text(eventUhrzeit == null
                          ? AppLocalizations.of(context).uhrzeitAuswaehlen
                          : eventUhrzeit.format(context)),
                      onPressed: () async {
                        var pickedTime = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 12, minute: 00),
                        );

                        if (dateTimeTyp == "wann") {
                          eventWannUhrzeit = pickedTime;
                        } else {
                          eventBisUhrzeit = pickedTime;
                        }

                        setState(() {});
                      },
                    )
                  ],
                ),
              ),
            );
    }

    ortEingabeBox() {
      if (ortTypDropdown.selected == "online") {
        return customTextInput(
            AppLocalizations.of(context).eventLinkEingeben, eventOrtKontroller,
            validator: global_functions.checkValidatorEmpty(context));
      } else if (ortTypDropdown.selected == "offline") {
        return ortAuswahlBox;
      } else {
        return const SizedBox.shrink();
      }
    }

    eventArtInformation() {
      return Positioned(
          top: -5,
          left: screenWidth < 640 ? -5 : ((screenWidth - 640) / 2) + 5,
          child: IconButton(
              icon: const Icon(Icons.help, size: 15),
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
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("privat       ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .privatInformationText,
                                      maxLines: 10,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                ]),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            margin: const EdgeInsets.only(left: 5, right: 5),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                      width: 70,
                                      child: Text(
                                          AppLocalizations.of(context)
                                              .halbOeffentlich,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .halbOeffentlichInformationText,
                                      maxLines: 10,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                ]),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            margin: const EdgeInsets.only(left: 5, right: 5),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context).oeffentlich,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .oeffentlichInformationText,
                                      maxLines: 10,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ]),
                          )
                        ]);
                  })));
    }

    ownEventBox() {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.only(left:10),
                width: screenWidth * 0.75,
                child: Text(AppLocalizations.of(context).frageErstellerEvent,
                    maxLines: 2, style: const TextStyle(fontSize: 18),)),
            const Expanded(
              child: SizedBox.shrink(),
            ),
            Checkbox(
                value: ownEvent,
                onChanged: (value) {
                  setState(() {
                    ownEvent = value;
                  });
                }),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).eventErstellen,
          buttons: [
            IconButton(
                onPressed: () => saveEvent(),
                icon: const Icon(Icons.done, size: 30))
          ]),
      body: SafeArea(
        child: ListView(
          children: [
            customTextInput("Event Name", eventNameKontroller,
                validator: global_functions.checkValidatorEmpty(context)),
            Stack(
              children: [eventArtDropdown, eventArtInformation()],
            ),
            ortTypDropdown,
            Align(child: ortEingabeBox()),
            sprachenAuswahlBox,
            eventIntervalDropdown,
            dateTimeBox(eventWannDatum, eventWannUhrzeit, "wann"),
            dateTimeBox(eventBisDatum, eventBisUhrzeit, "bis"),
            ownEventBox(),
            customTextInput(AppLocalizations.of(context).eventBeschreibung,
                eventBeschreibungKontroller,
                moreLines: 8, textInputAction: TextInputAction.newline),
          ],
        ),
      ),
    );
  }
}
