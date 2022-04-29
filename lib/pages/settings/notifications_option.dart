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

  allNotificationSetting(){
    return Row(
      children: [
        const SizedBox(width: 20),
        Text(
          kIsWeb? AppLocalizations.of(context).emailErhalten :
          AppLocalizations.of(context).benachrichtigungenErhalten, //email erhalten
          style: const TextStyle(fontSize: 20)
        ),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: widget.profil["notificationstatus"] == 1 ? true : false,
            onChanged: (value){
              setState(() {
                widget.profil["notificationstatus"] = value == true ? 1 : 0;
              });

              ProfilDatabase().updateProfil("notificationstatus = '$value'", "WHERE id = '$userId'");
            })
      ],
    );
  }

  chatNotificationSetting(){
    return Row(
      children: [
        const SizedBox(width: 20),
        Text(
            kIsWeb? AppLocalizations.of(context).chatEmailErhalten :
            AppLocalizations.of(context).chatNotificationErhalten,
            style: const TextStyle(fontSize: 20)
        ),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: widget.profil["chatNotificationOn"] == 1 ? true : false,
            onChanged: (value){
              setState(() {
                widget.profil["chatNotificationOn"] = value == true ? 1 : 0;
              });
              ProfilDatabase().updateProfil("chatNotificationOn = '$value'", "WHERE id = '$userId'");

            })
      ],
    );
  }

  eventNotificationSetting(){
    return Row(
      children: [
        const SizedBox(width: 20),
        Text(
            kIsWeb? AppLocalizations.of(context).eventEmailErhalten :
            AppLocalizations.of(context).eventNotificationErhalten,
            style: const TextStyle(fontSize: 20)
        ),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: widget.profil["eventNotificationOn"] == 1 ? true : false,
            onChanged: (value){
              setState(() {
                widget.profil["eventNotificationOn"] = value == true ? 1 : 0;
              });
              ProfilDatabase().updateProfil("eventNotificationOn = '$value'", "WHERE id = '$userId'");
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
          const SizedBox(height: 20,),
          allNotificationSetting(),
          if(widget.profil["notificationstatus"] == 1) chatNotificationSetting(),
          if(widget.profil["notificationstatus"] == 1) eventNotificationSetting()
        ],
      ),
    );
  }
}
