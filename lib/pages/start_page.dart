import 'package:familien_suche/pages/events/event_page.dart';
import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';


import 'news_page.dart';
import 'create_profil_page.dart';
import 'erkunden_page.dart';
import 'chat/chat_page.dart';
import 'settings/setting_page.dart';


class StartPage extends StatefulWidget{
  var selectedIndex;
  bool registered;

  StartPage({this.selectedIndex=0, this.registered = false});

  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>{
  var userID = FirebaseAuth.instance.currentUser?.uid;
  var userName = FirebaseAuth.instance.currentUser?.displayName;
  var userAuthEmail = FirebaseAuth.instance.currentUser?.email;
  PackageInfo packageInfo;


  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod() );

    super.initState();
  }

  _asyncMethod() async{
    try{

      var updateInformation = await InAppUpdate.checkForUpdate();
      if(updateInformation.updateAvailability ==
          UpdateAvailability.updateAvailable && !kIsWeb) {
        InAppUpdate.startFlexibleUpdate();
      }
    } catch (error){
      print("kein Playstore");
    }

    profilCheck();



  }

  profilCheck() async{
    if(userName == null) return;

    var userDBEmail = await ProfilDatabase().getOneData("email","id",userID);
    var userDeviceTokenDb = await ProfilDatabase().getOneData("token","id",userID);
    var userDeviceTokenReal = kIsWeb? null : await FirebaseMessaging.instance.getToken();

    if(userAuthEmail != userDBEmail["email"]){
      ProfilDatabase().updateProfil(userID, "email",userAuthEmail);
    }

    if(userDeviceTokenDb["token"] != userDeviceTokenReal){
      ProfilDatabase().updateProfil(userID, "token", userDeviceTokenReal);
    }

    ProfilDatabase().updateProfil(userID, "lastLogin", DateTime.now().toString());
  }


  Widget build(BuildContext context){
    List<Widget> tabPages = <Widget>[
      //BoardPage(),
      ErkundenPage(),
      EventPage(),
      ChatPage(),
      const SettingPage()
    ];



    void _onItemTapped(int index) {
      setState(() {
        widget.selectedIndex = index;
      });
    }

    chatIcon(){
      return FutureBuilder(
          future: ProfilDatabase().getOneData("newMessages", "id", userID),
          builder: (
              BuildContext context,
              AsyncSnapshot snap,
              ){
              if(snap.hasData) {
                  var newMessages = snap.data;

                  newMessages = newMessages == false ? 0 : int.parse(newMessages["newMessages"]);

                  return Stack(
                    clipBehavior: Clip.none, children: <Widget>[
                    const Icon(Icons.chat),
                    newMessages > 0 ? Positioned(
                        top: -10,
                        right: -10,
                        child: Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle
                            ),
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                newMessages.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            )
                        )
                    ) : SizedBox.shrink()
                  ],
                  );
                return const Icon(Icons.chat);
              }
              return const Icon(Icons.chat);
          });



    }

    return Scaffold(
          body: Center(
            child: tabPages.elementAt(widget.selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).colorScheme.primary,
            currentIndex: widget.selectedIndex,
            selectedItemColor: Colors.white,
            onTap: _onItemTapped,
            items: <BottomNavigationBarItem>[
/*
              BottomNavigationBarItem(
                icon: Icon(Icons.feed),
                label: 'News',
              ),

 */
              const BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'World',
              ),

              const BottomNavigationBarItem(
                icon: Icon(Icons.event),
                label: 'Events',
              ),


              BottomNavigationBarItem(
                icon: chatIcon(),
                label: 'Chat',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],

          )
    );
  }
}