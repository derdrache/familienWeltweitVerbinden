import 'dart:convert';

import 'package:familien_suche/widgets/windowConfirmCancelBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';
import '../../windows/dialog_window.dart';
import '../../widgets/layout/custom_dropdown_button.dart';
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/custom_text_input.dart';
import '../../global/global_functions.dart' as global_func;
import '../../windows/all_user_select.dart';
import '../show_profil.dart';

class FamilieProfilPage extends StatefulWidget {
  const FamilieProfilPage({Key? key}) : super(key: key);

  @override
  State<FamilieProfilPage> createState() => _FamilieProfilPageState();
}

class _FamilieProfilPageState extends State<FamilieProfilPage> {
  final Map ownProfil = Hive.box('secureBox').get("ownProfil");
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  List allProfils = Hive.box('secureBox').get("profils");
  bool familyProfilIsActive = false;
  var familyProfil;
  var inviteFamilyProfil;
  TextEditingController nameFamilyKontroller = TextEditingController();
  late CustomDropdownButton mainProfilDropdown;
  bool isLoding = true;
  late Map mainProfil;
  FocusNode nameFocusNode = FocusNode();

  @override
  void initState() {
    setData();

    nameFocusNode.addListener(() {
      if (!nameFocusNode.hasFocus) {
        saveName();
      }
    });

    super.initState();
  }

  setData() async {
    await checkIfFamilyExist();
    setProfilData();

    setState(() {
      isLoding = false;
    });
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

  saveName() async {
    var newName = nameFamilyKontroller.text.replaceAll("'", "''");

    var nameIsUsed =
    await FamiliesDatabase().getData("id", "WHERE name = '$newName'");

    if (nameIsUsed && context.mounted) {
      customSnackBar(
          context, AppLocalizations.of(context)!.usernameInVerwendung);
      return;
    }

    setState(() {
      familyProfil["name"] = newName;
    });

    FamiliesDatabase()
        .update("name = '$newName'", "WHERE id = '${familyProfil["id"]}'");
  }

  setProfilData() {
    if (familyProfil == false || familyProfil == null) return;

    mainProfil = getProfilFromHive(profilId: familyProfil["mainProfil"]);
    familyProfilIsActive = familyProfil["active"] == 1 ? true : false;
  }


  changeFamilyProfilStatus(active) async {
    FamiliesDatabase()
        .update("active = '$active'", "WHERE id = '${familyProfil["id"]}'");

    var hiveFamilyProfil = getFamilyProfil(familyId: familyProfil["id"]);
    hiveFamilyProfil["active"] =active;
  }

  createFamilyProfil() async {
    var uuid = const Uuid();
    var familieId = uuid.v4();
    var newFamilyProfil = {
      "id": familieId,
      "members": [userId],
      "name": "",
      "active": "1"
    };

    await FamiliesDatabase().addNewFamily({
      "id": familieId,
      "members": jsonEncode([userId]),
    });

    var familyProfils = Hive.box('secureBox').get("familyProfils") ?? [];
    familyProfils.add(newFamilyProfil);

    return newFamilyProfil;
  }

  checkHasFamilyProfil(user) async {
    var hasFamilyProfil = await FamiliesDatabase()
        .getData("*", "WHERE JSON_CONTAINS(members, '\"$user\"') > 0");

    return hasFamilyProfil != false ? true : false;
  }

  addMember(memberId) async {
    String memberName = getProfilFromHive(profilId: memberId, getNameOnly: true);
    if (familyProfil["members"].contains(memberId)) {
      customSnackBar(context,
          "$memberName ${AppLocalizations.of(context)!.isImFamilienprofil}");
      return;
    }
    if (familyProfil["einladung"].contains(memberId)) {
      customSnackBar(context,
          "$memberName ${AppLocalizations.of(context)!.wurdeSchonEingeladen}");
      return;
    }

    var hasFamilyProfil = await checkHasFamilyProfil(memberId);
    if (hasFamilyProfil) {
      if (context.mounted)customSnackBar(context, "$memberName ${AppLocalizations.of(context)!.istInEinemFamilienprofil}");
      return;
    }

    setState(() {
      familyProfil["einladung"].add(memberId);
    });

    if (context.mounted) customSnackBar(context, "$memberName ${AppLocalizations.of(context)!.familienprofilEingeladen}");

    FamiliesDatabase().update(
        "einladung = JSON_ARRAY_APPEND(einladung, '\$', '$memberId')",
        "WHERE id = '${familyProfil["id"]}'");
  }

  refuseFamilyInvite() async {
    setState(() {
      inviteFamilyProfil["einladung"].remove(userId);
    });

    FamiliesDatabase().update(
        "einladung = JSON_REMOVE(einladung, JSON_UNQUOTE(JSON_SEARCH(einladung, 'one', '$userId')))",
        "WHERE id = '${inviteFamilyProfil["id"]}'");
  }

  acceptFamilyInvite() async {
    mainProfil = getProfilFromHive(profilId: inviteFamilyProfil["mainProfil"]);

    setState(() {
      familyProfil = inviteFamilyProfil;
      inviteFamilyProfil = null;
      familyProfil["einladung"].remove(userId);
      familyProfil["members"].add(userId);
      familyProfilIsActive = true;
    });

    await FamiliesDatabase().update(
        "members = JSON_ARRAY_APPEND(members, '\$', '$userId'), einladung = JSON_REMOVE(einladung, JSON_UNQUOTE(JSON_SEARCH(einladung, 'one', '$userId')))",
        "WHERE id = '${familyProfil["id"]}'");
  }

  getAllProfilName(){
    List allProfilsName = [];

    for (var profil in allProfils) {
      allProfilsName.add(profil["name"]);
    }

    return allProfilsName;
  }


  @override
  Widget build(BuildContext context) {
    addMemberWindow() async {
      String selectedUserId = await AllUserSelectWindow(
        context: context,
        title: AppLocalizations.of(context)!.personSuchen,
      ).openWindow();

      addMember(selectedUserId);
    }

    activeSwitch() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(AppLocalizations.of(context)!.familienprofilAktivieren),
          const SizedBox(width: 10),
          Switch(
            value: familyProfilIsActive,
            onChanged: (value) async {
              if (value) {
                familyProfil ??= await createFamilyProfil();

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

    memberListWindow() {
      var membersId = familyProfil["members"];
      List<Widget> allMemberName = [];

      for (var member in membersId) {
        for (var profil in Hive.box('secureBox').get("profils")) {
          if (member == profil["id"]) {
            allMemberName.add(Container(
                margin: const EdgeInsets.all(10), child: Text(profil["name"])));
            break;
          }
        }
      }

      return showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context)!.member,
              children: allMemberName,
            );
          });
    }

    deleteDialog(){
      return  showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context)!.familyProfilloeschen,
              children: [
                Center(
                    child: Text(
                        AppLocalizations.of(context)!.familyProfilWirklichLoeschen)),
                WindowConfirmCancelBar(
                  confirmTitle: AppLocalizations.of(context)!.loeschen,
                  onConfirm: () async{
                    await FamiliesDatabase().delete(familyProfil["id"]);

                    var familyProfils = Hive.box('secureBox').get("familyProfils");
                    familyProfils.removeWhere((item) => item["id"] == familyProfil["id"]);

                    setState(() {
                      familyProfil = null;
                      familyProfilIsActive = false;
                    });
                  },
                )

              ],
            );
          });
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
                      if (familyProfil != null)
                        SimpleDialogOption(
                          child: Row(
                            children: [
                              const Icon(Icons.list),
                              const SizedBox(width: 10),
                              Text(AppLocalizations.of(context)!.member),
                            ],
                          ),
                          onPressed: () {
                            memberListWindow();
                          },
                        ),
                      if (familyProfil != null &&
                          familyProfil["name"].isNotEmpty)
                        SimpleDialogOption(
                          child: Row(
                            children: [
                              const Icon(Icons.person_add),
                              const SizedBox(width: 10),
                              Text(AppLocalizations.of(context)!
                                  .mitgliedHinzufuegen),
                            ],
                          ),
                          onPressed: () {
                            addMemberWindow();
                          },
                        ),
                      if (familyProfil != null)
                        SimpleDialogOption(
                          child: Row(
                            children: [
                              const Icon(Icons.delete),
                              const SizedBox(width: 10),
                              Text(AppLocalizations.of(context)!.loeschen),
                            ],
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            deleteDialog();
                          },
                        )
                    ],
                  ),
                ),
              ],
            );
          });
    }

    nameBox() {
      nameFamilyKontroller.text = familyProfil["name"];

      return CustomTextInput(AppLocalizations.of(context)!.familienprofilName,
          nameFamilyKontroller,
          focusNode: nameFocusNode, onSubmit: () => saveName());
    }

    chooseMainProfil() {
      var selectedId = familyProfil["mainProfil"];
      var selectedName = "";
      var allMembersId = familyProfil["members"] ?? [];
      List<String> allMembersName = [];

      for (var member in allMembersId) {
        for (var profil in allProfils) {
          if (member == profil["id"]) {
            if (selectedId == member) selectedName = profil["name"];
            allMembersName.add(profil["name"]);
            break;
          }
        }
      }

      mainProfilDropdown = CustomDropdownButton(
          hintText: AppLocalizations.of(context)!.hauptprofilWaehlen,
          selected: selectedName,
          items: allMembersName,
          onChange: () {
            var selected = mainProfilDropdown.getSelected();

            var selectedIndex = allMembersName.indexOf(selected);
            var selectedId = allMembersId[selectedIndex];

            mainProfil = getProfilFromHive(profilId: selectedId);

            setState(() {
              familyProfil["mainProfil"] = selectedId;
            });

            FamiliesDatabase().update("mainProfil = '$selectedId'",
                "WHERE id = '${familyProfil["id"]}'");
          });

      return mainProfilDropdown;
    }

    addFamilyMemberBox() {
      return InkWell(
        onTap: () => addMemberWindow(),
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              AppLocalizations.of(context)!.familienmitgliedHinzufuegen,
            ),
            const SizedBox(width: 10),
            const Icon(Icons.person_add)
          ]),
        ),
      );
    }

    familyProfilDescription() {
      return Container(
          margin: const EdgeInsets.all(20),
          child: Text(AppLocalizations.of(context)!.familienprofilBeschreibung));
    }

    familyProfilInvite() {
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.primary, width: 3)),
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.familyprofilInvite),
            const SizedBox(height: 5),
            Text(inviteFamilyProfil["name"],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => acceptFamilyInvite(),
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green)),
                  child: Text(AppLocalizations.of(context)!.annehmen),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: () => refuseFamilyInvite(),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.red)),
                    child: Text(AppLocalizations.of(context)!.ablehnen)),
              ],
            )
          ],
        ),
      );
    }

    showProfil() {
      bool profilComplete = false;

      if (familyProfil["name"].isNotEmpty &&
          (familyProfil["mainProfil"] != null && familyProfil["mainProfil"].isNotEmpty)) {
        profilComplete = true;
      }

      return profilComplete
          ? InkWell(
              onTap: () => global_func.changePage(
                  context,
                  ShowProfilPage(
                      profil: mainProfil)),
              child: Container(
                margin: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.familienprofilAnzeigen),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.preview,
                      size: 35,
                    )
                  ],
                ),
              ),
            )
          : Center(
              child: Container(
                margin: const EdgeInsets.all(30),
                child: Text(
                  AppLocalizations.of(context)!.familienprofilUnvollstaendig,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
    }

    return Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context)!.familyProfil,
          buttons: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => moreMenu(),
            )
          ],
        ),
        body: isLoding
            ? const Center(
                child: SizedBox(
                    height: 100,
                    width: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                    )))
            : Column(
                children: [
                  if (!familyProfilIsActive) activeSwitch(),
                  if (familyProfilIsActive) nameBox(),
                  if (familyProfilIsActive) chooseMainProfil(),
                  if (!familyProfilIsActive) familyProfilDescription(),
                  if (familyProfilIsActive && familyProfil["name"].isNotEmpty)
                    addFamilyMemberBox(),
                  if (familyProfilIsActive) showProfil(),
                  const Expanded(
                    child: SizedBox(),
                  ),
                  if (familyProfilIsActive) activeSwitch(),
                  if ((inviteFamilyProfil != false &&
                          inviteFamilyProfil != null) &&
                      inviteFamilyProfil["einladung"].contains(userId))
                    familyProfilInvite(),
                  const SizedBox(height: 10,)
                ],
              ));
  }
}
