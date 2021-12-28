import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

import 'board_page.dart';
import 'erkunden_page.dart';
import 'umkreis_page.dart';
import 'chat_page.dart';
import 'setting_page/setting_page.dart';


class StartPage extends StatefulWidget{
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>{
  int _selectedIndex = 0;

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
        _selectedIndex = index;
      });
    }

    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: pageMainColor,
      ),
      home: Scaffold(
          body: Center(
            child: tabPages.elementAt(_selectedIndex),
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
            currentIndex: _selectedIndex,
            selectedItemColor: pageMainColor,
            onTap: _onItemTapped,
          )
      ),
    );
  }
}