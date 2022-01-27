import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'create_profil_page.dart';
import 'board_page.dart';
import 'erkunden_page.dart';
import 'umkreis_page.dart';
import 'chat/chat_page.dart';
import 'settings/setting_page.dart';


class StartPage extends StatefulWidget{
  var selectedIndex;
  bool registered;

  StartPage({this.selectedIndex=0, this.registered = false});

  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>{


  checkIfFirstLogin(){
    if(widget.registered){ return false; }

    if(FirebaseAuth.instance.currentUser!.displayName == null ||
        FirebaseAuth.instance.currentUser!.displayName == ""){
      return true;
    }

    return false;

  }


  Widget build(BuildContext context){
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

    return checkIfFirstLogin() ? CreateProfilPage(): Scaffold(
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
            selectedItemColor: Colors.white,
            onTap: _onItemTapped,
          )
    );
  }
}