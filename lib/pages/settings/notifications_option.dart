import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';


class NotificationsOptionsPage extends StatefulWidget {
  var profil;

  NotificationsOptionsPage({Key key, this.profil}) : super(key: key);

  @override
  _NotificationsOptionsPageState createState() => _NotificationsOptionsPageState();
}

class _NotificationsOptionsPageState extends State<NotificationsOptionsPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;

  mitteilungEinstellung(){
    return Row(
      children: [
        SizedBox(width: 20),
        Text(
          kIsWeb? AppLocalizations.of(context).emailErhalten :
          AppLocalizations.of(context).benachrichtigungenErhalten, //email erhalten
          style: TextStyle(fontSize: 20)
        ),
        Expanded(child: SizedBox(width: 20)),
        Switch(
            value: widget.profil["notificationstatus"] ?? true,
            onChanged: (value){
              setState(() {
                widget.profil["notificationstatus"] = value;
              });

              ProfilDatabase().updateProfil(userId, "notificationstatus", value);

            })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(title: AppLocalizations.of(context).benachrichtigungen),
      body: Column(
        children: [
          SizedBox(height: 20,),
          mitteilungEinstellung()
        ],
      ),
    );
  }
}
