import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'board_page.dart';
import 'erkunden_page.dart';
import 'umkreis_page.dart';
import 'chat_page.dart';
import 'setting_page/setting_page.dart';
import 'setting_page/profil_change_page.dart';


class StartPage extends StatefulWidget{
  var selectedIndex;
  var newVisit;

  StartPage({this.selectedIndex=0, this.newVisit = false});

  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>{

  checkIfFirstLogin(){
    var userCreateTime = FirebaseAuth.instance.currentUser!.metadata.creationTime;
    var userLastLoginTime = FirebaseAuth.instance.currentUser!.metadata.lastSignInTime;

    if(widget.newVisit == false){
      return false;
    }else if (FirebaseAuth.instance.currentUser!.displayName == null){
      return true;
    } else{
      return false;
    }
  }

  Widget build(BuildContext context){
    const pageMainColor = Colors.grey;
    const navigationbarButtonColor = Colors.purple;
    List<Widget> tabPages = <Widget>[
      BoardPage(),
      ErkundenPage(),
      UmkreisPage(),
      ChatPage(),
      SettingPage()
    ];


    void _onItemTapped(int index) {
      setState(() {
        widget.selectedIndex = index;
      });
    }

    return checkIfFirstLogin() ? ProfilChangePage(newProfil: true): MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: pageMainColor,
      ),
      home: Scaffold(
          body: Center(
            child: tabPages.elementAt(widget.selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Board',
                backgroundColor: navigationbarButtonColor,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.travel_explore),
                label: 'Weltweit suchen',
                backgroundColor: navigationbarButtonColor,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_city),
                label: 'Dein Umkreis',
                backgroundColor: navigationbarButtonColor,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chat',
                backgroundColor: navigationbarButtonColor,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
                backgroundColor: navigationbarButtonColor,
              ),
            ],
            currentIndex: widget.selectedIndex,
            selectedItemColor: pageMainColor,
            onTap: _onItemTapped,
          )
      ),
    );
  }
}