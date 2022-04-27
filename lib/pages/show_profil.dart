import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../global/custom_widgets.dart';
import '../global/global_functions.dart' as global_functions;
import '../global/variablen.dart' as global_variablen;
import '../global/style.dart' as global_style;
import '../pages/chat/chat_details.dart';
import '../services/database.dart';
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
  var spracheIstDeutsch = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";
  var userFriendlist = [];
  double textSize = 16;
  double healineTextSize = 18;
  var monthsUntilInactive = 3;

  @override
  void initState() {
    setFriendList();
    checkOwnProfil();
    super.initState();
  }

  checkOwnProfil() {
    if (widget.profil["id"] == userID) widget.ownProfil = true;
  }

  setFriendList() async {
    if (widget.userName.isEmpty) return;

    var dbFriendlist = await ProfilDatabase()
        .getData("friendlist", "WHERE name = '${widget.userName}'");
    userFriendlist = dbFriendlist == "" ? [] : dbFriendlist;
  }

  getMonthDifference(){
    widget.profil["lastLogin"] =
        widget.profil["lastLogin"] ?? DateTime.parse("2022-02-13");
    var timeDifference = Duration(
        microseconds: (DateTime.now().microsecondsSinceEpoch -
            DateTime.parse(widget.profil["lastLogin"].toString())
                .microsecondsSinceEpoch)
            .abs());
    return timeDifference.inDays / 30.44;
  }

  @override
  Widget build(BuildContext context) {
    var monthDifference = getMonthDifference();

    openChatButton() {
      return TextButton(
          style: global_style.textButtonStyle(),
          child: const Icon(Icons.message),
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

      return TextButton(
          style: global_style.textButtonStyle(),
          child: onFriendlist
              ? const Icon(Icons.person_remove)
              : const Icon(Icons.person_add),
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
            }

            var ownProfilBox = Hive.box("ownProfilBox");
            var ownProfil = ownProfilBox.get("list");

            ownProfil["friendlist"] = userFriendlist;

            ownProfilBox.put("list", ownProfil);

            customSnackbar(context, snackbarText, color: Colors.green);

            ProfilDatabase().updateProfil(userID, "friendlist", userFriendlist);

            setState(() {});
          });
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

      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(themenText,
            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold)),
        Flexible(child: Text(inhaltText, style: TextStyle(fontSize: textSize)))
      ]);
    }

    aboutmeBox() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).ueberMich + ": ",
            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
          ),
          Flexible(
            child: Text(
              widget.profil["aboutme"],
              style: TextStyle(fontSize: textSize),
            ),
          )
        ],
      );
    }

    infoProfil() {
      double columnAbstand = 15;

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
              sprachenBox(),
              SizedBox(height: columnAbstand),
              kinderBox(),
              SizedBox(height: columnAbstand),
              interessenBox(),
              SizedBox(height: columnAbstand),
              if (widget.profil["aboutme"].isNotEmpty) aboutmeBox()
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
                  color: Theme.of(context).colorScheme.secondary,
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
                : const SizedBox.shrink()
          ],
        ),
      );
    }

    return Scaffold(
      appBar: customAppBar(title: "", buttons: [
        widget.ownProfil ? const SizedBox.shrink() : openChatButton(),
        widget.ownProfil ? const SizedBox.shrink() : friendlistButton()
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
              const SizedBox(height: 15),
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
