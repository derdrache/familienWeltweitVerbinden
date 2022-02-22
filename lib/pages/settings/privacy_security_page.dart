import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';

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
          SizedBox(width: 20),
          Text(AppLocalizations.of(context).emailAlleSichtbar, style: TextStyle(fontSize: 20),),
          Expanded(child: SizedBox(width: 20)),
          Switch(
              value: widget.profil["emailAnzeigen"],
              onChanged: (value){
                setState(() {
                  widget.profil["emailAnzeigen"] = value;
                });
                ProfilDatabase().updateProfil(
                    userID,
                    {"emailAnzeigen": widget.profil["emailAnzeigen"]}
                );
              })
        ],
      );
    }

    return Scaffold(
      appBar: customAppBar(title: AppLocalizations.of(context).privatsphaereSicherheit),
      body: Column(
        children: [
          SizedBox(height: 20,),
          emailSettingContainer()
        ],
      ),
    );
  }
}
