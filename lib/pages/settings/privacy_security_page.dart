import 'dart:io';
import 'dart:ui';
import 'package:familien_suche/global/variablen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../services/database.dart';
import '../login_register_page/login_page.dart';

class PrivacySecurityPage extends StatefulWidget {
  var profil;

  PrivacySecurityPage({Key key,this.profil}) : super(key: key);

  @override
  _PrivacySecurityPageState createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  double fontsize = 20;
  var automaticLocationDropdown = CustomDropDownButton();
  var spracheIstDeutsch = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";

  saveAutomaticLocation(){
    ProfilDatabase().updateProfil(
        "automaticLocation ='${automaticLocationDropdown.getSelected()}'",
        "WHERE id ='$userId'"
    );
  }

  @override
  Widget build(BuildContext context) {
    var locationList = spracheIstDeutsch ? standortbestimmung : standortbestimmungEnglisch;
    automaticLocationDropdown = CustomDropDownButton(
      items: locationList,
      selected: widget.profil["automaticLocation"] ?? (spracheIstDeutsch ?
        standortbestimmung[0] : standortbestimmungEnglisch[0]),
      onChange: () => saveAutomaticLocation(),
    );

    emailSettingContainer(){
      return Container(
        margin: EdgeInsets.all(10),
        child: Row(
          children: [
            Text(AppLocalizations.of(context).emailAlleSichtbar, style: TextStyle(fontSize: fontsize),),
            const Expanded(child: SizedBox(width: 20)),
            Switch(
                value: widget.profil["emailAnzeigen"] == 1 ? true: false,
                onChanged: (value){
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

    automaticLocationContainer(){
      return Container(
        margin: EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(width: 200,child: Text("Automatische Standortbestimmung", style: TextStyle(fontSize: fontsize),)),
            Expanded(child: SizedBox()),
            SizedBox(width: 150, child: automaticLocationDropdown)
          ],
        ),
      );
    }

    deleteProfilContainer(){
      return FloatingActionButton.extended(
        backgroundColor: Colors.red,
        label: const Text("Account löschen"),
        onPressed: () async {
          var userId = FirebaseAuth.instance.currentUser?.uid;
          ProfilDatabase().deleteProfil(userId);
          setState(() {});
          global_functions.changePageForever(context, const LoginPage());
        },
      );
    }

    return Scaffold(
      appBar: customAppBar(title: AppLocalizations.of(context).privatsphaereSicherheit),
      body: Column(
        children: [
          emailSettingContainer(),
          automaticLocationContainer(),
          const Expanded(child: SizedBox.shrink()),
          //deleteProfilContainer(),
          //SizedBox(height: 10)
        ],
      ),
    );
  }
}
