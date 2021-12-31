import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

import 'profil_change_page.dart';


class SettingPage extends StatelessWidget{

  Widget separationBox(){
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(width: 1, color: Colors.grey))
      )
    );
  }

  Widget build(BuildContext context){
    double screenWidth = MediaQuery.of(context).size.width;

    Widget elementButtons (icon, name){
      double elementDistance = 10;

      return Container(
          color: Colors.purple,
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child:Row(
              children:[
                SizedBox(width: elementDistance),
                Icon(icon, color: Colors.white),
                SizedBox(width: elementDistance),
                Text(name),
                Expanded(
                    child:Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children:[
                          Icon(Icons.chevron_right, color: Colors.white),
                          SizedBox(width: elementDistance)
                        ]
                    )
                ),
              ]
          )
      );
    }

    Widget settingElement(icon, text, page){
      return TextButton(
        child: elementButtons(icon, text),
        onPressed:  () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page)
        ),
      );
      return OpenContainer(
          closedBuilder: (context, _) => elementButtons(icon, text),
          openBuilder: (context, _) => page
          );
    }

    Widget settingOptions(screenWidth){

      return Container(
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.all(Radius.circular(10))
          ),
          width: screenWidth,
          child:Column(children: [
            settingElement(
                Icons.manage_accounts,
                "Profil bearbeiten",
                ProfilChangePage(newProfil: false,)
            ),
            separationBox(),
            settingElement(Icons.manage_accounts, "Placeholder", null)
          ])
      );
    }

    return Center(child:Column(
          children: [
            settingOptions(screenWidth)
          ],
        )
    );
  }
}