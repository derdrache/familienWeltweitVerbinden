import 'dart:convert';

import 'package:familien_suche/widgets/custom_like_button.dart';
import 'package:familien_suche/widgets/windowConfirmCancelBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:translator/translator.dart';

import '../../../functions/user_speaks_german.dart';
import '../../../global/global_functions.dart' as global_func;
import '../../../global/profil_sprachen.dart';
import '../../../global/variablen.dart';
import '../../../services/notification.dart';
import '../../../widgets/automatic_translation_notice.dart';
import '../../../widgets/layout/ownIconButton.dart';
import '../../../windows/dialog_window.dart';
import '../../../widgets/google_autocomplete.dart';
import '../../../services/database.dart';
import '../../../global/variablen.dart' as global_var;
import '../../../widgets/layout/custom_dropdown_button.dart';
import '../../../widgets/layout/custom_multi_select.dart';
import '../../../widgets/layout/custom_snackbar.dart';
import '../../../widgets/layout/custom_text_input.dart';
import '../../show_profil.dart';
import '../location/location_details/information_main.dart';
import 'meetup_image_galerie.dart';
import '../../../widgets/text_with_hyperlink_detection.dart';

var userId = FirebaseAuth.instance.currentUser!.uid;
var isWebDesktop = kIsWeb &&
    (defaultTargetPlatform != TargetPlatform.iOS ||
        defaultTargetPlatform != TargetPlatform.android);
double fontsize = isWebDesktop ? 12 : 16;

//ignore: must_be_immutable
class MeetupCardDetails extends StatefulWidget {
  Map meetupData;
  bool offlineMeetup;
  bool isCreator;
  bool isApproved;
  bool isPublic;

  MeetupCardDetails(
      {Key? key,
      required this.meetupData,
      this.offlineMeetup = true,
      this.isApproved = false})
      : isCreator = meetupData["erstelltVon"] == userId,
        isPublic =
            meetupData["art"] == "öffentlich" || meetupData["art"] == "public",
        super(key: key);

  @override
  State<MeetupCardDetails> createState() => _MeetupCardDetailsState();
}

class _MeetupCardDetailsState extends State<MeetupCardDetails> {
  final _scrollController = ScrollController();
  bool moreContent = false;
  final translator = GoogleTranslator();
  TextEditingController changeTextInputController = TextEditingController();
  var ortAuswahlBox = GoogleAutoComplete();
  var beschreibungInputKontroller = TextEditingController();
  late CustomDropdownButton changeDropdownInput;
  late CustomDropdownButton timeZoneDropdown;
  late CustomMultiTextForm changeMultiDropdownInput;
  bool chooseCurrentLocation = false;
  var ownProfil = Hive.box('secureBox').get("ownProfil");
  late bool userSpeakGerman;

  @override
  void initState() {
    userSpeakGerman = getUserSpeaksGerman();
    beschreibungInputKontroller.text = widget.meetupData["beschreibung"];

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
      customSnackBar(
          context, AppLocalizations.of(context)!.meetupInteresseZurueckgenommen,
          color: Colors.green);

      widget.meetupData["freischalten"].remove(userId);

      MeetupDatabase().update(
          "freischalten = JSON_REMOVE(freischalten, JSON_UNQUOTE(JSON_SEARCH(freischalten, 'one', '$userId'))),"
              "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id ='${widget.meetupData["id"]}'");
    } else {
      customSnackBar(
          context, AppLocalizations.of(context)!.meetupInteresseMitgeteilt,
          color: Colors.green);

      widget.meetupData["freischalten"].add(userId);

      MeetupDatabase().update(
          "freischalten = JSON_ARRAY_APPEND(freischalten, '\$', '$userId'),"
              "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id ='${widget.meetupData["id"]}'");

      prepareMeetupNotification(
          meetupId: widget.meetupData["id"],
          toId: widget.meetupData["erstelltVon"],
          meetupName: widget.meetupData["name"],
          typ: "freigeben");
    }

    updateHiveMeetup(widget.meetupData["id"], "freischalten",
        widget.meetupData["freischalten"]);
  }

  convertMeetupDateIntoMyDate() {
    int meetupZeitzone = widget.meetupData["zeitzone"];
    int deviceZeitzone = DateTime.now().timeZoneOffset.inHours;
    var meetupBeginn = widget.meetupData["wann"];

    meetupBeginn = DateTime.parse(meetupBeginn)
        .add(Duration(hours: deviceZeitzone - meetupZeitzone));

    var ownDate =
        meetupBeginn.toString().split(" ")[0].split("-").reversed.join(".");
    var ownTime =
        meetupBeginn.toString().split(" ")[1].toString().substring(0, 5);

    return "$ownDate $ownTime";
  }

  saveTag(newValue) {
    if (widget.meetupData["tags"]
            .contains(global_func.changeGermanToEnglish(newValue)) ||
        widget.meetupData["tags"]
            .contains(global_func.changeEnglishToGerman(newValue))) return;

    widget.meetupData["tags"].add(newValue);

    updateHiveMeetup(
        widget.meetupData["id"], "tags", widget.meetupData["tags"]);

    MeetupDatabase().update("tags = JSON_ARRAY_APPEND(tags, '\$', '$newValue')",
        "WHERE id = '${widget.meetupData["id"]}'");
  }

  removeTag(tag) {
    widget.meetupData["tags"].remove(tag);

    updateHiveMeetup(
        widget.meetupData["id"], "tags", widget.meetupData["tags"]);

    MeetupDatabase().update(
        "tags = JSON_REMOVE(tags, JSON_UNQUOTE(JSON_SEARCH(tags, 'one', '$tag')))",
        "WHERE id = '${widget.meetupData["id"]}'");
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

    var meetupId = widget.meetupData["id"];
    var meetupData = getMeetupFromHive(meetupId);

    meetupData["name"] = newName;
    meetupData["nameGer"] = newName;
    meetupData["nameEng"] = newName;

    translateAndSaveTitle(Map.of(meetupData));

    return true;
  }

  translateAndSaveTitle(meetupData) async {
    String newTitle = meetupData["name"];
    var languageCheck = await translator.translate(newTitle);
    bool titleIsGerman = languageCheck.sourceLanguage.code == "de";

    if (titleIsGerman) {
      meetupData["nameGer"] = newTitle;
      var translation = await descriptionTranslation(newTitle, "auto");
      meetupData["beschreibungEng"] =
          translation + automaticTranslationEng;
    } else {
      meetupData["nameEng"] = newTitle;
      var translation = await descriptionTranslation(newTitle, "de");
      meetupData["nameGer"] = translation + automaticTranslationGer;
    }

    String name = meetupData["name"].replaceAll("'", "''");
    String nameGer = meetupData["nameGer"].replaceAll("'", "''");
    String nameEng = meetupData["nameEng"].replaceAll("'", "''");

    MeetupDatabase().update(
        "name = '$name', nameGer = '$nameGer', nameEng = '$nameEng'",
        "WHERE id = '${widget.meetupData["id"]}'");
  }

  checkAndSaveNewBeschreibung() async {
    var newBeschreibung = beschreibungInputKontroller.text;

    if (newBeschreibung.isEmpty) return false;

    var meetupId = widget.meetupData["id"];
    var meetupData = getMeetupFromHive(meetupId);

    meetupData["beschreibung"] = newBeschreibung;
    meetupData["beschreibungGer"] = newBeschreibung;
    meetupData["beschreibungEng"] = newBeschreibung;

    translateAndSaveBeschreibung(Map.of(meetupData));

    return true;
  }

  translateAndSaveBeschreibung(meetupData) async {
    var newBeschreibung = meetupData["beschreibung"];
    var languageCheck = await translator.translate(newBeschreibung);
    bool descriptionIsGerman = languageCheck.sourceLanguage.code == "de";

    if (descriptionIsGerman) {
      meetupData["beschreibungGer"] = newBeschreibung;
      var translation = await descriptionTranslation(newBeschreibung, "auto");
      meetupData["beschreibungEng"] = translation;
    } else {
      meetupData["beschreibungEng"] = newBeschreibung;
      var translation = await descriptionTranslation(newBeschreibung, "de");
      meetupData["beschreibungGer"] = translation;
    }

    String beschreibung = meetupData["beschreibung"].replaceAll("'", "''");
    String beschreibungGer =
        meetupData["beschreibungGer"].replaceAll("'", "''");
    String beschreibungEng =
        meetupData["beschreibungEng"].replaceAll("'", "''");

    await MeetupDatabase().update(
        "beschreibung = '$beschreibung', beschreibungGer = '$beschreibungGer',beschreibungEng = '$beschreibungEng'",
        "WHERE id = '${meetupData["id"]}'");
  }

  checkAndSaveNewTimeZone() {
    String newTimeZone = timeZoneDropdown.getSelected();

    if (newTimeZone.isEmpty) return false;

    widget.meetupData["zeitzone"] = newTimeZone;
    updateHiveMeetup(widget.meetupData["id"], "zeitzone", newTimeZone);
    MeetupDatabase().update(
        "zeitzone = '$newTimeZone'", "WHERE id = '${widget.meetupData["id"]}'");

    return true;
  }

  checkAndSaveNewLocation() {
    Map newLocation = ortAuswahlBox.googleSearchResult!;

    if (newLocation["city"].isEmpty) return false;

    updateHiveMeetup(widget.meetupData["id"], "stadt", newLocation["city"]);
    updateHiveMeetup(
        widget.meetupData["id"], "land", newLocation["countryname"]);
    updateHiveMeetup(widget.meetupData["id"], "latt", newLocation["latt"]);
    updateHiveMeetup(widget.meetupData["id"], "longt", newLocation["longt"]);
    StadtinfoDatabase().addNewCity(newLocation);

    newLocation["city"] = newLocation["city"].replaceAll("'", "''");
    newLocation["countryname"] =
        newLocation["countryname"].replaceAll("'", "''");
    MeetupDatabase().updateLocation(widget.meetupData["id"], newLocation);

    return true;
  }

  checkAndSaveNewMapAndLink() {
    String newLink = changeTextInputController.text;

    if (newLink.isEmpty) return false;

    if (!global_func.isLink(newLink)) {
      customSnackBar(context, AppLocalizations.of(context)!.eingabeKeinLink);
      return;
    }

    widget.meetupData["link"] = newLink;
    updateHiveMeetup(widget.meetupData["id"], "link", newLink);
    MeetupDatabase()
        .update("link = '$newLink'", "WHERE id = '${widget.meetupData["id"]}'");

    return true;
  }

  checkAndSaveNewInterval() {
    String newInterval = changeDropdownInput.getSelected();

    if (newInterval.isEmpty) return false;

    widget.meetupData["eventInterval"] = newInterval;
    widget.meetupData["bis"] = DateTime.parse(widget.meetupData["wann"])
        .add(const Duration(days: 1))
        .toString();
    MeetupDatabase().update(
        "eventInterval = '$newInterval'",
        "bis = '${widget.meetupData["bis"]}'"
            "WHERE id = '${widget.meetupData["id"]}'");

    return true;
  }

  checkAndSaveNewSprache() {
    List newSprache = changeMultiDropdownInput.getSelected();

    if (newSprache.isEmpty) return false;

    widget.meetupData["sprache"] = newSprache;
    updateHiveMeetup(widget.meetupData["id"], "sprache", newSprache);
    MeetupDatabase().update("sprache = '${jsonEncode(newSprache)}'",
        "WHERE id = '${widget.meetupData["id"]}'");

    return true;
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 500) screenWidth = kIsWeb ? 350 : 500;
    double cardWidth = screenWidth / 1.12;
    double cardHeight = screenHeight / 1.4;
    bool isOffline = widget.meetupData["typ"] == global_var.meetupTyp[0] ||
        widget.meetupData["typ"] == global_var.meetupTypEnglisch[0];
    ortAuswahlBox.hintText = AppLocalizations.of(context)!.neueStadtEingeben;
    widget.meetupData["eventInterval"] = userSpeakGerman
        ? global_func.changeEnglishToGerman(widget.meetupData["eventInterval"])
        : global_func.changeGermanToEnglish(widget.meetupData["eventInterval"]);

    creatorChangeHintBox() {
      if (!widget.isCreator) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Center(
          child: Text(AppLocalizations.of(context)!.antippenZumAendern,
              style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    fremdesMeetupBox() {
      var fremdesMeetup = widget.meetupData["ownEvent"] == 0;

      if (!fremdesMeetup || widget.isCreator) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(10),
        width: screenWidth * 0.8,
        child: Text(AppLocalizations.of(context)!.nichtErstellerMeetup,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            maxLines: 2),
      );
    }

    meetupInformationRow(rowTitle, rowData, changeWindow,
        {bodyColor = Colors.black}) {
      return Container(
          margin: const EdgeInsets.only(left: 10, right: 10, top: 5),
          child: Row(
            children: [
              Text(rowTitle,
                  style: TextStyle(
                      fontSize: fontsize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
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
      if (!widget.isCreator) return;

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(title: title, height: height, children: [
              inputWidget,
              WindowConfirmCancelBar(
                confirmTitle: AppLocalizations.of(context)!.speichern,
                onConfirm: () async{
                  bool saveSuccess = await saveFunction();

                  if (!saveSuccess && context.mounted) {
                    customSnackBar(context,
                        AppLocalizations.of(context)!.keineEingabe);
                    return;
                  }

                  changeTextInputController = TextEditingController();
                  setState(() {});
                  if (context.mounted) Navigator.pop(context);
                },
              )
            ]);
          });
    }

    changeOrOpenLinkWindow() async {
      final RenderBox overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;

      await showMenu(
        context: context,
        position: RelativeRect.fromRect(
            Offset(MediaQuery.of(context).size.width - 60,
                    MediaQuery.of(context).size.height / 1.6) &
                const Size(40, 40),
            // smaller rect, the touch area
            Offset.zero & overlay.size // Bigger rect, the entire screen
            ),
        items: [
          PopupMenuItem(
              child: Text(AppLocalizations.of(context)!.linkBearbeiten),
              onTap: () {
                Future.delayed(
                    const Duration(seconds: 0),
                    () => openChangeWindow(
                        AppLocalizations.of(context)!.meetupMapLinkAendern,
                        CustomTextInput(
                            AppLocalizations.of(context)!
                                .neuenKartenlinkEingeben,
                            changeTextInputController),
                        checkAndSaveNewMapAndLink));
              }),
          PopupMenuItem(
            child: Text(AppLocalizations.of(context)!.linkOeffnen),
            onTap: () {
              Navigator.pop(context);
              global_func.openURL(widget.meetupData["link"]);
            },
          ),
        ],
        elevation: 8.0,
      );
    }

    nameInformation() {
      String title = widget.meetupData["title"];

      return InkWell(
        onTap: () => openChangeWindow(
            AppLocalizations.of(context)!.meetupNameAendern,
            CustomTextInput(AppLocalizations.of(context)!.neuenNamenEingeben,
                changeTextInputController,
                maxLength: 40),
            checkAndSaveNewName),
        child: Text(title.isNotEmpty ? title : widget.meetupData["name"],
            style: TextStyle(
                fontSize: fontsize + 8,
                fontWeight: FontWeight.bold,
                color: Colors.black),
            textAlign: TextAlign.center),
      );
    }

    bildAndTitleBox() {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Stack(
            children: [
              MeetupImageGalerie(
                isCreator: widget.isCreator,
                meetupData: widget.meetupData,
              ),
              if(widget.isCreator) Positioned(
                  right: 0, top: 0,
                  child: Banner(
                      message: AppLocalizations.of(context)!.besitzer,
                      location: BannerLocation.topEnd,
                      color: Theme.of(context).colorScheme.secondary

                  ))
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
      timeZoneDropdown = CustomDropdownButton(
          items: global_var.eventZeitzonen,
          selected: widget.meetupData["zeitzone"].toString());

      return meetupInformationRow(
        AppLocalizations.of(context)!.zeitzone,
        "GMT ${widget.meetupData["zeitzone"]}",
        () => openChangeWindow(
            AppLocalizations.of(context)!.meetupZeitzoneAendern,
            timeZoneDropdown,
            checkAndSaveNewTimeZone),
      );
    }

    openLocationChangeWindow() {
      bool isWorldwide = widget.meetupData["stadt"] == "worldwide" ||
          widget.meetupData["stadt"] == "Weltweit";

      if (!widget.isCreator && !isWorldwide) {
        global_func.changePage(context,
            LocationInformationPage(ortName: widget.meetupData["stadt"], ortLatt: widget.meetupData["latt"],));
        return;
      }

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
                  title: AppLocalizations.of(context)!.meetupStadtAendern,
                  height: 400,
                  children: [
                    ortAuswahlBox,
                    Container(
                      margin: const EdgeInsets.only(left: 5, right: 5),
                      child: Row(
                        children: [
                          Text(AppLocalizations.of(context)!
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
                    WindowConfirmCancelBar(
                      confirmTitle: AppLocalizations.of(context)!.speichern,
                      onConfirm: (){
                        setState(() {
                          checkAndSaveNewLocation();
                        });
                      },
                    )
                  ]);
            });
          });
    }

    locationInformation() {
      return meetupInformationRow(
          AppLocalizations.of(context)!.ort,
          widget.meetupData["stadt"] + ", " + widget.meetupData["land"],
          () => openLocationChangeWindow());
    }

    mapAndLinkInformation() {
      return meetupInformationRow(
          isOffline ? "Map: " : "Link: ", widget.meetupData["link"], () {
        if (widget.isCreator) changeOrOpenLinkWindow();
        if (!widget.isCreator) global_func.openURL(widget.meetupData["link"]);
      }, bodyColor: Theme.of(context).colorScheme.secondary);
    }

    intervalInformation() {
      changeDropdownInput = CustomDropdownButton(
          items: userSpeakGerman
              ? global_var.meetupInterval
              : global_var.meetupIntervalEnglisch,
          selected: widget.meetupData["eventInterval"]);

      return meetupInformationRow(
          "Interval",
          widget.meetupData["eventInterval"],
          () => openChangeWindow(
              AppLocalizations.of(context)!.meetupIntervalAendern,
              changeDropdownInput,
              checkAndSaveNewInterval));
    }

    sprachenInformation() {
      var data = userSpeakGerman
          ? global_func
              .changeEnglishToGerman(widget.meetupData["sprache"])
              .join(", ")
          : global_func
              .changeGermanToEnglish(widget.meetupData["sprache"])
              .join(", ");
      changeMultiDropdownInput = CustomMultiTextForm(
        selected: data.split(", "),
        hintText: "Sprachen auswählen",
        auswahlList: userSpeakGerman
            ? ProfilSprachen().getAllGermanLanguages()
            : ProfilSprachen().getAllEnglishLanguages(),
      );

      return meetupInformationRow(
          AppLocalizations.of(context)!.sprache,
          data,
          () => openChangeWindow(
              AppLocalizations.of(context)!.meetupSpracheAendern,
              changeMultiDropdownInput,
              checkAndSaveNewSprache,
              height: 600));
    }

    meetupBeschreibung() {
      bool meetupIsGerman = widget.meetupData["originalSprache"] == "de";
      bool showOriginal = (meetupIsGerman && userSpeakGerman) || (!meetupIsGerman && !userSpeakGerman);
      String discription = widget.meetupData["discription"];

      return Container(
          margin:
              const EdgeInsets.all(10),
          child: Center(
              child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 50.0,
                  ),
                  child: Column(
                    children: [
                      TextWithHyperlinkDetection(
                          text: discription.isNotEmpty
                              ? discription
                              : widget.meetupData["beschreibung"],
                          withoutActiveHyperLink: widget.isCreator,
                          onTextTab: widget.isCreator
                              ? () => openChangeWindow(
                                  AppLocalizations.of(context)!
                                      .meetupBeschreibungAendern,
                                  CustomTextInput(
                                      AppLocalizations.of(context)!
                                          .neueBeschreibungEingeben,
                                      beschreibungInputKontroller,
                                      moreLines: 8,
                                      textInputAction: TextInputAction.newline),
                                  checkAndSaveNewBeschreibung,)
                              : null),
                      AutomaticTranslationNotice(translated: !showOriginal && !widget.isCreator,),
                    ],
                  ))));
    }

    cardShadowColor() {
      if (widget.meetupData["zusage"].contains(userId)) return Colors.green;
      if (widget.meetupData["absage"].contains(userId)) return Colors.red;

      return Colors.grey;
    }

    secretFogWithButton() {
      var isOnList = widget.meetupData["freischalten"].contains(userId);

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
              OwnIconButton(
                icon: isOnList ? Icons.do_not_disturb_on : Icons.add_circle,
                size: 80,
                color: Colors.black,
                tooltipText: isOnList
                    ? AppLocalizations.of(context)!
                        .tooltipRemoveMeetupInformationRequest
                    : AppLocalizations.of(context)!.tooltipGetMeetupInformation,
                onPressed: () {
                  askForRelease(isOnList);
                  setState(() {});
                },
              ),
              const SizedBox(height: 40)
            ],
          ));
    }

    createChangeableMeetupTags(changeState) {
      List meetupTags = [];

      for (var tag in widget.meetupData["tags"]) {
        String tagText = userSpeakGerman
            ? global_func.changeEnglishToGerman(tag)
            : global_func.changeGermanToEnglish(tag);

        meetupTags.add(tagText);
      }

      return meetupTags;
    }

    changeMeetupTagsWindow() {
      List<String> tagItems = (userSpeakGerman
          ? global_var.reisearten + global_var.interessenListe
          : global_var.reiseartenEnglisch + global_var.interessenListeEnglisch);
      CustomMultiTextForm tagSelection = CustomMultiTextForm(
        auswahlList: tagItems,
        selected: createChangeableMeetupTags(null),
      );

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return StatefulBuilder(builder: (context, setStateMeetupTagWindow) {
              tagSelection.onConfirm = () {
                List selectedTags = tagSelection.getSelected();

                widget.meetupData["tags"] = selectedTags;

                updateHiveMeetup(widget.meetupData["id"], "tags", selectedTags);

                MeetupDatabase().update("tags = '${jsonEncode(selectedTags)}'",
                    "WHERE id = '${widget.meetupData["id"]}'");

                setStateMeetupTagWindow(() {});
                setState(() {});
              };

              return CustomAlertDialog(
                  title: AppLocalizations.of(context)!.tagsChange,
                  children: [
                    tagSelection

                    /*
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 250,
                        decoration: BoxDecoration(
                            border: Border.all(width: 1),
                            borderRadius: const BorderRadius.all(Radius.circular(style.roundedCorners))
                        ),
                        child: DropdownButtonHideUnderline(
                            child: DropdownButton(
                                hint: Center(
                                    child: Text(AppLocalizations.of(context)!
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
                                  setStateMeetupTagWindow(() {});
                                  setState(() {});
                                })),)
                    ]),
                    const SizedBox(height: 20),
                    Container(
                        margin: const EdgeInsets.all(5),
                        child: Wrap(
                          children: createChangeableMeetupTags(
                              setStateMeetupTagWindow),
                        ))

                     */
                  ]);
            });
          });
    }

    meetupTagList() {
      List<Widget> meetupTags = [];

      for (var tag in widget.meetupData["tags"]) {
        meetupTags.add(Container(
            margin: const EdgeInsets.only(right: 5, top: 5),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2),
              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            ),
            child: Text(
              userSpeakGerman
                  ? global_func.changeEnglishToGerman(tag)
                  : global_func.changeGermanToEnglish(tag),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            )));
      }

      if (meetupTags.isEmpty && widget.isCreator) {
        meetupTags.add(Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(20)
            ),
            child: Center(
              child: Text(AppLocalizations.of(context)!.klickForLabel,
                  style: const TextStyle(color: Colors.grey)),
            )));
      }

      return InkWell(
        onTap: () => widget.isCreator ? changeMeetupTagsWindow() : null,
        child: Container(
            margin: const EdgeInsets.only(left: 10, right: 10),
            child: Wrap(children: meetupTags)),
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
                    fremdesMeetupBox(),
                    ShowDatetimeBox(
                        meetupData: widget.meetupData,
                        isCreator: widget.isCreator),
                    timeZoneInformation(),
                    if (isOffline) locationInformation(),
                    if (!isOffline && !widget.isCreator)
                      meetupInformationRow(
                          AppLocalizations.of(context)!.meinDatum,
                          convertMeetupDateIntoMyDate(),
                          null),
                    if (widget.isApproved || widget.isPublic)
                      mapAndLinkInformation(),
                    if (widget.isApproved || widget.isPublic)
                      intervalInformation(),
                    sprachenInformation(),
                    if (widget.isApproved || widget.isPublic)
                      meetupBeschreibung(),
                    meetupTagList()
                  ],
                ),
              ),
              MeetupArtButton(
                meetupData: widget.meetupData,
                isCreator: widget.meetupData["erstelltVon"] == userId,
                pageState: setState,
              ),
            ],
          ),
          if (!widget.isApproved && !widget.isPublic) secretFogWithButton(),
          if (!widget.isCreator) Positioned(
            top: 25,
            right: 28,
            child: CustomLikeButton(
              meetupData: widget.meetupData,
            ),
          ),
          CardFeet(
            organisator: widget.meetupData["erstelltVon"],
            meetupData: widget.meetupData,
            meetupZusage: widget.meetupData["zusage"],
            width: cardWidth,
            moreContent: moreContent,
          ),
        ],
      ),
    );
  }
}

//ignore: must_be_immutable
class ShowDatetimeBox extends StatefulWidget {
  Map meetupData;
  bool isCreator;

  ShowDatetimeBox({Key? key, required this.meetupData, required this.isCreator})
      : super(key: key);

  @override
  State<ShowDatetimeBox> createState() => _ShowDatetimeBoxState();
}

class _ShowDatetimeBoxState extends State<ShowDatetimeBox> {
  late bool isSingeDay;
  late DateButton wannDateInputButton;
  late DateButton wannTimeInputButton;
  DateButton bisDateInputButton = DateButton(getDate: true);
  DateButton bisTimeInputButton = DateButton();

  saveChanges() async {
    var wannDate = wannDateInputButton.meetupDatum ??
        DateTime.parse(widget.meetupData["wann"]);
    var wannTime = wannTimeInputButton.uhrZeit ??
        DateTime.parse(widget.meetupData["wann"]);
    var newWannDate = DateTime(wannDate.year, wannDate.month, wannDate.day,
            wannTime.hour, wannTime.minute)
        .toString()
        .substring(0, 16);
    String? newBisDate;

    if (!isSingeDay) {
      var bisDate = bisDateInputButton.meetupDatum;
      var bisTime = bisTimeInputButton.uhrZeit;

      if (bisDate == null) {
        return customSnackBar(
            context, AppLocalizations.of(context)!.eingebenBisTagMeetup);
      }

      if (bisTime == null) {
        return customSnackBar(
            context, AppLocalizations.of(context)!.eingebenBisUhrzeitMeetup);
      }

      newBisDate = DateTime(bisDate.year, bisDate.month, bisDate.day,
              bisTime.hour, bisTime.minute)
          .toString()
          .substring(0, 16);
    }

    updateHiveMeetup(widget.meetupData["id"], "wann", "newWannDate");
    updateHiveMeetup(widget.meetupData["id"], "bis", "newBisDate");

    MeetupDatabase().update("wann = '$newWannDate', bis = '$newBisDate'",
        "WHERE id = '${widget.meetupData["id"]}'");

    setState(() {
      widget.meetupData["wann"] = newWannDate;
      widget.meetupData["bis"] = newBisDate;
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
          const Text("Meetup start"),
          const SizedBox(height: 5),
          wannDateInputButton,
          wannTimeInputButton
        ]),
        Column(children: [
          const Text("Meetup ende"),
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
              title: AppLocalizations.of(context)!.meetupDatumAendern,
              height: 300,
              children: [
                const SizedBox(height: 20),
                changeWindowMainButtons(),
                const SizedBox(height: 10),
                WindowConfirmCancelBar(
                  confirmTitle: AppLocalizations.of(context)!.speichern,
                  onConfirm: () => saveChanges(),
                )
              ]);
        });
  }

  createInhaltText() {
    List wannDatetimeList = widget.meetupData["wann"].split(" ");
    List wannDateList = wannDatetimeList[0].split("-");
    List wannTimeList = wannDatetimeList[1].split(":");

    if (!isSingeDay) {
      String wannDateText = wannDateList.reversed.take(2).toList().join(".");
      var bisDatetimeList = widget.meetupData["bis"]?.split(" ");
      var bisDateText = "?";
      var bisTimeText = "?";

      if (bisDatetimeList != null) {
        List bisDateList = bisDatetimeList[0].split("-");
        List bisTimeList = bisDatetimeList[1]?.split(":");

        bisDateText = bisDateList.reversed.join(".");
        bisTimeText = bisTimeList.take(2).join(":");
      }

      return "$wannDateText - $bisDateText \n ${wannTimeList.take(2).join(":")} - $bisTimeText";
    } else {
      return "${wannDateList.reversed.join(".")} ${wannTimeList.take(2).join(":")}";
    }
  }

  @override
  void initState() {
    wannDateInputButton = DateButton(
      getDate: true,
      meetupDatum: DateTime.parse(widget.meetupData["wann"]),
    );
    wannTimeInputButton = DateButton(
        uhrZeit: TimeOfDay(
            hour: int.parse(
                widget.meetupData["wann"].split(" ")[1].split(":")[0]),
            minute: int.parse(
                widget.meetupData["wann"].split(" ")[1].split(":")[1])));
    bisDateInputButton = DateButton(
      getDate: true,
      meetupDatum: widget.meetupData["bis"] != null
          ? DateTime.parse(widget.meetupData["bis"])
          : null,
    );
    bisTimeInputButton = DateButton(
        uhrZeit: widget.meetupData["bis"] != null
            ? TimeOfDay(
                hour: int.parse(
                    widget.meetupData["bis"].split(" ")[1].split(":")[0]),
                minute: int.parse(
                    widget.meetupData["bis"].split(" ")[1].split(":")[1]))
            : null);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    isSingeDay =
        widget.meetupData["eventInterval"] != global_var.meetupInterval[2] &&
            widget.meetupData["eventInterval"] !=
                global_var.meetupIntervalEnglisch[2];

    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      child: InkWell(
          onTap: !widget.isCreator ? null : () => openChangeWindow(),
          child: Row(
            children: [
              Text("${AppLocalizations.of(context)!.datum} ",
                  style: TextStyle(
                      fontSize: fontsize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
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
  var meetupDatum;
  bool getDate;

  DateButton({Key? key, this.meetupDatum, this.uhrZeit, this.getDate = false})
      : super(key: key);

  @override
  State<DateButton> createState() => _DateButtonState();
}

class _DateButtonState extends State<DateButton> {
  dateBox() {
    var dateString = AppLocalizations.of(context)!.datumAuswaehlen;
    if (widget.meetupDatum != null) {
      var dateFormat = DateFormat('dd.MM.yyyy');
      var dateTime = DateTime(widget.meetupDatum.year, widget.meetupDatum.month,
          widget.meetupDatum.day);
      dateString = dateFormat.format(dateTime);
    }

    return ElevatedButton(
      child: Text(dateString),
      onPressed: () async {
        widget.meetupDatum = await showDatePicker(
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
          ? AppLocalizations.of(context)!.uhrzeitAuswaehlen
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
class CardFeet extends StatefulWidget {
  String organisator;
  Map meetupData;
  double width;
  List meetupZusage;
  bool moreContent;

  CardFeet({
    Key? key,
    required this.organisator,
    required this.width,
    required this.meetupData,
    required this.meetupZusage,
    required this.moreContent,
  }) : super(key: key);

  @override
  State<CardFeet> createState() => _CardFeetState();
}

class _CardFeetState extends State<CardFeet> {
  late Map? organisatorProfil;
  var ownName = FirebaseAuth.instance.currentUser!.displayName;
  var teilnehmerAnzahl = "";

  @override
  Widget build(BuildContext context) {
    organisatorProfil = getProfilFromHive(profilId: widget.organisator);

    organisatorProfil ??= {};

    showTeilnehmerWindow() {
      var zusagenIds = widget.meetupData["zusage"];
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
              title: AppLocalizations.of(context)!.teilnehmer,
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
              child: Text(AppLocalizations.of(context)!.teilnehmer,
                  style: TextStyle(
                      fontSize: fontsize,
                      color: Theme.of(context).colorScheme.secondary)),
              onTap: () => showTeilnehmerWindow(),
            ),
            InkWell(
              child: Text(widget.meetupZusage.length.toString(),
                  style: TextStyle(
                      fontSize: fontsize,
                      color: Theme.of(context).colorScheme.secondary)),
              onTap: () => showTeilnehmerWindow(),
            ),
            Expanded(
                child: widget.moreContent
                    ? const Center(
                        child: Icon(Icons.arrow_downward, size: 18,),
                      )
                    : const SizedBox.shrink()),
            InkWell(
              child: Text(organisatorProfil!["name"] ?? "",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: fontsize)),
              onTap: () {
                global_func.changePage(
                    context,
                    ShowProfilPage(
                      profil: organisatorProfil!,
                    ));
              },
            )
          ],
        ),
      ),
    );
  }
}

class MeetupArtButton extends StatefulWidget {
  final Map meetupData;
  final bool isCreator;
  final Function pageState;

  const MeetupArtButton(
      {Key? key,
      required this.meetupData,
      required this.isCreator,
      required this.pageState})
      : super(key: key);

  @override
  State<MeetupArtButton> createState() => _MeetupArtButtonState();
}

class _MeetupArtButtonState extends State<MeetupArtButton> {
  var ownProfil = Hive.box('secureBox').get("ownProfil");
  late bool userSpeakGerman;
  late CustomDropdownButton meetupTypInput;
  late IconData icon;

  saveMeetupArt() {
    String select = meetupTypInput.getSelected();

    if (select == widget.meetupData["art"]) return;

    widget.meetupData["art"] = select;

    MeetupDatabase()
        .update("art = '$select'", "WHERE id = '${widget.meetupData["id"]}'");
  }

  meetupArtInformation() {
    return SizedBox(
      height: 20,
      child: Align(
          alignment: Alignment.centerRight,
          child: IconButton(
              icon: const Icon(Icons.help, size: 20),
              tooltip: AppLocalizations.of(context)!.tooltipMehrInformationen,
              onPressed: () => showDialog(
                  context: context,
                  builder: (BuildContext buildContext) {
                    return CustomAlertDialog(
                        height: 500,
                        title:
                            AppLocalizations.of(context)!.informationMeetupArt,
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
                                  Text(
                                      AppLocalizations.of(context)!.oeffentlich,
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
                  }))),
    );
  }

  @override
  void initState() {
    userSpeakGerman = getUserSpeaksGerman();
    meetupTypInput = CustomDropdownButton(
      items:
          userSpeakGerman ? global_var.eventArt : global_var.eventArtEnglisch,
      selected: userSpeakGerman
          ? global_func.changeEnglishToGerman(widget.meetupData["art"])
          : global_func.changeGermanToEnglish(widget.meetupData["art"]),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    icon = widget.meetupData["art"] == "öffentlich" ||
            widget.meetupData["art"] == "public"
        ? Icons.lock_open
        : widget.meetupData["art"] == "privat" ||
                widget.meetupData["art"] == "private"
            ? Icons.enhanced_encryption
            : Icons.lock;

    return Positioned(
      top: -5,
      left: -5,
      child: IconButton(
          icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          onPressed: !widget.isCreator
              ? null
              : () => showDialog(
                  context: context,
                  builder: (BuildContext buildContext) {
                    return CustomAlertDialog(
                        title: AppLocalizations.of(context)!.meetupArtAendern,
                        height: 200,
                        children: [
                          meetupArtInformation(),
                          meetupTypInput,
                          WindowConfirmCancelBar(
                            confirmTitle: AppLocalizations.of(context)!
                                .speichern,
                            onConfirm: () {
                              saveMeetupArt();
                              setState(() {});
                              widget.pageState(() {});
                              Navigator.pop(context);
                            },
                          )
                        ]);
                  })),
    );
  }
}
