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

// ignore: must_be_immutable
class ShowProfilPage extends StatefulWidget {
  String userName;
  var profil;
  var ownProfil;

  ShowProfilPage({Key key, this.userName, this.profil, this.ownProfil = false})
      : super(key: key);

  @override
  _ShowProfilPageState createState() => _ShowProfilPageState();
}

class _ShowProfilPageState extends State<ShowProfilPage> {
  var userID = FirebaseAuth.instance.currentUser.uid;
  var hasReiseplanungAccess = false;
  var spracheIstDeutsch = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";
  var userFriendlist = Hive.box('secureBox').get("ownProfil")["friendlist"];
  double columnAbstand = 15;
  double textSize = 16;
  double healineTextSize = 18;
  var monthsUntilInactive = 3;

  @override
  void initState() {
    checkOwnProfil();
    checkAccessReiseplanung();

    super.initState();
  }

  checkAccessReiseplanung() {
    var reiseplanungSetting = widget.profil["reiseplanungPrivacy"];

    if (widget.profil["reisePlanung"].isNotEmpty) return false;

    if (reiseplanungSetting == privacySetting[0] ||
        reiseplanungSetting == privacySettingEnglisch[0]) {
      hasReiseplanungAccess = true;
    } else if ((reiseplanungSetting == privacySetting[1] ||
            reiseplanungSetting == privacySettingEnglisch[1]) &&
        (widget.ownProfil["friendlist"].contains(widget.profil["id"]))) {
      hasReiseplanungAccess = true;
    } else if ((reiseplanungSetting == privacySetting[2] ||
            reiseplanungSetting == privacySettingEnglisch[2]) &&
        (widget.ownProfil["friendlist"].contains(widget.profil["id"])) &&
        (widget.profil["friendlist"].contains(widget.ownProfil["id"]))) {
      hasReiseplanungAccess = true;
    }
  }

  checkOwnProfil() {
    if (widget.profil["id"] == userID) widget.ownProfil = true;
  }

  getMonthDifference() {
    widget.profil["lastLogin"] =
        widget.profil["lastLogin"] ?? DateTime.parse("2022-02-13");
    var timeDifference = Duration(
        microseconds: (DateTime.now().microsecondsSinceEpoch -
                DateTime.parse(widget.profil["lastLogin"].toString())
                    .microsecondsSinceEpoch)
            .abs());
    return timeDifference.inDays / 30.44;
  }

  transformDateToText(dateString) {
    DateTime date = DateTime.parse(dateString);

    if ((date.month > DateTime.now().month &&
            date.year == DateTime.now().year) ||
        date.year > DateTime.now().year) {
      return date.month.toString() + "." + date.year.toString();
    } else {
      return AppLocalizations.of(context).jetzt;
    }
  }

  openBesuchteLaenderWindow() {
    List<Widget> besuchteLaenderList = [];

    for (var land in widget.profil["besuchteLaender"]) {
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

  @override
  Widget build(BuildContext context) {
    var monthDifference = getMonthDifference();

    openChatButton() {
      return IconButton(
          icon: const Icon(Icons.message),
          onPressed: () async {
            var profilId = await ProfilDatabase()
                .getData("id", "WHERE name = '${widget.profil["name"]}'");
            var users = [userID, profilId];
            var chatId = global_functions.getChatID(users);

            var groupChatData =
                await ChatDatabase().getChatData("*", "WHERE id = '$chatId'");

            if (groupChatData == false) {
              groupChatData = {
                "users": {
                  profilId: {"name": widget.profil["name"], "newMessages": 0},
                  userID: {"name": widget.userName, "newMessages": 0}
                }
              };
            }

            global_functions.changePage(
                context,
                ChatDetailsPage(
                  groupChatData: groupChatData,
                ));
          });
    }

    friendlistButton() {
      var onFriendlist = userFriendlist.isNotEmpty
          ? userFriendlist.contains(widget.profil["id"])
          : false;

      return SimpleDialogOption(
          child: Row(
            children: [
              onFriendlist
                  ? const Icon(Icons.person_remove)
                  : const Icon(Icons.person_add),
              const SizedBox(width: 10),
              onFriendlist
                  ? Text(AppLocalizations.of(context).freundEntfernen)
                  : Text(AppLocalizations.of(context).freundHinzufuegen),
            ],
          ),
          onPressed: () {
            var snackbarText = "";

            if (onFriendlist) {
              userFriendlist.remove(widget.profil["id"]);
              snackbarText = widget.profil["name"] +
                  AppLocalizations.of(context).friendlistEntfernt;
              if (userFriendlist.isEmpty) userFriendlist = [];
            } else {
              userFriendlist.add(widget.profil["id"]);
              snackbarText = widget.profil["name"] +
                  AppLocalizations.of(context).friendlistHinzugefuegt;

              prepareFriendNotification(
                  newFriendId: userID,
                  toId: widget.profil["id"],
                  toCanGerman: widget.profil["sprachen"].contains("Deutsch") ||
                      widget.profil["sprachen"].contains("german"));
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

    blockierenButton() {
      var ownId = FirebaseAuth.instance.currentUser.uid;
      var onBlockList =
          widget.profil["geblocktVon"].contains(ownId);

      return SimpleDialogOption(
          child: Row(
            children: [
              onBlockList
                  ? const Icon(Icons.do_not_touch)
                  : const Icon(Icons.back_hand),
              const SizedBox(width: 10),
              onBlockList
                  ? Text(AppLocalizations.of(context).freigeben)
                  : Text(AppLocalizations.of(context).blockieren),
            ],
          ),
          onPressed: () {
            var snackbarText = "";
            var allProfils = Hive.box('secureBox').get("profils");
            var databaseQuery = "";

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
              if (widget.profil["id"] == profil["id"]) {
                profil["blockiertVon"] = widget.profil["geblocktVon"];
              }
            }

            Hive.box('secureBox').put("profils", allProfils);

            customSnackbar(context, snackbarText, color: Colors.green);

            ProfilDatabase().updateProfil(
                databaseQuery,
                "WHERE id = '${widget.profil["id"]}'");

            Navigator.pop(context);
            setState(() {});
          });
    }

    meldeButton() {
      return SimpleDialogOption(
          child: Row(
            children: [
              const Icon(Icons.report),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).melden),
            ],
          ),
          onPressed: () {
            var meldeText = TextEditingController();
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
                          meldeText,
                          moreLines: 10),
                      const SizedBox(height: 20),
                      FloatingActionButton.extended(
                          onPressed: () {
                            ReportsDatabase().add(
                                userID,
                                "Melde User id: " + widget.profil["id"],
                                meldeText.text);
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
                          blockierenButton(),
                          meldeButton()
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
      return Container(
        alignment: Alignment.center,
        padding:
            const EdgeInsets.only(top: 20, bottom: 10, left: 10, right: 10),
        child: Row(
          children: [
            ProfilImage(widget.profil, fullScreenWindow: true),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.profil["name"],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
              ),
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
          Text(widget.profil["ort"], style: TextStyle(fontSize: textSize))
        ],
      );
    }

    travelTypBox() {
      var themaText = AppLocalizations.of(context).artDerReise + ": ";
      var inhaltText =
          global_functions.changeGermanToEnglish(widget.profil["reiseart"]);

      if (spracheIstDeutsch) {
        inhaltText =
            global_functions.changeEnglishToGerman(widget.profil["reiseart"]);
      }

      return Row(children: [
        Text(themaText,
            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold)),
        Text(inhaltText, style: TextStyle(fontSize: textSize))
      ]);
    }

    aufreiseBox() {
      var themenText = AppLocalizations.of(context).aufReise + ": ";
      var inhaltText = "";

      if (widget.profil["aufreiseSeit"] == null) {
        return const SizedBox.shrink();
      } else if (widget.profil["aufreiseBis"] == null) {
        var seidText = widget.profil["aufreiseSeit"]
            .split("-")
            .take(2)
            .toList()
            .reversed
            .join("-");
        inhaltText = seidText + " - " + AppLocalizations.of(context).offen;
      } else {
        var seidText = widget.profil["aufreiseSeit"]
            .split("-")
            .take(2)
            .toList()
            .reversed
            .join("-");
        var bisText = widget.profil["aufreiseBis"]
            .split("-")
            .take(2)
            .toList()
            .reversed
            .join("-");
        inhaltText = seidText + " - " + bisText;
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
          .changeGermanToEnglish(widget.profil["sprachen"])
          .join(", ");

      if (spracheIstDeutsch) {
        inhaltText = global_functions
            .changeEnglishToGerman(widget.profil["sprachen"])
            .join(", ");
      }

      return Row(children: [
        Text(themenText,
            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold)),
        Text(inhaltText, style: TextStyle(fontSize: textSize))
      ]);
    }

    kinderBox() {
      var childrenProfilList = widget.profil["kinder"];
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
          .changeGermanToEnglish(widget.profil["interessen"])
          .join(", ");

      if (spracheIstDeutsch) {
        inhaltText = global_functions
            .changeEnglishToGerman(widget.profil["interessen"])
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
            Text(
              widget.profil["aboutme"],
              style: TextStyle(fontSize: textSize),
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
              widget.profil["tradeNotize"],
              style: TextStyle(fontSize: textSize),
            ),
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

        if (reiseplan["ortData"]["city"] !=
            reiseplan["ortData"]["countryname"]) {
          ortText += " / " + reiseplan["ortData"]["countryname"];
        }

        reiseplanung.add(Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                    transformDateToText(reiseplan["von"]) +
                        " - " +
                        transformDateToText(reiseplan["bis"]) +
                        " in " +
                        ortText,
                    style: TextStyle(fontSize: textSize)),
              ),
            ],
          ),
        ));
        reiseplanung.add(const SizedBox(height: 5));
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
        ...reiseplanung
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
            Text(widget.profil["besuchteLaender"].length.toString(),
                style: TextStyle(fontSize: textSize))
          ]),
        ),
      );
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
                if (monthDifference >= monthsUntilInactive)
                  Text(AppLocalizations.of(context).inaktiv,
                      style: TextStyle(
                          color: Colors.red, fontSize: healineTextSize))
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
              if (hasReiseplanungAccess || widget.ownProfil) reisePlanungBox(),
              if (widget.profil["aboutme"].isNotEmpty) aboutmeBox(),
              if (widget.profil["tradeNotize"].isNotEmpty) tradeNotizeBox(),
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
            widget.profil["emailAnzeigen"] == 1
                ? FutureBuilder(
                    future: ProfilDatabase().getData(
                        "email", "WHERE id = '${widget.profil["id"]}'"),
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

    return Scaffold(
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
              if (widget.profil["emailAnzeigen"] == 1) kontaktProfil(),
            ]),
          ),
        ),
      ),
    );
  }
}
