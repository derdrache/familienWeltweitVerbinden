import 'package:flutter/material.dart';

import 'pages/board_page.dart';
import 'pages/erkunden_page.dart';
import 'pages/umkreis_page.dart';
import 'pages/chat_page.dart';
import 'pages/setting_page/setting_page.dart';

void main()async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget{
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>{
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