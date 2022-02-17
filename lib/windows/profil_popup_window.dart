import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';

import '../global/global_functions.dart' as global_functions;
import '../global/variablen.dart' as global_variablen;
import '../global/style.dart' as global_style;
import '../pages/chat/chat_details.dart';
import '../services/database.dart';


class ProfilPopupWindow{
  dynamic globalSetState;
  dynamic context;
  String userName;
  var userID = FirebaseAuth.instance.currentUser!.uid;
  Map profil;
  Map userFriendlist;
  var spracheIstDeutsch = Platform.localeName == "de_DE";


  ProfilPopupWindow({required this.context, required this.userName,
    required this.profil,required this.userFriendlist});

  _menuBarProfil(){
    return Row(
      children: [
        TextButton(
          style: global_style.textButtonStyle(),
          child: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(child: SizedBox()),
        _messageButton(),
        _friendButton()
        //addFriendButton,
      ],
    );
  }

  _messageButton(){
    return TextButton(
        style: global_style.textButtonStyle(),
        child: const Icon(Icons.message),
        onPressed: () async {
          var profilID = await ProfilDatabase().getProfilId("name", profil["name"]);
          var users = [userID, profilID];
          var newChat = false;

          var groupChatData = await ChatDatabase()
              .getChat(global_functions.getChatID(users));

          if(groupChatData == null){
            newChat = true;
            groupChatData = {
              "users": {
                profilID: {"name": profil["name"], "newMessages" : 0},
                userID: {"name": userName, "newMessages" : 0}
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

  _friendButton(){
    var onFriendlist = userFriendlist.keys.contains(profil["name"]);

    return TextButton(
        style: global_style.textButtonStyle(),
        child: onFriendlist ? const Icon(Icons.person_remove) : const Icon(Icons.person_add),
        onPressed: (){
          if(onFriendlist){
            userFriendlist.remove(profil["name"]);
            if(userFriendlist.keys.isEmpty) userFriendlist = {"empty": true};
          } else {
            if(userFriendlist["empty"] == true) userFriendlist = {profil["name"]: true};
            userFriendlist[profil["name"]] = true;
          }

          ProfilDatabase().updateProfil(
              userID, {"friendlist": userFriendlist}
          );

          globalSetState(() => userFriendlist.keys.contains(profil["name"]));

        }
    );
  }

  _titelProfil(){
    return Center(
        child:
        Text(
          profil["name"],
          style: const TextStyle(
              fontSize: 24
          ),
        )
    );
  }

  _infoProfil(){
    var childrenProfilList = profil["kinder"];
    var childrenList = [];
    double columnAbstand = 5;
    var interessenTextGerman = AppLocalizations.of(context)!.interessen+": " + global_variablen.changeEnglishToGerman(profil["interessen"]).join(", ");
    var interessenTextEnglish = AppLocalizations.of(context)!.interessen+": " + global_variablen.changeGermanToEnglish(profil["interessen"]).join(", ");
    var reiseArtGerman = AppLocalizations.of(context)!.artDerReise+": " + global_variablen.changeEnglishToGerman(profil["reiseart"]);
    var reiseArtEnglish = AppLocalizations.of(context)!.artDerReise+": " + global_variablen.changeGermanToEnglish(profil["reiseart"]);
    var spracheGerman = AppLocalizations.of(context)!.sprachen+": " + global_variablen.changeEnglishToGerman(profil["sprachen"]).join(", ");
    var spracheEnglish = AppLocalizations.of(context)!.sprachen+": " + global_variablen.changeGermanToEnglish(profil["sprachen"]).join(", ");


    childrenProfilList.forEach((child){
      childrenList.add(global_functions.ChangeTimeStamp(child).intoYears()
          .toString()+"J");
    });


    return Container(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [ const
            Text("Info", style: TextStyle(color: Colors.blue)),
            SizedBox(height: columnAbstand),
            Text(AppLocalizations.of(context)!.aktuelleStadt +": " + profil["ort"]),
            SizedBox(height: columnAbstand),
            spracheIstDeutsch ?
                Text(reiseArtGerman):
                Text(reiseArtEnglish),
            SizedBox(height: columnAbstand),
            spracheIstDeutsch ?
                Text(spracheGerman):
                Text(spracheEnglish),
            SizedBox(height: columnAbstand),
            Text(AppLocalizations.of(context)!.kinder +": " + childrenList.join(" , ")),
            SizedBox(height: columnAbstand),
            spracheIstDeutsch ? 
                Text(interessenTextGerman):
                Text(interessenTextEnglish),
            SizedBox(height: columnAbstand),
            Text(AppLocalizations.of(context)!.ueberMich + ": " + profil["aboutme"]),
          ],
        )
    );
  }

  _kontaktProfil(){
    return Container(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.kontakt,style: const TextStyle(color: Colors.blue),),
          profil["emailAnzeigen"] ?
            Text("Email: " + profil["email"]) : const SizedBox.shrink()
        ],
      ),
    );
  }

  profilPopupWindow(){

    return showDialog(
        context: context,
        builder: (BuildContext buildContext){
          return StatefulBuilder(
              builder: (context, setState){
                globalSetState = setState;
                return AlertDialog(
                  backgroundColor: Colors.white,
                  contentPadding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                  content: SizedBox(
                    height: 400,
                    width: double.maxFinite,
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: ListView(
                          children: [
                            _menuBarProfil(),
                            const SizedBox(height: 25),
                            _titelProfil(),
                            const SizedBox(height: 30),
                            _infoProfil(),
                            const SizedBox(height: 30),
                            _kontaktProfil(),
                          ]
                      ),
                    ),
                  ),
                );
              });
        }
    );
  }

}


