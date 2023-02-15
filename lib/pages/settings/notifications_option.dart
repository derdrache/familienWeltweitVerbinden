import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../services/database/database.dart';
import '../../widgets/custom_appbar.dart';

class NotificationsOptionsPage extends StatefulWidget {
  const NotificationsOptionsPage({Key key}) : super(key: key);

  @override
  _NotificationsOptionsPageState createState() =>
      _NotificationsOptionsPageState();
}

class _NotificationsOptionsPageState extends State<NotificationsOptionsPage> {
  Map ownProfil = Hive.box("secureBox").get("ownProfil");
  var userId = FirebaseAuth.instance.currentUser.uid;


  allNotificationSetting() {
    return Row(
      children: [
        const SizedBox(width: 20),
        Text(
            AppLocalizations.of(context).alleBenachrichtigungen,//email erhalten
            style: const TextStyle(fontSize: 20)),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: ownProfil["notificationstatus"] == 1 ? true : false,
            onChanged: (value) {
              setState(() {
                ownProfil["notificationstatus"] = value == true ? 1 : 0;
              });

              ProfilDatabase().updateProfil(
                  "notificationstatus = '${ownProfil["notificationstatus"]}'",
                  "WHERE id = '$userId'");
            })
      ],
    );
  }

  chatNotificationSetting() {
    return Row(
      children: [
        const SizedBox(width: 20),
        Text(
            AppLocalizations.of(context).chatNotification,
            style: const TextStyle(fontSize: 20)),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: ownProfil["chatNotificationOn"] == 1 ? true : false,
            onChanged: (value) {
              setState(() {
                ownProfil["chatNotificationOn"] = value == true ? 1 : 0;
              });
              ProfilDatabase().updateProfil("chatNotificationOn = '$value'",
                  "WHERE id = '${ownProfil["chatNotificationOn"]}'");
            })
      ],
    );
  }

  eventNotificationSetting() {
    return Row(
      children: [
        const SizedBox(width: 20),
        Text(
            AppLocalizations.of(context).meetupNotification,
            style: const TextStyle(fontSize: 20)),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: ownProfil["eventNotificationOn"] == 1 ? true : false,
            onChanged: (value) {
              setState(() {
                ownProfil["eventNotificationOn"] = value == true ? 1 : 0;
              });
              ProfilDatabase().updateProfil("eventNotificationOn = '$value'",
                  "WHERE id = '${ownProfil["eventNotificationOn"]}'");
            })
      ],
    );
  }

  newFriendNotificationSetting() {
    return Row(
      children: [
        const SizedBox(width: 20),
        Text(
            AppLocalizations.of(context).friendNotification,
            style: const TextStyle(fontSize: 20)),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: ownProfil["newFriendNotificationOn"] == 1 ? true : false,
            onChanged: (value) {
              setState(() {
                ownProfil["newFriendNotificationOn"] =
                    value == true ? 1 : 0;
              });
              ProfilDatabase().updateProfil(
                  "newFriendNotificationOn = '$value'",
                  "WHERE id = '${ownProfil["newFriendNotificationOn"]}'");
            })
      ],
    );
  }

  familieInRangeNotificationSetting(){
    double distance = ownProfil["familiesDistance"].toDouble() ?? 50.0;
    bool familieInRangeNotificationOn = distance > 0;

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 20),
            Text(
                AppLocalizations.of(context).familieInRangeNotification,
                style: const TextStyle(fontSize: 20)),
            const Expanded(child: SizedBox(width: 20)),
            Switch(
                value: familieInRangeNotificationOn,
                onChanged: (value) {
                  var distance = value ? 50 : 0;

                  setState(() {
                    ownProfil["familiesDistance"] = distance;
                  });

                  ProfilDatabase().updateProfil(
                      "familiesDistance = $distance",
                      "WHERE id = '$userId'"
                  );
                }
            )
          ],
        ),
        if(familieInRangeNotificationOn) Text(
            "${distance.round()} km ${AppLocalizations.of(context).umkreis}"
        ),
        if(familieInRangeNotificationOn) Slider(
          value: distance,
          min: 5,
          max: 200,
          divisions: 100,
          label: '${distance.round()} km',
          onChanged: (newDistance){
            setState(() {
              distance = newDistance;
              ownProfil["familiesDistance"] = newDistance;
            });
          },
          onChangeEnd: (newDistance){
            ProfilDatabase().updateProfil(
                "familiesDistance = $newDistance",
                "WHERE id = '$userId'"
            );
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          CustomAppBar(
              title: AppLocalizations.of(context).benachrichtigungen
          ),
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          allNotificationSetting(),
          if (ownProfil["notificationstatus"] == 1)
            chatNotificationSetting(),
          if (ownProfil["notificationstatus"] == 1)
            eventNotificationSetting(),
          if (ownProfil["notificationstatus"] == 1)
            newFriendNotificationSetting(),
          if(ownProfil["notificationstatus"] == 1)
            familieInRangeNotificationSetting()
        ],
      ),
    );
  }
}
