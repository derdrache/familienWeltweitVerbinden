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

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_func;
import '../../widgets/dialogWindow.dart';
import '../../widgets/google_autocomplete.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_var;
import '../../widgets/image_galerie.dart';
import '../../widgets/text_with_hyperlink_detection.dart';

/*
Clean Code Notize:
- ShowDataAndChangeWindow => vereinfachen :
    => getData ifs mehr zusammenfassen
    =>
- isApproved && isPublic zusammenfassen?
 */

var userId = FirebaseAuth.instance.currentUser.uid;
var isWebDesktop = kIsWeb &&
    (defaultTargetPlatform != TargetPlatform.iOS ||
        defaultTargetPlatform != TargetPlatform.android);
double fontsize = isWebDesktop ? 12 : 16;
var isGerman = kIsWeb
    ? window.locale.languageCode == "de"
    : Platform.localeName == "de_DE";

class EventCardDetails extends StatefulWidget {
  var event;
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
  final _controller = ScrollController();
  var moreContent = false;

  @override
  void initState() {
    _controller.addListener(() {
      if (_controller.position.atEdge) {
        bool isTop = _controller.position.pixels == 0;
        if (isTop) {
          moreContent = true;
        } else {
          moreContent = false;
        }
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => checkMoreContent());
    super.initState();
  }

  checkMoreContent() {
    if (_controller.position.maxScrollExtent > 0) {
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

      setState(() {
        widget.event["freischalten"].remove(userId);
      });

      EventDatabase().update(
          "freischalten = JSON_REMOVE(freischalten, JSON_UNQUOTE(JSON_SEARCH(freischalten, 'one', '$userId'))),"
              "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id ='${widget.event["id"]}'");
    } else {
      customSnackbar(
          context, AppLocalizations.of(context).eventInteresseMitgeteilt,
          color: Colors.green);

      setState(() {
        widget.event["freischalten"].add(userId);
      });

      EventDatabase().update(
          "freischalten = JSON_ARRAY_APPEND(freischalten, '\$', '$userId'),"
              "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id ='${widget.event["id"]}'");
    }
  }

  convertIntoMyDate() {
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

  addTag(changeState) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 250,
        height: 50,
        decoration: BoxDecoration(border: Border.all()),
        child: DropdownButtonHideUnderline(
            child: DropdownButton(
                hint: Center(
                    child: Text(AppLocalizations.of(context).tagHinzufuegen)),
                isExpanded: true,
                items: (isGerman
                        ? global_var.reisearten + global_var.interessenListe
                        : global_var.reiseartenEnglisch +
                            global_var.interessenListeEnglisch)
                    .map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (newValue) async {
                  if (widget.event["tags"].contains(
                          global_func.changeGermanToEnglish(newValue)) ||
                      widget.event["tags"].contains(
                          global_func.changeEnglishToGerman(newValue))) return;

                  widget.event["tags"].add(newValue);
                  changeState(() {});

                  await EventDatabase().update(
                      "tags = JSON_ARRAY_APPEND(tags, '\$', '$newValue')",
                      "WHERE id = '${widget.event["id"]}'");
                  setState(() {});
                })),
      )
    ]);
  }

  createChangeableEventTags(changeState) {
    List<Widget> eventTags = [];

    for (var tag in widget.event["tags"]) {
      eventTags.add(InkWell(
        onTap: () async {
          widget.event["tags"].remove(tag);
          changeState(() {});

          await EventDatabase().update(
              "tags = JSON_REMOVE(tags, JSON_UNQUOTE(JSON_SEARCH(tags, 'one', '$tag')))",
              "WHERE id = '${widget.event["id"]}'");
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
                  isGerman
                      ? global_func.changeEnglishToGerman(tag)
                      : global_func.changeGermanToEnglish(tag),
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
    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(builder: (context, setStateEventTagWindow) {
            return CustomAlertDialog(
                title: AppLocalizations.of(context).tagsChange,
                children: [
                  const SizedBox(height: 20),
                  addTag(setStateEventTagWindow),
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

  @override
  Widget build(BuildContext context) {
    var isAssetImage =
        widget.event["bild"].substring(0, 5) == "asset" ? true : false;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    bool isOffline = widget.event["typ"] == global_var.eventTyp[0] ||
        widget.event["typ"] == global_var.eventTypEnglisch[0];

    if (screenWidth > 500) screenWidth = kIsWeb ? 350 : 500;
    double cardWidth = screenWidth / 1.12;
    double cardHeight = screenHeight / 1.34;
    widget.event["eventInterval"] = isGerman
        ? global_func.changeEnglishToGerman(widget.event["eventInterval"])
        : global_func.changeGermanToEnglish(widget.event["eventInterval"]);

    bildAndTitleBox() {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Stack(
            children: [
              ImageGalerie(
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
                      child: ShowDataAndChangeWindow(
                          eventId: widget.event["id"],
                          windowTitle:
                              AppLocalizations.of(context).eventNameAendern,
                          rowData: widget.event["name"],
                          inputHintText:
                              AppLocalizations.of(context).neuenNamenEingeben,
                          isCreator: widget.isCreator,
                          modus: "textInput",
                          singleShow: true,
                          databaseKennzeichnung: "name")))),
        ],
      );
    }

    creatorChangeHintBox() {
      if (widget.isCreator) {
        return Center(
          child: Text(AppLocalizations.of(context).antippenZumAendern,
              style: const TextStyle(color: Colors.grey)),
        );
      }
      return const SizedBox.shrink();
    }

    fremdesEventBox() {
      var fremdesEvent = widget.event["ownEvent"] == 0;

      if (fremdesEvent && !widget.isCreator) {
        return Container(
          padding: const EdgeInsets.only(left: 10, right: 10),
          width: screenWidth * 0.8,
          child: Text(AppLocalizations.of(context).nichtErstellerEvent,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 18),
              maxLines: 2),
        );
      }

      return const SizedBox.shrink();
    }

    eventInformationBox() {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          children: [
            ShowDatetimeBox(event: widget.event, isCreator: widget.isCreator),
            const SizedBox(height: 5),
            ShowDataAndChangeWindow(
                eventId: widget.event["id"],
                windowTitle: AppLocalizations.of(context).eventZeitzoneAendern,
                rowTitle: AppLocalizations.of(context).zeitzone,
                rowData: widget.event["zeitzone"],
                inputHintText:
                    AppLocalizations.of(context).neueZeitzoneEingeben,
                isCreator: widget.isCreator,
                modus: "dropdown",
                databaseKennzeichnung: "zeitzone",
                items: global_var.eventZeitzonen),
            const SizedBox(height: 5),
            if (isOffline)
              ShowDataAndChangeWindow(
                  eventId: widget.event["id"],
                  windowTitle: AppLocalizations.of(context).eventStadtAendern,
                  rowTitle: AppLocalizations.of(context).ort,
                  rowData: widget.event["stadt"] + ", " + widget.event["land"],
                  inputHintText: AppLocalizations.of(context).neueStadtEingeben,
                  isCreator: widget.isCreator,
                  modus: "googleAutoComplete",
                  databaseKennzeichnung: "location"),
            if (!isOffline && !widget.isCreator)
              Row(
                children: [
                  Text(AppLocalizations.of(context).meinDatum,
                      style: TextStyle(
                          fontSize: fontsize, fontWeight: FontWeight.bold)),
                  const Expanded(child: SizedBox.shrink()),
                  Text(convertIntoMyDate(),
                      style: TextStyle(fontSize: fontsize))
                ],
              ),
            const SizedBox(height: 5),
            if (widget.isApproved || widget.isPublic)
              ShowDataAndChangeWindow(
                  eventId: widget.event["id"],
                  windowTitle: AppLocalizations.of(context).eventMapLinkAendern,
                  rowTitle: isOffline ? "Map: " : "Link: ",
                  rowData: widget.event["link"],
                  inputHintText:
                      AppLocalizations.of(context).neuenKartenlinkEingeben,
                  isCreator: widget.isCreator,
                  modus: "textInput",
                  databaseKennzeichnung: "link"),
            if (widget.isApproved || widget.isPublic) const SizedBox(height: 5),
            if (widget.isApproved || widget.isPublic)
              ShowDataAndChangeWindow(
                eventId: widget.event["id"],
                windowTitle: AppLocalizations.of(context).eventIntervalAendern,
                inputHintText: "",
                isCreator: widget.isCreator,
                rowTitle: "Interval",
                rowData: widget.event["eventInterval"],
                items: isGerman
                    ? global_var.eventInterval
                    : global_var.eventIntervalEnglisch,
                modus: "dropdown",
                databaseKennzeichnung: "eventInterval",
                saveFunction: () async {
                  widget.event = await EventDatabase()
                      .getData("*", "WHERE id = '${widget.event["id"]}'");
                  setState(() {});
                },
              ),
            if (widget.isApproved || widget.isPublic) const SizedBox(height: 5),
            ShowDataAndChangeWindow(
                eventId: widget.event["id"],
                windowTitle: AppLocalizations.of(context).eventSpracheAendern,
                inputHintText: "",
                isCreator: widget.isCreator,
                rowTitle: AppLocalizations.of(context).sprache,
                rowData: isGerman
                    ? global_func
                        .changeEnglishToGerman(widget.event["sprache"])
                        .join(", ")
                    : global_func
                        .changeGermanToEnglish(widget.event["sprache"])
                        .join(", "),
                items: isGerman
                    ? global_var.sprachenListe
                    : global_var.sprachenListeEnglisch,
                modus: "multiDropdown",
                databaseKennzeichnung: "sprache"),
          ],
        ),
      );
    }

    eventBeschreibung() {
      return Container(
          margin:
              const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 10),
          child: Center(
              child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: 50.0,
            ),
            child: ShowDataAndChangeWindow(
                eventId: widget.event["id"],
                windowTitle:
                    AppLocalizations.of(context).eventBeschreibungAendern,
                rowData: widget.event["beschreibung"],
                inputHintText:
                    AppLocalizations.of(context).neueBeschreibungEingeben,
                isCreator: widget.isCreator,
                modus: "textInput",
                multiLines: true,
                databaseKennzeichnung: "beschreibung"),
          )));
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
                  onTap: () => askForRelease(isOnList)),
              const Text(""),
              const SizedBox(
                height: 40,
              )
            ],
          ));
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
                  controller: _controller,
                  shrinkWrap: true,
                  children: [
                    bildAndTitleBox(),
                    const SizedBox(height: 20),
                    creatorChangeHintBox(),
                    fremdesEventBox(),
                    eventInformationBox(),
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

class ShowDataAndChangeWindow extends StatefulWidget {
  String windowTitle;
  String rowTitle;
  var rowData;
  String inputHintText;
  bool isCreator;
  List items;
  String modus;
  bool singleShow;
  bool multiLines;
  String databaseKennzeichnung;
  var oldDate;
  String eventId;
  Function saveFunction;

  ShowDataAndChangeWindow(
      {Key key,
      this.windowTitle,
      this.isCreator,
      this.rowTitle,
      this.rowData,
      this.inputHintText,
      this.items,
      this.modus,
      this.singleShow = false,
      this.multiLines = false,
      this.databaseKennzeichnung,
      this.oldDate,
      this.eventId,
      this.saveFunction})
      : super(key: key);

  @override
  _ShowDataAndChangeWindowState createState() =>
      _ShowDataAndChangeWindowState();
}

class _ShowDataAndChangeWindowState extends State<ShowDataAndChangeWindow> {
  var dropdownInput = CustomDropDownButton();
  var multiDropDownInput = CustomMultiTextForm();
  var inputKontroller = TextEditingController();
  var ortAuswahlBox = GoogleAutoComplete();
  var uhrZeitButton = DateButton();
  var datumButton = DateButton(getDate: true);
  var uhrZeit;

  @override
  void initState() {
    if (widget.rowData != String) widget.rowData = widget.rowData.toString();
    if (widget.databaseKennzeichnung != "link") {
      inputKontroller.text = widget.rowData;
    }

    dropdownInput = CustomDropDownButton(
        hintText: widget.inputHintText,
        items: widget.items,
        selected: widget.rowData);

    multiDropDownInput = CustomMultiTextForm(
      selected: widget.rowData.split(", "),
      auswahlList: widget.items,
    );

    ortAuswahlBox.hintText = widget.inputHintText;

    super.initState();
  }

  getData() {
    var data;

    if (widget.databaseKennzeichnung == "name") {
      data = inputKontroller.text;
    } else if (widget.databaseKennzeichnung == "location") {
      data = ortAuswahlBox.googleSearchResult;
    } else if (widget.databaseKennzeichnung == "link") {
      data = inputKontroller.text;
    } else if (widget.databaseKennzeichnung == "art") {
      data = dropdownInput.getSelected();
    } else if (widget.databaseKennzeichnung == "eventInterval") {
      data = dropdownInput.getSelected();
    } else if (widget.databaseKennzeichnung == "sprache") {
      data = multiDropDownInput.getSelected();
    } else if (widget.databaseKennzeichnung == "beschreibung") {
      data = inputKontroller.text;
    } else if (widget.databaseKennzeichnung == "zeitzone") {
      data = dropdownInput.getSelected();
    } else if (widget.modus == "date") {
      var date = datumButton.eventDatum ?? DateTime.parse(widget.oldDate);
      var time = uhrZeitButton.uhrZeit ?? DateTime.parse(widget.oldDate);

      data = DateTime(date.year, date.month, date.day, time.hour, time.minute)
          .toString()
          .substring(0, 16);
    }

    return data;
  }

  checkValidation(data) {
    var validationText = "";

    if (widget.databaseKennzeichnung == "name") {
      if (data.isEmpty) {
        validationText = AppLocalizations.of(context).bitteNameEingeben;
      }
      if (data.length > 40) {
        validationText = AppLocalizations.of(context).usernameZuLang;
      }
    } else if (widget.databaseKennzeichnung == "link") {
      if (data.substring(0, 4) != "http" && data.substring(0, 3) != "www") {
        validationText = AppLocalizations.of(context).eingabeKeinLink;
      }
    }

    return validationText;
  }

  changeRowData(data) {
    if (widget.databaseKennzeichnung == "location") {
      widget.rowData = data["city"] + ", " + data["countryname"];
    } else {
      widget.rowData = data;
    }
  }

  saveChanges() async {
    var data = getData();
    var errorText = checkValidation(data);

    if (!errorText.isEmpty) {
      customSnackbar(context, errorText);
      return;
    }

    changeRowData(data);

    Navigator.pop(context);

    setState(() {});

    if (widget.databaseKennzeichnung == "location") {
      await EventDatabase().updateLocation(widget.eventId, data);
      StadtinfoDatabase().addNewCity(data);
    } else {
      await EventDatabase().update("${widget.databaseKennzeichnung} = '$data'",
          "WHERE id = '${widget.eventId}'");
    }

    if (widget.saveFunction != null) widget.saveFunction();
  }

  @override
  Widget build(BuildContext context) {
    inputBox() {
      if (widget.modus == "textInput") {
        return customTextInput(widget.inputHintText, inputKontroller,
            moreLines: widget.multiLines ? 7 : 1,
            textInputAction: TextInputAction.newline);
      }
      if (widget.modus == "dropdown") return dropdownInput;
      if (widget.modus == "multiDropdown") return multiDropDownInput;
      if (widget.modus == "googleAutoComplete") return ortAuswahlBox;
    }

    openChangeWindow() {
      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
                title: widget.windowTitle,
                height: widget.multiLines ||
                        widget.modus == "googleAutoComplete" ||
                        widget.modus == "date"
                    ? 300
                    : 180,
                children: [
                  inputBox(),
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: Text(AppLocalizations.of(context).abbrechen,
                                style: TextStyle(fontSize: fontsize)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                              child: Text(
                                  AppLocalizations.of(context).speichern,
                                  style: TextStyle(fontSize: fontsize)),
                              onPressed: () => saveChanges()),
                        ]),
                  )
                ]);
          });
    }

    openLinkAskWindow() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: [
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  openChangeWindow();
                },
                child: Text(AppLocalizations.of(context).linkBearbeiten),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  if (!widget.rowData.contains("http")) {
                    widget.rowData = "http://" + widget.rowData;
                  }
                  global_func.openURL(widget.rowData);
                },
                child: Text(AppLocalizations.of(context).linkOeffnen),
              ),
            ],
          );
        },
      );
    }

    return !widget.singleShow && !widget.multiLines
        ? Row(
            children: [
              Text(widget.rowTitle + " ",
                  style: TextStyle(
                      fontSize: fontsize, fontWeight: FontWeight.bold)),
              const Expanded(child: SizedBox.shrink()),
              InkWell(
                child: SizedBox(
                  width: 200,
                  child: Text(
                    widget.databaseKennzeichnung == "zeitzone"
                        ? "GMT " + widget.rowData.toString()
                        : widget.rowData,
                    style: TextStyle(
                        fontSize: fontsize,
                        color: widget.databaseKennzeichnung != "link"
                            ? Colors.black
                            : Theme.of(context).colorScheme.secondary),
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.end,
                  ),
                ),
                onTap: widget.databaseKennzeichnung != "link"
                    ? null
                    : () {
                        if (widget.isCreator) {
                          if(widget.rowData.isEmpty){
                            openChangeWindow();
                          } else{
                            openLinkAskWindow();
                          }
                        } else {
                          if (!widget.rowData.contains("http")) {
                            widget.rowData = "http://" + widget.rowData;
                          }
                          global_func.openURL(widget.rowData);
                        }
                      },
              )
            ],
          )
        : widget.multiLines
            ? TextWithHyperlinkDetection(
                text: widget.rowData,
                onTextTab: widget.isCreator ? () => openChangeWindow() : null)
            : Text(widget.rowData,
                style: TextStyle(
                    fontSize: fontsize + 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center);
  }
}

class ShowDatetimeBox extends StatefulWidget {
  var event;
  var isCreator;

  ShowDatetimeBox({this.event, this.isCreator});

  @override
  _ShowDatetimeBoxState createState() => _ShowDatetimeBoxState();
}

class _ShowDatetimeBoxState extends State<ShowDatetimeBox> {
  var isSingeDay;
  var wannDateInputButton;
  var wannTimeInputButton;
  var bisDateInputButton = DateButton(getDate: true);
  var bisTimeInputButton = DateButton();

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
      var bisTime = bisTimeInputButton.eventDatum;

      if (bisDate == null) {
        return customSnackbar(
            context, AppLocalizations.of(context).eingebenBisTagEvent);
      } else {
        bisDate = DateTime.parse(widget.event["bis"]);
      }

      if (bisTime == null) {
        return customSnackbar(
            context, AppLocalizations.of(context).eingebenBisUhrzeitEvent);
      } else {
        bisTime = DateTime.parse(widget.event["bis"]);
      }

      newBisDate = DateTime(bisDate.year, bisDate.month, bisDate.day,
              bisTime.hour, bisTime.minute)
          .toString()
          .substring(0, 16);
    }
    await EventDatabase().update("wann = '$newWannDate', bis = '$newBisDate'",
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

    return InkWell(
        onTap: !widget.isCreator ? null : () => openChangeWindow(),
        child: Row(
          children: [
            Text(AppLocalizations.of(context).datum + " ",
                style:
                    TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold)),
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
        ));
  }
}

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
  var organisatorText = const Text("");
  Map organisatorProfil;
  var ownName = FirebaseAuth.instance.currentUser.displayName;
  var teilnehmerAnzahl = "";

  @override
  void initState() {
    setOrganisatorText();
    super.initState();
  }

  setOrganisatorText() async {
    organisatorProfil = await ProfilDatabase()
        .getData("*", "WHERE id = '${widget.organisator}'");

    organisatorText = Text(organisatorProfil["name"],
        style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: fontsize));

    setState(() {});
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
              child: organisatorText,
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
            lastDate: DateTime(DateTime.now().year + 1));

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

class InteresseButton extends StatefulWidget {
  bool hasIntereset;
  String id;

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
            widget.hasIntereset = widget.hasIntereset ? false : true;

            setState(() {});

            var interesseList = await EventDatabase()
                .getData("interesse", "WHERE id = '${widget.id}'");

            if (widget.hasIntereset) {
              interesseList.add(userId);
            } else {
              interesseList.remove(userId);
            }

            EventDatabase().update(
                "interesse = '${json.encode(interesseList)}'",
                "WHERE id = '${widget.id}'");
          },
          child: Icon(
            Icons.favorite,
            color: widget.hasIntereset ? Colors.red : Colors.black,
            size: 30,
          )),
    );
  }
}
