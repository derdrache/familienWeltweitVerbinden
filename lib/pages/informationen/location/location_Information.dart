import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/pages/informationen/meetups/meetup_card_details.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:translator/translator.dart';

import '../../../functions/is_user_inactive.dart';
import '../../../global/custom_widgets.dart';
import '../../../global/global_functions.dart' as global_func;
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/dialogWindow.dart';
import '../../../widgets/text_with_hyperlink_detection.dart';
import '../../../windows/nutzerrichtlinen.dart';
import '../../start_page.dart';
import 'weltkarte_mini.dart';

class LocationInformationPage extends StatefulWidget {
  var ortName;
  var fromCityPage;

  LocationInformationPage({Key? key, this.ortName, this.fromCityPage = false})
      : super(key: key);

  @override
  State<LocationInformationPage> createState() =>
      _LocationInformationPageState();
}

class _LocationInformationPageState extends State<LocationInformationPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  late bool isCity;
  late bool hasInterest;
  Map location = {};
  int _selectNavigationIndex = 0;
  late List tabPages;
  late List usersCityInformation;

  @override
  void initState() {
    location = getCityFromHive(cityName: widget.ortName);

    location["familien"].remove(userId);
    usersCityInformation = getCityUserInfoFromHive(widget.ortName);
    isCity = location["isCity"] == 1;
    tabPages = [
      GeneralInformationPage(
        location: location,
        usersCityInformation: usersCityInformation,
        fromCityPage: widget.fromCityPage,
      ),
      InsiderInformationPage(location: location),
    ];
    addLastTab();

    super.initState();
  }

  addLastTab() {
    if (isCity) {
      tabPages.add(WorldmapMini(location: location));
    } else {
      tabPages.add(CountryCitiesPage(countryName: widget.ortName));
    }
  }

  changeIntereset() {
    if (hasInterest) {
      hasInterest = false;

      location["interesse"].remove(userId);
      StadtinfoDatabase().update(
          "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id = '${location["id"]}'");
    } else {
      hasInterest = true;

      location["interesse"].add(userId);
      StadtinfoDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id = '${location["id"]}'");
    }

    setState(() {});
  }

  void _onNavigationItemTapped(int index) {
    setState(() {
      _selectNavigationIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    hasInterest = location["interesse"]?.contains(userId) ?? false;

    return SelectionArea(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: widget.ortName,
        leading: widget.fromCityPage
            ? StartPage(selectedIndex: 2, informationPageIndex: isCity ? 3 : 4)
            : null,
        buttons: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () async {
              Clipboard.setData(
                  ClipboardData(text: "</cityId=" + location["id"].toString()));
              customSnackbar(
                  context, AppLocalizations.of(context)!.linkWurdekopiert,
                  color: Colors.green);
              global_func.changePageForever(
                  context,
                  StartPage(
                    selectedIndex: 3,
                  ));
            },
          ),
          IconButton(
            onPressed: () => changeIntereset(),
            icon: Icon(
              Icons.star,
              color: hasInterest ? Colors.yellow.shade900 : Colors.black,
            ),
          )
        ],
      ),
      body: tabPages.elementAt(_selectNavigationIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.primary,
        currentIndex: _selectNavigationIndex,
        selectedItemColor: Colors.white,
        onTap: _onNavigationItemTapped,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: 'Information',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.tips_and_updates),
            label: AppLocalizations.of(context)!.insiderInformation,
          ),
          if (isCity)
            BottomNavigationBarItem(
              icon: const Icon(Icons.map),
              label: AppLocalizations.of(context)!.karte,
            ),
          if (!isCity)
            BottomNavigationBarItem(
              icon: const Icon(Icons.location_city),
              label: AppLocalizations.of(context)!.cities,
            ),
        ],
      ),
    ));
  }
}

class GeneralInformationPage extends StatefulWidget {
  Map location;
  List usersCityInformation;
  bool fromCityPage;

  GeneralInformationPage(
      {Key? key,
      required this.location,
      required this.usersCityInformation,
      this.fromCityPage = false})
      : super(key: key);

  @override
  _GeneralInformationPageState createState() => _GeneralInformationPageState();
}

class _GeneralInformationPageState extends State<GeneralInformationPage> {
  var userId = FirebaseAuth.instance.currentUser!.uid;
  bool canGerman = false;
  bool canEnglish = false;
  late bool isCity;
  final translator = GoogleTranslator();
  List familiesThere = [];

  @override
  void initState() {
    isCity = widget.location["isCity"] == 1;

    super.initState();
  }

  removeInactiveFamilies(familyList) {
    List allActiveProfils = List.of(getAllActiveProfilsHive());
    List activeFamilies = [];

    for (var profil in allActiveProfils) {
      if (familyList.contains(profil["id"])) activeFamilies.add(profil["id"]);
    }

    return activeFamilies;
  }

  showFamilyVisitWindow(list) {
    List<Widget> familiesList = [];

    for (var family in list) {
      var profil = getProfilFromHive(profilId: family);
      var isInactive = isUserInactive(profil);

      if (profil == null) continue;

      familiesList.add(InkWell(
        onTap: () =>
            global_func.changePage(context, ShowProfilPage(profil: profil)),
        child: Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Text(
                  profil["name"],
                  style: const TextStyle(fontSize: 20),
                ),
                if (isInactive)
                  Text(
                    " - ${AppLocalizations.of(context)!.inaktiv}",
                    style: const TextStyle(color: Colors.red),
                  )
              ],
            )),
      ));
    }

    if (familiesList.isEmpty) {
      familiesList.add(Container(
          margin: const EdgeInsets.all(10),
          child: Text(AppLocalizations.of(context)!.keineFamilieStadt)));
    } else {
      familiesList.add(const SizedBox(height: 10));
    }

    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext buildContext) {
              return CustomAlertDialog(
                  title: AppLocalizations.of(context)!.besuchtVon,
                  children: familiesList);
            }));
  }

  getFamiliesThere() {
    int familiesOnLocation = 0;
    var allProfils = getAllActiveProfilsHive();

    for (var profil in allProfils) {
      if (profil["ort"].isEmpty) continue;

      bool inLocation;

      if (isCity) {
        inLocation = widget.location["ort"].contains(profil["ort"]) ?? false;
      } else {
        inLocation = widget.location["ort"].contains(profil["land"]) ?? false;
      }

      if (inLocation) {
        familiesThere.add(profil["id"]);
        familiesOnLocation += 1;
      }
    }

    return familiesOnLocation;
  }

  createNewChatGroup(lcationId) async {
    String locationId = lcationId.toString();
    var chatGroup = getChatGroupFromHive(connectedWith: locationId.toString());
    if (chatGroup != null) return;

    var checkChatGroup = await ChatGroupsDatabase()
        .getChatData("id", "WHERE connected = '</stadt=$locationId'");
    if (checkChatGroup != false) return;

    var newChatId =
        await ChatGroupsDatabase().addNewChatGroup(null, "</stadt=$locationId");
    var hiveChatGroups = Hive.box('secureBox').get("chatGroups");
    hiveChatGroups.add({
      "id": newChatId,
      "users": {},
      "lastMessage": "</neuer Chat",
      "lastMessageDate": DateTime.now().millisecondsSinceEpoch,
      "connected": "</stadt=$locationId"
    });
  }

  @override
  Widget build(BuildContext context) {
    double iconSize = 28;
    double fontSize = 18;
    var anzahlFamilien = widget.location["familien"]?.length ?? 0;

    _showCurrentlyThere() {
      var familiesOnLocation = getFamiliesThere();

      return InkWell(
        onTap: () => showFamilyVisitWindow(familiesThere),
        child: Container(
          margin: const EdgeInsets.all(5),
          child: Row(
            children: [
              Icon(Icons.pin_drop, size: iconSize),
              const SizedBox(width: 10),
              Text(
                  AppLocalizations.of(context)!.aktuellDort +
                      familiesOnLocation.toString() +
                      AppLocalizations.of(context)!.familien,
                  style: TextStyle(
                      fontSize: fontSize,
                      decoration: TextDecoration.underline)),
            ],
          ),
        ),
      );
    }

    _showVisited() {
      return InkWell(
        onTap: () => showFamilyVisitWindow(widget.location["familien"]),
        child: Container(
          margin: const EdgeInsets.all(5),
          child: Row(
            children: [
              Icon(Icons.family_restroom, size: iconSize),
              const SizedBox(width: 10),
              Text(
                  AppLocalizations.of(context)!.besuchtVon +
                      anzahlFamilien.toString() +
                      AppLocalizations.of(context)!.familien,
                  style: TextStyle(
                      fontSize: fontSize,
                      decoration: TextDecoration.underline)),
            ],
          ),
        ),
      );
    }

    _showInsiderCount() {
      return Container(
        margin: const EdgeInsets.all(5),
        child: Row(
          children: [
            Icon(
              Icons.tips_and_updates,
              size: iconSize,
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.insiderInformation + ": ",
                style: TextStyle(fontSize: fontSize)),
            const SizedBox(width: 5),
            Text(widget.usersCityInformation.length.toString(),
                style: TextStyle(fontSize: fontSize))
          ],
        ),
      );
    }

    _showCost() {
      setCostIconColor(indikator) {
        if (indikator <= 1) return Colors.green[800];
        if (indikator <= 2) return Colors.green;
        if (indikator <= 3) return Colors.yellow;
        if (indikator <= 4) return Colors.orange;

        return Colors.red;
      }

      return Container(
        margin: const EdgeInsets.all(5),
        child: Row(
          children: [
            Icon(
              Icons.monetization_on_outlined,
              color: widget.location["kosten"] == null
                  ? null
                  : setCostIconColor(widget.location["kosten"]),
              size: iconSize,
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.kosten,
                style: TextStyle(fontSize: fontSize)),
            const SizedBox(width: 5),
            Text(
                widget.location["kosten"] == null
                    ? "?"
                    : "\$ " * widget.location["kosten"],
                style: TextStyle(fontSize: fontSize))
          ],
        ),
      );
    }

    _showInternetSpeed() {
      String internetSpeedText = widget.location["internet"] == null
          ? "?"
          : widget.location["internet"].toString();

      setInternetIconColor(indikator) {
        if (indikator <= 20) return Colors.red;
        if (indikator <= 40) return Colors.orange;
        if (indikator <= 60) return Colors.yellow;
        if (indikator <= 80) return Colors.green;

        return Colors.green[800];
      }

      return Container(
        margin: const EdgeInsets.all(5),
        child: Row(
          children: [
            Icon(
              Icons.network_check_outlined,
              color: widget.location["internet"] == null
                  ? null
                  : setInternetIconColor(widget.location["internet"]),
              size: iconSize,
            ),
            const SizedBox(width: 10),
            Text("Internet: ", style: TextStyle(fontSize: fontSize)),
            const SizedBox(width: 5),
            Text(
                widget.location["internet"] == null
                    ? "?"
                    : "Ø $internetSpeedText Mbps",
                style: TextStyle(fontSize: fontSize))
          ],
        ),
      );
    }

    _showWeather() {
      return Container(
        margin: const EdgeInsets.all(5),
        child: Row(
          children: [
            Icon(
              Icons.thermostat,
              size: iconSize,
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.wetter,
                style: TextStyle(fontSize: fontSize)),
            if (widget.location["wetter"] != null)
              Flexible(
                  child: InkWell(
                      onTap: () =>
                          global_func.openURL(widget.location["wetter"]),
                      child: Text(widget.location["wetter"],
                          style:
                              TextStyle(color: Colors.blue, fontSize: fontSize),
                          overflow: TextOverflow.ellipsis)))
          ],
        ),
      );
    }

    return SelectionArea(
      child: SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _showCurrentlyThere(),
                      _showVisited(),
                      _showInsiderCount(),
                      _showCost(),
                      _showInternetSpeed(),
                      _showWeather(),
                    ]),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await createNewChatGroup(widget.location["id"]);

              global_func.changePage(
                  context,
                  ChatDetailsPage(
                    isChatgroup: true,
                    connectedWith: "</stadt=${widget.location["id"]}",
                  ));
            },
            child: const Icon(Icons.message),
          ),
        ),
      ),
    );
  }
}

class InsiderInformationPage extends StatefulWidget {
  Map location;

  InsiderInformationPage({Key? key, required this.location}) : super(key: key);

  @override
  State<InsiderInformationPage> createState() => _InsiderInformationPageState();
}

class _InsiderInformationPageState extends State<InsiderInformationPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final translator = GoogleTranslator();
  late List usersCityInformation;

  addInformationWindow() {
    var titleTextKontroller = TextEditingController();
    var informationTextKontroller = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
              title: AppLocalizations.of(context)!.insiderInformationHinzufuegen,
              children: [
                customTextInput(
                    AppLocalizations.of(context)!.titel, titleTextKontroller),
                const SizedBox(height: 10),
                customTextInput(AppLocalizations.of(context)!.beschreibung,
                    informationTextKontroller,
                    moreLines: 8, textInputAction: TextInputAction.newline),
                const SizedBox(height: 5),
                NutzerrichtlinenAnzeigen(page: "create"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        child: Text(
                          AppLocalizations.of(context)!.speichern,
                          style: const TextStyle(fontSize: 20),
                        ),
                        onPressed: () => saveNewInformation(
                            title: titleTextKontroller.text,
                            inhalt: informationTextKontroller.text)),
                    TextButton(
                      child: Text(
                        AppLocalizations.of(context)!.abbrechen,
                        style: const TextStyle(fontSize: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20)
              ]);
        });
  }

  saveNewInformation({title, inhalt}) async {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String nowFormatted = formatter.format(now);
    String titleGer, informationGer, titleEng, informationEng;

    if (title.isEmpty) {
      customSnackbar(
          context, AppLocalizations.of(context)!.titelStadtinformationEingeben);
      return;
    } else if (title.length > 100) {
      customSnackbar(context, AppLocalizations.of(context)!.titleZuLang);
      return;
    } else if (title.isEmpty) {
      customSnackbar(context,
          AppLocalizations.of(context)!.beschreibungStadtinformationEingeben);
      return;
    }

    var newUserInformation = {
      "ort": widget.location["ort"],
      "sprache": "auto",
      "titleGer": title,
      "informationGer": inhalt,
      "titleEng": title,
      "informationEng": inhalt,
      "erstelltAm": nowFormatted,
      "erstelltVon": userId,
      "thumbUp": [],
      "thumbDown": []
    };

    setState(() {
      usersCityInformation.add(newUserInformation);
    });

    Navigator.pop(context);

    var languageCheck = await translator.translate(inhalt);
    var languageCode = languageCheck.sourceLanguage.code;
    if (languageCode == "auto") languageCode = "en";

    if (languageCode == "en") {
      titleEng = title;
      informationEng = inhalt;
      var titleTranslation =
          await translator.translate(title, from: "en", to: "de");
      titleGer = titleTranslation.toString();
      var informationTranslation =
          await translator.translate(inhalt, from: "en", to: "de");
      informationGer = informationTranslation.toString();
    } else {
      titleGer = title;
      informationGer = inhalt;
      titleEng = "";
      informationEng = "";
      var titleTranslation =
          await translator.translate(title, from: "de", to: "en");
      titleEng = titleTranslation.toString();
      var informationTranslation =
          await translator.translate(inhalt, from: "de", to: "en");
      informationEng = informationTranslation.toString();
    }

    newUserInformation["sprache"] = languageCode;
    newUserInformation["titleGer"] = titleGer;
    newUserInformation["informationGer"] = informationGer;
    newUserInformation["titleEng"] = titleEng;
    newUserInformation["informationEng"] = informationEng;

    var secureBox = Hive.box("secureBox");
    var allInformations = secureBox.get("stadtinfoUser");
    allInformations.add(newUserInformation);
    secureBox.put("stadtinfoUser", allInformations);

    newUserInformation["ort"] = newUserInformation["ort"].replaceAll("'", "''");
    newUserInformation["titleGer"] =
        newUserInformation["titleGer"].replaceAll("'", "''");
    newUserInformation["informationGer"] =
        newUserInformation["informationGer"].replaceAll("'", "''");
    newUserInformation["titleEng"] =
        newUserInformation["titleEng"].replaceAll("'", "''");
    newUserInformation["informationEng"] =
        newUserInformation["informationEng"].replaceAll("'", "''");

    StadtinfoUserDatabase().addNewInformation(newUserInformation);
  }

  setThumbUp(index) {
    var infoId = usersCityInformation[index]["id"];

    if (usersCityInformation[index]["thumbUp"].contains(userId)) {
      usersCityInformation[index]["thumbUp"].remove(userId);

      StadtinfoUserDatabase().update(
          "thumbUp = JSON_REMOVE(thumbUp, JSON_UNQUOTE(JSON_SEARCH(thumbUp, 'one', '$userId')))",
          "WHERE id ='$infoId'");
    } else {
      bool hasThumbDown = usersCityInformation[index]["thumbDown"].contains(userId);
      usersCityInformation[index]["thumbUp"].add(userId);
      usersCityInformation[index]["thumbDown"].remove(userId);
      String sqlStatement = "thumbUp = JSON_ARRAY_APPEND(thumbUp, '\$', '$userId')";
      if(hasThumbDown) sqlStatement += ",thumbDown = JSON_REMOVE(thumbDown, JSON_UNQUOTE(JSON_SEARCH(thumbDown, 'one', '$userId')))";

      StadtinfoUserDatabase().update(
          sqlStatement,
          "WHERE id ='$infoId'");
    }
    setState(() {});
  }

  setThumbDown(index) {
    var infoId = usersCityInformation[index]["id"];

    if (usersCityInformation[index]["thumbDown"].contains(userId)) {
      usersCityInformation[index]["thumbDown"].remove(userId);

      StadtinfoUserDatabase().update(
          "thumbDown = JSON_REMOVE(thumbDown, JSON_UNQUOTE(JSON_SEARCH(thumbDown, 'one', '$userId')))",
          "WHERE id ='$infoId'");
    } else {
      usersCityInformation[index]["thumbDown"].add(userId);
      usersCityInformation[index]["thumbUp"].remove(userId);

      StadtinfoUserDatabase().update(
          "thumbUp = JSON_REMOVE(thumbUp, JSON_UNQUOTE(JSON_SEARCH(thumbUp, 'one', '$userId'))), thumbDown = JSON_ARRAY_APPEND(thumbDown, '\$', '$userId')",
          "WHERE id ='$infoId'");
    }

    setState(() {});
  }

  sortInformation(data) {
    data.sort((a, b) => (b["thumbUp"].length - b["thumbDown"].length)
        .compareTo(a["thumbUp"].length - a["thumbDown"].length) as int);
    return data;
  }

  changeInformationDialog(information) {
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
                  title: AppLocalizations.of(context)!.informationAendern,
                  children: [
                    customTextInput(AppLocalizations.of(context)!.titel,
                        titleTextKontroller),
                    const SizedBox(height: 10),
                    customTextInput(AppLocalizations.of(context)!.beschreibung,
                        informationTextKontroller,
                        moreLines: 8, textInputAction: TextInputAction.newline),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: Text(AppLocalizations.of(context)!.speichern),
                          onPressed: () => changeInformation(
                              id: information["id"],
                              newTitle: titleTextKontroller.text,
                              newInformation: informationTextKontroller.text),
                        ),
                        TextButton(
                          child: Text(AppLocalizations.of(context)!.abbrechen),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 20)
                  ]);
            }));
  }

  changeInformation({id, newTitle, newInformation}) async {
    newTitle = newTitle.trim();
    newInformation = newInformation.trim();

    if (newTitle.isEmpty) {
      customSnackbar(
          context, AppLocalizations.of(context)!.titelStadtinformationEingeben);
      return;
    } else if (newTitle.length > 100) {
      customSnackbar(context, AppLocalizations.of(context)!.titleZuLang);
      return;
    } else if (newInformation.isEmpty) {
      customSnackbar(context,
          AppLocalizations.of(context)!.beschreibungStadtinformationEingeben);
      return;
    }

    for (var i = 0; i < usersCityInformation.length; i++) {
      if (usersCityInformation[i]["id"] == id) {
        usersCityInformation[i]["titleGer"] = newTitle;
        usersCityInformation[i]["informationGer"] = newInformation;
        usersCityInformation[i]["titleEng"] = newTitle;
        usersCityInformation[i]["informationEng"] = newInformation;
        break;
      }
    }

    updateDatabase(id, newTitle, newInformation);

    setState(() {});
    Navigator.pop(context);
  }

  updateDatabase(
    id,
    newTitle,
    newInformation,
  ) async {
    String titleGer, informationGer, titleEng, informationEng;

    var languageCheck = await translator.translate(newInformation);
    var languageCode = languageCheck.sourceLanguage.code;
    if (languageCode == "auto") languageCode = "en";

    if (languageCode == "en") {
      titleEng = newTitle;
      informationEng = newInformation;
      var titleTranslation =
          await translator.translate(newTitle, from: "en", to: "de");
      titleGer = titleTranslation.toString();
      var informationTranslation =
          await translator.translate(newInformation, from: "en", to: "de");
      informationGer = informationTranslation.toString();
    } else {
      titleGer = newTitle;
      informationGer = newInformation;
      titleEng = "";
      informationEng = "";
      var titleTranslation =
          await translator.translate(newTitle, from: "de", to: "en");
      titleEng = titleTranslation.toString();
      var informationTranslation =
          await translator.translate(newInformation, from: "de", to: "en");
      informationEng = informationTranslation.toString();
    }

    var secureBox = Hive.box("secureBox");
    var allInformations = secureBox.get("stadtinfoUser");

    for (var i = 0; i < allInformations.length; i++) {
      if (allInformations[i]["id"] == id) {
        allInformations[i]["sprache"] = languageCode;
        allInformations[i]["titleGer"] = titleGer;
        allInformations[i]["informationGer"] = informationGer;
        allInformations[i]["titleEng"] = titleEng;
        allInformations[i]["informationEng"] = informationEng;
        break;
      }
    }
    secureBox.put("stadtinfoUser", allInformations);

    titleGer = titleGer.replaceAll("'", "''");
    informationGer = informationGer.replaceAll("'", "''");
    titleEng = titleEng.replaceAll("'", "''");
    informationEng = informationEng.replaceAll("'", "''");

    await StadtinfoUserDatabase().update(
        "sprache ='$languageCode',  "
            "titleGer = '$titleGer', "
            "informationGer = '$informationGer',"
            "titleEng = '$titleEng',"
            "informationEng = '$informationEng'",
        "WHERE id ='$id'");
  }

  copyInformationDialog(information) {
    var informationText = isGerman
        ? information["informationGer"]
        : information["informationGer"];

    Clipboard.setData(ClipboardData(text: informationText));

    customSnackbar(context, AppLocalizations.of(context)!.informationKopiert,
        color: Colors.green);
  }

  deleteInformationDialog(information) async {
    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: AppLocalizations.of(context)!.informationLoeschen,
                height: 90,
                children: [
                  const SizedBox(height: 10),
                  Center(
                      child: Text(AppLocalizations.of(context)!
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

                      setState(() {
                        usersCityInformation.remove(information);
                      });

                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.abbrechen),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              );
            }));
  }

  reportInformationDialog(information) {
    var reportTextKontroller = TextEditingController();

    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext buildContext) {
              return CustomAlertDialog(
                  height: 500,
                  title: AppLocalizations.of(context)!.informationMelden,
                  children: [
                    customTextInput("", reportTextKontroller,
                        moreLines: 10,
                        hintText: AppLocalizations.of(context)!
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
                          label: Text(AppLocalizations.of(context)!.senden)),
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

  @override
  void initState() {
    usersCityInformation = getCityUserInfoFromHive(widget.location["ort"]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    usersCityInformation = sortInformation(usersCityInformation);

    openInformationMenu(positionDetails, information) async {
      double left = positionDetails.globalPosition.dx;
      double top = positionDetails.globalPosition.dy;
      bool canChange = information["erstelltVon"] == userId;
      usersCityInformation = getCityUserInfoFromHive(widget.location["ort"]);

      await showMenu(
          context: context,
          position: RelativeRect.fromLTRB(left, top, 0, 0),
          items: [
            if (canChange)
              PopupMenuItem(
                child: Text(AppLocalizations.of(context)!.bearbeiten),
                onTap: () => changeInformationDialog(information),
              ),
            PopupMenuItem(
              child: Text(AppLocalizations.of(context)!.kopieren),
              onTap: () => copyInformationDialog(information),
            ),
            PopupMenuItem(
              child: Text(AppLocalizations.of(context)!.melden),
              onTap: () => reportInformationDialog(information),
            ),
            if (canChange)
              PopupMenuItem(
                  child: Text(AppLocalizations.of(context)!.loeschen),
                  onTap: () {
                    deleteInformationDialog(information);
                  }),
          ]);
    }

    insiderInfoBox(information, index) {
      information["index"] = index;
      var informationText = getInsiderInfoText(information);
      var showTitle = informationText["title"];
      var showInformation = informationText["information"];
      var translationIn = informationText["translationIn"];
      var creatorProfil =
          getProfilFromHive(profilId: information["erstelltVon"]) ?? {};

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
                child: TextWithHyperlinkDetection(
                  text: showInformation,
                  fontsize: 16,
                )),
            if (translationIn != null)
              Padding(
                padding: const EdgeInsets.only(right: 5, top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.automatischeUebersetzung,
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
                      onPressed: () => setThumbUp(index),
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
                      onPressed: () => setThumbDown(index),
                      icon: Icon(Icons.thumb_down,
                          color: information["thumbDown"].contains(userId)
                              ? Colors.red
                              : Colors.grey)),
                  const Expanded(child: SizedBox()),
                  GestureDetector(
                    onTap: () => global_func.changePage(
                        context,
                        ShowProfilPage(
                          profil: creatorProfil,
                        )),
                    child: Text(
                      creatorProfil["name"] ?? "" +
                          " " +
                          information["erstelltAm"]
                              .split("-")
                              .reversed
                              .join("-"),
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
        userCityInfo.add(Container(
          height: 500,
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.keineInsiderInformation,
              style: const TextStyle(color: Colors.grey, fontSize: 20),
            ),
          ),
        ));
      }

      return Container(
        margin: const EdgeInsets.all(10),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(shrinkWrap: true, children: userCityInfo),
            )
          ],
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        body: userInfoBox(),
        floatingActionButton: FloatingActionButton(
            heroTag: "create Stadtinformation",
            child: const Icon(Icons.create),
            onPressed: () => addInformationWindow()),
      ),
    );
  }
}

class CountryCitiesPage extends StatefulWidget {
  final String countryName;

  CountryCitiesPage({Key? key, required this.countryName}) : super(key: key);

  @override
  State<CountryCitiesPage> createState() => _CountryCitiesPageState();
}

class _CountryCitiesPageState extends State<CountryCitiesPage> {
  getAllCitiesFromCountry() {
    List allCities = Hive.box('secureBox').get("stadtinfo");
    List citiesFromCountry = [];

    for (var city in allCities) {
      var isCity = city["isCity"] == 1;
      var fromCountry = widget.countryName.contains(city["land"]);

      if (isCity && fromCountry) {
        city["userInfos"] = getCityUserInfoFromHive(city["ort"]);

        citiesFromCountry.add(city);
      }
    }

    return sortCityList(citiesFromCountry);
  }

  sortCityList(cityList) {
    cityList.sort((a, b) {
      var calculationA = a["familien"].length + a["userInfos"].length;
      var calculationB = b["familien"].length + b["userInfos"].length;

      return calculationB.compareTo(calculationA) as int;
    });

    return cityList;
  }

  setInternetIconColor(indikator) {
    if (indikator <= 20) return Colors.red;
    if (indikator <= 40) return Colors.orange;
    if (indikator <= 60) return Colors.yellow;
    if (indikator <= 80) return Colors.green;

    return Colors.green[800];
  }

  setCostIconColor(indikator) {
    if (indikator <= 1) return Colors.green[800];
    if (indikator <= 2) return Colors.green;
    if (indikator <= 3) return Colors.yellow;
    if (indikator <= 4) return Colors.orange;

    return Colors.red;
  }

  getCityUserInfoCount(cityName) {
    List cityUserInfos = getCityUserInfoFromHive(cityName);

    return cityUserInfos.length;
  }

  @override
  Widget build(BuildContext context) {
    cityEntry(city) {
      return GestureDetector(
        onTap: () => global_func.changePage(
            context, LocationInformationPage(ortName: city["ort"])),
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              border: Border.all(), borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city["ort"],
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(AppLocalizations.of(context)!.stadtInformationen +
                        getCityUserInfoCount(city["ort"]).toString()),
                    const SizedBox(height: 5),
                    Text(AppLocalizations.of(context)!.besuchtVon +
                        city["familien"].length.toString() +
                        AppLocalizations.of(context)!.familien),
                  ],
                ),
              ),
              if (city["kosten"] != null)
                Icon(
                  Icons.monetization_on_outlined,
                  size: 25,
                  color: setCostIconColor(city["kosten"]),
                ),
              const SizedBox(width: 10),
              if (city["internet"] != null)
                Icon(Icons.network_check_outlined,
                    size: 25, color: setInternetIconColor(city["internet"])),
            ],
          ),
        ),
      );
    }

    createCityList() {
      List<Widget> cityList = [];
      var citiesFromCountry = getAllCitiesFromCountry();

      for (var city in citiesFromCountry) {
        cityList.add(cityEntry(city));
      }

      return cityList;
    }

    return SafeArea(
        child: ListView(
      shrinkWrap: true,
      children: createCityList(),
    ));
  }
}
