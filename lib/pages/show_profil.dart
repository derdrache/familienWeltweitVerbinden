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

// ignore: must_be_immutable
class ShowProfilPage extends StatefulWidget {
  String userName;
  Map profil;
  var ownProfil;
  var reiseplanungSpezial;

  ShowProfilPage(
      {Key key,
      this.userName,
      this.profil,
      this.ownProfil = false,
      this.reiseplanungSpezial = false})
      : super(key: key);

  @override
  _ShowProfilPageState createState() => _ShowProfilPageState();
}

class _ShowProfilPageState extends State<ShowProfilPage> {
  var userID = FirebaseAuth.instance.currentUser.uid;
  var spracheIstDeutsch = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";
  var userFriendlist = Hive.box('secureBox').get("ownProfil")["friendlist"];
  double columnAbstand = 15;
  double textSize = 16;
  double healineTextSize = 18;
  var monthsUntilInactive = 3;
  var timeDifferenceLastLogin;
  Map profil;
  var familyProfil;

  @override
  void initState() {
    profil = Map.of(widget.profil);
    checkIsOwnProfil();
    checkFamilyMember();
    checkAccessReiseplanung();
    timeDifferenceLastLogin = Duration(
        microseconds: (DateTime.now().microsecondsSinceEpoch -
                DateTime.parse(profil["lastLogin"].toString())
                    .microsecondsSinceEpoch)
            .abs());

    if(widget.reiseplanungSpezial) setNormalProfil();

    super.initState();
  }

  checkIsOwnProfil() {
    if (profil["id"] == userID) widget.ownProfil = true;
  }

  checkFamilyMember(){
    familyProfil = getFamilyProfil(familyMember: profil["id"]);

    if(familyProfil == null) return;

    var familyName = familyProfil["name"];
    var mainMemberProfil = Map.of(getProfilFromHive(profilId: familyProfil["mainProfil"]));
    mainMemberProfil["name"] = (spracheIstDeutsch ? "Familie:" : "family") + " " + familyName;
    profil = mainMemberProfil;
  }

  checkAccessReiseplanung() {
    var hasReiseplanungAccess = false;
    var reiseplanungSetting = profil["reiseplanungPrivacy"];

    if (profil["reisePlanung"].isEmpty) return false;

    if (reiseplanungSetting == privacySetting[0] ||
        reiseplanungSetting == privacySettingEnglisch[0]) {
      hasReiseplanungAccess = true;
    } else if ((reiseplanungSetting == privacySetting[1] ||
            reiseplanungSetting == privacySettingEnglisch[1]) &&
        (widget.ownProfil["friendlist"].contains(profil["id"]))) {
      hasReiseplanungAccess = true;
    } else if ((reiseplanungSetting == privacySetting[2] ||
            reiseplanungSetting == privacySettingEnglisch[2]) &&
        (widget.ownProfil["friendlist"].contains(profil["id"])) &&
        (profil["friendlist"].contains(widget.ownProfil["id"]))) {
      hasReiseplanungAccess = true;
    }

    return hasReiseplanungAccess;
  }

  getMonthDifference() {
    profil["lastLogin"] =
        profil["lastLogin"] ?? DateTime.parse("2022-02-13");
    return timeDifferenceLastLogin.inDays / 30.44;
  }

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

  setNormalProfil(){
    var localProfils = Hive.box('secureBox').get("profils") ?? [];
    var profilData;


    for(var profil in localProfils){
      if(profil["id"] == profil["id"]){
        profilData = profil;
      }
    }

    profil = Map.of(profilData);
  }

  openBesuchteLaenderWindow() {
    List<Widget> besuchteLaenderList = [];

    for (var land in profil["besuchteLaender"]) {
      besuchteLaenderList
          .add(Container(margin: const EdgeInsets.all(10), child: Text(land)));
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

  openChat(chatpartnerId, chatpartnerName) async {
    var chatId = global_functions.getChatID(chatpartnerId);

    var groupChatData =
        await ChatDatabase().getChatData("*", "WHERE id = '$chatId'");

    if (groupChatData == false) {
      groupChatData = {
        "users": {
          chatpartnerId: {"name": profil["name"], "newMessages": 0},
          userID: {"name": widget.userName, "newMessages": 0}
        }
      };
    }

    global_functions.changePage(
        context,
        ChatDetailsPage(
          chatPartnerId: chatpartnerId,
          groupChatData: groupChatData,
        ));
  }

  @override
  Widget build(BuildContext context) {
    var monthDifference = getMonthDifference();

    openChatButton() {
      return IconButton(
          icon: const Icon(Icons.message),
          onPressed: () async {

            if (familyProfil != null) {
              List<Widget> menuList = [];

              familyProfil["members"].remove(userID);

              for (var memberId in familyProfil["members"]) {
                var memberName = getProfilFromHive(profilId: memberId, getNameOnly: true);

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
              openChat(profil["id"], profil["name"]);
            }
          });
    }

    friendlistButton() {
      var onFriendlist = userFriendlist.contains(profil["id"]);

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
              userFriendlist.remove(profil["id"]);
              snackbarText = profil["name"] +
                  AppLocalizations.of(context).friendlistEntfernt;

              var newsId = getNewsId("added " + profil["id"]);

              if(newsId != null) NewsPageDatabase().delete(newsId);
            } else {
              userFriendlist.add(profil["id"]);
              snackbarText = profil["name"] +
                  AppLocalizations.of(context).friendlistHinzugefuegt;


              prepareFriendNotification(
                  newFriendId: userID,
                  toId: profil["id"],
                  toCanGerman: profil["sprachen"].contains("Deutsch") ||
                      profil["sprachen"].contains("german"));

              newsData["information"] = "added " + profil["id"];
              NewsPageDatabase().addNewNews(newsData);
            }

            var localBox = Hive.box('secureBox');
            var ownProfil = localBox.get("ownProfil");

            ownProfil["friendlist"] = userFriendlist;
            localBox.put("ownProfil", ownProfil);

            customSnackbar(context, snackbarText, color: Colors.green);

            ProfilDatabase().updateProfil(
                "friendlist = '${jsonEncode(userFriendlist)}'",
                "WHERE id = '$userID'");



            Navigator.pop(context);
            setState(() {});
          });
    }

    userBlockierenButton() {
      var ownId = FirebaseAuth.instance.currentUser.uid;
      var onBlockList = profil["geblocktVon"].contains(ownId);

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
              profil["geblocktVon"].remove(ownId);
              databaseQuery =
                  "geblocktVon = JSON_REMOVE(geblocktVon, JSON_UNQUOTE(JSON_SEARCH(geblocktVon, 'one', '$ownId')))";
              snackbarText = AppLocalizations.of(context).benutzerFreigegeben;
            } else {
              profil["geblocktVon"].add(ownId);
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
                databaseQuery, "WHERE id = '${profil["id"]}'");

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
                                userID,
                                "Melde User id: " + profil["id"],
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

    titelBox() {
      var familyMemberName = "";
      if (widget.userName != null) profil["name"] = widget.userName;

      if(familyProfil != null){
        var familyMember = familyProfil["members"];
        for(var member in familyMember){
          familyMemberName += getProfilFromHive(profilId: member, getNameOnly: true);
          familyMemberName += ", ";
        }
      }

      return Container(
        alignment: Alignment.center,
        padding:
            const EdgeInsets.only(top: 20, bottom: 10, left: 10, right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfilImage(profil, fullScreenWindow: true),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profil["name"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if(familyProfil != null) const SizedBox(height: 5),
                    if(familyProfil != null) Text(familyMemberName
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    locationBox() {
      return Row(
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
      );
    }

    travelTypBox() {
      var themaText = AppLocalizations.of(context).artDerReise + ": ";
      var inhaltText =
          global_functions.changeGermanToEnglish(profil["reiseart"]);

      if (spracheIstDeutsch) {
        inhaltText =
            global_functions.changeEnglishToGerman(profil["reiseart"]);
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
      var seitText = profil["aufreiseSeit"]
          .split("-")
          .take(2)
          .toList()
          .reversed
          .join("-");
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
        SizedBox(height: columnAbstand),
      ]);
    }

    sprachenBox() {
      var themenText = AppLocalizations.of(context).sprachen + ": ";
      var inhaltText = global_functions
          .changeGermanToEnglish(profil["sprachen"])
          .join(", ");

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
          Text(childrenList.reversed.join(" , "),
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
              fontsize: textSize,
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

        if (reiseplan["ortData"]["city"] !=
            reiseplan["ortData"]["countryname"]) {
          ortText += " / " + reiseplan["ortData"]["countryname"];
        }

        reiseplanung.add(Container(
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
        ));
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).reisePlanung + ": ",
              style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
            ),
            if (widget.ownProfil)
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
          margin: EdgeInsets.only(top: columnAbstand, bottom: columnAbstand),
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
      var daysOffline = timeDifferenceLastLogin.inDays;

      if (monthDifference >= monthsUntilInactive) {
        text = AppLocalizations.of(context).inaktiv;
        size = healineTextSize;
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

    infoProfil() {
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
                        fontSize: healineTextSize,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold)),
                const Expanded(child: SizedBox.shrink()),
                createZuletztOnlineText()
              ]),
              SizedBox(height: columnAbstand),
              locationBox(),
              SizedBox(height: columnAbstand),
              travelTypBox(),
              SizedBox(height: columnAbstand),
              aufreiseBox(),
              sprachenBox(),
              SizedBox(height: columnAbstand),
              kinderBox(),
              besuchteLaenderBox(),
              if (checkAccessReiseplanung() || widget.ownProfil)
                reisePlanungBox(),
              if (profil["aboutme"].isNotEmpty) aboutmeBox(),
              if (profil["tradeNotize"].isNotEmpty) tradeNotizeBox(),
              interessenBox(),
              SizedBox(height: columnAbstand),
            ],
          ));
    }

    kontaktProfil() {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).kontakt,
              style: TextStyle(
                  fontSize: healineTextSize,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            profil["emailAnzeigen"] == 1
                ? FutureBuilder(
                    future: ProfilDatabase().getData(
                        "email", "WHERE id = '${profil["id"]}'"),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Row(children: [
                          Text(
                            "Email: ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: textSize),
                          ),
                          Text(snapshot.data,
                              style: TextStyle(fontSize: textSize))
                        ]);
                      }
                      return Container();
                    })
                : const SizedBox.shrink(),
            SizedBox(height: columnAbstand)
          ],
        ),
      );
    }

    return SelectionArea(
      child: Scaffold(
        appBar: CustomAppBar(title: "", buttons: [
          widget.ownProfil ? const SizedBox.shrink() : openChatButton(),
          widget.ownProfil ? const SizedBox.shrink() : moreMenuButton()
        ]),
        body: SizedBox(
          width: double.maxFinite,
          child: Scrollbar(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              }),
              child: ListView(children: [
                titelBox(),
                const SizedBox(height: 10),
                infoProfil(),
                const SizedBox(height: 15),
                if (profil["emailAnzeigen"] == 1) kontaktProfil(),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
