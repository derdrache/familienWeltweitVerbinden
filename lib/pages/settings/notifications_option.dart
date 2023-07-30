import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';

class NotificationsOptionsPage extends StatefulWidget {
  const NotificationsOptionsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsOptionsPage> createState() => _NotificationsOptionsPageState();
}

class _NotificationsOptionsPageState extends State<NotificationsOptionsPage> {
  Map ownProfil = Hive.box("secureBox").get("ownProfil");
  var userId = FirebaseAuth.instance.currentUser!.uid;


  allNotificationSetting() {
    return Row(
      children: [
        const SizedBox(width: 20),
        Text(
            AppLocalizations.of(context)!.alleBenachrichtigungen,
            style: const TextStyle(fontSize: 20)),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: ownProfil["notificationstatus"] == 1 ? true : false,
            onChanged: (value) {
              var notificationOn = value == true ? 1 : 0;

              setState(() {
                ownProfil["notificationstatus"] = notificationOn;
                ownProfil["chatNotificationOn"] = notificationOn;
                ownProfil["eventNotificationOn"] = notificationOn;
                ownProfil["newFriendNotificationOn"] = notificationOn;
                ownProfil["familiesDistance"] = value ? 50 : 0;
                ownProfil["travelPlanNotification"] = notificationOn;
              });

              ProfilDatabase().updateProfil(
                  "notificationstatus = '$notificationOn', "
                      "chatNotificationOn = '$notificationOn', "
                      "eventNotificationOn = '$notificationOn',"
                      "newFriendNotificationOn = '$notificationOn',"
                      "familiesDistance = ${value ? 50 : 0},"
                      "travelPlanNotification = '$notificationOn'",
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
            AppLocalizations.of(context)!.chatNotification,
            style: const TextStyle(fontSize: 20)),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: ownProfil["chatNotificationOn"] == 1 ? true : false,
            onChanged: (value) {
              var notificationOn = value == true ? 1 : 0;

              setState(() {
                ownProfil["chatNotificationOn"] = notificationOn;
              });
              ProfilDatabase().updateProfil("chatNotificationOn = '$notificationOn'",
                  "WHERE id = '${ownProfil["id"]}'");
            })
      ],
    );
  }

  eventNotificationSetting() {
    return Row(
      children: [
        const SizedBox(width: 20),
        Text(
            AppLocalizations.of(context)!.meetupNotification,
            style: const TextStyle(fontSize: 20)),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: ownProfil["eventNotificationOn"] == 1 ? true : false,
            onChanged: (value) {
              var notificationOn = value == true ? 1 : 0;

              setState(() {
                ownProfil["eventNotificationOn"] = notificationOn;
              });
              ProfilDatabase().updateProfil("eventNotificationOn = '$notificationOn'",
                  "WHERE id = '${ownProfil["id"]}'");
            })
      ],
    );
  }

  newFriendNotificationSetting() {
    return Row(
      children: [
        const SizedBox(width: 20),
        Text(
            AppLocalizations.of(context)!.friendNotification,
            style: const TextStyle(fontSize: 20)),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: ownProfil["newFriendNotificationOn"] == 1 ? true : false,
            onChanged: (value) {
              var notificationOn = value == true ? 1 : 0;

              setState(() {
                ownProfil["newFriendNotificationOn"] = notificationOn;
              });
              ProfilDatabase().updateProfil(
                  "newFriendNotificationOn = '$notificationOn'",
                  "WHERE id = '${ownProfil["id"]}'");
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
                AppLocalizations.of(context)!.familieInRangeNotification,
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
            "${distance.round()} km ${AppLocalizations.of(context)!.umkreis}"
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

  friendsTravelPlanNotificationSetting(){
    return Row(
      children: [
        const SizedBox(width: 20),
        Text(
            AppLocalizations.of(context)!.reiseplanungNotification,
            style: const TextStyle(fontSize: 20)),
        const Expanded(child: SizedBox(width: 20)),
        Switch(
            value: ownProfil["travelPlanNotification"] == 1 ? true : false,
            onChanged: (value) {
              var notificationOn = value == true ? 1 : 0;

              setState(() {
                ownProfil["travelPlanNotification"] = notificationOn;
              });
              ProfilDatabase().updateProfil(
                  "travelPlanNotification = '$notificationOn'",
                  "WHERE id = '${ownProfil["id"]}'");
            })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool notificationsAllowed = ownProfil["notificationstatus"] == 1;

    return Scaffold(
      appBar:
          CustomAppBar(
              title: AppLocalizations.of(context)!.benachrichtigungen
          ),
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          allNotificationSetting(),
          if (notificationsAllowed) chatNotificationSetting(),
          if (notificationsAllowed) eventNotificationSetting(),
          if (notificationsAllowed) newFriendNotificationSetting(),
          if (notificationsAllowed) familieInRangeNotificationSetting(),
          if (notificationsAllowed) friendsTravelPlanNotificationSetting(),
        ],
      ),
    );
  }
}
