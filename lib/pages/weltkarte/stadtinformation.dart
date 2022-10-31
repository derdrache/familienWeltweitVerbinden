import 'dart:convert';

import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:translator/translator.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_func;
import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';
import '../../widgets/text_with_hyperlink_detection.dart';
import '../start_page.dart';

class StadtinformationsPage extends StatefulWidget {
  var ortName;
  var newEntry;

  StadtinformationsPage({this.ortName, this.newEntry, Key key}) : super(key: key);

  @override
  _StadtinformationsPageState createState() => _StadtinformationsPageState();
}

class _StadtinformationsPageState extends State<StadtinformationsPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  bool canGerman = false;
  bool canEnglish = false;
  var cityInformation = {};
  var usersCityInformation = [];
  final translator = GoogleTranslator();


  @override
  void initState() {
    var stadtinfoData = Hive.box("secureBox").get("stadtinfo");

    for (var city in stadtinfoData) {
      if (city["ort"].contains(widget.ortName)) {
        cityInformation = city;
        break;
      }
    }

    //cityInformation["familien"].remove(userId);

    //refreshCityUserInfo();

    super.initState();
  }

  refreshCityUserInfo() {
    usersCityInformation = [];
    var stadtinfoUserData = Hive.box("secureBox").get("stadtinfoUser");

    for (var city in stadtinfoUserData) {
      if (widget.ortName.contains(city["ort"])) {
        usersCityInformation.add(city);
      }
    }

    usersCityInformation = sortThumb(usersCityInformation);
  }

  setThumb(thumb, index) async {
    var infoId = usersCityInformation[index]["id"];

    if (thumb == "up") {
      if (usersCityInformation[index]["thumbUp"].contains(userId)) return;

      setState(() {
        usersCityInformation[index]["thumbUp"].add(userId);
        usersCityInformation[index]["thumbDown"].remove(userId);
      });

      var dbData = await StadtinfoUserDatabase()
          .getData("thumbUp, thumbDown", "WHERE id ='$infoId'");
      var dbThumbUpList = dbData["thumbUp"];
      var dbThumbDownList = dbData["thumbDown"];

      dbThumbUpList.add(userId);
      dbThumbDownList.remove(userId);

      await StadtinfoUserDatabase().update(
          "thumbUp = '${jsonEncode(dbThumbUpList)}', thumbDown = '${jsonEncode(dbThumbDownList)}'",
          "WHERE id ='$infoId'");
    } else if (thumb == "down") {
      if (usersCityInformation[index]["thumbDown"].contains(userId)) return;

      setState(() {
        usersCityInformation[index]["thumbDown"].add(userId);
        usersCityInformation[index]["thumbUp"].remove(userId);
      });

      var dbData = await StadtinfoUserDatabase()
          .getData("thumbUp, thumbDown", "WHERE id ='$infoId'");
      var dbThumbUpList = dbData["thumbUp"];
      var dbThumbDownList = dbData["thumbDown"];

      dbThumbDownList.add(userId);
      dbThumbUpList.remove(userId);

      await StadtinfoUserDatabase().update(
          "thumbUp = '${jsonEncode(dbThumbUpList)}', thumbDown = '${jsonEncode(dbThumbDownList)}'",
          "WHERE id ='$infoId'");
    }
  }

  sortThumb(data) {
    data.sort((a, b) => (b["thumbUp"].length - b["thumbDown"].length)
        .compareTo(a["thumbUp"].length - a["thumbDown"].length) as int);
    return data;
  }

  showFamilyVisitWindow() {
    var allProfils = Hive.box("secureBox").get("profils");
    List<Widget> familiesList = [];

    for (var family in cityInformation["familien"]) {
      var name = "";

      for (var profil in allProfils) {
        if (profil["id"] == family){
          name = profil["name"];
          familiesList.add(InkWell(
            onTap: () => global_func.changePage(
                context, ShowProfilPage(userName: name, profil: profil)),
            child: Container(
                padding: const EdgeInsets.all(10),
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 20),
                )),
          ));
          break;
        }
      }
    }

    if (familiesList.isEmpty) {
      familiesList.add(Container(
          margin: const EdgeInsets.all(10),
          child: Text(AppLocalizations.of(context).keineFamilieStadt)));
    } else {
      familiesList.add(const SizedBox(height: 10));
    }

    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext buildContext) {
              return CustomAlertDialog(
                  title: AppLocalizations.of(context).besuchtVon,
                  children: familiesList);
            }));
  }

  changeInformationWindow(information) {
    var informationData = getInsiderInfoText(information);
    var titleTextKontroller =
        TextEditingController(text: informationData["title"]);
    var informationTextKontroller =
        TextEditingController(text: informationData["information"]);

    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext buildContext) {
              return CustomAlertDialog(
                  title: AppLocalizations.of(context).informationAendern,
                  children: [
                    customTextInput(AppLocalizations.of(context).titel,
                        titleTextKontroller),
                    const SizedBox(height: 10),
                    customTextInput(AppLocalizations.of(context).beschreibung,
                        informationTextKontroller,
                        moreLines: 8,
                        textInputAction: TextInputAction.newline),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: Text(AppLocalizations.of(context).speichern),
                          onPressed: () => changeInformation(
                              information: information,
                              newTitle: titleTextKontroller.text,
                              newInformation: informationTextKontroller.text),
                        ),
                        TextButton(
                          child: Text(AppLocalizations.of(context).abbrechen),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 20)
                  ]);
            }));
  }

  changeInformation({information, newTitle, newInformation}) async {
    String titleGer, informationGer, titleEng, informationEng;
    newTitle = newTitle.trim();
    newInformation = newInformation.trim();

    if (newTitle.isEmpty) {
      customSnackbar(
          context, AppLocalizations.of(context).titelStadtinformationEingeben);
      return;
    } else if (newTitle.length > 100) {
      customSnackbar(context, AppLocalizations.of(context).titleZuLang);
      return;
    } else if (newInformation.isEmpty) {
      customSnackbar(context,
          AppLocalizations.of(context).beschreibungStadtinformationEingeben);
      return;
    }

    var languageCheck = await translator.translate(newInformation);
    var languageCode = languageCheck.sourceLanguage.code;
    if(languageCode == "auto") languageCode = "en";

    if (languageCode == "en") {
      titleEng = newTitle;
      informationEng = newInformation;
      var titleTranslation = await translator.translate(newTitle,
          from: "en", to: "de");
      titleGer = titleTranslation.toString();
      var informationTranslation = await translator.translate(newInformation,
          from: "en", to: "de");
      informationGer = informationTranslation.toString();
    } else {
      titleGer = newTitle;
      informationGer = newInformation;
      titleEng = "";
      informationEng = "";
      var titleTranslation = await translator.translate(newTitle,
          from: "de", to: "en");
      titleEng = titleTranslation.toString();
      var informationTranslation = await translator.translate(newInformation,
          from: "de", to: "en");
      informationEng = informationTranslation.toString();
    }

    var secureBox = Hive.box("secureBox");
    var allInformations = secureBox.get("stadtinfoUser");

    for (var i = 0; i < allInformations.length; i++) {
      if (allInformations[i]["id"] == information["id"]) {
        allInformations[i]["sprache"] = languageCode;
        allInformations[i]["titleGer"] = titleGer;
        allInformations[i]["informationGer"] = informationGer;
        allInformations[i]["titleEng"] = titleEng;
        allInformations[i]["informationEng"] = informationEng;
        break;
      }
    }

    secureBox.put("stadtinfoUser", allInformations);

    setState(() {});
    Navigator.pop(context);

    StadtinfoUserDatabase().update(
        "sprache ='$languageCode',  "
            "titleGer = '$titleGer', "
            "informationGer = '$informationGer',"
            "titleEng = '$titleEng',"
            "informationEng = '$informationEng'",
        "WHERE id ='${information["id"]}'");
  }

  deleteInformation(information) async {
    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: AppLocalizations.of(context).informationLoeschen,
                height: 90,
                children: [
                  const SizedBox(height: 10),
                  Center(
                      child: Text(AppLocalizations.of(context)
                          .informationWirklichLoeschen))
                ],
                actions: [
                  TextButton(
                    child: const Text("Ok"),
                    onPressed: () {
                      StadtinfoUserDatabase().delete(information["id"]);

                      var secureBox = Hive.box("secureBox");
                      var allInformations = secureBox.get("stadtinfoUser");
                      allInformations.remove(information);
                      secureBox.put("stadtinfoUser", allInformations);

                      setState(() {});

                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: Text(AppLocalizations.of(context).abbrechen),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              );
            }));
  }

  reportInformation(information) {
    var reportTextKontroller = TextEditingController();

    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext buildContext) {
              return CustomAlertDialog(
                  height: 500,
                  title: AppLocalizations.of(context).informationMelden,
                  children: [
                    customTextInput("", reportTextKontroller,
                        moreLines: 10,
                        hintText: AppLocalizations.of(context)
                            .informationMeldenFrage),
                    Container(
                      margin:
                          const EdgeInsets.only(left: 30, top: 10, right: 30),
                      child: FloatingActionButton.extended(
                          onPressed: () {
                            Navigator.pop(context);
                            ReportsDatabase().add(
                                userId,
                                "Melde Information id: " +
                                    information["id"].toString(),
                                reportTextKontroller.text);
                          },
                          label: Text(AppLocalizations.of(context).senden)),
                    )
                  ]);
            }));
  }

  getInsiderInfoText(information) {
    var showTitle = "";
    var showInformation = "";
    var tranlsationIn;
    var ownlanguages = Hive.box("secureBox").get("ownProfil")["sprachen"];
    var informationLanguage = information["sprache"] == "de"
        ? ["Deutsch", "german"]
        : ["Englisch", "english"];
    bool canSpeakInformationLanguage =
        ownlanguages.contains(informationLanguage[0]) ||
            ownlanguages.contains(informationLanguage[1]);

    if (information["titleGer"].isEmpty) {
      return {
        "title": information["titleEng"],
        "information": information["informationEng"]
      };
    }
    if (information["titleEng"].isEmpty) {
      return {
        "title": information["titleGer"],
        "information": information["informationGer"]
      };
    }

    if (canSpeakInformationLanguage) {
      if (information["sprache"] == "de") {
        showTitle = information["titleGer"];
        showInformation = information["informationGer"];
      } else {
        showTitle = information["titleEng"];
        showInformation = information["informationEng"];
      }
    } else {
      if (information["sprache"] == "de") {
        tranlsationIn = "englisch";
        showTitle = information["titleEng"];
        showInformation = information["informationEng"];
      } else {
        tranlsationIn = "deutsch";
        showTitle = information["titleGer"];
        showInformation = information["informationGer"];
      }
    }

    return {
      "title": showTitle,
      "information": showInformation,
      "translationIn": tranlsationIn
    };
  }

  saveNewInformation({title, inhalt}) async {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String nowFormatted = formatter.format(now);
    String titleGer, informationGer, titleEng, informationEng;

    if (title.isEmpty) {
      customSnackbar(
          context, AppLocalizations.of(context).titelStadtinformationEingeben);
      return;
    } else if (title.length > 100) {
      customSnackbar(context, AppLocalizations.of(context).titleZuLang);
      return;
    } else if (title.isEmpty) {
      customSnackbar(context,
          AppLocalizations.of(context).beschreibungStadtinformationEingeben);
      return;
    }

    var languageCheck = await translator.translate(inhalt);
    var languageCode = languageCheck.sourceLanguage.code;
    if(languageCode == "auto") languageCode = "en";

    if (languageCode == "en") {
      titleEng = title;
      informationEng = inhalt;
      var titleTranslation =await translator.translate(title,
          from: "en", to: "de");
      titleGer = titleTranslation.toString();
      var informationTranslation = await translator.translate(inhalt,
          from: "en", to: "de");
      informationGer = informationTranslation.toString();
    } else {
      titleGer = title;
      informationGer = inhalt;
      titleEng = "";
      informationEng = "";
      var titleTranslation = await translator.translate(title,
          from: "de", to: "en");
      titleEng = titleTranslation.toString();
      var informationTranslation = await translator.translate(inhalt,
          from: "de", to: "en");
      informationEng = informationTranslation.toString();
    }

    var newUserInformation = {
      "ort": widget.ortName,
      "sprache": languageCode,
      "titleGer": titleGer,
      "informationGer": informationGer,
      "titleEng": titleEng,
      "informationEng": informationEng,
      "erstelltAm": nowFormatted,
      "thumbUp": [],
      "thumbDown": []
    };

    StadtinfoUserDatabase().addNewInformation(newUserInformation);

    var secureBox = Hive.box("secureBox");
    var allInformations = secureBox.get("stadtinfoUser");
    allInformations.add(newUserInformation);
    secureBox.put("stadtinfoUser", allInformations);

    Navigator.pop(context);

    setState(() {});
  }

  createChatGroup() async {
    var chatGroup = getChatGroupFromHive(cityInformation["id"].toString());
    if (chatGroup != null) return;

    var checkChatGroup = await ChatGroupsDatabase().getChatData(
        "id", "WHERE connected = '</stadt=${cityInformation["id"]}'");
    if (checkChatGroup != false) return;

    var newChatId = await ChatGroupsDatabase().addNewChatGroup(null, "</stadt=${cityInformation["id"]}");
    var hiveChatGroups = Hive.box('secureBox').get("chatGroups");
    hiveChatGroups.add({
      "id": newChatId,
      "users": {},
      "lastMessage": "</neuer Chat",
      "lastMessageDate": DateTime.now().millisecondsSinceEpoch,
      "connected": "</stadt=${cityInformation["id"]}"
    });
  }

  @override
  Widget build(BuildContext context) {
    allgemeineInfoBox() {
      String internetSpeedText = cityInformation["internet"] == null
          ? "?"
          : cityInformation["internet"].toString();

      setCostIconColor(indikator) {
        if (indikator <= 1) return Colors.green[800];
        if (indikator <= 2) return Colors.green;
        if (indikator <= 3) return Colors.yellow;
        if (indikator <= 4) return Colors.orange;

        return Colors.red;
      }

      setInternetIconColor(indikator) {
        if (indikator <= 20) return Colors.red;
        if (indikator <= 40) return Colors.orange;
        if (indikator <= 60) return Colors.yellow;
        if (indikator <= 80) return Colors.green;

        return Colors.green[800];
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            AppLocalizations.of(context).allgemeineInformation,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (cityInformation["kosten"] != null)
            Container(
              margin: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Icon(
                    Icons.monetization_on_outlined,
                    color: setCostIconColor(cityInformation["kosten"]),
                  ),
                  const SizedBox(width: 5),
                  const Text("Kosten: "),
                  const SizedBox(width: 5),
                  Text("\$ " * cityInformation["kosten"])
                ],
              ),
            ),
          if (cityInformation["internet"] != null)
            Container(
              margin: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Icon(Icons.network_check_outlined,
                      color: setInternetIconColor(cityInformation["internet"])),
                  const SizedBox(width: 5),
                  const Text("Internet: "),
                  const SizedBox(width: 5),
                  Text("Ø $internetSpeedText Mbps")
                ],
              ),
            ),
          if (cityInformation["wetter"] != null)
            Container(
              margin: const EdgeInsets.all(5),
              child: Row(
                children: [
                  const Icon(Icons.thermostat),
                  const SizedBox(width: 5),
                  Text(AppLocalizations.of(context).wetter),
                  Flexible(
                      child: InkWell(
                          onTap: () => launch(cityInformation["wetter"]),
                          child: Text(cityInformation["wetter"],
                              style: const TextStyle(color: Colors.blue),
                              overflow: TextOverflow.ellipsis)))
                ],
              ),
            ),
          InkWell(
            onTap: () => showFamilyVisitWindow(),
            child: Container(
              margin: const EdgeInsets.all(5),
              child: Row(
                children: [
                  const Icon(Icons.family_restroom),
                  const SizedBox(width: 5),
                  Text(AppLocalizations.of(context).besuchtVon +
                      cityInformation["familien"].length.toString() +
                      AppLocalizations.of(context).familien),
                ],
              ),
            ),
          ),
        ]),
      );
    }

    openInformationMenu(positionDetails, information) async {
      double left = positionDetails.globalPosition.dx;
      double top = positionDetails.globalPosition.dy;
      bool canChange = information["erstelltVon"] == userId; /*&&
          DateTime.now()
                  .difference(DateTime.parse(information["erstelltAm"]))
                  .inDays <=
              1;
              */

      await showMenu(
          context: context,
          position: RelativeRect.fromLTRB(left, top, 0, 0),
          items: [
            if (canChange)
              PopupMenuItem(
                child: Text(AppLocalizations.of(context).bearbeiten),
                onTap: () => changeInformationWindow(information),
              ),
            PopupMenuItem(
              child: Text(AppLocalizations.of(context).melden),
              onTap: () => reportInformation(information),
            ),
            if (canChange)
              PopupMenuItem(
                  child: Text(AppLocalizations.of(context).loeschen),
                  onTap: () {
                    deleteInformation(information);
                  }),
          ]);
    }

    insiderInfoBox(information, index) {
      information["index"] = index;
      var informationText = getInsiderInfoText(information);
      var showTitle = informationText["title"];
      var showInformation = informationText["information"];
      var translationIn = informationText["translationIn"];
      var creatorProfil = getProfilFromHive(profilId: information["erstelltVon"]);

      return Container(
        margin: const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
            border: Border.all(
                width: 2, color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 5, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Text(
                        showTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      )),
                  const Expanded(child: SizedBox()),
                  GestureDetector(
                    onTapDown: (positionDetails) =>
                        openInformationMenu(positionDetails, information),
                    child: const Icon(Icons.more_horiz),
                  ),
                  const SizedBox(width: 5)
                ],
              ),
            ),
            Container(
                margin: const EdgeInsets.only(left: 10, right: 10),
                child: TextWithHyperlinkDetection(text:showInformation, fontsize: 16,)),
            if (translationIn != null)
              Padding(
                padding: const EdgeInsets.only(right: 5, top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppLocalizations.of(context).automatischeUebersetzung,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                      onPressed: () => setThumb("up", index),
                      icon: Icon(
                        Icons.thumb_up,
                        color: information["thumbUp"].contains(userId)
                            ? Colors.green
                            : Colors.grey,
                      )),
                  Text((information["thumbUp"].length -
                          information["thumbDown"].length)
                      .toString()),
                  IconButton(
                      //padding: EdgeInsets.all(5),
                      onPressed: () => setThumb("down", index),
                      icon: Icon(Icons.thumb_down,
                          color: information["thumbDown"].contains(userId)
                              ? Colors.red
                              : Colors.grey)),
                  const Expanded(child: SizedBox()),
                  GestureDetector(
                    onTap: ()=> global_func.changePage(context, ShowProfilPage(profil: creatorProfil,)),
                    child: Text(creatorProfil["name"] + " " +information["erstelltAm"].split("-").reversed.join("-"),
                            style: const TextStyle(color: Colors.black),
                          ),
                  ),
                  const SizedBox(width: 5)
                ],
              ),
            )
          ],
        ),
      );
    }

    userInfoBox() {
      List<Widget> userCityInfo = [];

      for (var i = 0; i < usersCityInformation.length; i++) {
        userCityInfo.add(insiderInfoBox(usersCityInformation[i], i));
      }

      if (userCityInfo.isEmpty) {
        userCityInfo.add(Text(
          AppLocalizations.of(context).keineInsiderInformation,
          style: const TextStyle(color: Colors.grey),
        ));
      }

      return Container(
        margin: const EdgeInsets.all(10),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).insiderInformation,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(shrinkWrap: true, children: userCityInfo),
            )
          ],
        ),
      );
    }

    addInformationWindow() {
      var titleTextKontroller = TextEditingController();
      var informationTextKontroller = TextEditingController();

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
                title:
                    AppLocalizations.of(context).insiderInformationHinzufuegen,
                children: [
                  customTextInput(
                      AppLocalizations.of(context).titel, titleTextKontroller),
                  const SizedBox(height: 10),
                  customTextInput(AppLocalizations.of(context).beschreibung,
                      informationTextKontroller,
                      moreLines: 8, textInputAction: TextInputAction.newline),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          child: Text(AppLocalizations.of(context).speichern),
                          onPressed: () => saveNewInformation(
                              title: titleTextKontroller.text,
                              inhalt: informationTextKontroller.text)),
                      TextButton(
                        child: Text(AppLocalizations.of(context).abbrechen),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20)
                ]);
          });
    }

    refreshCityUserInfo();

    return SelectionArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: CustomAppBar(
            title: widget.ortName,
            leading: widget.newEntry != null ? StartPage() : null,
            buttons: [
              IconButton(
                icon: const Icon(Icons.message),
                onPressed: () async {
                  await createChatGroup();

                  global_func.changePage(context, ChatDetailsPage(
                    isChatgroup: true,
                    connectedId: "</stadt=${cityInformation["id"]}",
                  ));
                },
              )
            ],
        ),
        body: Column(
          children: [
            allgemeineInfoBox(),
            const SizedBox(height: 10),
            Expanded(child: userInfoBox())
          ],
        ),
        floatingActionButton: FloatingActionButton(
            heroTag: "create Stadtinformation",
            child: const Icon(Icons.create),
            onPressed: () => addInformationWindow()),
      ),
    );
  }
}
