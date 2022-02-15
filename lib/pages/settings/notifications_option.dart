import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';


class NotificationsOptionsPage extends StatefulWidget {
  var profil;

  NotificationsOptionsPage({Key? key, this.profil}) : super(key: key);

  @override
  _NotificationsOptionsPageState createState() => _NotificationsOptionsPageState();
}

class _NotificationsOptionsPageState extends State<NotificationsOptionsPage> {
  var userId = FirebaseAuth.instance.currentUser!.uid;

  mitteilungEinstellung(){
    return Row(
      children: [
        SizedBox(width: 20),
        Text("Benachrichtigungen erhalten", style: TextStyle(fontSize: 20),),
        Expanded(child: SizedBox(width: 20)),
        Switch(
            value: widget.profil["notificationstatus"] ?? true,
            onChanged: (value){
              setState(() {
                widget.profil["notificationstatus"] = value;
              });

              ProfilDatabase().updateProfil(
                  userId,
                  {"notificationstatus": value}
              );

            })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(title: "Benachrichtigungen"),
      body: Column(
        children: [
          SizedBox(height: 20,),
          mitteilungEinstellung()
        ],
      ),
    );
  }
}
