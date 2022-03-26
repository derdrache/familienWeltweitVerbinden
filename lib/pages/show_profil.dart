import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/custom_widgets.dart';
import '../global/global_functions.dart' as global_functions;
import '../global/variablen.dart' as global_variablen;
import '../global/style.dart' as global_style;
import '../pages/chat/chat_details.dart';
import '../services/database.dart';


class ShowProfilPage extends StatefulWidget {
  var userName;
  var profil;
  var ownProfil;


  ShowProfilPage({
    Key key,
    this.userName,
    this.profil,
    this.ownProfil = false

  }) : super(key: key);

  @override
  _ShowProfilPageState createState() => _ShowProfilPageState();
}

class _ShowProfilPageState extends State<ShowProfilPage> {
  var userID = FirebaseAuth.instance.currentUser.uid;
  var spracheIstDeutsch = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";
  var userFriendlist = [];
  double textSize = 16;
  double healineTextSize = 18;


@override
  void initState() {
    setFriendList();

    super.initState();
  }


  setFriendList() async {
    if (widget.userName == null) return;
    userFriendlist = await ProfilDatabase().getOneData("friendlist", "name", widget.userName);
  }

  @override
  Widget build(BuildContext context) {

    messageButton(){
      return TextButton(
          style: global_style.textButtonStyle(),
          child: const Icon(Icons.message),
          onPressed: () async {
            var profilID = await ProfilDatabase().getOneData("id", "name", widget.profil["name"]);
            var users = [userID, profilID];

            var newChat = false;

            var groupChatData = await ChatDatabase()
                .getChat(global_functions.getChatID(users));

            if(groupChatData == false){
              newChat = true;
              groupChatData = {
                "users": {
                  profilID: {"name": widget.profil["name"], "newMessages" : 0},
                  userID: {"name": widget.userName, "newMessages" : 0}
                }
              };
            }

            global_functions.changePage(context, ChatDetailsPage(
              groupChatData: groupChatData,
            ));
          }
      );
    }

    friendButton(){
      var onFriendlist = userFriendlist != ""?
        userFriendlist.contains(widget.profil["name"]) : false;

      return TextButton(
          style: global_style.textButtonStyle(),
          child: onFriendlist ? const Icon(Icons.person_remove) : const Icon(Icons.person_add),
          onPressed: (){
            var snackbarText = "";

            if(onFriendlist){
              userFriendlist.remove(widget.profil["name"]);
              snackbarText = widget.profil["name"] + AppLocalizations.of(context).friendlistEntfernt;
              if(userFriendlist.isEmpty) userFriendlist = [];
            } else {
              userFriendlist.add(widget.profil["name"]);
              snackbarText = widget.profil["name"] + AppLocalizations.of(context).friendlistHinzugefuegt;
            }

            customSnackbar(context, snackbarText, color: Colors.green);

            ProfilDatabase().updateProfil(userID, "friendlist", userFriendlist);


            setState(() {});

          }
      );
    }

    titelBox(){
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(top: 20,bottom: 10),
        child: SizedBox(
            child:
            Text(
              widget.profil["name"],
              style: const TextStyle(
                  fontSize: 24
              ),
            )
        ),
      );
    }

    cityBox(){
      return Row(
        children: [
          Text(
            AppLocalizations.of(context).aktuelleOrt +": ",
            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.profil["ort"],style: TextStyle(fontSize: textSize))
        ],
      );
    }

    travelBox(){
      var themaText = AppLocalizations.of(context).artDerReise+": ";
      var inhaltText = global_variablen.changeGermanToEnglish(widget.profil["reiseart"]);

      if(spracheIstDeutsch) inhaltText = global_variablen.changeEnglishToGerman(widget.profil["reiseart"]);


     return Row(
           children: [
             Text(themaText,style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold)),
             Text(inhaltText,style: TextStyle(fontSize: textSize))
           ]
         );
    }

    sprachenBox(){
      var themenText = AppLocalizations.of(context).sprachen+": ";
      var inhaltText = global_variablen.changeGermanToEnglish(widget.profil["sprachen"]).join(", ");

      if(spracheIstDeutsch) inhaltText =global_variablen.changeEnglishToGerman(widget.profil["sprachen"]).join(", ");

      return Row(
          children: [
            Text(themenText,style: TextStyle(fontSize: textSize,fontWeight: FontWeight.bold)),
            Text(inhaltText,style: TextStyle(fontSize: textSize))
          ]
      );
    }

    kinderBox(){
      var childrenProfilList = widget.profil["kinder"];
      var childrenList = [];

      childrenProfilList.forEach((child){
        childrenList.add(global_functions.ChangeTimeStamp(child).intoYears()
            .toString()+"J");
      });

      return Row(
        children: [
          Text(
              AppLocalizations.of(context).kinder +": ",
              style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.bold
              )
          ),
          Text(childrenList.join(" , "),style: TextStyle(fontSize: textSize))
        ],
      );
    }

    interessenBox(){
      var themenText = AppLocalizations.of(context).interessen+": ";
      var inhaltText = global_variablen.changeGermanToEnglish(widget.profil["interessen"]).join(", ");

      if(spracheIstDeutsch) inhaltText = global_variablen.changeEnglishToGerman(widget.profil["interessen"]).join(", ");

      return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(themenText,style: TextStyle(fontSize: textSize,fontWeight: FontWeight.bold)),
            Flexible(child: Text(inhaltText,style: TextStyle(fontSize: textSize)))
          ]
      );
    }

    aboutmeBox(){
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

    infoProfil(){
      double columnAbstand = 15;

      return Container(
          padding: const EdgeInsets.only(left: 10, top: 20),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: global_variablen.borderColorGrey))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text("Info", style: TextStyle(
                fontSize: healineTextSize,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold
              ),
            ),
              SizedBox(height: columnAbstand),
              cityBox(),
              SizedBox(height: columnAbstand),
              travelBox(),
              SizedBox(height: columnAbstand),
              sprachenBox(),
              SizedBox(height: columnAbstand),
              kinderBox(),
              SizedBox(height: columnAbstand),
              interessenBox(),
              SizedBox(height: columnAbstand),
              aboutmeBox()
            ],
          )
      );
    }

    kontaktProfil(){
      return Container(
        margin: EdgeInsets.only(top: 10),
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).kontakt,
              style: TextStyle(
                  fontSize: healineTextSize,
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 10),
            widget.profil["emailAnzeigen"] ?
                Row(children: [
                  Text("Email: " ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: textSize),),
                  Text(widget.profil["email"],style: TextStyle(fontSize: textSize))
                ]) : const SizedBox.shrink()

          ],
        ),
      );
    }


    return Scaffold(
      appBar: customAppBar(
          title: "",
          buttons: [widget.ownProfil ? SizedBox.shrink() : messageButton(),
                    widget.ownProfil ? SizedBox.shrink() : friendButton()]
      ),
      body:
      SizedBox(
        width: double.maxFinite,
        child: Scrollbar(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            }),
            child: ListView(
                  children: [
                    titelBox(),
                    const SizedBox(height: 15),
                    infoProfil(),
                    const SizedBox(height: 15),
                    if(widget.profil["emailAnzeigen"]) kontaktProfil(),
                  ]
              ),
          ),
          ),
        ),
    );

    }
}

