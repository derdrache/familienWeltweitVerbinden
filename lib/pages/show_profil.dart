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
  Map? userFriendlist = {"empty": true};
  var ownProfil;


  ShowProfilPage({
    Key? key,
    this.userName,
    required this.profil,
    this.userFriendlist,
    this.ownProfil = false

  }) : super(key: key);

  @override
  _ShowProfilPageState createState() => _ShowProfilPageState();
}

class _ShowProfilPageState extends State<ShowProfilPage> {
  var userID = FirebaseAuth.instance.currentUser!.uid;
  var spracheIstDeutsch = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";
  double textSize = 16;
  double healineTextSize = 18;


  @override
  Widget build(BuildContext context) {

    messageButton(){
      return TextButton(
          style: global_style.textButtonStyle(),
          child: const Icon(Icons.message),
          onPressed: () async {
            //Vereinfachen, das meiste müsste Chat Details machen
            var profilID = await ProfilDatabase().getProfilId("name", widget.profil["name"]);
            var users = [userID, profilID];
            var newChat = false;

            var groupChatData = await ChatDatabase()
                .getChat(global_functions.getChatID(users));

            if(groupChatData == null){
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
              newChat: newChat,
            ));
          }
      );
    }

    friendButton(){
      var onFriendlist = widget.userFriendlist!.keys.contains(widget.profil["name"]);

      return TextButton(
          style: global_style.textButtonStyle(),
          child: onFriendlist ? const Icon(Icons.person_remove) : const Icon(Icons.person_add),
          onPressed: (){
            var snackbarText = "";

            if(onFriendlist){
              widget.userFriendlist!.remove(widget.profil["name"]);
              snackbarText = "Benutzer von der Freundesliste entfernt";
              if(widget.userFriendlist!.keys.isEmpty) widget.userFriendlist = {"empty": true};
            } else {
              if(widget.userFriendlist!["empty"] == true) widget.userFriendlist = {widget.profil["name"]: true};
              widget.userFriendlist![widget.profil["name"]] = true;
              snackbarText = "Benutzer der Freundesliste hinzugefügt";
            }

            customSnackbar(context, snackbarText, color: Colors.green);

            ProfilDatabase().updateProfil(
                userID, {"friendlist": widget.userFriendlist}
            );

            setState(() {
              widget.userFriendlist!.keys.contains(widget.profil["name"]);
            });

          }
      );
    }

    titelBox(){
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(top: 20,bottom: 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: global_variablen.borderColorGrey
          ))
        ),
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
            AppLocalizations.of(context)!.aktuelleStadt +": ",
            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.profil["ort"],style: TextStyle(fontSize: textSize))
        ],
      );
    }

    travelBox(){
      var themaText = AppLocalizations.of(context)!.artDerReise+": ";
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
      var themenText = AppLocalizations.of(context)!.sprachen+": ";
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
              AppLocalizations.of(context)!.kinder +": ",
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
      var themenText = AppLocalizations.of(context)!.interessen+": ";
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
            AppLocalizations.of(context)!.ueberMich + ": ",
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
          padding: const EdgeInsets.only(left: 10, bottom: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: global_variablen.borderColorGrey))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text("Info", style: TextStyle(
                fontSize: healineTextSize,
                color: Theme.of(context).colorScheme.tertiary,
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
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.kontakt,
              style: TextStyle(
                  fontSize: healineTextSize,
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.bold
              ),
            ),
            widget.profil["emailAnzeigen"] ?
            Text("Email: " + widget.profil["email"]) : const SizedBox.shrink()
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
          thumbVisibility: true,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },),
            child: ListView(
                children: [
                  titelBox(),
                  const SizedBox(height: 15),
                  infoProfil(),
                  const SizedBox(height: 15),
                  kontaktProfil(),
                ]
            ),
          ),
        ),
      ),
    );

    }
}
