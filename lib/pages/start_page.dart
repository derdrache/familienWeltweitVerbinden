import 'package:familien_suche/services/database.dart';
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
  var userID = FirebaseAuth.instance.currentUser!.uid;
  var userName = FirebaseAuth.instance.currentUser?.displayName;
  var userAuthEmail = FirebaseAuth.instance.currentUser!.email;


  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod() );

    super.initState();
  }

  _asyncMethod() async{
    var userDBEmail = await ProfilDatabaseKontroller().getProfilEmail(userID);

    if(userAuthEmail != userDBEmail  && userName != null){
      ProfilDatabaseKontroller().updateProfil(userID, {"email": userAuthEmail});
    }

  }

  checkIfFirstLogin(){
    if(widget.registered){ return false; }

    if(userName == null || userName == ""){
      return true;
    }

    return false;

  }



  Widget build(BuildContext context){
    const navigationbarButtonColor = Colors.purple;
    List<Widget> tabPages = <Widget>[
      BoardPage(),
      ErkundenPage(),
      //UmkreisPage(),
      ChatPage(),
      SettingPage()
    ];


    void _onItemTapped(int index) {
      setState(() {
        widget.selectedIndex = index;
      });
    }

    chatIcon(){
      return StreamBuilder(
          stream: ProfilDatabaseKontroller().getNewMessagesStream(userID),
          builder: (
              BuildContext context,
              AsyncSnapshot snap,
              ){
              if(snap.hasData) {
                if (snap.data.snapshot.value != null && snap.data.snapshot.value != 0) {
                  var newMessages = snap.data.snapshot.value;
                  return Stack(
                    clipBehavior: Clip.none, children: <Widget>[
                    Icon(Icons.chat),
                    Positioned(
                        top: -10,
                        right: -10,
                        child: Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle
                            ),
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  newMessages.toString(),
                                  style: TextStyle(fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            )
                        )
                    )
                  ],
                  );
                }
                return Icon(Icons.chat);
              }
              return Icon(Icons.chat);
          });



    }

    return checkIfFirstLogin() ? CreateProfilPage(): Scaffold(
          body: Center(
            child: tabPages.elementAt(widget.selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
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
              /*
              BottomNavigationBarItem(
                icon: Icon(Icons.location_city),
                label: 'Dein Umkreis',
                backgroundColor: navigationbarButtonColor,
              ),

               */
              BottomNavigationBarItem(
                icon: chatIcon(),
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