import 'dart:io';

import 'package:familien_suche/widgets/windowConfirmCancelBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import '../../global/style.dart' as style;

import '../../auth/secrets.dart';
import '../../global/variablen.dart';
import '../../global/global_functions.dart' as global_func;
import '../../global/global_functions.dart' as global_functions;
import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';
import '../../windows/dialog_window.dart';
import '../../widgets/layout/custom_dropdown_button.dart';
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/custom_text_input.dart';
import '../login_register_page/login_page.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({Key? key}) : super(key: key);

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  Map ownProfil = Hive.box("secureBox").get("ownProfil");
  final double fontsize = 20;
  late CustomDropdownButton automaticLocationDropdown;
  late CustomDropdownButton reiseplanungDropdown;
  late CustomDropdownButton exactLocationDropdown;
  final bool spracheIstDeutsch = kIsWeb
      ? PlatformDispatcher.instance.locale.languageCode == "de"
      : Platform.localeName == "de_DE";

  
  saveAutomaticLocation() async {
    if(ownProfil["reiseart"] == "fixed location" || ownProfil["reiseart"] == "Fester Standort"){
      customSnackBar(context, AppLocalizations.of(context)!.automatischerStandortNichtMoeglich);
      return;
    }

    var automaticLocationOption = automaticLocationDropdown.getSelected();

    if (automaticLocationOption != standortbestimmung[0] &&
        automaticLocationOption != standortbestimmungEnglisch[0]) {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
    }

    ownProfil["automaticLocation"] = automaticLocationOption;

    ProfilDatabase().updateProfil(
        "automaticLocation ='$automaticLocationOption'", "WHERE id ='$userId'");
  }

  saveReiseplanung() async{
    var reiseplanungPrivacyAuswahl = reiseplanungDropdown.getSelected();

    ownProfil["reiseplanungPrivacy"] = reiseplanungPrivacyAuswahl;

    ProfilDatabase().updateProfil(
        "reiseplanungPrivacy = '$reiseplanungPrivacyAuswahl'",
        "WHERE id = '$userId'"
    );
  }

  saveExactLocation() async{
    var exactLocationPrivacyAuswahl = exactLocationDropdown.getSelected();

    ownProfil["genauerStandortPrivacy"] = exactLocationPrivacyAuswahl;

    ProfilDatabase().updateProfil(
        "genauerStandortPrivacy = '$exactLocationPrivacyAuswahl'",
        "WHERE id = '$userId'"
    );
  }

  setAutomaticLocationDropdown(){
    var locationList = spracheIstDeutsch ?
      standortbestimmung : standortbestimmungEnglisch;
    var selected = ownProfil["automaticLocation"] != null ?
      (spracheIstDeutsch ?
      global_func.changeEnglishToGerman(ownProfil["automaticLocation"]) :
      global_func.changeGermanToEnglish(ownProfil["automaticLocation"])) :
      (spracheIstDeutsch
          ? standortbestimmung[0]
          : standortbestimmungEnglisch[0]);

    automaticLocationDropdown = CustomDropdownButton(
      items: locationList,
      selected: selected,
      onChange: () => saveAutomaticLocation(),
    );
  }

  setExactLocationDropdown(){
    var items = spracheIstDeutsch ? privacySetting : privacySettingEnglisch;
    var selected = spracheIstDeutsch ?
    global_func.changeEnglishToGerman(ownProfil["genauerStandortPrivacy"]) :
    global_func.changeGermanToEnglish(ownProfil["genauerStandortPrivacy"]);

    exactLocationDropdown = CustomDropdownButton(
      items: items,
      selected: selected,
      onChange: () => saveExactLocation(),
    );
  }

  setReiseplanungDropdown(){
    var items = spracheIstDeutsch ? privacySetting : privacySettingEnglisch;
    var selected = spracheIstDeutsch ?
    global_func.changeEnglishToGerman(ownProfil["reiseplanungPrivacy"]) :
    global_func.changeGermanToEnglish(ownProfil["reiseplanungPrivacy"]);

    reiseplanungDropdown = CustomDropdownButton(
        items: items,
        selected: selected,
        onChange: () => saveReiseplanung(),
    );
  }


  @override
  Widget build(BuildContext context) {
    setAutomaticLocationDropdown();
    setReiseplanungDropdown();
    setExactLocationDropdown();


    automaticLocationContainer() {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.automatischeStandortbestimmung,
                style: TextStyle(fontSize: fontsize),
              ),
            ),
            SizedBox(width: 170, child: automaticLocationDropdown)
          ],
        ),
      );
    }

    exactLocationBox(){
      return Container(
          margin: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.genauerStandortSichtbarFuer,
                style: TextStyle(fontSize: fontsize),
              ),
            ),
            SizedBox(width: 170,child: exactLocationDropdown)
          ],)
      );
    }

    reiseplanungBox(){
      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.reiseplanungSichtbarFuer,
              style: TextStyle(fontSize: fontsize),
            ),
          ),
          SizedBox(width: 170,child: reiseplanungDropdown)
        ],)
      );
    }

    chooseProfilIdWindow() async{
      String deleteId = "";
      TextEditingController idController = TextEditingController();

      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: "Accountid zum löschen eingeben",
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: () {
                    deleteId = idController.text;
                    Navigator.pop(context);
                  }
                ),
              ],
              children: [
                Center(child: CustomTextInput("Account id eingeben", idController))
              ],
            );
          });

      return deleteId;
    }

    deleteProfilWindow() {
      var deleteSaftyRequestController = TextEditingController();

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context)!.accountLoeschen,
              children: [
                const SizedBox(height: 20),
                Center(
                    child: Text(
                        AppLocalizations.of(context)!.accountWirklichLoeschen)),
                const SizedBox(height: 20,),
                TextField(
                  controller: deleteSaftyRequestController,
                  decoration: InputDecoration(
                      isDense: true,
                      hintText: "delete",
                      enabledBorder: OutlineInputBorder(
                          borderSide:  BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(style.roundedCorners)
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(style.roundedCorners)
                      )
                  )),
                const SizedBox(height: 30,),
                WindowConfirmCancelBar(
                  confirmTitle: AppLocalizations.of(context)!.loeschen,
                  onConfirm: (){
                    if (deleteSaftyRequestController.text == "delete"
                        || deleteSaftyRequestController.text == "löschen"){
                      var deleteProfil = ownProfil;

                      ProfilDatabase().deleteProfil(deleteProfil["id"]);
                      dbDeleteImage(deleteProfil["bild"]);

                      setState(() {});
                      global_functions.changePageForever(context, const LoginPage());
                    }
                  },
                )
              ],
            );
          });
    }

    deleteAccountBox(){
      return Container(
          margin: const EdgeInsets.all(10),
          child: InkWell(
            onTap:() async {
              if(userId == mainAdmin){
                String choosenProfilId = await chooseProfilIdWindow();
                ProfilDatabase().deleteProfil(choosenProfilId);
                Map deleteProfil = getProfilFromHive(profilId: choosenProfilId);
                dbDeleteImage(deleteProfil["bild"]);
              }else{
                deleteProfilWindow();
              }
            },
            child: Row(children: [
              const Icon(Icons.delete, color: Colors.red,),
              const SizedBox(width: 10,),
              Text(
                AppLocalizations.of(context)!.accountLoeschen,
                style: TextStyle(fontSize: fontsize, color: Colors.red),
              )
            ],),
          )
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context)!.privatsphaereSicherheit),
      body: SafeArea(
        child: Column(
          children: [
            automaticLocationContainer(),
            exactLocationBox(),
            reiseplanungBox(),
            const SizedBox(height: 10,),
            deleteAccountBox(),
          ],
        ),
      ),
    );
  }
}
