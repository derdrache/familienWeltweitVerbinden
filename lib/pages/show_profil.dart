import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:familien_suche/widgets/dialogWindow.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../global/custom_widgets.dart';
import '../global/encryption.dart';
import '../global/global_functions.dart' as global_functions;
import '../global/global_functions.dart';
import '../global/variablen.dart' as global_variablen;
import '../global/variablen.dart';
import '../pages/chat/chat_details.dart';
import '../services/database.dart';
import '../services/notification.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/profil_image.dart';
import '../widgets/text_with_hyperlink_detection.dart';
import 'informationen/location/location_Information.dart';

var userId = FirebaseAuth.instance.currentUser.uid;
double columnSpacing = 15;
double textSize = 16;
double headlineTextSize = 18;

// ignore: must_be_immutable
class ShowProfilPage extends StatefulWidget {
  String userName;
  Map profil;

  ShowProfilPage({Key key, this.userName, this.profil}) : super(key: key);

  @override
  _ShowProfilPageState createState() => _ShowProfilPageState();
}

class _ShowProfilPageState extends State<ShowProfilPage> {
  Map profil;
  Map familyProfil;

  @override
  void initState() {
    profil = Map.of(widget.profil);

    checkIfIsFamilyMember();

    super.initState();
  }

  checkIfIsFamilyMember() {
    var spracheIstDeutsch = kIsWeb
        ? window.locale.languageCode == "de"
        : Platform.localeName == "de_DE";
    familyProfil = getFamilyProfil(familyMember: profil["id"]);

    if (familyProfil == null ||
        familyProfil["mainProfil"].isEmpty ||
        familyProfil["name"].isEmpty) {
      familyProfil = null;
      return;
    }

    var familyName = familyProfil["name"];
    var mainMemberProfil = Map.of(getProfilFromHive(profilId: familyProfil["mainProfil"]));
    mainMemberProfil["name"] =
        (spracheIstDeutsch ? "Familie" : "Family") + " " + familyName;
    profil = mainMemberProfil;
  }

  @override
  Widget build(BuildContext context) {

    return SelectionArea(
      child: Scaffold(
        appBar: _AppBar(profil: profil, familyProfil: familyProfil),
        body: SafeArea(
          child: SizedBox(
            width: double.maxFinite,
            child: Scrollbar(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                }),
                child: ListView(children: [
                  _UserNameDisplay(profil: profil, familyProfil: familyProfil),
                  const SizedBox(height: 10),
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

class _AppBar extends StatefulWidget implements PreferredSizeWidget {
  final Map profil;
  final Map familyProfil;

  const _AppBar({Key key, this.profil, this.familyProfil}) : super(key: key);

  @override
  State<_AppBar> createState() => _AppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

class _AppBarState extends State<_AppBar> {
  var ownProfil = Hive.box('secureBox').get("ownProfil") ?? [];
  var userFriendlist = Hive.box('secureBox').get("ownProfil")["friendlist"];
  String _userName;
  bool _isOwnProfil;

  @override
  void initState(){
    bool isFmailyMember = widget.familyProfil != null
        && widget.familyProfil["members"].contains(userId);
    _isOwnProfil = widget.profil["id"] == userId || isFmailyMember;
    _userName = widget.profil["name"];

    createUserNotizen();

    super.initState();
  }

  createUserNotizen() async{
    if(ownProfil["userNotizen"] != null) return;

    var userNotizen = await NotizDatabase().getData("userNotizen", "WHERE id = '$userId'");

    if(userNotizen == false){
      NotizDatabase().newNotize();
      ownProfil["userNotizen"] = {};
    }else{
      if(userNotizen.isNotEmpty){
        userNotizen = decrypt(userNotizen);
        userNotizen = json.decode(userNotizen);
      }
      ownProfil["userNotizen"] = userNotizen;
    }

  }

  saveNotiz(notiz){
    ownProfil["userNotizen"][widget.profil["id"]] = notiz;

    var encryptNotes = encrypt(json.encode(ownProfil["userNotizen"]));

    NotizDatabase().update(
        "userNotizen = '$encryptNotes'",
        "WHERE id = '$userId'"
    );
  }

  openChat(chatpartnerId, chatpartnerName) async {
    global_functions.changePage(
        context,
        ChatDetailsPage(
          chatPartnerId: chatpartnerId,
        ));
  }

  openNoteWindow(){
    TextEditingController userNotizController = TextEditingController();
    bool changeNote = false;

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(
            builder: (context, noteState) {
              var notizen = ownProfil["userNotizen"];
              var userNotiz = notizen[widget.profil["id"]];

              return CustomAlertDialog(
                  title: AppLocalizations.of(context).notizeUeber + _userName,
                  children: [
                    if(userNotiz == null || changeNote) TextField(
                      controller: userNotizController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: AppLocalizations.of(context).notizEingeben,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if(userNotiz== null || changeNote) FloatingActionButton.extended(
                      label: Text(AppLocalizations.of(context).speichern),
                        onPressed: (){
                          saveNotiz(userNotizController.text);

                          noteState(() {
                            changeNote = false;
                          });
                        }
                    ),
                    if(userNotiz != null && !changeNote) InkWell(
                      onTap: ()=> noteState((){
                        changeNote = true;
                        userNotizController.text = userNotiz;
                      }),
                      child: Text(userNotiz, maxLines: 10)
                    ),
                    const SizedBox(height: 5)
                  ]);
            }
          );
        });
  }

  @override
  Widget build(BuildContext context) {

    openNoteButton(){
      return IconButton(
        icon: const Icon(Icons.description),
        onPressed: () => openNoteWindow(),
      );
    }

    openChatButton() {
      return IconButton(
          icon: const Icon(Icons.message),
          onPressed: () async {
            if (widget.familyProfil != null) {
              List<Widget> menuList = [];

              widget.familyProfil["members"].remove(userId);

              for (var memberId in widget.familyProfil["members"]) {
                var memberName =
                    getProfilFromHive(profilId: memberId, getNameOnly: true);

                menuList.add(SimpleDialogOption(
                  child: Row(
                    children: [
                      Text(memberName),
                    ],
                  ),
                  onPressed: () {
                    openChat(memberId, memberName);
                  },
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
                            insetPadding: const EdgeInsets.only(
                                top: 40, left: 0, right: 10),
                            children: menuList,
                          ),
                        ),
                      ],
                    );
                  });
            } else {
              openChat(widget.profil["id"], widget.profil["name"]);
            }
          });
    }

    friendlistButton() {
      var onFriendlist = userFriendlist.contains(widget.profil["id"]);

      return SimpleDialogOption(
          child: Row(
            children: [
              Icon(onFriendlist ? Icons.person_remove : Icons.person_add),
              const SizedBox(width: 10),
              Text(onFriendlist
                  ? AppLocalizations.of(context).freundEntfernen
                  : AppLocalizations.of(context).freundHinzufuegen)
            ],
          ),
          onPressed: () {
            var snackbarText = "";
            var newsData = {
              "typ": "friendlist",
              "information": "",
            };

            if (onFriendlist) {
              userFriendlist.remove(widget.profil["id"]);
              snackbarText =
                  _userName + AppLocalizations.of(context).friendlistEntfernt;

              var newsId = getNewsId("added " + widget.profil["id"]);

              if (newsId != null) NewsPageDatabase().delete(newsId);
            } else {
              userFriendlist.add(widget.profil["id"]);
              snackbarText = _userName +
                  AppLocalizations.of(context).friendlistHinzugefuegt;

              prepareFriendNotification(
                  newFriendId: userId,
                  toId: widget.profil["id"],
                  toCanGerman: widget.profil["sprachen"].contains("Deutsch") ||
                      widget.profil["sprachen"].contains("german"));

              newsData["information"] = "added " + widget.profil["id"];
              NewsPageDatabase().addNewNews(newsData);
            }

            var localBox = Hive.box('secureBox');
            var ownProfil = localBox.get("ownProfil");

            ownProfil["friendlist"] = userFriendlist;
            localBox.put("ownProfil", ownProfil);

            customSnackbar(context, snackbarText, color: Colors.green);

            ProfilDatabase().updateProfil(
                "friendlist = '${jsonEncode(userFriendlist)}'",
                "WHERE id = '$userId'");

            Navigator.pop(context);
            setState(() {});
          });
    }

    userBlockierenButton() {
      var ownId = FirebaseAuth.instance.currentUser.uid;
      var onBlockList = widget.profil["geblocktVon"].contains(ownId);

      return SimpleDialogOption(
          child: Row(
            children: [
              Icon(onBlockList ? Icons.do_not_touch : Icons.back_hand),
              const SizedBox(width: 10),
              Text(onBlockList
                  ? AppLocalizations.of(context).freigeben
                  : AppLocalizations.of(context).blockieren)
            ],
          ),
          onPressed: () {
            String snackbarText = "";
            var allProfils = Hive.box('secureBox').get("profils");
            String databaseQuery = "";

            if (onBlockList) {
              widget.profil["geblocktVon"].remove(ownId);
              databaseQuery =
                  "geblocktVon = JSON_REMOVE(geblocktVon, JSON_UNQUOTE(JSON_SEARCH(geblocktVon, 'one', '$ownId')))";
              snackbarText = AppLocalizations.of(context).benutzerFreigegeben;
            } else {
              widget.profil["geblocktVon"].add(ownId);
              databaseQuery =
                  "geblocktVon = JSON_ARRAY_APPEND(geblocktVon, '\$', '$ownId')";
              snackbarText = AppLocalizations.of(context).benutzerBlockieren;
            }

            for (var profil in allProfils) {
              if (profil["id"] == profil["id"]) {
                profil["blockiertVon"] = profil["geblocktVon"];
              }
            }

            Hive.box('secureBox').put("profils", allProfils);

            customSnackbar(context, snackbarText, color: Colors.green);

            ProfilDatabase().updateProfil(
                databaseQuery, "WHERE id = '${widget.profil["id"]}'");

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
              Text(AppLocalizations.of(context).melden),
            ],
          ),
          onPressed: () {
            var meldeTextKontroller = TextEditingController();
            Navigator.pop(context);

            showDialog(
                context: context,
                builder: (BuildContext buildContext) {
                  return CustomAlertDialog(
                    height: 380,
                    title: AppLocalizations.of(context).benutzerMelden,
                    children: [
                      customTextInput(
                          AppLocalizations.of(context).benutzerMeldenFrage,
                          meldeTextKontroller,
                          moreLines: 10),
                      const SizedBox(height: 20),
                      FloatingActionButton.extended(
                          onPressed: () {
                            ReportsDatabase().add(
                                userId,
                                "Melde User id: " + widget.profil["id"],
                                meldeTextKontroller.text);
                            Navigator.pop(context);
                            customSnackbar(context,
                                AppLocalizations.of(context).benutzerGemeldet,
                                color: Colors.green);
                          },
                          label: Text(AppLocalizations.of(context).senden))
                    ],
                  );
                });
          });
    }

    moreMenuButton() {
      return IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 220,
                      child: SimpleDialog(
                        contentPadding: EdgeInsets.zero,
                        insetPadding:
                            const EdgeInsets.only(top: 40, left: 0, right: 10),
                        children: [
                          friendlistButton(),
                          userBlockierenButton(),
                          meldeUserButton()
                        ],
                      ),
                    ),
                  ],
                );
              });
        },
      );
    }

    return CustomAppBar(title: "", buttons: [
      _isOwnProfil ? const SizedBox.shrink() : openNoteButton(),
      _isOwnProfil ? const SizedBox.shrink() : openChatButton(),
      _isOwnProfil ? const SizedBox.shrink() : moreMenuButton()
    ]);
  }
}

// ignore: must_be_immutable
class _UserNameDisplay extends StatelessWidget {
  Map profil;
  Map familyProfil;

  _UserNameDisplay({Key key, this.profil, this.familyProfil}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width*0.7;

    openChat(chatpartnerId, chatpartnerName) async {
      global_functions.changePage(
          context,
          ChatDetailsPage(
            chatPartnerId: chatpartnerId,
            chatPartnerName: chatpartnerName,
          ));
    }

    getFamilyMemberNames() {
      var familyMemberName = "";

      if (familyProfil != null) {
        var familyMember = familyProfil["members"];
        for (var member in familyMember) {
          familyMemberName +=
              getProfilFromHive(profilId: member, getNameOnly: true);
          familyMemberName += ", ";
        }
      }

      return familyMemberName;
    }

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 10, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfilImage(profil, fullScreenWindow: true),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => openChat(profil["id"], profil["name"]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: screenWidth,
                      child: Text(
                        profil["name"],
                        style: TextStyle(
                            fontSize: profil["name"].length > 20 ? 20 : 24,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    if (familyProfil != null) const SizedBox(height: 5),
                    if (familyProfil != null) Text(getFamilyMemberNames())
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserInformationDisplay extends StatelessWidget {
  final Map profil;

  checkAccessReiseplanung() {
    var ownProfil = Hive.box("secureBox").get("ownProfil");
    var hasAccess = false;
    var reiseplanungSetting = profil["reiseplanungPrivacy"];
    var isPrivacyLevel1 = reiseplanungSetting == privacySetting[0] ||
        reiseplanungSetting == privacySettingEnglisch[0];
    var isPrivacyLevel2 = reiseplanungSetting == privacySetting[1] ||
        reiseplanungSetting == privacySettingEnglisch[1];
    var isPrivacyLevel3 = reiseplanungSetting == privacySetting[2] ||
        reiseplanungSetting == privacySettingEnglisch[2];

    if (profil["reisePlanung"].isEmpty) return false;

    if (isPrivacyLevel1) {
      hasAccess = true;
    } else if (isPrivacyLevel2 &&
        (ownProfil["friendlist"].contains(profil["id"]))) {
      hasAccess = true;
    } else if (isPrivacyLevel3 &&
        ownProfil["friendlist"].contains(profil["id"]) &&
        profil["friendlist"].contains(ownProfil["id"])) {
      hasAccess = true;
    }

    return hasAccess;
  }

  const _UserInformationDisplay({Key key, this.profil}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isOwnProfil = profil["id"] == userId;
    profil["lastLogin"] = profil["lastLogin"] ?? DateTime.parse("2022-02-13");

    transformDateToText(dateString, {onlyMonth = false}) {
      DateTime date = DateTime.parse(dateString);

      if ((date.month > DateTime.now().month &&
              date.year == DateTime.now().year) ||
          date.year > DateTime.now().year ||
          onlyMonth) {
        return date.month.toString() + "." + date.year.toString();
      } else {
        return AppLocalizations.of(context).jetzt;
      }
    }

    openBesuchteLaenderWindow() {
      List<Widget> besuchteLaenderList = [];

      for (var land in profil["besuchteLaender"]) {
        besuchteLaenderList.add(
            Container(margin: const EdgeInsets.all(10), child: Text(land)));
      }

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).besuchteLaender,
              children: besuchteLaenderList,
            );
          });
    }

    locationBox() {
      return GestureDetector(
        onTap: () => changePage(context, LocationInformationPage(ortName: profil["ort"])),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context).aktuelleOrt + ": ",
              style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
            ),
            Flexible(
                child: Text(
              profil["ort"],
              style: TextStyle(fontSize: textSize),
              maxLines: 2,
            ))
          ],
        ),
      );
    }

    travelTypBox() {
      var themaText = AppLocalizations.of(context).artDerReise + ": ";
      var inhaltText =
          global_functions.changeGermanToEnglish(profil["reiseart"]);

      if (spracheIstDeutsch) {
        inhaltText = global_functions.changeEnglishToGerman(profil["reiseart"]);
      }

      return Row(children: [
        Text(themaText,
            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold)),
        Text(inhaltText, style: TextStyle(fontSize: textSize))
      ]);
    }

    aufreiseBox() {
      if (profil["aufreiseSeit"] == null) return const SizedBox.shrink();

      var themenText = AppLocalizations.of(context).aufReise + ": ";
      var seitText =
          profil["aufreiseSeit"].split("-").take(2).toList().reversed.join("-");
      var inhaltText = "";

      if (profil["aufreiseBis"] == null) {
        inhaltText = seitText + " - " + AppLocalizations.of(context).offen;
      } else {
        var bisText = profil["aufreiseBis"]
            .split("-")
            .take(2)
            .toList()
            .reversed
            .join("-");
        inhaltText = seitText + " - " + bisText;
      }

      return Column(children: [
        Row(children: [
          Text(themenText,
              style:
                  TextStyle(fontSize: textSize, fontWeight: FontWeight.bold)),
          Text(inhaltText, style: TextStyle(fontSize: textSize))
        ]),
        SizedBox(height: columnSpacing),
      ]);
    }

    sprachenBox() {
      var themenText = AppLocalizations.of(context).sprachen + ": ";
      var inhaltText =
          global_functions.changeGermanToEnglish(profil["sprachen"]).join(", ");

      if (spracheIstDeutsch) {
        inhaltText = global_functions
            .changeEnglishToGerman(profil["sprachen"])
            .join(", ");
      }

      return Row(children: [
        Text(themenText,
            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold)),
        Text(inhaltText, style: TextStyle(fontSize: textSize))
      ]);
    }

    kinderBox() {
      var childrenProfilList = profil["kinder"];
      childrenProfilList.sort();
      var childrenList = [];
      var alterZusatz = spracheIstDeutsch ? "J" : "y";

      childrenProfilList.forEach((child) {
        childrenList.add(
            global_functions.ChangeTimeStamp(child).intoYears().toString() +
                alterZusatz);
      });

      return Row(
        children: [
          Text(AppLocalizations.of(context).kinder + ": ",
              style:
                  TextStyle(fontSize: textSize, fontWeight: FontWeight.bold)),
          Text(childrenList.reversed.join(", "),
              style: TextStyle(fontSize: textSize))
        ],
      );
    }

    interessenBox() {
      var themenText = AppLocalizations.of(context).interessen + ": ";
      var inhaltText = global_functions
          .changeGermanToEnglish(profil["interessen"])
          .join(", ");

      if (spracheIstDeutsch) {
        inhaltText = global_functions
            .changeEnglishToGerman(profil["interessen"])
            .join(", ");
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(themenText,
            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(
          inhaltText,
          style: TextStyle(fontSize: textSize),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        )
      ]);
    }

    aboutmeBox() {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).ueberMich + ": ",
              style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            TextWithHyperlinkDetection(
              text: profil["aboutme"],
              fontsize: textSize-1,
            )
          ],
        ),
      );
    }

    tradeNotizeBox() {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).verkaufenTauschenSchenken + ": ",
              style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              profil["tradeNotize"],
              style: TextStyle(fontSize: textSize),
            ),
          ],
        ),
      );
    }

    reisePlanungBox() {
      var reiseplanung = [];
      var reiseplanungPrivacy = spracheIstDeutsch
          ? changeEnglishToGerman(profil["reiseplanungPrivacy"])
          : changeGermanToEnglish(profil["reiseplanungPrivacy"]);

      profil["reisePlanung"]
          .sort((a, b) => a["von"].compareTo(b["von"]) as int);

      for (var reiseplan in profil["reisePlanung"]) {
        String ortText = reiseplan["ortData"]["city"];
        var dateReiseplanBis = DateTime.parse(reiseplan["bis"]);
        var dateNow = DateTime(DateTime.now().year, DateTime.now().month);

        if (dateReiseplanBis.isBefore(dateNow)) continue;

        if (reiseplan["ortData"]["city"] !=
            reiseplan["ortData"]["countryname"]) {
          ortText += " / " + reiseplan["ortData"]["countryname"];
        }

        reiseplanung.add(GestureDetector(
          onTap: () => changePage(context, LocationInformationPage(ortName: profil["ort"])),
          child: Container(
            margin: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                      transformDateToText(reiseplan["von"]) +
                          " - " +
                          transformDateToText(reiseplan["bis"], onlyMonth: true) +
                          " in " +
                          ortText,
                      style: TextStyle(fontSize: textSize)),
                ),
              ],
            ),
          ),
        ));
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).reisePlanung + ": ",
              style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
            ),
            if (isOwnProfil)
              Text("(" +
                  AppLocalizations.of(context).fuer +
                  reiseplanungPrivacy +
                  ")")
          ],
        ),
        const SizedBox(height: 5),
        ...reiseplanung,
        const SizedBox(height: 5)
      ]);
    }

    besuchteLaenderBox() {
      return InkWell(
        onTap: () => openBesuchteLaenderWindow(),
        child: Container(
          margin: EdgeInsets.only(top: columnSpacing, bottom: columnSpacing),
          child: Row(children: [
            Text(AppLocalizations.of(context).besuchteLaender + ": ",
                style:
                    TextStyle(fontSize: textSize, fontWeight: FontWeight.bold)),
            Text(profil["besuchteLaender"].length.toString(),
                style: TextStyle(fontSize: textSize))
          ]),
        ),
      );
    }

    createZuletztOnlineText() {
      var text = "";
      var color = Colors.grey;
      var size = textSize - 2;
      var monthsUntilInactive = 3;
      var timeDifferenceLastLogin = Duration(
          microseconds: (DateTime.now().microsecondsSinceEpoch -
                  DateTime.parse(profil["lastLogin"].toString())
                      .microsecondsSinceEpoch)
              .abs());
      var daysOffline = timeDifferenceLastLogin.inDays;
      var monthDifference = timeDifferenceLastLogin.inDays / 30.44;

      if (monthDifference >= monthsUntilInactive) {
        text = AppLocalizations.of(context).inaktiv;
        size = headlineTextSize;
      } else if (daysOffline > 30) {
        text = AppLocalizations.of(context).langeZeitNichtGesehen;
      } else if (daysOffline > 7) {
        text = AppLocalizations.of(context).innerhalbMonatsGesehen;
      } else if (daysOffline > 1) {
        text = AppLocalizations.of(context).innerhalbWocheGesehen;
      } else {
        text = AppLocalizations.of(context).kuerzlichGesehen;
      }

      return Text(text, style: TextStyle(color: color, fontSize: size));
    }

    socialMediaItem(link){
      return Container(
        margin: const EdgeInsets.all(5),
        child: Row(
          children: [
            const Text("- "),
            TextWithHyperlinkDetection(text: link,)
          ],
        ),
      );
    }

    socialMediaBox(){
      List<Widget> socialMediaContent = [];

      for(var socialMediaLink in profil["socialMediaLinks"]){
        socialMediaContent.add(socialMediaItem(socialMediaLink));
      }

      return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Social Media: ",
                style:
                TextStyle(fontSize: textSize, fontWeight: FontWeight.bold)),
            ...socialMediaContent
          ]));
    }



    return Container(
        padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: global_variablen.borderColorGrey))),
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
            SizedBox(height: columnSpacing),
            locationBox(),
            SizedBox(height: columnSpacing),
            travelTypBox(),
            SizedBox(height: columnSpacing),
            aufreiseBox(),
            sprachenBox(),
            SizedBox(height: columnSpacing),
            kinderBox(),
            besuchteLaenderBox(),
            if (checkAccessReiseplanung() || isOwnProfil) reisePlanungBox(),
            if(profil["socialMediaLinks"].isNotEmpty) socialMediaBox(),
            if (profil["aboutme"].isNotEmpty) aboutmeBox(),
            if (profil["tradeNotize"].isNotEmpty) tradeNotizeBox(),
            interessenBox(),
            SizedBox(height: columnSpacing),
          ],
        ));
  }
}


