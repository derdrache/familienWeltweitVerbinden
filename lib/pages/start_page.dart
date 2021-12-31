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

  StartPage({this.selectedIndex=0});

  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>{
  int _selectedIndex = 0;

  checkIfFirstLogin(){
    var userCreateTime = FirebaseAuth.instance.currentUser!.metadata.creationTime;
    var userLastLoginTime = FirebaseAuth.instance.currentUser!.metadata.lastSignInTime;

    // or FirebaseAuth.instance.currentUser!.displayName == null ?
    if (userCreateTime == userLastLoginTime){
      return true;
    } else{
      return false;
    }
  }

  Widget build(BuildContext context){
    const pageMainColor = Colors.grey;
    const navigationbarButtonColor = Colors.purple;
    print(FirebaseAuth.instance.currentUser!.displayName);
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