import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:curved_text/curved_text.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:translator/translator.dart';

import '../global/style.dart' as style;
import '../global/encryption.dart';
import '../global/global_functions.dart' as global_functions;
import '../global/global_functions.dart';
import '../global/variablen.dart';
import '../pages/chat/chat_details.dart';
import '../services/database.dart';
import '../services/notification.dart';
import '../widgets/colorful_background.dart';
import '../widgets/layout/custom_snackbar.dart';
import '../widgets/layout/custom_text_input.dart';
import '../widgets/profil_image.dart';
import '../widgets/text_with_hyperlink_detection.dart';
import '../windows/custom_popup_menu.dart';
import '../windows/dialog_window.dart';
import 'informationen/location/location_information.dart';

String? userId = FirebaseAuth.instance.currentUser?.uid;
double headlineTextSize = 18;

class ShowProfilPage extends StatefulWidget {
  final Map profil;

  const ShowProfilPage({Key? key, required this.profil}) : super(key: key);

  @override
  State<ShowProfilPage> createState() => _ShowProfilPageState();
}

class _ShowProfilPageState extends State<ShowProfilPage> {
  late Map profil;
  late Map? familyProfil;

  @override
  void initState() {
    profil = Map.of(widget.profil);

    checkIfIsFamilyMember();

    super.initState();
  }

  checkIfIsFamilyMember() {
    bool spracheIstDeutsch = kIsWeb
        ? PlatformDispatcher.instance.locale.languageCode == "de"
        : Platform.localeName == "de_DE";
    familyProfil = getFamilyProfil(familyMember: profil["id"]);

    if (familyProfil == null ||
        familyProfil!["active"] == 0 ||
        familyProfil!["mainProfil"].isEmpty ||
        familyProfil!["name"].isEmpty) {
      familyProfil = null;
      return;
    }

    var familyName = familyProfil!["name"];
    var mainMemberProfil =
        Map.of(getProfilFromHive(profilId: familyProfil!["mainProfil"]));
    String familyText = spracheIstDeutsch ? "Familie" : "Family";
    mainMemberProfil["name"] = "$familyText $familyName";
    profil = mainMemberProfil;
  }

  @override
  Widget build(BuildContext context) {
    header() {
      return Stack(
        children: [
          ClipPath(
              clipper: _MyCustomClipper(),
              child: ColorfulBackground(
                height: 250,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary
                ],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ProfilImage(
                      profil,
                      size: 60,
                      fullScreenWindow: true,
                    ),
                    SizedBox(
                        height: 60,
                        child: CurvedText(
                          curvature: -0.002,
                          text: profil["name"],
                          textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        )),
                  ],
                ),
              )),
          Positioned(child: _AppBar(profil: profil, familyProfil: familyProfil))
        ],
      );
    }

    return SelectionArea(
      child: Scaffold(
        body: SafeArea(
          child: SizedBox(
            width: double.maxFinite,
            child: Scrollbar(
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                }),
                child: ListView(children: [
                  header(),
                  _UserInformationDisplay(profil: profil),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyCustomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double width = size.width;
    double height = size.height;

    var path = Path();

    path.lineTo(0, height - 30);
    path.quadraticBezierTo(width * 0.5, height + 30, width, height - 30);
    path.lineTo(width, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _AppBar extends StatefulWidget {
  final Map profil;
  final Map? familyProfil;

  const _AppBar({Key? key, required this.profil, this.familyProfil})
      : super(key: key);

  @override
  State<_AppBar> createState() => _AppBarState();
}

class _AppBarState extends State<_AppBar> {
  Map ownProfil = Hive.box('secureBox').get("ownProfil") ?? {};
  List userFriendlist = Hive.box('secureBox').get("ownProfil")["friendlist"];
  late String _userName;
  late bool _isOwnProfil;
  Color buttonColor = Colors.white;

  @override
  void initState() {
    bool isFmailyMember = widget.familyProfil != null &&
        widget.familyProfil!["members"].contains(userId);
    _isOwnProfil = widget.profil["id"] == userId || isFmailyMember;
    _userName = widget.profil["name"];

    createUserNotizen();

    super.initState();
  }

  createUserNotizen() async {
    if (ownProfil["userNotizen"] != null) return;

    var userNotizen =
        await NotizDatabase().getData("userNotizen", "WHERE id = '$userId'");

    if (userNotizen == false) {
      NotizDatabase().newNotize();
      ownProfil["userNotizen"] = {};
    } else {
      if (userNotizen.isNotEmpty) {
        userNotizen = decrypt(userNotizen);
        userNotizen = json.decode(userNotizen);
      }
      ownProfil["userNotizen"] = userNotizen;
    }
  }

  saveNotiz(notiz) {
    ownProfil["userNotizen"][widget.profil["id"]] = notiz;

    var encryptNotes = encrypt(json.encode(ownProfil["userNotizen"]));

    NotizDatabase()
        .update("userNotizen = '$encryptNotes'", "WHERE id = '$userId'");
  }

  openChat(chatpartnerId) async {
    global_functions.changePage(
        context,
        ChatDetailsPage(
          chatPartnerId: chatpartnerId,
        ));
  }

  openNoteWindow() {
    TextEditingController userNotizController = TextEditingController();
    bool changeNote = false;

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(builder: (context, noteState) {
            var notizen = ownProfil["userNotizen"];
            var userNotiz = notizen[widget.profil["id"]];

            return CustomAlertDialog(
                title: AppLocalizations.of(context)!.notizeUeber + _userName,
                children: [
                  if (userNotiz == null || changeNote)
                    TextField(
                      controller: userNotizController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: AppLocalizations.of(context)!.notizEingeben,
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (userNotiz == null || changeNote)
                    FloatingActionButton.extended(
                        label: Text(AppLocalizations.of(context)!.speichern),
                        onPressed: () {
                          saveNotiz(userNotizController.text);

                          noteState(() {
                            changeNote = false;
                          });
                        }),
                  if (userNotiz != null && !changeNote)
                    InkWell(
                        onTap: () => noteState(() {
                              changeNote = true;
                              userNotizController.text = userNotiz;
                            }),
                        child: Text(userNotiz, maxLines: 10)),
                  const SizedBox(height: 5)
                ]);
          });
        });
  }

  changeFriendStatus(isFriend) {
    var snackbarText = "";
    var newsData = {
      "typ": "friendlist",
      "information": "",
    };

    if (isFriend) {
      userFriendlist.remove(widget.profil["id"]);
      snackbarText =
          _userName + AppLocalizations.of(context)!.friendlistEntfernt;

      var newsId = getNewsId("added ${widget.profil["id"]}");

      if (newsId != null) NewsPageDatabase().delete(newsId);
    } else {
      userFriendlist.add(widget.profil["id"]);
      snackbarText =
          _userName + AppLocalizations.of(context)!.friendlistHinzugefuegt;

      prepareFriendNotification(
          newFriendId: userId,
          toId: widget.profil["id"],
          toCanGerman: widget.profil["sprachen"].contains("Deutsch") ||
              widget.profil["sprachen"].contains("german"));

      newsData["information"] = "added ${widget.profil["id"]}";
      NewsPageDatabase().addNewNews(newsData);
    }

    var localBox = Hive.box('secureBox');
    Map ownProfil = localBox.get("ownProfil");

    ownProfil["friendlist"] = userFriendlist;
    localBox.put("ownProfil", ownProfil);

    customSnackBar(context, snackbarText, color: Colors.green);

    ProfilDatabase().updateProfil(
        "friendlist = '${jsonEncode(userFriendlist)}'", "WHERE id = '$userId'");

    Navigator.pop(context);
    setState(() {});
  }

  userBlockieren(ownId, onBlockList) {
    String snackbarText = "";
    List allProfils = Hive.box('secureBox').get("profils");
    String databaseQuery = "";

    if (onBlockList) {
      widget.profil["geblocktVon"].remove(ownId);
      databaseQuery =
          "geblocktVon = JSON_REMOVE(geblocktVon, JSON_UNQUOTE(JSON_SEARCH(geblocktVon, 'one', '$ownId')))";
      snackbarText = AppLocalizations.of(context)!.benutzerFreigegeben;
    } else {
      widget.profil["geblocktVon"].add(ownId);
      databaseQuery =
          "geblocktVon = JSON_ARRAY_APPEND(geblocktVon, '\$', '$ownId')";
      snackbarText = AppLocalizations.of(context)!.benutzerBlockieren;
    }

    for (var profil in allProfils) {
      if (profil["id"] == profil["id"]) {
        profil["blockiertVon"] = profil["geblocktVon"];
      }
    }

    Hive.box('secureBox').put("profils", allProfils);

    customSnackBar(context, snackbarText, color: Colors.green);

    ProfilDatabase()
        .updateProfil(databaseQuery, "WHERE id = '${widget.profil["id"]}'");
  }

  @override
  Widget build(BuildContext context) {
    friendButton() {
      bool isFriend = userFriendlist.contains(widget.profil["id"]);

      return IconButton(
          onPressed: () => changeFriendStatus(isFriend),
          tooltip: isFriend
              ? AppLocalizations.of(context)!.freundEntfernen
              : AppLocalizations.of(context)!.freundHinzufuegen,
          icon: Icon(isFriend ? Icons.person_remove : Icons.person_add,
              color: buttonColor));
    }

    openNoteButton() {
      return IconButton(
        icon: Icon(
          Icons.description,
          color: buttonColor,
        ),
        tooltip: AppLocalizations.of(context)!.tooltipNotizBenutzerAngelegen,
        onPressed: () => openNoteWindow(),
      );
    }

    selectChatMemberWindow() {
      List<Widget> menuList = [];

      widget.familyProfil!["members"].remove(userId);

      for (var memberId in widget.familyProfil!["members"]) {
        var memberName =
            getProfilFromHive(profilId: memberId, getNameOnly: true);

        menuList.add(SimpleDialogOption(
          child: Row(
            children: [
              Text(memberName),
            ],
          ),
          onPressed: () => openChat(memberId),
        ));
      }

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 200,
                  child: SimpleDialog(
                    contentPadding: EdgeInsets.zero,
                    insetPadding:
                        const EdgeInsets.only(top: 40, left: 0, right: 10),
                    children: menuList,
                  ),
                ),
              ],
            );
          });
    }

    openChatButton() {
      return IconButton(
          icon: Icon(
            Icons.message,
            color: buttonColor,
          ),
          tooltip: AppLocalizations.of(context)!.tooltipChatBenutzer,
          onPressed: () async {
            if (widget.familyProfil != null) {
              selectChatMemberWindow();
            } else {
              openChat(widget.profil["id"]);
            }
          });
    }

    userBlockierenButton() {
      String? ownId = FirebaseAuth.instance.currentUser?.uid;
      bool onBlockList = widget.profil["geblocktVon"].contains(ownId);

      return SimpleDialogOption(
          child: Row(
            children: [
              Icon(onBlockList ? Icons.do_not_touch : Icons.back_hand),
              const SizedBox(width: 10),
              Text(onBlockList
                  ? AppLocalizations.of(context)!.freigeben
                  : AppLocalizations.of(context)!.blockieren)
            ],
          ),
          onPressed: () {
            userBlockieren(ownId, onBlockList);

            Navigator.pop(context);
            setState(() {});
          });
    }

    meldeUserButton() {
      return SimpleDialogOption(
          child: Row(
            children: [
              const Icon(Icons.report),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.melden),
            ],
          ),
          onPressed: () {
            TextEditingController meldeTextKontroller = TextEditingController();
            Navigator.pop(context);

            showDialog(
                context: context,
                builder: (BuildContext buildContext) {
                  return CustomAlertDialog(
                    height: 380,
                    title: AppLocalizations.of(context)!.benutzerMelden,
                    children: [
                      CustomTextInput(
                          AppLocalizations.of(context)!.benutzerMeldenFrage,
                          meldeTextKontroller,
                          moreLines: 10),
                      const SizedBox(height: 20),
                      FloatingActionButton.extended(
                          onPressed: () {
                            ReportsDatabase().add(
                                userId,
                                "Melde User id: ${widget.profil["id"]}",
                                meldeTextKontroller.text);
                            Navigator.pop(context);
                            customSnackBar(context,
                                AppLocalizations.of(context)!.benutzerGemeldet,
                                color: Colors.green);
                          },
                          label: Text(AppLocalizations.of(context)!.senden))
                    ],
                  );
                });
          });
    }

    moreMenuButton() {
      return IconButton(
        icon: Icon(
          Icons.more_vert,
          color: buttonColor,
        ),
        onPressed: () {
          CustomPopupMenu(context,
              width: 220,
              children: [userBlockierenButton(), meldeUserButton()]);
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: buttonColor),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(child: SizedBox.shrink()),
          if (!_isOwnProfil) friendButton(),
          if (!_isOwnProfil) openNoteButton(),
          if (!_isOwnProfil) openChatButton(),
          if (!_isOwnProfil) moreMenuButton(),
        ],
      ),
    );
  }
}

class _UserInformationDisplay extends StatefulWidget {
  final Map profil;


  const _UserInformationDisplay({Key? key, required this.profil})
      : super(key: key);

  @override
  State<_UserInformationDisplay> createState() => _UserInformationDisplayState();
}

class _UserInformationDisplayState extends State<_UserInformationDisplay> {
  bool tranlsation = false;
  String translatedAboutMe = "";

  checkAccessReiseplanung() {
    Map ownProfil = Hive.box("secureBox").get("ownProfil") ?? {};
    bool hasAccess = false;
    String reiseplanungSetting = widget.profil["reiseplanungPrivacy"];
    bool isPrivacyLevel1 = reiseplanungSetting == privacySetting[0] ||
        reiseplanungSetting == privacySettingEnglisch[0];
    bool isPrivacyLevel2 = reiseplanungSetting == privacySetting[1] ||
        reiseplanungSetting == privacySettingEnglisch[1];
    bool isPrivacyLevel3 = reiseplanungSetting == privacySetting[2] ||
        reiseplanungSetting == privacySettingEnglisch[2];

    if (widget.profil["reisePlanung"].isEmpty) return false;

    if (isPrivacyLevel1) {
      hasAccess = true;
    } else if (isPrivacyLevel2 &&
        (ownProfil["friendlist"].contains(widget.profil["id"]))) {
      hasAccess = true;
    } else if (isPrivacyLevel3 &&
        ownProfil["friendlist"].contains(widget.profil["id"]) &&
        widget.profil["friendlist"].contains(ownProfil["id"])) {
      hasAccess = true;
    }

    return hasAccess;
  }

  translateAboutMe() async {
    if(translatedAboutMe.isEmpty){
      final translator = GoogleTranslator();
      var translation = await translator.translate(
          widget.profil["aboutme"],
          to: "auto");

      translatedAboutMe = translation.text;
    }

    setState(() {
      tranlsation = !tranlsation;
    });

  }

  @override
  Widget build(BuildContext context) {
    bool isOwnProfil = widget.profil["id"] == userId;
    widget.profil["lastLogin"] ??= DateTime.parse("2022-02-13");

    transformDateToText(dateString, {onlyMonth = false}) {
      DateTime date = DateTime.parse(dateString);
      bool laterSameYear =
          date.month > DateTime.now().month && date.year == DateTime.now().year;
      bool laterOnlyYears = date.year > DateTime.now().year;

      if (laterSameYear || laterOnlyYears || onlyMonth) {
        return "${date.month}.${date.year}";
      } else {
        return AppLocalizations.of(context)!.jetzt;
      }
    }

    createZuletztOnlineText() {
      var text = "";
      var color = Colors.grey;
      var size = style.textSize - 2;
      var timeDifferenceLastLogin = Duration(
          microseconds: (DateTime.now().microsecondsSinceEpoch -
                  DateTime.parse(widget.profil["lastLogin"].toString())
                      .microsecondsSinceEpoch)
              .abs());
      var daysOffline = timeDifferenceLastLogin.inDays;
      var monthDifference = timeDifferenceLastLogin.inDays / 30.44;

      if (monthDifference >= monthsUntilInactive) {
        text = AppLocalizations.of(context)!.inaktiv;
        size = headlineTextSize;
      } else if (daysOffline > 30) {
        text = AppLocalizations.of(context)!.langeZeitNichtGesehen;
      } else if (daysOffline > 7) {
        text = AppLocalizations.of(context)!.innerhalbMonatsGesehen;
      } else if (daysOffline > 1) {
        text = AppLocalizations.of(context)!.innerhalbWocheGesehen;
      } else {
        text = AppLocalizations.of(context)!.kuerzlichGesehen;
      }

      return Text(text, style: TextStyle(color: color, fontSize: size));
    }

    locationDisplay() {
      return GestureDetector(
        onTap: () => changePage(
            context, LocationInformationPage(ortName: widget.profil["ort"])),
        child: Row(
          children: [
            Text(
              "${AppLocalizations.of(context)!.aktuelleOrt}: ",
              style: const TextStyle(
                  fontSize: style.textSize,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline),
            ),
            Flexible(
                child: Text(
              widget.profil["ort"],
              style: const TextStyle(
                  fontSize: style.textSize,
                  decoration: TextDecoration.underline),
              maxLines: 2,
            ))
          ],
        ),
      );
    }

    travelTypDisplay() {
      String themaText = "${AppLocalizations.of(context)!.artDerReise}: ";
      String inhaltText =
          global_functions.changeGermanToEnglish(widget.profil["reiseart"]);

      if (spracheIstDeutsch) {
        inhaltText = global_functions.changeEnglishToGerman(widget.profil["reiseart"]);
      }

      return Row(children: [
        Text(themaText,
            style: const TextStyle(
                fontSize: style.textSize, fontWeight: FontWeight.bold)),
        Text(inhaltText, style: const TextStyle(fontSize: style.textSize))
      ]);
    }

    openBesuchteLaenderWindow() {
      List<Widget> besuchteLaenderList = [];

      for (var land in widget.profil["besuchteLaender"]) {
        besuchteLaenderList.add(
            Container(margin: const EdgeInsets.all(10), child: Text(land)));
      }

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context)!.besuchteLaender,
              children: besuchteLaenderList,
            );
          });
    }

    besuchteLaenderDisplay() {
      return InkWell(
        onTap: () => openBesuchteLaenderWindow(),
        child: Row(children: [
          Text(
            "${AppLocalizations.of(context)!.besuchteLaender}: ",
            style: const TextStyle(
                fontSize: style.textSize,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline),
          ),
          Text(widget.profil["besuchteLaender"].length.toString(),
              style: const TextStyle(
                  fontSize: style.textSize,
                  decoration: TextDecoration.underline))
        ]),
      );
    }

    aufreiseDisplay() {
      if (widget.profil["aufreiseSeit"] == null) return const SizedBox.shrink();

      String themenText = "${AppLocalizations.of(context)!.aufReise}: ";
      String seitText =
          widget.profil["aufreiseSeit"].split("-").take(2).toList().reversed.join("-");
      String inhaltText = "";

      if (widget.profil["aufreiseBis"] == null) {
        DateTime aufreiseSeit = DateTime.parse(widget.profil["aufreiseSeit"]);
        String yearsOnTravel =
            (DateTime.now().difference(aufreiseSeit).inDays / 365)
                .toStringAsFixed(1);

        inhaltText =
            "$yearsOnTravel ${AppLocalizations.of(context)!.jahre} / $seitText - ${AppLocalizations.of(context)!.offen}";
      } else {
        DateTime aufreiseSeit = DateTime.parse(widget.profil["aufreiseSeit"]);
        DateTime aufreiseBis = DateTime.parse(widget.profil["aufreiseBis"]);
        String yearsOnTravel =
            (aufreiseBis.difference(aufreiseSeit).inDays / 365)
                .toStringAsFixed(1);
        var bisText = widget.profil["aufreiseBis"]
            .split("-")
            .take(2)
            .toList()
            .reversed
            .join("-");
        inhaltText =
            "$yearsOnTravel ${AppLocalizations.of(context)!.jahre} - $seitText - $bisText";
      }

      return Row(children: [
        Text(themenText,
            style: const TextStyle(
                fontSize: style.textSize, fontWeight: FontWeight.bold)),
        Text(inhaltText, style: const TextStyle(fontSize: style.textSize))
      ]);
    }

    reiseInfoBox() {
      return _InfoBox(
          child: Column(
        children: [
          const SizedBox(height: 5),
          locationDisplay(),
          const SizedBox(height: 10),
          travelTypDisplay(),
          const SizedBox(height: 10),
          besuchteLaenderDisplay(),
          const SizedBox(height: 10),
          aufreiseDisplay(),
          const SizedBox(height: 5),
        ],
      ));
    }

    sprachenDisplay() {
      String themenText = "${AppLocalizations.of(context)!.sprachen}: ";
      String inhaltText =
          global_functions.changeGermanToEnglish(widget.profil["sprachen"]).join(", ");

      if (spracheIstDeutsch) {
        inhaltText = global_functions
            .changeEnglishToGerman(widget.profil["sprachen"])
            .join(", ");
      }

      return Row(children: [
        Text(themenText,
            style: const TextStyle(
                fontSize: style.textSize, fontWeight: FontWeight.bold)),
        Text(inhaltText, style: const TextStyle(fontSize: style.textSize))
      ]);
    }

    kinderDisplay() {
      List childrenProfilList = widget.profil["kinder"];
      childrenProfilList.sort();
      List childrenList = [];
      String alterZusatz = spracheIstDeutsch ? "J" : "y";

      for (var child in childrenProfilList) {
        childrenList.add(
            global_functions.ChangeTimeStamp(child).intoYears().toString() +
                alterZusatz);
      }

      return Row(
        children: [
          Text("${AppLocalizations.of(context)!.kinder}: ",
              style: const TextStyle(
                  fontSize: style.textSize, fontWeight: FontWeight.bold)),
          Text(childrenList.reversed.join(", "),
              style: const TextStyle(fontSize: style.textSize))
        ],
      );
    }

    familyInfoBox() {
      return _InfoBox(
        child: Column(
          children: [
            const SizedBox(
              height: 5,
            ),
            sprachenDisplay(),
            const SizedBox(
              height: 10,
            ),
            kinderDisplay(),
            const SizedBox(height: 5)
          ],
        ),
      );
    }

    reisePlanungBox() {
      var reiseplanung = [];
      var reiseplanungPrivacy = spracheIstDeutsch
          ? changeEnglishToGerman(widget.profil["reiseplanungPrivacy"])
          : changeGermanToEnglish(widget.profil["reiseplanungPrivacy"]);

      widget.profil["reisePlanung"]
          .sort((a, b) => a["von"].compareTo(b["von"]) as int);

      for (var reiseplan in widget.profil["reisePlanung"]) {
        String ortText = reiseplan["ortData"]["city"];
        DateTime dateReiseplanBis = DateTime.parse(reiseplan["bis"]);
        DateTime dateNow = DateTime(DateTime.now().year, DateTime.now().month);

        if (dateReiseplanBis.isBefore(dateNow)) continue;

        if (reiseplan["ortData"]["city"] !=
            reiseplan["ortData"]["countryname"]) {
          ortText += " / ${reiseplan["ortData"]["countryname"]}";
        }

        reiseplanung.add(GestureDetector(
          onTap: () => changePage(context,
              LocationInformationPage(ortName: reiseplan["ortData"]["city"])),
          child: Container(
            margin: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                Row(
                  children: [
                    Text(
                        "${transformDateToText(reiseplan["von"])} - ${transformDateToText(reiseplan["bis"], onlyMonth: true)} in ",
                        style: const TextStyle(fontSize: style.textSize)),
                    Text(ortText,
                        style: const TextStyle(
                            fontSize: style.textSize,
                            decoration: TextDecoration.underline))
                  ],
                ),
              ],
            ),
          ),
        ));
      }

      if (reiseplanung.isEmpty) return const SizedBox.shrink();

      return _InfoBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Text(
                "${AppLocalizations.of(context)!.reisePlanung}: ",
                style: const TextStyle(
                    fontSize: style.textSize, fontWeight: FontWeight.bold),
              ),
              if (isOwnProfil)
                Text(
                    "(${AppLocalizations.of(context)!.fuer} $reiseplanungPrivacy)")
            ],
          ),
          const SizedBox(height: 5),
          ...reiseplanung,
          const SizedBox(height: 5)
        ]),
      );
    }

    socialMediaItem(link) {
      String displayLink = link;
      Widget icon;

      if (link.contains("instagram")) {
        displayLink = link.replaceAll("https://", "");
        displayLink = displayLink.split("/")[1];
        displayLink = displayLink.split("?")[0];

        icon = Padding(
          padding: const EdgeInsets.all(2.0),
          child: Image.asset(
            "assets/icons/instagram.png",
            width: 20,
            height: 20,
          ),
        );
      } else if (link.contains("facebook")) {
        displayLink = link.replaceAll("https://", "");
        displayLink = displayLink.split("/")[1];

        icon = Padding(
          padding: const EdgeInsets.all(2.0),
          child:
              Image.asset("assets/icons/facebook.png", width: 20, height: 20),
        );
      } else if (link.contains("youtube")) {
        displayLink = link.replaceAll("https://", "");
        displayLink = displayLink.split("/")[1];

        icon = Padding(
          padding: const EdgeInsets.all(2.0),
          child: Image.asset("assets/icons/youtube.png", width: 20, height: 20),
        );
      } else if(link.contains("linktr.ee")){
        displayLink = link.replaceAll("https://", "");
        displayLink = displayLink.split("/")[1];

        icon = Padding(
            padding: const EdgeInsets.all(2.0),
            child: Image.asset("assets/icons/linktree.png", width: 20, height: 20)
        );
      }else {
        icon = const Icon(Icons.public);
      }

      return Container(
        margin: const EdgeInsets.all(5),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 5),
            InkWell(
              onTap: () => global_functions.openURL(link),
              child: SizedBox(
                  width: 300,
                  child: Text(displayLink,
                      style: const TextStyle(
                        color: Colors.blue,
                      ))),
            )
          ],
        ),
      );
    }

    socialMediaBox() {
      List<Widget> socialMediaContent = [];

      for (var socialMediaLink in widget.profil["socialMediaLinks"]) {
        socialMediaContent.add(socialMediaItem(socialMediaLink));
      }

      return _InfoBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Social Media: ",
              style: TextStyle(
                  fontSize: style.textSize, fontWeight: FontWeight.bold)),
          ...socialMediaContent
        ]),
      );
    }

    interessenBox() {
      Map ownProfil = Hive.box('secureBox').get("ownProfil") ?? {};
      String themenText = AppLocalizations.of(context)!.interessen;
      List profilInteresets =
          global_functions.changeGermanToEnglish(widget.profil["interessen"]);
      List matchInterest = [];

      if (spracheIstDeutsch) {
        profilInteresets =
            global_functions.changeEnglishToGerman(widget.profil["interessen"]);
      }

      for (var interest in widget.profil["interessen"]) {
        List ownInterests = [
          ...global_functions.changeEnglishToGerman(ownProfil["interessen"]),
          ...global_functions.changeGermanToEnglish(ownProfil["interessen"])
        ];
        bool match = false;

        if (ownInterests.contains(interest) && !isOwnProfil) match = true;

        matchInterest.add(match);
      }

      return _InfoBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              themenText,
              style: const TextStyle(
                  fontSize: style.textSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < profilInteresets.length; i++)
                    Container(
                      margin: const EdgeInsets.only(
                          left: 5, right: 5, top: 5, bottom: 5),
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, top: 5, bottom: 5),
                      decoration: BoxDecoration(
                          color: matchInterest[i]
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.white,
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        profilInteresets[i],
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                ],
              ),
            )
          ],
        ),
      );
    }

    aboutmeBox() {
      return _InfoBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.ueberMich,
                  style: const TextStyle(
                      fontSize: style.textSize, fontWeight: FontWeight.bold),
                ),
                const Expanded(child: SizedBox.shrink()),
                InkWell(onTap: () => translateAboutMe(), child: Text("translate", style: TextStyle(fontSize: style.textSize, color: Theme.of(context).colorScheme.secondary),))
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            TextWithHyperlinkDetection(
              text: tranlsation
                  ? translatedAboutMe + "\n\n<${AppLocalizations.of(context)!.automatischeUebersetzung}>"
                  : widget.profil["aboutme"],
              fontsize: style.textSize - 1,
            )
          ],
        ),
      );
    }

    return Container(
        padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text("Info",
                  style: TextStyle(
                      fontSize: headlineTextSize,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const Expanded(child: SizedBox.shrink()),
              createZuletztOnlineText()
            ]),
            const SizedBox(height: 15),
            reiseInfoBox(),
            familyInfoBox(),
            interessenBox(),
            if (checkAccessReiseplanung() || isOwnProfil) reisePlanungBox(),
            if (widget.profil["socialMediaLinks"].isNotEmpty) socialMediaBox(),
            if (widget.profil["aboutme"].isNotEmpty) aboutmeBox(),
          ],
        ));
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 15),
        width: double.infinity,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.blueGrey),
            borderRadius: BorderRadius.circular(style.roundedCorners)),
        child: child);
  }
}
