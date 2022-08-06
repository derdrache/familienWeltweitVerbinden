import 'package:familien_suche/pages/show_profil.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../global/variablen.dart' as global_var;
import '../services/database.dart';
import '../global/global_functions.dart' as global_func;

class NewsPage extends StatefulWidget{
  const NewsPage({Key key}) : super(key: key);

  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage>{
  var userId = FirebaseAuth.instance.currentUser.uid;
  var newsFeedData = Hive.box('secureBox').get("newsFeed") ?? [];
  var events = Hive.box('secureBox').get("events") ?? [];
  var cityUserInfo = Hive.box('secureBox').get("stadtinfoUser") ?? [];
  var ownProfil = Hive.box('secureBox').get("ownProfil");
  List<Widget> newsFeed = [];
  var newsFeedDateList = [];

  @override
  void initState() {

    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod());
    super.initState();
  }

  _asyncMethod() async {
    await refreshNewsFeed();
    await refreshEvents();
    await refreshCityUserInfo();

    setState(() {});
  }

  refreshNewsFeed() async {
    List<dynamic> dbNewsData =
        await NewsPageDatabase().getData("*", "ORDER BY erstelltAm ASC", returnList: true);
    if (dbNewsData == false) dbNewsData = [];

    Hive.box('secureBox').put("newsFeed", dbNewsData);

    newsFeedData = dbNewsData;
  }

  refreshEvents() async{
    List<dynamic> dbEvents =
    await EventDatabase().getData("*", "ORDER BY stadt ASC", returnList: true);
    if (dbEvents == false) dbEvents = [];

    Hive.box('secureBox').put("events", dbEvents);

    events = dbEvents;

  }

  refreshCityUserInfo() async{
    cityUserInfo =
    await StadtinfoUserDatabase().getData("*", "", returnList: true);
    Hive.box('secureBox').put("stadtinfoUser", cityUserInfo);
  }




  Widget build(BuildContext context){

    iconBox(icon){
      return Container(
        margin: const EdgeInsets.all(15),
        height: 25,
        width: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.all(Radius.circular(10))

        ),
        child: Icon(icon, color: Colors.white,size: 24,)
      );
    }

    friendsSliderBox(){
      return Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 1, color: global_var.borderColorGrey))
        ),
        width: 600,
        height: 80,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            iconBox(Icons.people),
            iconBox(Icons.people),
            iconBox(Icons.people),
            iconBox(Icons.people),
            iconBox(Icons.people),
            iconBox(Icons.people),
          ],
        ),
      );
    }

    headBox(){
      return Container(
        padding: const EdgeInsets.all(10),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          const IconButton(
            icon: const Icon(Icons.settings),
            onPressed: null,
          )
        ],),
      );
    }

    newsFeedBox(){
      return Container(
        margin: EdgeInsets.all(10),
        child: ListView(
          shrinkWrap: true,
          children: newsFeed,
        )
      );
    }


    friendsDisplay(news){
      var newsUserId = news["information"].split(" ")[1];
      var friendProfil = global_func.getProfilFromHive(newsUserId);
      var isFriend = ownProfil["friendlist"].contains(newsUserId);
      var text = "";

      if(friendProfil == null || ownProfil == null || !isFriend) return const SizedBox.shrink();


      if(news["information"].contains("added")){
        text = friendProfil["name"] + AppLocalizations.of(context).alsFreundHinzugefuegt;
      }

      return InkWell(
        onTap: (){
          global_func.changePage(context, ShowProfilPage(
            profil: friendProfil
          ));
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all()
          ),
          child: Center(child: Text(text)),
        ),
      );
    }

    changePlaceDisplay(news){
      var newsUserId = news["erstelltVon"];
      var newsUserProfil = global_func.getProfilFromHive(newsUserId);
      var isFriend = ownProfil["friendlist"].contains(newsUserId);
      var text = "";
      var ort = news["information"]["city"];
      var land = news["information"]["countryname"];
      var ortInfo = land == ort ? land : ort + " / " + land;

      // Land in die passende Sprache wechseln?
      // in der gleichen Stadt + radius?

      if(isFriend){
        text = newsUserProfil["name"] + "ist jetzt in " + ortInfo;
      }


      return InkWell(
        onTap: (){
          global_func.changePage(context, ShowProfilPage(
              profil: newsUserProfil
          ));
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all()
          ),
          child: Center(child: Text(text)),
        ),
      );
    }

    eventsDisplay(news){
      // locale Events anzeigen
      // interessante Online Events anzeigen
      return Container();
    }

    neueStadtinformationDisplay(news){
      // stadtinformation für den aktuellen Ort anzeigen
      return Container();
    }


    createNewsFeed(){
      newsFeed = [];

      for(var news in newsFeedData){
        if(news["erstelltVon"].contains(userId)) continue;

        if(news["typ"] == "friendlist") newsFeed.add(friendsDisplay(news));
        if(news["typ"] == "ortswechsel") newsFeed.add(changePlaceDisplay(news));
      }

      for(var event in events){

      }

      for(var info in cityUserInfo){

      }
    }


    createNewsFeed();

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: kIsWeb? 0: 24),
        child: Column(
          children: [
            headBox(),
            newsFeedBox()
          ],
        ),
      )
    );

  }
}
