import 'dart:io';
import 'dart:ui';
import 'package:collection/collection.dart';

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
  var ownProfil = Hive.box('secureBox').get("ownProfil") ?? {};
  var userNewsContentHive = Hive.box('secureBox').get("userNewsContent") ?? [];
  Map ownSettingProfil;
  List newsFeed = [];
  var newsFeedDateList = [];
  final _controller = ScrollController();
  var scrollbarOnBottom = true;
  var userNewsContent = [];

  @override
  void initState() {
    ownSettingProfil = getSettingProfilOrAddNew();
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

  getSettingProfilOrAddNew() {
    var newsSettings = Hive.box('secureBox').get("newsSettings") ?? [];
    var ownProfil;
    for (var newsSetting in newsSettings) {
      if (newsSetting["id"] == userId) ownProfil = newsSetting;
    }

    if (ownProfil != null) return ownProfil;

    var newProfil = {
      "id": userId,
      "showFriendAdded": true,
      "showFriendChangedLocation": true,
      "showNewFamilyLocation": true,
      "showInterestingEvents": true,
      "showCityInformation": true,
      "showFriendTravelPlan": true
    };

    NewsSettingsDatabase().newProfil();
    newsSettings.add(newProfil);

    if (Hive.box('secureBox').get("newsSettings") == null) {
      Hive.box('secureBox').put("newsSettings", newsSettings);
    }

    return newProfil;
  }

  _asyncMethod() async {
    if (ownProfil.isEmpty) await getOwnProfil();
    await refreshNewsFeed();
    await refreshEvents();
    await refreshCityUserInfo();

    setState(() {});
  }

  getOwnProfil() async {
    ownProfil = await ProfilDatabase().getData("*", "WHERE id = '$userId'");
    if (ownProfil == false) ownProfil = {};

    Hive.box('secureBox').put("ownProfil", ownProfil);
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

  evenTagMatch(tags) {
    var ownInteressen = ownProfil["interessen"];

    for (var interesse in ownInteressen) {
      if (tags.contains(interesse)) return true;
    }

    return false;
  }

  sortNewsFeed() {
    newsFeed.sort((a, b) {
      int compare = a["date"].compareTo(b["date"]);
      return compare;
    });
  }

  getNewsWidgetList() {
    var widgetList = [];

    for (var item in newsFeed) {
      widgetList.add(item["newsWidget"]);
    }

    return widgetList;
  }

  checkIfNotNew(newsContent, erstelltVon) {
    for (var hiveNews in userNewsContentHive) {
      if (hiveNews["news"] == newsContent &&
          erstelltVon == hiveNews["ersteller"]) return false;
      if (const DeepCollectionEquality()
              .equals(hiveNews["news"], newsContent) &&
          erstelltVon == hiveNews["ersteller"]) return false;

      if (newsContent is Map && hiveNews["news"] is Map) {
        if (newsContent["ortData"] == null ||
            hiveNews["news"]["ortData"] == null) continue;
        if (const DeepCollectionEquality()
                .equals(hiveNews["news"], newsContent) &&
            erstelltVon == hiveNews["ersteller"]) {
          return false;
        }
      }
    }

    return true;
  }

  updateHiveUserNewsContent() {
    Hive.box('secureBox').put("userNewsContent", userNewsContent);
  }

  Widget build(BuildContext context) {

    friendsDisplay(news) {
      var userAdded = news["information"].split(" ")[1];
      var newsUserId = news["erstelltVon"];
      var friendProfil = global_func.getProfilFromHive(newsUserId);
      var text = "";

      if (friendProfil == null ||
          !userAdded.contains(userId) ||
          !ownSettingProfil["showFriendAdded"]) {
        return const SizedBox.shrink();
      }

      if (news["information"].contains("added")) {
        text = friendProfil["name"] +
            AppLocalizations.of(context).alsFreundHinzugefuegt;
      }

      userNewsContent
          .add({"news": news["information"], "ersteller": news["erstelltVon"]});

      return InkWell(
        onTap: () {
          global_func.changePage(context, ShowProfilPage(profil: friendProfil));
        },
        child: Align(
          child: Container(
              width: 800,
              margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(),
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
              child: Column(
                children: [
                  Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (checkIfNotNew(news["information"], news["erstelltVon"]))
                        const Icon(
                          Icons.fiber_new,
                          size: 30,
                        ),
                      const Expanded(child: SizedBox.shrink()),
                      Text(news["erstelltAm"].split(" ")[0],
                          style: TextStyle(color: Colors.grey[600]))
                    ],
                  )
                ],
              )),
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
      var samePlaceAndTime = ownOrt == newsOrt &&
          locationTimeCheck >= 0 &&
          ownSettingProfil["showNewFamilyLocation"];

      if (newsUserProfil == null ||
          !ownSettingProfil["showFriendChangedLocation"] ||
          !ownSettingProfil["showNewFamilyLocation"] || !(isFriend || samePlaceAndTime)) {
        return const SizedBox.shrink();
      }

      if (isFriend && ownSettingProfil["showFriendChangedLocation"]) {
        text = newsUserProfil["name"] +
            AppLocalizations.of(context).freundOrtsWechsel +
            newsOrtInfo;
      } else if (ownOrt == newsOrt &&
          locationTimeCheck >= 0 &&
          ownSettingProfil["showNewFamilyLocation"]) {
        text = newsUserProfil["name"] +
            AppLocalizations.of(context).familieInDeinemOrt;
      }

      userNewsContent
          .add({"news": news["information"], "ersteller": news["erstelltVon"]});

      return InkWell(
        onTap: () {
          global_func.changePage(
              context, ShowProfilPage(profil: newsUserProfil));
        },
        child: Align(
          child: Container(
              width: 800,
              margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(),
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
              child: Column(
                children: [
                  Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (checkIfNotNew(news["information"], news["erstelltVon"]))
                        const Icon(
                          Icons.fiber_new,
                          size: 30,
                        ),
                      const Expanded(child: SizedBox.shrink()),
                      Text(news["erstelltAm"].split(" ")[0],
                          style: TextStyle(color: Colors.grey[600]))
                    ],
                  )
                ],
              )),
        ),
      );
    }

    friendsNewTravelPlanDisplay(news) {
      var newsUserId = news["erstelltVon"];
      var friendProfil = global_func.getProfilFromHive(newsUserId);
      var isFriend = ownProfil["friendlist"].contains(newsUserId);

      if (!isFriend ||
          friendProfil == null ||
          !ownSettingProfil["showFriendTravelPlan"]) {
        return const SizedBox.shrink();
      }

      var newTravelPlan = news["information"];
      var travelPlanVon =
          newTravelPlan["von"].split(" ")[0].split("-").reversed.join("-");
      var travelPlanbis =
          newTravelPlan["bis"].split(" ")[0].split("-").reversed.join("-");
      var travelPlanCity = newTravelPlan["ortData"]["city"];
      var travelPlanCountry = newTravelPlan["ortData"]["countryname"];
      var textTitle = friendProfil["name"] +
          AppLocalizations.of(context).friendNewTravelPlan;
      var textDate = travelPlanVon + " - " + travelPlanbis;
      var textLocation = travelPlanCity + " / " + travelPlanCountry;

      userNewsContent
          .add({"news": news["information"], "ersteller": news["erstelltVon"]});

      return InkWell(
        onTap: () {
          global_func.changePage(context, ShowProfilPage(profil: friendProfil));
        },
        child: Align(
          child: Container(
              width: 800,
              margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(textTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(textDate),
                  Text(textLocation),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (checkIfNotNew(news["information"], news["erstelltVon"]))
                        const Icon(
                          Icons.fiber_new,
                          size: 30,
                        ),
                      const Expanded(child: SizedBox.shrink()),
                      Text(news["erstelltAm"].split(" ")[0],
                          style: TextStyle(color: Colors.grey[600]))
                    ],
                  )
                ],
              )),
        ),
      );
    }

    eventsDisplay(event, myLastLocationDate) {
      var locationTimeCheck = DateTime.parse(event["erstelltAm"])
          .compareTo(DateTime.parse(myLastLocationDate));
      var checkOfflineEvent = event["typ"] == "offline" &&
          locationTimeCheck >= 0 &&
          event["stadt"] == ownProfil["ort"];
      var checkOnlineEvent =
          event["typ"] == "online" && evenTagMatch(event["tags"]);

      if (!checkOfflineEvent && !checkOnlineEvent ||
          !ownSettingProfil["showInterestingEvents"] ||
          event["erstelltVon"] == userId) {
        return const SizedBox.shrink();
      }

      userNewsContent.add(
          {"news": event["beschreibung"], "ersteller": event["erstelltVon"]});

      return Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                EventCard(
                  margin: const EdgeInsets.all(15),
                  event: event,
                  withInteresse: true,
                ),
                Positioned(
                  bottom: 20,
                  right: -70,
                  child: Text(event["erstelltAm"].split(" ")[0],
                      style: TextStyle(color: Colors.grey[600])),
                ),
                if (checkIfNotNew(event["beschreibung"], event["erstelltVon"]))
                  const Positioned(
                      bottom: 20,
                      left: -70,
                      child: Icon(
                        Icons.fiber_new,
                        size: 30,
                      ))
              ],
            ),
          ));
    }

    neueStadtinformationDisplay(info, myLastLocationDate) {
      var locationTimeCheck = DateTime.parse(info["erstelltAm"])
          .compareTo(DateTime.parse(myLastLocationDate));

      if (!(locationTimeCheck >= 0 && info["ort"] == ownProfil["ort"]) ||
          info["erstelltVon"] == userId ||
          !ownSettingProfil["showCityInformation"]) {
        return const SizedBox.shrink();
      }

      var spracheIstDeutsch = kIsWeb
          ? window.locale.languageCode == "de"
          : Platform.localeName == "de_DE";
      var textHeader =
          info["ort"] + AppLocalizations.of(context).hatNeueStadtinformation;
      var textBody =
          spracheIstDeutsch ? info["informationGer"] : info["informationEng"];

      userNewsContent.add({"news": textBody, "ersteller": info["erstelltVon"]});

      return InkWell(
        onTap: () {
          global_func.changePage(
              context, StadtinformationsPage(ortName: info["ort"]));
        },
        child: Align(
          child: Container(
            width: 800,
              margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(textHeader,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(textBody),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (checkIfNotNew(textBody, info["erstelltVon"]))
                        const Icon(
                          Icons.fiber_new,
                          size: 30,
                        ),
                      const Expanded(child: SizedBox.shrink()),
                      Text(info["erstelltAm"].split(" ")[0],
                          style: TextStyle(color: Colors.grey[600]))
                    ],
                  )
                ],
              )),
        ),
      );
    }

    createNewsFeed() {
      newsFeed = [];
      var myLastLocationChangeDate = getMyLastLocationChangeDate();


      for (var news in newsFeedData) {
        if (news["erstelltVon"].contains(userId)) continue;

        if (news["typ"] == "friendlist") {
          newsFeed.add(
              {"newsWidget": friendsDisplay(news), "date": news["erstelltAm"]});
        } else if (news["typ"] == "ortswechsel") {
          newsFeed.add({
            "newsWidget": changePlaceDisplay(news, myLastLocationChangeDate),
            "date": news["erstelltAm"]
          });
        } else if (news["typ"] == "reiseplanung") {
          newsFeed.add({
            "newsWidget": friendsNewTravelPlanDisplay(news),
            "date": news["erstelltAm"]
          });
        }
      }


      for (var event in events) {
        newsFeed.add({
          "newsWidget": eventsDisplay(event, myLastLocationChangeDate),
          "date": event["erstelltAm"]
        });
      }

      for (var info in cityUserInfo) {
        newsFeed.add({
          "newsWidget":
              neueStadtinformationDisplay(info, myLastLocationChangeDate),
          "date": info["erstelltAm"]
        });
      }
    }

    getSettingProfilOrAddNew();
    createNewsFeed();
    sortNewsFeed();
    updateHiveUserNewsContent();

    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
        floatingActionButton: scrollbarOnBottom
            ? Container(
                margin: const EdgeInsets.only(top: 5),
                child: FloatingActionButton(
                  mini: true,
                  child: const Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => NewsPageSettingsPage(
                                  settingsProfil: ownSettingProfil)))
                      .whenComplete(() => setState(() {})),
                ),
              )
            : null,
        body: Container(
            padding: const EdgeInsets.only(top: 24),
            child: ListView(
                controller: _controller,
                reverse: true,
                shrinkWrap: true,
                children: [
                  ...getNewsWidgetList().reversed.toList(),
                ])));
  }
}
