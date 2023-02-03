import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:familien_suche/pages/show_profil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:translator/translator.dart';

import '../../../global/custom_widgets.dart';
import '../../../global/global_functions.dart' as global_func;
import '../../../services/notification.dart';
import '../../../widgets/dialogWindow.dart';
import '../../../widgets/google_autocomplete.dart';
import '../../../services/database.dart';
import '../../../global/variablen.dart' as global_var;
import '../../../widgets/event_image_galerie.dart';
import '../../../widgets/text_with_hyperlink_detection.dart';

var userId = FirebaseAuth.instance.currentUser.uid;
var isWebDesktop = kIsWeb &&
    (defaultTargetPlatform != TargetPlatform.iOS ||
        defaultTargetPlatform != TargetPlatform.android);
double fontsize = isWebDesktop ? 12 : 16;
var isGerman = kIsWeb
    ? window.locale.languageCode == "de"
    : Platform.localeName == "de_DE";

//ignore: must_be_immutable
class EventCardDetails extends StatefulWidget {
  Map event;
  bool offlineEvent;
  bool isCreator;
  bool isApproved;
  bool isPublic;

  EventCardDetails(
      {Key key, this.event, this.offlineEvent = true, this.isApproved = false})
      : isCreator = event["erstelltVon"] == userId,
        isPublic = event["art"] == "öffentlich" || event["art"] == "public",
        super(key: key);

  @override
  _EventCardDetailsState createState() => _EventCardDetailsState();
}

class _EventCardDetailsState extends State<EventCardDetails> {
  final _scrollController = ScrollController();
  bool moreContent = false;
  final translator = GoogleTranslator();
  TextEditingController changeTextInputController = TextEditingController();
  var ortAuswahlBox = GoogleAutoComplete();
  var beschreibungInputKontroller = TextEditingController();
  var changeDropdownInput = CustomDropDownButton();
  var changeMultiDropdownInput = CustomMultiTextForm();
  bool chooseCurrentLocation = false;
  var ownProfil = Hive.box('secureBox').get("ownProfil");

  @override
  void initState() {
    beschreibungInputKontroller.text = widget.event["beschreibung"];

    addScrollListener();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => scrollbarCheckForMoreContent());
    super.initState();
  }

  addScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        bool isTop = _scrollController.position.pixels == 0;
        if (isTop) {
          moreContent = true;
        } else {
          moreContent = false;
        }
        setState(() {});
      }
    });
  }

  scrollbarCheckForMoreContent() {
    if (_scrollController.position.maxScrollExtent > 0) {
      setState(() {
        moreContent = true;
      });
    }
  }

  askForRelease(isOnList) async {
    if (isOnList) {
      customSnackbar(
          context, AppLocalizations.of(context).eventInteresseZurueckgenommen,
          color: Colors.green);

      widget.event["freischalten"].remove(userId);

      EventDatabase().update(
          "freischalten = JSON_REMOVE(freischalten, JSON_UNQUOTE(JSON_SEARCH(freischalten, 'one', '$userId'))),"
              "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id ='${widget.event["id"]}'");
    } else {
      customSnackbar(
          context, AppLocalizations.of(context).eventInteresseMitgeteilt,
          color: Colors.green);

      widget.event["freischalten"].add(userId);

      EventDatabase().update(
          "freischalten = JSON_ARRAY_APPEND(freischalten, '\$', '$userId'),"
              "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id ='${widget.event["id"]}'");

      prepareEventNotification(
          eventId: widget.event["id"],
          toId: ownProfil["Id"],
          eventName : widget.event["name"],
          typ: "freigeben"
      );
    }

    updateHiveEvent(
        widget.event["id"], "freischalten", widget.event["freischalten"]);
  }

  convertEventDateIntoMyDate() {
    var eventZeitzone = widget.event["zeitzone"];
    var deviceZeitzone = DateTime.now().timeZoneOffset.inHours;
    var eventBeginn = widget.event["wann"];

    eventBeginn = DateTime.parse(eventBeginn)
        .add(Duration(hours: deviceZeitzone - eventZeitzone));

    var ownDate =
        eventBeginn.toString().split(" ")[0].split("-").reversed.join(".");
    var ownTime =
        eventBeginn.toString().split(" ")[1].toString().substring(0, 5);

    return ownDate + " " + ownTime;
  }

  saveTag(newValue) {
    if (widget.event["tags"]
            .contains(global_func.changeGermanToEnglish(newValue)) ||
        widget.event["tags"]
            .contains(global_func.changeEnglishToGerman(newValue))) return;

    widget.event["tags"].add(newValue);

    updateHiveEvent(widget.event["id"], "tags", widget.event["tags"]);

    EventDatabase().update("tags = JSON_ARRAY_APPEND(tags, '\$', '$newValue')",
        "WHERE id = '${widget.event["id"]}'");
  }

  removeTag(tag) {
    widget.event["tags"].remove(tag);

    updateHiveEvent(widget.event["id"], "tags", widget.event["tags"]);

    EventDatabase().update(
        "tags = JSON_REMOVE(tags, JSON_UNQUOTE(JSON_SEARCH(tags, 'one', '$tag')))",
        "WHERE id = '${widget.event["id"]}'");
  }

  descriptionTranslation(text, targetLanguage) async {
    text = text.replaceAll("'", "");

    var translation =
        await translator.translate(text, from: "auto", to: targetLanguage);

    return translation.toString();
  }

  checkAndSaveNewName() {
    String newName = changeTextInputController.text;

    if (newName.isEmpty) return false;

    if (newName.length > 40) {
      customSnackbar(context, AppLocalizations.of(context).usernameZuLang);
    }

    widget.event["name"] = newName;
    updateHiveEvent(widget.event["id"], "name", newName);
    EventDatabase()
        .update("name = '$newName'", "WHERE id = '${widget.event["id"]}'");

    return true;
  }

  checkAndSaveNewBeschreibung() async {
    var newBeschreibung = beschreibungInputKontroller.text;

    if (newBeschreibung.isEmpty) return false;

    var eventId = widget.event["id"];
    var event = getEventFromHive(eventId);

    event["beschreibung"] = newBeschreibung;
    event["beschreibungGer"]= newBeschreibung;
    event["beschreibungEng"]= newBeschreibung;

    translateAndSaveBeschreibung(event);

    return true;
  }

  translateAndSaveBeschreibung(event) async{
    var newBeschreibung = event["beschreibung"];
    var languageCheck = await translator.translate(newBeschreibung);
    bool descriptionIsGerman = languageCheck.sourceLanguage.code == "de";

    if (descriptionIsGerman) {
      event["beschreibungGer"] = newBeschreibung;
      var translation = await descriptionTranslation(newBeschreibung, "auto");
      event["beschreibungEng"] =
          translation + "\n\nThis is an automatic translation";
    } else {
      event["beschreibungEng"] = newBeschreibung;
      var translation = await descriptionTranslation(newBeschreibung, "de");
      event["beschreibungGer"] = translation +
          "\n\nHierbei handelt es sich um eine automatische Übersetzung";
    }

    await EventDatabase().update(
        "beschreibung = '${event["beschreibung"]}', beschreibungGer = '${event["beschreibungGer"]}',beschreibungEng = '${event["beschreibungEng"]}'",
        "WHERE id = '${event["id"]}'");
  }

  checkAndSaveNewTimeZone() {
    String newTimeZone = changeTextInputController.text;

    if (newTimeZone.isEmpty) return false;

    widget.event["zeitzone"] = newTimeZone;
    updateHiveEvent(widget.event["id"], "zeitzone", newTimeZone);
    EventDatabase().update(
        "zeitzone = '$newTimeZone'", "WHERE id = '${widget.event["id"]}'");

    return true;
  }

  checkAndSaveNewLocation() {
    var newLocation = ortAuswahlBox.googleSearchResult;

    if (newLocation["city"].isEmpty) return false;

    updateHiveEvent(widget.event["id"], "stadt", newLocation["city"]);
    updateHiveEvent(widget.event["id"], "land", newLocation["countryname"]);
    updateHiveEvent(widget.event["id"], "latt", newLocation["latt"]);
    updateHiveEvent(widget.event["id"], "longt", newLocation["longt"]);
    EventDatabase().updateLocation(widget.event["id"], newLocation);
    StadtinfoDatabase().addNewCity(newLocation);

    return true;
  }

  checkAndSaveNewMapAndLink() {
    String newLink = changeTextInputController.text;

    if (newLink.isEmpty) return false;

    if (!global_func.isLink(newLink)) {
      customSnackbar(context, AppLocalizations.of(context).eingabeKeinLink);
      return;
    }

    widget.event["link"] = newLink;
    updateHiveEvent(widget.event["id"], "link", newLink);
    EventDatabase()
        .update("link = '$newLink'", "WHERE id = '${widget.event["id"]}'");

    return true;
  }

  checkAndSaveNewInterval() {
    String newInterval = changeDropdownInput.getSelected();

    if (newInterval.isEmpty) return false;

    widget.event["eventInterval"] = newInterval;
    updateHiveEvent(widget.event["id"], "eventInterval", newInterval);
    EventDatabase().update(
        "eventInterval = '$newInterval'", "WHERE id = '${widget.event["id"]}'");

    return true;
  }

  checkAndSaveNewSprache() {
    List newSprache = changeMultiDropdownInput.getSelected();

    if (newSprache.isEmpty) return false;

    widget.event["sprache"] = newSprache;
    updateHiveEvent(widget.event["id"], "sprache", newSprache);
    EventDatabase().update("sprache = '${jsonEncode(newSprache)}'",
        "WHERE id = '${widget.event["id"]}'");

    return true;
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 500) screenWidth = kIsWeb ? 350 : 500;
    double cardWidth = screenWidth / 1.12;
    double cardHeight = screenHeight / 1.34;
    bool isOffline = widget.event["typ"] == global_var.eventTyp[0] ||
        widget.event["typ"] == global_var.eventTypEnglisch[0];
    ortAuswahlBox.hintText = AppLocalizations.of(context).neueStadtEingeben;
    widget.event["eventInterval"] = isGerman
        ? global_func.changeEnglishToGerman(widget.event["eventInterval"])
        : global_func.changeGermanToEnglish(widget.event["eventInterval"]);

    creatorChangeHintBox() {
      if (!widget.isCreator) return const SizedBox.shrink();

      return Center(
        child: Text(AppLocalizations.of(context).antippenZumAendern,
            style: const TextStyle(color: Colors.grey)),
      );
    }

    fremdesEventBox() {
      var fremdesEvent = widget.event["ownEvent"] == 0;

      if (!fremdesEvent || widget.isCreator) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.only(left: 10, right: 10),
        width: screenWidth * 0.8,
        child: Text(AppLocalizations.of(context).nichtErstellerEvent,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            maxLines: 2),
      );
    }

    eventInformationRow(rowTitle, rowData, changeWindow,
        {bodyColor = Colors.black}) {
      return Container(
          margin: const EdgeInsets.only(left: 10, right: 10, top: 5),
          child: Row(
            children: [
              Text(rowTitle,
                  style: TextStyle(
                      fontSize: fontsize, fontWeight: FontWeight.bold)),
              const Expanded(child: SizedBox.shrink()),
              InkWell(
                onTap: changeWindow,
                child: SizedBox(
                    width: 200,
                    child: Text(rowData,
                        textAlign: TextAlign.end,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: fontsize, color: bodyColor))),
              )
            ],
          ));
    }

    openChangeWindow(title, inputWidget, saveFunction, {double height = 180}) {
      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(title: title, height: height, children: [
              inputWidget,
              Container(
                margin: const EdgeInsets.only(right: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      child: Text(AppLocalizations.of(context).abbrechen,
                          style: TextStyle(fontSize: fontsize)),
                      onPressed: () {
                        changeTextInputController = TextEditingController();
                        Navigator.pop(context);
                      }),
                  TextButton(
                      child: Text(AppLocalizations.of(context).speichern,
                          style: TextStyle(fontSize: fontsize)),
                      onPressed: () async {
                        bool saveSuccess = await saveFunction();

                        if (!saveSuccess) {
                          customSnackbar(context,
                              AppLocalizations.of(context).keineEingabe);
                          return;
                        }

                        changeTextInputController = TextEditingController();
                        setState(() {});
                        Navigator.pop(context);
                      }),
                ]),
              )
            ]);
          });
    }

    nameInformation() {
      return InkWell(
        onTap: () => openChangeWindow(
            AppLocalizations.of(context).eventNameAendern,
            customTextInput(AppLocalizations.of(context).neuenNamenEingeben,
                changeTextInputController),
            checkAndSaveNewName),
        child: Text(widget.event["name"],
            style:
                TextStyle(fontSize: fontsize + 8, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
      );
    }

    bildAndTitleBox() {
      bool isAssetImage =
          widget.event["bild"].substring(0, 5) == "asset" ? true : false;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Stack(
            children: [
              EventImageGalerie(
                isCreator: widget.isCreator,
                event: widget.event,
                child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    child: isAssetImage
                        ? Image.asset(widget.event["bild"],
                            fit: BoxFit.fitWidth)
                        : Container(
                            constraints:
                                BoxConstraints(maxHeight: screenHeight / 2.08),
                            child: Image.network(
                              widget.event["bild"],
                            ))),
              ),
            ],
          ),
          Positioned.fill(
              bottom: -10,
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ]),
                      margin: const EdgeInsets.only(left: 30, right: 30),
                      width: 800,
                      child: nameInformation()))),
        ],
      );
    }

    timeZoneInformation() {
      return eventInformationRow(
        AppLocalizations.of(context).zeitzone,
        "GMT " + widget.event["zeitzone"].toString(),
        () => openChangeWindow(
            AppLocalizations.of(context).eventZeitzoneAendern,
            customTextInput(AppLocalizations.of(context).neueZeitzoneEingeben,
                changeTextInputController),
            checkAndSaveNewTimeZone),
      );
    }

    openLocationChangeWindow() {
      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return StatefulBuilder(builder: (context, dialogSetState) {
              if (chooseCurrentLocation) {
                var currentLocaton = {
                  "city": ownProfil["ort"],
                  "countryname": ownProfil["land"],
                  "longt": ownProfil["longt"],
                  "latt": ownProfil["latt"],
                };
                ortAuswahlBox.setLocation(currentLocaton);
              } else {
                ortAuswahlBox.clear();
              }

              return CustomAlertDialog(
                  title: AppLocalizations.of(context).eventStadtAendern,
                  height: 400,
                  children: [
                    ortAuswahlBox,
                    Container(
                      margin: const EdgeInsets.only(left: 5, right: 5),
                      child: Row(
                        children: [
                          Text(AppLocalizations.of(context)
                              .aktuellenOrtVerwenden),
                          const Expanded(child: SizedBox.shrink()),
                          Switch(
                              value: chooseCurrentLocation,
                              onChanged: (newValue) {
                                chooseCurrentLocation = newValue;
                                dialogSetState(() {});
                              })
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                child: Text(
                                    AppLocalizations.of(context).abbrechen,
                                    style: TextStyle(fontSize: fontsize)),
                                onPressed: () {
                                  Navigator.pop(context);
                                }),
                            TextButton(
                                child: Text(
                                    AppLocalizations.of(context).speichern,
                                    style: TextStyle(fontSize: fontsize)),
                                onPressed: () {
                                  checkAndSaveNewLocation();
                                  setState(() {});
                                  Navigator.pop(context);
                                }),
                          ]),
                    )
                  ]);
            });
          });
    }

    locationInformation() {
      return eventInformationRow(
          AppLocalizations.of(context).ort,
          widget.event["stadt"] + ", " + widget.event["land"],
          () => openLocationChangeWindow());
    }

    mapAndLinkInformation() {
      return eventInformationRow(
          isOffline ? "Map: " : "Link: ",
          widget.event["link"],
          () => openChangeWindow(
              AppLocalizations.of(context).eventMapLinkAendern,
              customTextInput(
                  AppLocalizations.of(context).neuenKartenlinkEingeben,
                  changeTextInputController),
              checkAndSaveNewMapAndLink),
          bodyColor: Theme.of(context).colorScheme.secondary);
    }

    intervalInformation() {
      changeDropdownInput = CustomDropDownButton(
          items: isGerman
              ? global_var.eventInterval
              : global_var.eventIntervalEnglisch,
          selected: widget.event["eventInterval"]);

      return eventInformationRow(
          "Interval",
          widget.event["eventInterval"],
          () => openChangeWindow(
              AppLocalizations.of(context).eventIntervalAendern,
              changeDropdownInput,
              checkAndSaveNewInterval));
    }

    sprachenInformation() {
      var data = isGerman
          ? global_func
              .changeEnglishToGerman(widget.event["sprache"])
              .join(", ")
          : global_func
              .changeGermanToEnglish(widget.event["sprache"])
              .join(", ");
      changeMultiDropdownInput = CustomMultiTextForm(
        selected: data.split(", "),
        hintText: "Sprachen auswählen",
        auswahlList: isGerman
            ? global_var.sprachenListe
            : global_var.sprachenListeEnglisch,
      );

      return eventInformationRow(
          AppLocalizations.of(context).sprache,
          data,
          () => openChangeWindow(
              AppLocalizations.of(context).eventSpracheAendern,
              changeMultiDropdownInput,
              checkAndSaveNewSprache,
              height: 600));
    }

    eventBeschreibung() {
      if (widget.event["beschreibungGer"].isEmpty) {
        widget.event["beschreibungGer"] = widget.event["beschreibung"];
      }
      if (widget.event["beschreibungEng"].isEmpty) {
        widget.event["beschreibungEng"] = widget.event["beschreibung"];
      }
      var usedDiscription = isGerman
          ? widget.event["beschreibungGer"]
          : widget.event["beschreibungEng"];

      return Container(
          margin:
              const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 10),
          child: Center(
              child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 50.0,
                  ),
                  child: TextWithHyperlinkDetection(
                      text: usedDiscription,
                      onTextTab: widget.isCreator
                          ? () => openChangeWindow(
                              AppLocalizations.of(context)
                                  .eventBeschreibungAendern,
                              customTextInput(
                                  AppLocalizations.of(context)
                                      .neueBeschreibungEingeben,
                                  beschreibungInputKontroller,
                                  moreLines: 13,
                                  textInputAction: TextInputAction.newline),
                              checkAndSaveNewBeschreibung,
                              height: 400)
                          : null))));
    }

    cardShadowColor() {
      if (widget.event["zusage"].contains(userId)) return Colors.green;
      if (widget.event["absage"].contains(userId)) return Colors.red;

      return Colors.grey;
    }

    secretFogWithButton() {
      var isOnList = widget.event["freischalten"].contains(userId);

      return Container(
          width: cardWidth,
          height: cardHeight,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.withOpacity(0.6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                  child: Icon(
                    isOnList ? Icons.do_not_disturb_on : Icons.add_circle,
                    size: 80,
                    color: Colors.black,
                  ),
                  onTap: () {
                    askForRelease(isOnList);
                    setState(() {});
                  }),
              const SizedBox(height: 40)
            ],
          ));
    }

    createChangeableEventTags(changeState) {
      List<Widget> eventTags = [];

      for (var tag in widget.event["tags"]) {
        String tagText = isGerman
            ? global_func.changeEnglishToGerman(tag)
            : global_func.changeGermanToEnglish(tag);

        eventTags.add(InkWell(
          onTap: () async {
            removeTag(tag);
            changeState(() {});
            setState(() {});
          },
          child: Stack(
            children: [
              Container(
                  margin: const EdgeInsets.only(right: 5, top: 10),
                  padding: const EdgeInsets.only(
                      left: 5, top: 5, bottom: 5, right: 22),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  ),
                  child: Text(
                    tagText,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  )),
              const Positioned(
                  top: 20,
                  right: 14,
                  child: Icon(Icons.cancel, color: Colors.red, size: 15))
            ],
          ),
        ));
      }

      return eventTags;
    }

    changeEventTagsWindow() {
      List<String> tagItems = (isGerman
          ? global_var.reisearten + global_var.interessenListe
          : global_var.reiseartenEnglisch + global_var.interessenListeEnglisch);

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return StatefulBuilder(builder: (context, setStateEventTagWindow) {
              return CustomAlertDialog(
                  title: AppLocalizations.of(context).tagsChange,
                  children: [
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 250,
                        height: 50,
                        decoration: BoxDecoration(border: Border.all()),
                        child: DropdownButtonHideUnderline(
                            child: DropdownButton(
                                hint: Center(
                                    child: Text(AppLocalizations.of(context)
                                        .tagHinzufuegen)),
                                isExpanded: true,
                                items: tagItems.map((String item) {
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  );
                                }).toList(),
                                onChanged: (newValue) async {
                                  saveTag(newValue);
                                  setStateEventTagWindow(() {});
                                  setState(() {});
                                })),
                      )
                    ]),
                    const SizedBox(height: 20),
                    Container(
                        margin: const EdgeInsets.all(5),
                        child: Wrap(
                          children:
                              createChangeableEventTags(setStateEventTagWindow),
                        ))
                  ]);
            });
          });
    }

    eventTags() {
      List<Widget> eventTags = [];

      for (var tag in widget.event["tags"]) {
        eventTags.add(Container(
            margin: const EdgeInsets.only(right: 5, top: 5),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2),
              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            ),
            child: Text(
              isGerman
                  ? global_func.changeEnglishToGerman(tag)
                  : global_func.changeGermanToEnglish(tag),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            )));
      }

      if (eventTags.isEmpty && widget.isCreator) {
        eventTags.add(Container(
            margin: const EdgeInsets.all(10),
            child: const Text("Hier klicken um Eventlabel hinzuzufügen",
                style: TextStyle(color: Colors.grey))));
      }

      return InkWell(
        onTap: () => widget.isCreator ? changeEventTagsWindow() : null,
        child: Container(
            margin: const EdgeInsets.only(left: 10, right: 10),
            child: Wrap(children: eventTags)),
      );
    }

    return Center(
      child: Stack(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 30),
                width: cardWidth,
                height: cardHeight,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: cardShadowColor().withOpacity(0.6),
                        spreadRadius: 12,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ]),
                child: ListView(
                  controller: _scrollController,
                  shrinkWrap: true,
                  children: [
                    bildAndTitleBox(),
                    const SizedBox(height: 20),
                    creatorChangeHintBox(),
                    fremdesEventBox(),
                    ShowDatetimeBox(
                        event: widget.event, isCreator: widget.isCreator),
                    timeZoneInformation(),
                    if (isOffline) locationInformation(),
                    if (!isOffline && !widget.isCreator)
                      eventInformationRow(
                          AppLocalizations.of(context).meinDatum,
                          convertEventDateIntoMyDate(),
                          null),
                    if (widget.isApproved || widget.isPublic)
                      mapAndLinkInformation(),
                    if (widget.isApproved || widget.isPublic)
                      intervalInformation(),
                    sprachenInformation(),
                    if (widget.isApproved || widget.isPublic)
                      eventBeschreibung(),
                    eventTags()
                  ],
                ),
              ),
              if (moreContent)
                const Positioned.fill(
                  bottom: 35,
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Icon(Icons.arrow_downward)),
                )
            ],
          ),
          if (!widget.isApproved && !widget.isPublic) secretFogWithButton(),
          if (!widget.isCreator)
            InteresseButton(
              hasIntereset: widget.event["interesse"].contains(userId),
              id: widget.event["id"],
            ),
          CardFeet(
              organisator: widget.event["erstelltVon"],
              event: widget.event,
              eventZusage: widget.event["zusage"],
              width: cardWidth),
        ],
      ),
    );
  }
}

//ignore: must_be_immutable
class ShowDatetimeBox extends StatefulWidget {
  Map event;
  bool isCreator;

  ShowDatetimeBox({Key key, this.event, this.isCreator}) : super(key: key);

  @override
  _ShowDatetimeBoxState createState() => _ShowDatetimeBoxState();
}

class _ShowDatetimeBoxState extends State<ShowDatetimeBox> {
  bool isSingeDay;
  DateButton wannDateInputButton;
  DateButton wannTimeInputButton;
  DateButton bisDateInputButton = DateButton(getDate: true);
  DateButton bisTimeInputButton = DateButton();

  saveChanges() async {
    var wannDate =
        wannDateInputButton.eventDatum ?? DateTime.parse(widget.event["wann"]);
    var wannTime =
        wannTimeInputButton.uhrZeit ?? DateTime.parse(widget.event["wann"]);
    var newWannDate = DateTime(wannDate.year, wannDate.month, wannDate.day,
            wannTime.hour, wannTime.minute)
        .toString()
        .substring(0, 16);
    var newBisDate;

    if (!isSingeDay) {
      var bisDate = bisDateInputButton.eventDatum;
      var bisTime = bisTimeInputButton.uhrZeit;

      if (bisDate == null) {
        return customSnackbar(
            context, AppLocalizations.of(context).eingebenBisTagEvent);
      }

      if (bisTime == null) {
        return customSnackbar(
            context, AppLocalizations.of(context).eingebenBisUhrzeitEvent);
      }

      newBisDate = DateTime(bisDate.year, bisDate.month, bisDate.day,
              bisTime.hour, bisTime.minute)
          .toString()
          .substring(0, 16);
    }

    updateHiveEvent(widget.event["id"], "wann", "newWannDate");
    updateHiveEvent(widget.event["id"], "bis", "newBisDate");

    EventDatabase().update("wann = '$newWannDate', bis = '$newBisDate'",
        "WHERE id = '${widget.event["id"]}'");

    setState(() {
      widget.event["wann"] = newWannDate;
      widget.event["bis"] = newBisDate;
    });
    Navigator.pop(context);
  }

  changeWindowMainButtons() {
    if (isSingeDay) {
      return Column(children: [
        wannDateInputButton,
        const SizedBox(height: 20),
        wannTimeInputButton,
        const SizedBox(height: 10)
      ]);
    } else if (!isSingeDay) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Column(children: [
          const Text("Event start"),
          const SizedBox(height: 5),
          wannDateInputButton,
          wannTimeInputButton
        ]),
        Column(children: [
          const Text("Event ende"),
          const SizedBox(height: 5),
          bisDateInputButton,
          bisTimeInputButton
        ])
      ]);
    }
  }

  openChangeWindow() {
    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
              title: AppLocalizations.of(context).eventDatumAendern,
              height: 300,
              children: [
                const SizedBox(height: 20),
                changeWindowMainButtons(),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                      child: Text(AppLocalizations.of(context).abbrechen,
                          style: TextStyle(fontSize: fontsize)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                        child: Text(AppLocalizations.of(context).speichern,
                            style: TextStyle(fontSize: fontsize)),
                        onPressed: () => saveChanges()),
                  ]),
                )
              ]);
        });
  }

  createInhaltText() {
    List wannDatetimeList = widget.event["wann"].split(" ");
    List wannDateList = wannDatetimeList[0].split("-");
    List wannTimeList = wannDatetimeList[1].split(":");

    if (!isSingeDay) {
      var bisDatetimeList = widget.event["bis"]?.split(" ");
      var bisDateText = "?";
      var bisTimeText = "?";

      if (bisDatetimeList != null) {
        List bisDateList = bisDatetimeList[0].split("-");
        List bisTimeList = bisDatetimeList[1]?.split(":");

        bisDateText = bisDateList.reversed.join(".");
        bisTimeText = bisTimeList.take(2).join(":");
      }

      return wannDateList.last +
          " - " +
          bisDateText +
          "\n " +
          wannTimeList.take(2).join(":") +
          " - " +
          bisTimeText;
    } else {
      return wannDateList.reversed.join(".") +
          " " +
          wannTimeList.take(2).join(":");
    }
  }

  @override
  void initState() {
    wannDateInputButton = DateButton(
      getDate: true,
      eventDatum: DateTime.parse(widget.event["wann"]),
    );
    wannTimeInputButton = DateButton(
        uhrZeit: TimeOfDay(
            hour: int.parse(widget.event["wann"].split(" ")[1].split(":")[0]),
            minute:
                int.parse(widget.event["wann"].split(" ")[1].split(":")[1])));
    bisDateInputButton = DateButton(
      getDate: true,
      eventDatum: widget.event["bis"] != null
          ? DateTime.parse(widget.event["bis"])
          : null,
    );
    bisTimeInputButton = DateButton(
        uhrZeit: widget.event["bis"] != null
            ? TimeOfDay(
                hour:
                    int.parse(widget.event["bis"].split(" ")[1].split(":")[0]),
                minute:
                    int.parse(widget.event["bis"].split(" ")[1].split(":")[1]))
            : null);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    isSingeDay = widget.event["eventInterval"] != global_var.eventInterval[2] &&
        widget.event["eventInterval"] != global_var.eventIntervalEnglisch[2];

    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      child: InkWell(
          onTap: !widget.isCreator ? null : () => openChangeWindow(),
          child: Row(
            children: [
              Text(AppLocalizations.of(context).datum + " ",
                  style: TextStyle(
                      fontSize: fontsize, fontWeight: FontWeight.bold)),
              const Expanded(child: SizedBox.shrink()),
              SizedBox(
                width: 200,
                child: Text(
                  createInhaltText(),
                  style: TextStyle(fontSize: fontsize, color: Colors.black),
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.end,
                ),
              )
            ],
          )),
    );
  }
}

//ignore: must_be_immutable
class DateButton extends StatefulWidget {
  var uhrZeit;
  var eventDatum;
  var getDate;

  DateButton({Key key, this.eventDatum, this.uhrZeit, this.getDate = false})
      : super(key: key);

  @override
  _DateButtonState createState() => _DateButtonState();
}

class _DateButtonState extends State<DateButton> {
  dateBox() {
    var dateString = AppLocalizations.of(context).datumAuswaehlen;
    if (widget.eventDatum != null) {
      var dateFormat = DateFormat('dd.MM.yyyy');
      var dateTime = DateTime(widget.eventDatum.year, widget.eventDatum.month,
          widget.eventDatum.day);
      dateString = dateFormat.format(dateTime);
    }

    return ElevatedButton(
      child: Text(dateString),
      onPressed: () async {
        widget.eventDatum = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(DateTime.now().year + 2));

        setState(() {});
      },
    );
  }

  timeBox() {
    return ElevatedButton(
      child: Text(widget.uhrZeit == null
          ? AppLocalizations.of(context).uhrzeitAuswaehlen
          : widget.uhrZeit.format(context)),
      onPressed: () async {
        widget.uhrZeit = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 12, minute: 00),
        );

        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: widget.getDate ? dateBox() : timeBox(),
    );
  }
}

//ignore: must_be_immutable
class InteresseButton extends StatefulWidget {
  bool hasIntereset;
  final String id;

  InteresseButton({Key key, this.hasIntereset, this.id}) : super(key: key);

  @override
  _InteresseButtonState createState() => _InteresseButtonState();
}

class _InteresseButtonState extends State<InteresseButton> {
  var color = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 25,
      right: 28,
      child: GestureDetector(
          onTap: () async {
            var myInterestedEvents =
                Hive.box('secureBox').get("interestEvents") ?? [];
            var eventData = getEventFromHive(widget.id);
            var myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];
            widget.hasIntereset = !widget.hasIntereset;

            if (widget.hasIntereset) {
              eventData["interesse"].add(userId);
              myInterestedEvents.add(eventData);
              EventDatabase().update(
                  "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
                  "WHERE id ='${widget.id}'");

              myGroupChats.add(getChatGroupFromHive(widget.id));
              ChatGroupsDatabase().updateChatGroup(
                  "users = JSON_MERGE_PATCH(users, '${json.encode({
                        userId: {"newMessages": 0}
                      })}')",
                  "WHERE connected LIKE '%${widget.id}%'");
            } else {
              eventData["interesse"].remove(userId);
              myInterestedEvents
                  .removeWhere((event) => event["id"] == widget.id);
              EventDatabase().update(
                  "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
                  "WHERE id ='${widget.id}'");

              myGroupChats.removeWhere(
                  (chatGroup) => chatGroup["connected"].contains(widget.id));
              ChatGroupsDatabase().updateChatGroup(
                  "users = JSON_REMOVE(users, '\$.$userId')",
                  "WHERE connected LIKE '%${widget.id}%'");
            }

            setState(() {});
          },
          child: Icon(
            Icons.favorite,
            color: widget.hasIntereset ? Colors.red : Colors.black,
            size: 30,
          )),
    );
  }
}

//ignore: must_be_immutable
class CardFeet extends StatefulWidget {
  String organisator;
  var event;
  double width;
  var eventZusage;

  CardFeet(
      {Key key, this.organisator, this.width, this.event, this.eventZusage})
      : super(key: key);

  @override
  _CardFeetState createState() => _CardFeetState();
}

class _CardFeetState extends State<CardFeet> {
  Map organisatorProfil;
  var ownName = FirebaseAuth.instance.currentUser.displayName;
  var teilnehmerAnzahl = "";

  @override
  void initState() {
    organisatorProfil = getProfilFromHive(profilId: widget.organisator);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    showTeilnehmerWindow() {
      var zusagenIds = widget.event["zusage"];
      var allProfils = Hive.box("secureBox").get("profils");
      var zusagenProfils = [];
      List<Widget> zusagenNameBoxes = [];

      for (var profilId in zusagenIds) {
        for (var profil in allProfils) {
          if (profil["id"] == profilId) {
            zusagenProfils.add(profil);
            break;
          }
        }
      }

      for (var member in zusagenProfils) {
        zusagenNameBoxes.add(InkWell(
            onTap: () {
              global_func.changePage(
                  context,
                  ShowProfilPage(
                    profil: member,
                  ));
            },
            child: Container(
                margin: const EdgeInsets.all(10),
                child: Text(
                  member["name"],
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ))));
      }

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).teilnehmer,
              children: zusagenNameBoxes,
            );
          });
    }

    return Positioned(
      bottom: 25,
      left: 30,
      child: Container(
        padding: const EdgeInsets.only(right: 20),
        width: widget.width,
        child: Row(
          children: [
            InkWell(
              child: Text(AppLocalizations.of(context).teilnehmer,
                  style: TextStyle(
                      fontSize: fontsize,
                      color: Theme.of(context).colorScheme.secondary)),
              onTap: () => showTeilnehmerWindow(),
            ),
            InkWell(
              child: Text(widget.eventZusage.length.toString(),
                  style: TextStyle(
                      fontSize: fontsize,
                      color: Theme.of(context).colorScheme.secondary)),
              onTap: () => showTeilnehmerWindow(),
            ),
            const Expanded(child: SizedBox()),
            InkWell(
              child: Text(organisatorProfil["name"] ?? "",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: fontsize)),
              onTap: () {
                global_func.changePage(
                    context,
                    ShowProfilPage(
                      profil: organisatorProfil,
                    ));
              },
            )
          ],
        ),
      ),
    );
  }
}
