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
  var familyMembersCount = 0;
  var dballProfilIdAndName = [];
  var allProfilsName = [];
  var searchAutocomplete = SearchAutocomplete();
  var familyProfil;
  var inviteFamilyProfil;

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

    if (dbData == false) {
      inviteFamilyProfil = await FamiliesDatabase()
          .getData("*", "WHERE JSON_CONTAINS(einladung, '\"$userId\"') > 0");
    }

    if (dbData != false) familyProfil = dbData;

    return dbData != false;
  }

  setProfilData() {
    if (familyProfil == false || familyProfil == null) {
      return;
    }

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

  checkHasFamilyProfil(user) async {
    var hasFamilyProfil = await FamiliesDatabase()
        .getData("*", "WHERE JSON_CONTAINS(members, '\"$user\"') > 0");

    return hasFamilyProfil != false ? true : false;
  }

  addMember({member}) {
    var idIndex = -1;

    if (searchAutocomplete.getSelected().isEmpty && member == null) return;

    if (searchAutocomplete.getSelected().isNotEmpty) {
      idIndex = allProfilsName.indexOf(searchAutocomplete.getSelected()[0]);
    } else {
      idIndex = allProfilsName.indexOf(member);
    }

    var memberId = dballProfilIdAndName[idIndex]["id"];

    var hasFamilyProfil = checkHasFamilyProfil(memberId);
    if (hasFamilyProfil) {
      customSnackbar(context, "Der Benutzer ist schon in einer Familie");
      return;
    }

    if (familyProfil["members"].contains(memberId) ||
        familyProfil["einladung"].contains(memberId)) return;

    setState(() {
      familyProfil["einladung"].add(userId);
    });

    FamiliesDatabase().update(
        "einladung = JSON_ARRAY_APPEND(einladung, '\$', '$userId')",
        "WHERE id = '${familyProfil["id"]}'");
  }

  refuseFamilyInvite() async {
    setState(() {
      familyProfil["einladung"].remove(userId);
    });

    FamiliesDatabase().update(
        "einladung = JSON_REMOVE(einladung, JSON_UNQUOTE(JSON_SEARCH(einladung, 'one', '$userId')))",
        "WHERE id = '${inviteFamilyProfil["id"]}'");
  }

  acceptFamilyInvite() async {
    setState(() {
      familyProfil["einladung"].remove(userId);
      familyProfil["members"].add(userId);
    });

    await FamiliesDatabase().update(
        "members = JSON_ARRAY_APPEND(members, '\$', '$userId'), JSON_REMOVE(einladung, JSON_UNQUOTE(JSON_SEARCH(einladung, 'one', '$userId')))",
        "WHERE id = '${familyProfil["id"]}'");
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> createFriendlistBox() {
      var userFriendlist = ownProfil["friendlist"];

      for (var i = 0; i < userFriendlist.length; i++) {
        for (var profil in dballProfilIdAndName) {
          if (profil["id"] == userFriendlist[i]) {
            userFriendlist[i] = profil["name"];
            break;
          }
        }
      }

      List<Widget> friendsBoxen = [];
      for (var friend in userFriendlist) {
        friendsBoxen.add(GestureDetector(
          onTap: () => addMember(member: friend),
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
                    insetPadding:
                        const EdgeInsets.only(top: 40, left: 0, right: 10),
                    children: [
                      SimpleDialogOption(
                        child: Row(
                          children: [
                            const Icon(Icons.person_add),
                            const SizedBox(width: 10),
                            Text(AppLocalizations.of(context)
                                .mitgliedHinzufuegen),
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
          margin: const EdgeInsets.all(20),
          child: const Text(
              "Wenn das Familienprofil aktiviert wird, wird bei jedem Familienmitglied ein einheitliches Profil auftauchen."
              "\n\nAuf der Weltkarte wird nicht mehr jedes Familienmitglied einzeln angezeigt, sondern nur noch das Familienprofil."));
    }

    familyProfilInvite() {
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.primary, width: 3)),
        child: Column(
          children: [
            Text("Du wurdest eingeladen dem Familienprofil " +
                inviteFamilyProfil["name"] +
                " beizutreten"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => acceptFamilyInvite(),
                  child: Text(AppLocalizations.of(context).annehmen),
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: () => refuseFamilyInvite(),
                    child: Text(AppLocalizations.of(context).ablehnen),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.red))),
              ],
            )
          ],
        ),
      );
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

                return Column(
                  children: [
                    //if (familyProfilIsActive) familyProfilPage(),
                    if (familyMembersCount < 2 && familyProfilIsActive)
                      addFamilyMemberBox(),
                    //chooseMainProfil(),
                    activeSwitch(),
                    if (!familyProfilIsActive) familyProfilDescription(),
                    const Expanded(
                      child: SizedBox(),
                    ),
                    if (inviteFamilyProfil != false &&
                        inviteFamilyProfil["einladung"].contains(userId))
                      familyProfilInvite()
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
