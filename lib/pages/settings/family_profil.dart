import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';
import '../../widgets/search_autocomplete.dart';
import '../../global/variablen.dart' as global_var;

class FamilieProfilPage extends StatefulWidget {
  const FamilieProfilPage({Key key}) : super(key: key);

  @override
  State<FamilieProfilPage> createState() => _FamilieProfilPageState();
}

class _FamilieProfilPageState extends State<FamilieProfilPage> {
  var ownProfil = Hive.box('secureBox').get("ownProfil");
  var userId = FirebaseAuth.instance.currentUser.uid;
  bool familyProfilIsActive = false;
  var familyMembersCount = 1;
  var dballProfilIdAndName = [];
  var allProfilsName = [];
  var searchAutocomplete = SearchAutocomplete();
  var familyProfil;

  @override
  void initState() {
    getAllProfilName();

    super.initState();
  }

  getAllProfilName() async {
    dballProfilIdAndName = await ProfilDatabase().getData("id, name", "");
    allProfilsName = [];

    for (var profil in dballProfilIdAndName) {
      allProfilsName.add(profil["name"]);
    }
  }

  checkIfFamilyExist() async {
    var dbData = await FamiliesDatabase()
        .getData("*", "WHERE JSON_CONTAINS(members, '\"$userId\"') > 0");

    if (dbData != false) familyProfil = dbData;

    return dbData != false;
  }

  setProfilData() {
    if (familyProfil == false) return;

    familyProfilIsActive = familyProfil["active"] == 1 ? true : false;
    familyMembersCount = familyProfil["members"].length;
  }

  changeFamilyProfilStatus(active) async {
    FamiliesDatabase()
        .update("active = '$active'", "WHERE id = '${familyProfil["id"]}'");
  }

  createFamilyProfil() async {
    var uuid = const Uuid();
    var eventId = uuid.v4();

    FamiliesDatabase().addNewFamily({
      "id": eventId,
      "members": jsonEncode([userId]),
    });

    setState(() {
      familyProfil = {
        "id": eventId,
        "members": [userId],
        "name": "",
        "active": "1"
      };
    });
  }

  addMember() {
    var idIndex = -1;

    if (searchAutocomplete.getSelected().isEmpty) return;

    if (searchAutocomplete.getSelected().isNotEmpty) {
      idIndex = allProfilsName.indexOf(searchAutocomplete.getSelected()[0]);
    } else {
      idIndex = dballProfilIdAndName.indexOf("member");
    }

    var memberId = dballProfilIdAndName[idIndex]["id"];
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> createFriendlistBox() {
      var userFriendlist = ownProfil["friendlist"];

      List<Widget> friendsBoxen = [];
      for (var friend in userFriendlist) {
        friendsBoxen.add(GestureDetector(
          onTap: () => null,
          child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          width: 1, color: global_var.borderColorGrey))),
              child: Text(friend)),
        ));
      }

      if (userFriendlist.isEmpty) {
        return [
          Center(
              heightFactor: 10,
              child: Text(
                  AppLocalizations.of(context).nochKeineFreundeVorhanden,
                  style: const TextStyle(color: Colors.grey)))
        ];
      }

      return friendsBoxen;
    }

    windowOptions(saveFunction) {
      return Container(
        margin: const EdgeInsets.only(right: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
            child: Text(AppLocalizations.of(context).abbrechen,
                style: const TextStyle()),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
              child: Text(AppLocalizations.of(context).speichern,
                  style: const TextStyle()),
              onPressed: () => saveFunction()),
        ]),
      );
    }

    addMemberWindow() {
      searchAutocomplete = SearchAutocomplete(
        hintText: AppLocalizations.of(context).personSuchen,
        searchableItems: allProfilsName,
        onConfirm: () {},
      );

      return showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
              height: 800,
              title: AppLocalizations.of(context).mitgliedHinzufuegen,
              children: [
                Center(child: SizedBox(width: 300, child: searchAutocomplete)),
                windowOptions(() => addMember()),
                ...createFriendlistBox(),
              ],
            );
          });
    }

    activeSwitch() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Familienprofil aktivieren ?"),
          const SizedBox(width: 10),
          Switch(
            value: familyProfilIsActive,
            onChanged: (value) async {
              if (value) {
                if (familyProfil == null) await createFamilyProfil();
                changeFamilyProfilStatus(1);
              } else {
                changeFamilyProfilStatus(0);
              }

              setState(() {
                familyProfilIsActive = value;
              });
            },
          ),
        ],
      );
    }

    moreMenu() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 250,
                  child: SimpleDialog(
                    contentPadding: EdgeInsets.zero,
                    insetPadding: EdgeInsets.only(top: 40, left: 0, right: 10),
                    children: [
                      SimpleDialogOption(
                        child: Row(
                          children: [
                            const Icon(Icons.person_add),
                            const SizedBox(width: 10),
                            Text(AppLocalizations.of(context).mitgliedHinzufuegen),
                          ],
                        ),
                        onPressed: () {
                          addMemberWindow();
                        },
                      )
                    ],
                  ),
                ),
              ],
            );
          });
    }

    chooseMainProfil() {
      return CustomDropDownButton(
          hintText: "Hauptprofil wählen", selected: "", items: const []);
    }

    addFamilyMemberBox() {
      return InkWell(
        onTap: () => addMemberWindow(),
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                width: 250,
                child: const Text(
                  "Für ein Familienprofil werden mindestens zwei Familienmitglieder benötigt",
                  maxLines: 2,
                )),
            const SizedBox(width: 10),
            const Icon(Icons.person_add)
          ]),
        ),
      );
    }

    familyProfilPage() {
      return;
    }

    familyProfilDescription() {
      return Container(
          margin: EdgeInsets.all(20),
          child: Text(
              "Wenn das Familienprofil aktiviert wird, wird bei jedem Familienmitglied ein einheitliches Profil auftauchen."
              "\n\nAuf der Weltkarte wird nicht mehr jedes Familienmitglied einzeln angezeigt, sondern nur noch das Familienprofil."));
    }

    return Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context).familyProfil,
          buttons: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => moreMenu(),
            )
          ],
        ),
        body: FutureBuilder(
            future: checkIfFamilyExist(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                setProfilData();

                return ListView(
                  children: [
                    //if (familyProfilIsActive) familyProfilPage(),
                    if (familyMembersCount < 2 && familyProfilIsActive)
                      addFamilyMemberBox(),
                    //chooseMainProfil(),
                    activeSwitch(),
                    if (!familyProfilIsActive) familyProfilDescription()
                  ],
                );
              }
              return const Center(
                  child: SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                      )));
            }));
  }
}
