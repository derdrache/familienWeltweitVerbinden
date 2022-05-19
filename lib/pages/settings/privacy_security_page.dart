import 'dart:io';
import 'dart:ui';
import 'package:familien_suche/global/variablen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';
import '../login_register_page/login_page.dart';

class PrivacySecurityPage extends StatefulWidget {
  var profil;

  PrivacySecurityPage({Key key, this.profil}) : super(key: key);

  @override
  _PrivacySecurityPageState createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  double fontsize = 20;
  var automaticLocationDropdown = CustomDropDownButton();
  var spracheIstDeutsch = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";

  saveAutomaticLocation() async {
    var locationAuswahl = automaticLocationDropdown.getSelected();




    if (locationAuswahl != standortbestimmung[0] &&
        locationAuswahl != standortbestimmungEnglisch[0]) {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    }

    ProfilDatabase().updateProfil(
        "automaticLocation ='$locationAuswahl'", "WHERE id ='$userId'");
  }

  @override
  Widget build(BuildContext context) {
    var locationList =
        spracheIstDeutsch ? standortbestimmung : standortbestimmungEnglisch;
    automaticLocationDropdown = CustomDropDownButton(
      items: locationList,
      selected: widget.profil["automaticLocation"] ??
          (spracheIstDeutsch
              ? standortbestimmung[0]
              : standortbestimmungEnglisch[0]),
      onChange: () => saveAutomaticLocation(),
    );

    emailSettingContainer() {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context).emailAlleSichtbar,
              style: TextStyle(fontSize: fontsize),
            ),
            const Expanded(child: SizedBox(width: 20)),
            Switch(
                value: widget.profil["emailAnzeigen"] == 1 ? true : false,
                onChanged: (value) {
                  setState(() {
                    widget.profil["emailAnzeigen"] = value == true ? 1 : 0;
                  });
                  ProfilDatabase().updateProfil(
                      "emailAnzeigen = '${widget.profil["emailAnzeigen"]}'",
                      "WHERE id = '$userId'");
                })
          ],
        ),
      );
    }

    automaticLocationContainer() {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
                width: 200,
                child: Text(
                  AppLocalizations.of(context).automatischeStandortbestimmung,
                  style: TextStyle(fontSize: fontsize),
                )),
            const Expanded(child: SizedBox()),
            SizedBox(width: 150, child: automaticLocationDropdown)
          ],
        ),
      );
    }

    deleteProfilWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).accountLoeschen,
              height: 90,
              children: [
                const SizedBox(height: 10),
                Center(
                    child: Text(
                        AppLocalizations.of(context).accountWirklichLoeschen))
              ],
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: () {
                    var userId = FirebaseAuth.instance.currentUser?.uid;
                    ProfilDatabase().deleteProfil(userId);
                    setState(() {});
                    global_functions.changePageForever(
                        context, const LoginPage());
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context).abbrechen),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            );
          });
    }

    deleteProfilContainer() {
      return FloatingActionButton.extended(
          backgroundColor: Colors.red,
          label: Text(AppLocalizations.of(context).accountLoeschen),
          onPressed: () => deleteProfilWindow());
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).privatsphaereSicherheit),
      body: Column(
        children: [
          emailSettingContainer(),
          automaticLocationContainer(),
          const Expanded(child: SizedBox.shrink()),
          deleteProfilContainer(),
          const SizedBox(height: 10)
        ],
      ),
    );
  }
}
