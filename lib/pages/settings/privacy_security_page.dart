import 'package:flutter/material.dart';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';

class PrivacySecurityPage extends StatefulWidget {
  var profil;

  PrivacySecurityPage({Key? key,required this.profil}) : super(key: key);

  @override
  _PrivacySecurityPageState createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {

  @override
  Widget build(BuildContext context) {
    print(widget.profil);

    emailSettingContainer(){
      return Row(
        children: [
          SizedBox(width: 20),
          Text("Email für alle Sichtbar", style: TextStyle(fontSize: 20),),
          Expanded(child: SizedBox(width: 20)),
          Switch(
              value: widget.profil["emailAnzeigen"],
              onChanged: (value){
                setState(() {
                  widget.profil["emailAnzeigen"] = value;
                });
                dbChangeProfil(
                    widget.profil["docid"],
                    {"emailAnzeigen": widget.profil["emailAnzeigen"]}
                );
              })
        ],
      );
    }

    return Scaffold(
      appBar: customAppBar(title: "Privatsphäre und Sicherheit"),
      body: Column(
        children: [
          SizedBox(height: 20,),
          emailSettingContainer()
        ],
      ),
    );
  }
}
