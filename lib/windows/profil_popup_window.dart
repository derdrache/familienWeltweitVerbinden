import 'package:flutter/material.dart';

import '../global/global_functions.dart' as globalFunctions;


_menuBarProfil(context, addFriendButton){
  return Row(
    children: [
      TextButton(
        style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                )
            )
        ),
        child: Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      Expanded(child: SizedBox()),
      TextButton(
          style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                  )
              )
          ),
          child: Icon(Icons.message),
          onPressed: () => print("open Chat or create a new one")
      ),
      addFriendButton,
      TextButton(
        style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                )
            )
        ),
        child: Icon(Icons.more_vert),
        onPressed: () => print("open Settings"),

      )
    ],
  );
}

_titelProfil(profil){
  return Center(
      child:
      Text(
        profil["name"],
        style: TextStyle(
          fontSize: 24
        ),
      )
  );
}

_infoProfil(profil){
  var childrenList = profil["kinder"];
  var childrenAgeList = [];
  double columnAbstand = 5;

  childrenList.forEach((child){
    childrenAgeList.add(globalFunctions.timeStampToAllDict(child)["years"]);
  });


  return Container(
      padding: EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Info", style: TextStyle(color: Colors.blue)),
          SizedBox(height: columnAbstand),
          Text("Ort: " + profil["ort"]),
          SizedBox(height: columnAbstand),
          Text("Reiseart: " + profil["reiseart"]),
          SizedBox(height: columnAbstand),
          Text("Sprache: " + profil["sprachen"].join(" , ")),
          SizedBox(height: columnAbstand),
          Text("Kinder: " + childrenAgeList.join(" , ")),
          SizedBox(height: columnAbstand),
          Text("Interessen: " + profil["interessen"].join(" , ")),
          SizedBox(height: columnAbstand),
          Text("Über mich: " + profil["aboutme"]),
        ],
      )
  );
}

_kontaktProfil(profil){
  return Container(
    padding: EdgeInsets.only(left: 10),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Kontakt",style: TextStyle(color: Colors.blue),),
          Text("Email: " + profil["email"])
        ],
      ),
  );
}

profilPopupWindow(context, profil, {addFriendButton}){

  return showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(10, 20, 10, 20),
          content: Container(
            height: 400,
            width: double.maxFinite,
            child: Scrollbar(
              isAlwaysShown: true,
              child: ListView(
                  children: [
                    _menuBarProfil(context, addFriendButton),
                    SizedBox(height: 25),
                    _titelProfil(profil),
                    SizedBox(height: 30),
                    _infoProfil(profil),
                    SizedBox(height: 30),
                    _kontaktProfil(profil),
                  ]
              ),
            ),
          ),
        );
      }
  );
}

