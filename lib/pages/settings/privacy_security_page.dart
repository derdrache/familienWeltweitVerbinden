import 'package:firebase_auth/firebase_auth.dart';
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
  var userID = FirebaseAuth.instance.currentUser.uid;

  @override
  Widget build(BuildContext context) {

    emailSettingContainer(){
      return Row(
        children: [
          const SizedBox(width: 20),
          Text(AppLocalizations.of(context).emailAlleSichtbar, style: const TextStyle(fontSize: 20),),
          const Expanded(child: SizedBox(width: 20)),
          Switch(
              value: widget.profil["emailAnzeigen"] == 1 ? true: false,
              onChanged: (value){
                setState(() {
                  widget.profil["emailAnzeigen"] = value == true ? 1 : 0;
                });
                ProfilDatabase().updateProfil(
                  "emailAnzeigen = '${widget.profil["emailAnzeigen"]}'",
                  "WHERE id = '$userID'");
              })
        ],
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
          const SizedBox(height: 20,),
          emailSettingContainer(),
          const Expanded(child: SizedBox.shrink()),
          //deleteProfilContainer(),
          //SizedBox(height: 10)
        ],
      ),
    );
  }
}
