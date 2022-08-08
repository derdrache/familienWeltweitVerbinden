import 'dart:io';
import 'dart:ui';

import 'package:familien_suche/pages/show_profil.dart';
import 'package:familien_suche/pages/weltkarte/stadtinformation.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import '../../../services/database.dart';
import '../../../global/global_functions.dart' as global_func;
import '../events/eventCard.dart';
import 'news_page_settings.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key key}) : super(key: key);

  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var newsFeedData = Hive.box('secureBox').get("newsFeed") ?? [];
  var events = Hive.box('secureBox').get("events") ?? [];
  var cityUserInfo = Hive.box('secureBox').get("stadtinfoUser") ?? [];
  var ownProfil = Hive.box('secureBox').get("ownProfil");
  List newsFeed = [];
  var newsFeedDateList = [];
  final _controller = ScrollController();
  var scrollbarOnBottom = true;

  @override
  void initState() {
    _controller.addListener(() {
        bool isTop = _controller.position.pixels == 0;
        if (isTop) {
          scrollbarOnBottom = true;
        } else {
          scrollbarOnBottom = false;
        }
        setState(() {});

    });

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
    List<dynamic> dbNewsData = await NewsPageDatabase()
        .getData("*", "ORDER BY erstelltAm ASC", returnList: true);
    if (dbNewsData == false) dbNewsData = [];

    Hive.box('secureBox').put("newsFeed", dbNewsData);

    newsFeedData = dbNewsData;
  }

  refreshEvents() async {
    List<dynamic> dbEvents = await EventDatabase()
        .getData("*", "ORDER BY stadt ASC", returnList: true);
    if (dbEvents == false) dbEvents = [];

    Hive.box('secureBox').put("events", dbEvents);

    events = dbEvents;
  }

  refreshCityUserInfo() async {
    cityUserInfo =
        await StadtinfoUserDatabase().getData("*", "", returnList: true);
    Hive.box('secureBox').put("stadtinfoUser", cityUserInfo);
  }

  getMyLastLocationChangeDate() {
    var lastLocationChangeDate = "";

    for (var news in newsFeedData) {
      if (news["erstelltVon"] == userId && news["typ"] == "ortswechsel") {
        lastLocationChangeDate = news["erstelltAm"].split(" ")[0];
      }
    }

    if (lastLocationChangeDate.isEmpty) lastLocationChangeDate = "2022-08-01";

    return lastLocationChangeDate;
  }

  evenTagMatch(tags){
    var ownInteressen = ownProfil["interessen"];

    for(var interesse in ownInteressen){
      if(tags.contains(interesse)) return true;
    }

    return false;
  }

  Widget build(BuildContext context) {

    friendsDisplay(news) {
      var userAdded = news["information"].split(" ")[1];
      var newsUserId = news["erstelltVon"];
      var friendProfil = global_func.getProfilFromHive(newsUserId);
      var text = "";

      if (friendProfil == null || !userAdded.contains(userId)) {
        return const SizedBox.shrink();
      }

      if (news["information"].contains("added")) {
        text = friendProfil["name"] +
            AppLocalizations.of(context).alsFreundHinzugefuegt;
      }

      return InkWell(
        onTap: () {
          global_func.changePage(context, ShowProfilPage(profil: friendProfil));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), border: Border.all(),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(children: [
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text(news["erstelltAm"].split(" ")[0],
            style: TextStyle(color: Colors.grey[600]))
            ],)
          ],)
        ),
      );
    }

    changePlaceDisplay(news, myLastLocationDate) {
      var newsUserId = news["erstelltVon"];
      var newsUserProfil = global_func.getProfilFromHive(newsUserId);
      var isFriend = ownProfil["friendlist"].contains(newsUserId);
      var text = "";
      var newsOrt = news["information"]["city"];
      var newsLand = news["information"]["countryname"];
      var newsOrtInfo =
          newsLand == newsOrt ? newsLand : newsOrt + " / " + newsLand;
      var ownOrt = ownProfil["ort"];
      var locationTimeCheck = DateTime.parse(news["erstelltAm"])
          .compareTo(DateTime.parse(myLastLocationDate));

      if(newsUserProfil == null) return const SizedBox.shrink();

      if (isFriend) {
        text = newsUserProfil["name"] + AppLocalizations.of(context).freundOrtsWechsel + newsOrtInfo;
      } else if (ownOrt == newsOrt && locationTimeCheck >= 0) {
        text = newsUserProfil["name"] + AppLocalizations.of(context).familieInDeinemOrt;
      }

      return InkWell(
        onTap: () {
          global_func.changePage(
              context, ShowProfilPage(profil: newsUserProfil));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), border: Border.all(),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(children: [
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text(news["erstelltAm"].split(" ")[0],
            style: TextStyle(color: Colors.grey[600]))
            ],)
          ],)
        ),
      );
    }

    eventsDisplay(event,  myLastLocationDate) {
      var locationTimeCheck = DateTime.parse(event["erstelltAm"])
          .compareTo(DateTime.parse(myLastLocationDate));
      var checkOfflineEvent = event["typ"] == "offline" && locationTimeCheck >= 0 && event["stadt"] == ownProfil["ort"];
      var checkOnlineEvent = event["typ"] == "online" && evenTagMatch(event["tags"]);

      if(!checkOfflineEvent && !checkOnlineEvent) return const SizedBox.shrink();



      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Stack(clipBehavior: Clip.none,children: [
            EventCard(
              margin: const EdgeInsets.all(15),
              event: event,
              withInteresse: true,
            ),
            Positioned(
              bottom: 20,
              right: -70,
              child: Text(
                  event["erstelltAm"].split(" ")[0],
                  style: TextStyle(color: Colors.grey[600])),
            )
          ],),
        )
      );
    }

    neueStadtinformationDisplay(info, myLastLocationDate) {
      var locationTimeCheck = DateTime.parse(info["erstelltAm"])
          .compareTo(DateTime.parse(myLastLocationDate));

      if(!(locationTimeCheck >= 0 && info["ort"] == ownProfil["ort"]) || info["erstelltVon"] == userId){
        return const SizedBox.shrink();
      }

      var spracheIstDeutsch = kIsWeb
          ? window.locale.languageCode == "de"
          : Platform.localeName == "de_DE";
      var textHeader = info["ort"]
          + AppLocalizations.of(context).hatNeueStadtinformation;
      var textBody = spracheIstDeutsch ? info["informationGer"] : info["informationEng"];

      return InkWell(
        onTap: () {
          global_func.changePage(
              context, StadtinformationsPage(ortName: info["ort"]));
        },
        child: Container(
            margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),border: Border.all(),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
              Text(textHeader, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Text(textBody),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(info["erstelltAm"].split(" ")[0],
                    style: TextStyle(color: Colors.grey[600]))
              ],)
            ],)
        ),
      );
    }

    createNewsFeed() {
      newsFeed = [];
      var myLastLocationChangeDate = getMyLastLocationChangeDate();

      for (var news in newsFeedData) {
        if (news["erstelltVon"].contains(userId)) continue;

        if (news["typ"] == "friendlist") newsFeed.add(friendsDisplay(news));
        if (news["typ"] == "ortswechsel") {
          newsFeed.add(changePlaceDisplay(news, myLastLocationChangeDate));
        }

      }

      for (var event in events) {
        newsFeed.add(eventsDisplay(event, myLastLocationChangeDate));
      }

      for (var info in cityUserInfo) {
        newsFeed.add(neueStadtinformationDisplay(info, myLastLocationChangeDate));
        newsFeed.add(neueStadtinformationDisplay(info, myLastLocationChangeDate));
      }
    }

    createNewsFeed();

    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
        floatingActionButton: scrollbarOnBottom ? Container(
          margin: const EdgeInsets.only(top:5),
          child: FloatingActionButton(
            mini: true,
            child: const Icon(Icons.settings),
            onPressed: () => global_func.changePage(context, NewsPageSettingsPage()),
          ),
        ) : null,
        body: Container(
          padding: const EdgeInsets.only(top: kIsWeb ? 0 : 24),
          child: ListView(
            controller: _controller,
              reverse: true,
              shrinkWrap: true,
              children: [
                ...newsFeed.reversed.toList(),
              ]
          )
        )
    );
  }
}
