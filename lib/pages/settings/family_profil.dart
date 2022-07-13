import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

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
  bool familyProfilIsActive = false;
  bool familyExist = false;
  var familyMembersCount = 1;
  var dballProfilIdAndName = [];
  var allProfilsName = [];
  var searchAutocomplete = SearchAutocomplete();

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

  addMember() {
    var idIndex = -1;

    if(searchAutocomplete.getSelected().isEmpty) return;

    if(searchAutocomplete.getSelected().isNotEmpty){
      idIndex = allProfilsName
          .indexOf(searchAutocomplete.getSelected()[0]);
    }else{
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
                style: TextStyle()),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
              child: Text(AppLocalizations.of(context).speichern,
                  style: TextStyle()),
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
          Text("Familienprofil aktivieren ?"),
          SizedBox(width: 10),
          Switch(
            value: familyProfilIsActive,
            onChanged: (value) {
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
              children: const [
                SizedBox(
                  width: 250,
                  child: SimpleDialog(
                    contentPadding: EdgeInsets.zero,
                    insetPadding: EdgeInsets.only(top: 40, left: 0, right: 10),
                    children: [],
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
          margin: EdgeInsets.all(20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                width: 250,
                child: Text(
                  "Für ein Familienprofil werden mindestens zwei Familienmitglieder benötigt",
                  maxLines: 2,
                )),
            SizedBox(width: 10),
            Icon(Icons.person_add)
          ]),
        ),
      );
    }

    familyProfilPage() {
      return;
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
        body: ListView(
          children: [
            //if (familyProfilIsActive) familyProfilPage(),
            if (familyMembersCount < 2 && familyProfilIsActive)
              addFamilyMemberBox(),
            //chooseMainProfil(),
            activeSwitch(),
          ],
        ));
  }
}
