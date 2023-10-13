import 'package:familien_suche/widgets/windowConfirmCancelBar.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'dialog_window.dart';
import '../widgets/search_autocomplete.dart';
import '../../global/style.dart' as style;


class AllUserSelectWindow {
  var context;
  String title;
  List<String> allUserNames = [];
  var allUserIds = [];
  late var searchAutocomplete;
  String? selectedUserId;
  var ownProfil = Hive.box('secureBox').get("ownProfil");

  AllUserSelectWindow({this.context, required this.title});

  setAllUserData() {
    var allProfilData = Hive.box("secureBox").get("profils");

    for (var profil in allProfilData) {
      if (ownProfil["geblocktVon"].contains(profil["id"])) continue;

      allUserNames.add(profil["name"]);
      allUserIds.add(profil["id"]);
    }
  }

  setSearchAutocomplete(){
    return SearchAutocomplete(
      hintText: AppLocalizations.of(context)!.personSuchen,
      searchableItems: allUserNames,
      onConfirm: (){
        var selectedUser = searchAutocomplete.getSelected()[0];
        var userIndex = allUserNames.indexOf(selectedUser);
        var selectedUserId = allUserIds[userIndex];

        Navigator.pop(context, selectedUserId);
      },
    );
  }

  List<Widget> createFriendlistBox() {
    var userFriendlist = Hive.box('secureBox').get("ownProfil")["friendlist"];

    for (var i = 0; i < userFriendlist.length; i++) {
      for (var profil in Hive.box('secureBox').get("profils")) {
        if (profil["id"] == userFriendlist[i]) {
          userFriendlist[i] = profil["name"];
          break;
        }
      }
    }

    List<Widget> friendsBoxen = [];
    for (var friend in userFriendlist) {
      friendsBoxen.add(GestureDetector(
        onTap: () {
          var userIndex = allUserNames.indexOf(friend);
          var selectedUserId = allUserIds[userIndex];
          Navigator.pop(context, selectedUserId);
        },
        child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        width: 1, color: style.borderColorGrey))),
            child: Text(friend)),
      ));
    }

    if (userFriendlist.isEmpty) {
      return [
        Center(
            heightFactor: 10,
            child: Text(AppLocalizations.of(context)!.nochKeineFreundeVorhanden,
                style: const TextStyle(color: Colors.grey)))
      ];
    }

    return friendsBoxen;
  }

  getSelectedUserData(){
    return selectedUserId;
  }

  openWindow(){
    setAllUserData();
    searchAutocomplete = setSearchAutocomplete();

    return showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: title,
            children: [
              searchAutocomplete,
              const SizedBox(height: 15),
              WindowConfirmCancelBar(
                confirmTitle: AppLocalizations.of(context)!.speichern,
                withCloseWindow: false,
                onConfirm: (){
                  var selectedUser = searchAutocomplete.getSelected()[0];
                  var userIndex = allUserNames.indexOf(selectedUser);
                  var selectedUserId = allUserIds[userIndex];

                  Navigator.pop(context, selectedUserId);
                },
              ),
              ...createFriendlistBox(),
            ],
          );
        });
  }
}
