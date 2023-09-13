import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:translator/translator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../global/profil_sprachen.dart';
import '../../../services/database.dart';
import '../../../global/global_functions.dart' as global_functions;
import '../../../widgets/custom_appbar.dart';
import '../../../windows/dialog_window.dart';
import '../../../widgets/google_autocomplete.dart';
import '../../../global/variablen.dart' as global_var;
import '../../../global/style.dart' as style;
import '../../../widgets/layout/custom_dropdown_button.dart';
import '../../../widgets/layout/custom_multi_select.dart';
import '../../../widgets/layout/custom_snackbar.dart';
import '../../../widgets/layout/custom_text_input.dart';
import '../../../widgets/nutzerrichtlinen.dart';
import 'meetup_details.dart';

class MeetupErstellen extends StatefulWidget {
  const MeetupErstellen({Key? key}) : super(key: key);

  @override
  State<MeetupErstellen> createState() => _MeetupErstellenState();
}

class _MeetupErstellenState extends State<MeetupErstellen> {
  String userID = Hive.box("secureBox").get("ownProfil")["id"];
  bool isGerman = kIsWeb
      ? PlatformDispatcher.instance.locale.languageCode == "de"
      : Platform.localeName == "de_DE";
  TextEditingController meetupNameKontroller = TextEditingController();
  DateTime? meetupWannDatum;
  DateTime? meetupBisDatum;
  TimeOfDay? meetupWannUhrzeit;
  TimeOfDay? meetupBisUhrzeit;
  TextEditingController meetupBeschreibungKontroller = TextEditingController();
  TextEditingController meetupOrtKontroller = TextEditingController();
  late CustomMultiTextForm sprachenAuswahlBox;
  late CustomDropdownButton meetupArtDropdown;
  late CustomDropdownButton ortTypDropdown;
  GoogleAutoComplete ortAuswahlBox = GoogleAutoComplete(margin: const EdgeInsets.only(top: 0, bottom:5, left:10, right:10), withOwnLocation: true);
  late CustomDropdownButton meetupIntervalDropdown;
  bool ownMeetup = true;
  final translator = GoogleTranslator();
  bool chooseCurrentLocation = false;

  @override
  void initState() {
    sprachenAuswahlBox = CustomMultiTextForm(
        auswahlList: isGerman
            ? ProfilSprachen().getAllGermanLanguages()
            : ProfilSprachen().getAllEnglishLanguages());

    ortTypDropdown = CustomDropdownButton(
      selected: "offline",
      hintText: "offline / online",
      items: isGerman ? global_var.meetupTyp : global_var.meetupTypEnglisch,
      onChange: () {
        setState(() {});
      },
    );

    meetupArtDropdown = CustomDropdownButton(
      items: isGerman ? global_var.eventArt : global_var.eventArtEnglisch,
    );

    meetupIntervalDropdown = CustomDropdownButton(
        items: isGerman
            ? global_var.meetupInterval
            : global_var.meetupIntervalEnglisch,
        onChange: () {
          setState(() {});
        });

    super.initState();
  }

  isMultiDayMeetup(interval) {
    return interval == global_var.meetupInterval[2] ||
        interval == global_var.meetupIntervalEnglisch[2];
  }

  saveMeetup() async {
    var locationData = ortAuswahlBox.getGoogleLocationData();
    var uuid = const Uuid();
    var meetupId = uuid.v4();
    var allValid = checkValidations(locationData);
    var interval = meetupIntervalDropdown.getSelected();
    DateTime? bisDate;

    FocusManager.instance.primaryFocus?.unfocus();

    if (!allValid) {
      customSnackBar(context, allValid);
      return;
    }
    var wannDate = DateTime(meetupWannDatum!.year, meetupWannDatum!.month,
        meetupWannDatum!.day, meetupWannUhrzeit!.hour, meetupWannUhrzeit!.minute);
    if (isMultiDayMeetup(interval)) {
      bisDate = DateTime(meetupBisDatum!.year, meetupBisDatum!.month,
          meetupBisDatum!.day, meetupBisUhrzeit!.hour, meetupBisUhrzeit!.minute);
    }

    if (locationData["latt"] == null) {
      locationData = {
        "longt": -50.1,
        "latt": 30.1,
        "countryname": "Online",
        "city": "Online"
      };
    }

    var meetupData = {
      "id": meetupId,
      "name": meetupNameKontroller.text,
      "nameGer": meetupNameKontroller.text,
      "nameEng": meetupNameKontroller.text,
      "erstelltAm": DateTime.now().toString(),
      "erstelltVon": userID,
      "beschreibung": meetupBeschreibungKontroller.text,
      "beschreibungGer":meetupBeschreibungKontroller.text,
      "beschreibungEng": meetupBeschreibungKontroller.text,
      "stadt": locationData["city"],
      "art": meetupArtDropdown.getSelected(),
      "wann": wannDate.toString(),
      "bis": bisDate?.toString(),
      "typ": ortTypDropdown.getSelected(),
      "sprache": json.encode(sprachenAuswahlBox.getSelected()),
      "interval": interval,
      "link": ortTypDropdown.getSelected() == "online"
          ? meetupOrtKontroller.text
          : "",
      "land": locationData["countryname"],
      "longt": locationData["longt"],
      "latt": locationData["latt"],
      "zeitzone": DateTime.now().timeZoneOffset.inHours.toString(),
      "interesse": json.encode([userID]),
      "bild": "assets/bilder/strand.jpg",
      "ownEvent": ownMeetup
    };

    saveDB(Map.of(meetupData), locationData);


    meetupData["freischalten"] = [];
    meetupData["eventInterval"] = meetupData["interval"];
    meetupData["absage"] = [];
    meetupData["zusage"] = [];
    meetupData["freigegeben"] = [];
    meetupData["sprache"] = json.decode(meetupData["sprache"]);
    meetupData["interesse"] = json.decode(meetupData["interesse"]);
    meetupData["tags"] = [];
    meetupData["immerZusagen"] = [];

    var myOwnMeetups = Hive.box('secureBox').get("myEvents") ?? [];
    myOwnMeetups.add(meetupData);
    var meetups = Hive.box('secureBox').get("events") ?? [];
    meetups.add(meetupData);

    Navigator.pop(context);
    global_functions.changePage(context, MeetupDetailsPage(meetupData: meetupData));
  }

  saveDB(meetup, locationData) async{
    var languageCheck = await translator.translate(meetup["beschreibung"]);
    bool descriptionIsGerman = languageCheck.sourceLanguage.code == "de";

    if(descriptionIsGerman){
      meetup["nameGer"] = meetup["name"];
      meetup["nameEng"] = await descriptionTranslation(meetup["name"], "auto");
      meetup["beschreibungGer"] = meetup["beschreibung"];
      meetup["beschreibungEng"] = await descriptionTranslation(meetup["beschreibungGer"], "auto");
      meetup["beschreibungEng"] += "\n\nThis is an automatic translation";
    }else{
      meetup["nameEng"] = meetup["name"];
      meetup["nameGer"] = await descriptionTranslation(meetup["name"], "auto");
      meetup["beschreibungEng"] = meetup["beschreibung"];
      meetup["beschreibungGer"] = await descriptionTranslation(
          meetup["beschreibungEng"] + "\n\n Hierbei handelt es sich um eine automatische Übersetzung","de");
      meetup["beschreibungGer"] = meetup["beschreibungGer"] + "\n\nHierbei handelt es sich um eine automatische Übersetzung";
    }


    await MeetupDatabase().addNewMeetup(meetup);

    StadtinfoDatabase().addNewCity(locationData);
    ChatGroupsDatabase().addNewChatGroup(
        userID, "</event=${meetup["id"]}"
    );
  }

  descriptionTranslation(text, targetLanguage) async{
    text = text.replaceAll("'", "");

    var translation = await translator.translate(text,
        from: "auto", to: targetLanguage);

    return translation.toString();
  }

  checkValidations(locationData) {
    var validationFailText = "";

    if (meetupNameKontroller.text.isEmpty) {
      validationFailText = AppLocalizations.of(context)!.bitteNameEingeben;
    } else if (meetupArtDropdown.getSelected().isEmpty) {
      validationFailText = AppLocalizations.of(context)!.bitteMeetupArtEingeben;
    } else if (meetupIntervalDropdown.getSelected().isEmpty) {
      validationFailText =
          AppLocalizations.of(context)!.bitteMeetupIntervalEingeben;
    } else if (ortTypDropdown.getSelected().isEmpty) {
      validationFailText = AppLocalizations.of(context)!.bitteMeetupTypEingeben;
    } else if (ortTypDropdown.getSelected() == "offline" &&
        locationData["city"] == null) {
      validationFailText = AppLocalizations.of(context)!.bitteStadtEingeben;
    } else if (ortTypDropdown.getSelected() == "online" &&
        meetupOrtKontroller.text.isEmpty) {
      validationFailText = AppLocalizations.of(context)!.bitteLinkEingeben;
    } else if (sprachenAuswahlBox.getSelected().isEmpty) {
      validationFailText = AppLocalizations.of(context)!.bitteSpracheEingeben;
    } else if (meetupWannDatum == null) {
      validationFailText = AppLocalizations.of(context)!.bitteMeetupDatumEingeben;
    } else if (meetupBisDatum == null &&
        isMultiDayMeetup(meetupIntervalDropdown.getSelected())) {
      validationFailText =
          AppLocalizations.of(context)!.bitteEnddatumMeetupEingeben;
    } else if (meetupWannUhrzeit == null) {
      validationFailText =
          AppLocalizations.of(context)!.bitteMeetupUhrzeitEingeben;
    } else if (meetupBeschreibungKontroller.text.isEmpty) {
      validationFailText =
          AppLocalizations.of(context)!.bitteMeetupBeschreibungEingeben;
    }

    if (validationFailText.isEmpty) return true;

    customSnackBar(context, validationFailText);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    sprachenAuswahlBox.hintText =
        AppLocalizations.of(context)!.spracheAuswaehlen;
    meetupArtDropdown.hintText = AppLocalizations.of(context)!.meetupArten;
    meetupIntervalDropdown.hintText = isGerman
        ? global_var.meetupInterval.join(", ")
        : global_var.meetupIntervalEnglisch.join(", ");
    ortAuswahlBox.hintText = AppLocalizations.of(context)!.stadtEingeben;

    dateTimeBox(meetupDatum, meetupUhrzeit, dateTimeTyp) {
      var dateString = AppLocalizations.of(context)!.datumAuswaehlen;
      if (meetupDatum != null) {
        var dateFormat = DateFormat('dd-MM-yyyy');
        var dateTime =
            DateTime(meetupDatum.year, meetupDatum.month, meetupDatum.day);
        dateString = dateFormat.format(dateTime);
      }

      return !isMultiDayMeetup(meetupIntervalDropdown.getSelected()) &&
              dateTimeTyp == "bis"
          ? const SizedBox.shrink()
          : Align(
              child: Container(
                constraints: const BoxConstraints(maxWidth: style.webWidth),
                margin: const EdgeInsets.only(left: 15, right: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        dateTimeTyp == "wann"
                            ? "Meetup start: "
                            : AppLocalizations.of(context)!.meetupEnde,
                        style: const TextStyle(fontSize: 18),
                      ),
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
                          meetupWannDatum = pickedDate!;
                        } else {
                          meetupBisDatum = pickedDate!;
                        }

                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      child: Text(meetupUhrzeit == null
                          ? AppLocalizations.of(context)!.uhrzeitAuswaehlen
                          : meetupUhrzeit.format(context)),
                      onPressed: () async {
                        var pickedTime = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 12, minute: 00),
                        );

                        if (dateTimeTyp == "wann") {
                          meetupWannUhrzeit = pickedTime!;
                        } else {
                          meetupBisUhrzeit = pickedTime!;
                        }

                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 10,)
                  ],
                ),
              ),
            );
    }

    ortEingabeBox() {
      if (ortTypDropdown.selected == "online") {
        return CustomTextInput(
            AppLocalizations.of(context)!.meetupLinkEingeben, meetupOrtKontroller,
            validator: global_functions.checkValidatorEmpty(context));
      } else if (ortTypDropdown.selected == "offline") {
        return ortAuswahlBox;
      } else {
        return const SizedBox.shrink();
      }
    }

    meetupArtInformation() {
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
                        title: AppLocalizations.of(context)!.informationMeetupArt,
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
                                      AppLocalizations.of(context)!
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
                                          AppLocalizations.of(context)!
                                              .halbOeffentlich,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!
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
                                  Text(AppLocalizations.of(context)!.oeffentlich,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!
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

    ownMeetupBox() {
      return Container(
        constraints: const BoxConstraints(maxWidth: style.webWidth),
        margin: const EdgeInsets.only(left: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(AppLocalizations.of(context)!.frageErstellerMeetup,
                  maxLines: 2, style: const TextStyle(fontSize: 18),),
            ),
            Checkbox(
                value: ownMeetup,
                onChanged: (value) {
                  setState(() {
                    ownMeetup = value!;
                  });
                }),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context)!.meetupErstellen,
          buttons: [
            IconButton(
                onPressed: () => saveMeetup(),
                tooltip: AppLocalizations.of(context)!.tooltipEingabeBestaetigen,
                icon: const Icon(Icons.done, size: 30))
          ]),
      body: SafeArea(
        child: ListView(
          children: [
            CustomTextInput("Meetup Name", meetupNameKontroller,
                validator: global_functions.checkValidatorEmpty(context), maxLength: 40),
            Stack(
              children: [Align(child: meetupArtDropdown), meetupArtInformation()],
            ),
            Align(child: ortTypDropdown),
            Align(child: ortEingabeBox()),
            Align(child: sprachenAuswahlBox),
            Align(child: meetupIntervalDropdown),
            dateTimeBox(meetupWannDatum, meetupWannUhrzeit, "wann"),
            dateTimeBox(meetupBisDatum, meetupBisUhrzeit, "bis"),
            Align(child: ownMeetupBox()),
            CustomTextInput(AppLocalizations.of(context)!.meetupBeschreibung,
                meetupBeschreibungKontroller,
                moreLines: 8, textInputAction: TextInputAction.newline),
            Center(child: NutzerrichtlinenAnzeigen(page: "create")),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }
}
