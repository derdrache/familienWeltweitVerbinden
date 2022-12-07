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
import 'package:intl/intl.dart';
import '../../../services/database.dart';
import '../../../global/global_functions.dart' as global_func;
import '../events/eventCard.dart';
import 'news_page_settings.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key key}) : super(key: key);

  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final String userId = FirebaseAuth.instance.currentUser.uid;
  List newsFeedData = Hive.box('secureBox').get("newsFeed") ?? [];
  List events = Hive.box('secureBox').get("events") ?? [];
  List cityUserInfo = Hive.box('secureBox').get("stadtinfoUser") ?? [];
  Map ownProfil = Hive.box('secureBox').get("ownProfil") ?? {};
  List userNewsContentHive = Hive.box('secureBox').get("userNewsContent") ?? [];
  Map ownSettingProfil = Hive.box('secureBox').get("ownNewsSetting");
  List newsFeed = [];
  List newsFeedDateList = [];
  final _controller = ScrollController();
  bool scrollbarOnBottom = true;
  List userNewsContent = [];

  @override
  void initState() {
    ownSettingProfil ??= _addNewSettingProfil();

    _controller.addListener(() {
      bool isTop = _controller.position.pixels == 0;
      if (isTop) {
        scrollbarOnBottom = true;
      } else {
        scrollbarOnBottom = false;
      }
      setState(() {});
    });



    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_){
          _refresh();
    });
  }

  _refresh()async{
    await refreshHiveNewsPage();
    setState(() {});
  }

  _addNewSettingProfil(){
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
    Hive.box('secureBox').put("ownNewsSetting", newProfil);

    return newProfil;
  }

  _getMyLastLocationChangeDate() {
    var lastLocationChangeDate = "";

    for (var news in newsFeedData) {
      if (news["erstelltVon"] == userId && news["typ"] == "ortswechsel") {
        lastLocationChangeDate = news["erstelltAm"].split(" ")[0];
      }
    }

    String newsPagePatchDate = "2022-08-01";
    if (lastLocationChangeDate.isEmpty) lastLocationChangeDate = newsPagePatchDate;

    return lastLocationChangeDate;
  }

  _evenTagMatch(tags) {
    List ownInteressen = ownProfil["interessen"];

    for (var interesse in ownInteressen) {
      if (tags.contains(global_func.changeGermanToEnglish(interesse)) ||
          tags.contains(global_func.changeEnglishToGerman(interesse))) {
        return interesse;
      }
    }
  }

  _sortNewsFeed() {
    newsFeed.sort((a, b) {
      int compare = a["date"].compareTo(b["date"]);
      return compare;
    });
  }

  _getNewsWidgetList() {
    double screenHeight = MediaQuery.of(context).size.height;
    var widgetList = [];

    for (var item in newsFeed) {
      widgetList.add(item["newsWidget"]);
    }

    if (_checkWidgetListIsEmpty(widgetList)) {
      widgetList.add(Center(
          child: Container(
              padding: EdgeInsets.only(top: screenHeight/3),
              child: Text(
                AppLocalizations.of(context).keineNewsVorhanden,
                style: const TextStyle(fontSize: 20),
              ))));
    }

    return widgetList;
  }

  _checkIfNew(newsContent, erstelltVon) {
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

  _updateHiveUserNewsContent() {
    Hive.box('secureBox').put("userNewsContent", userNewsContent);
  }

  _checkWidgetListIsEmpty(widgetList) {
    for (var widget in widgetList) {
      if (!(widget.runtimeType == SizedBox)) {
        return false;
      }
    }

    return true;
  }

  Widget build(BuildContext context) {
    const double titleFontSize = 15;

    friendsDisplay(news) {
      String addedUser = news["information"].split(" ")[1];
      String newsUserId = news["erstelltVon"];
      Map friendProfil = getProfilFromHive(profilId: newsUserId);
      String text = "";

      if (friendProfil == null ||
          !addedUser.contains(userId) ||
          ownSettingProfil["showFriendAdded"] == 0) {
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
          child: Stack(
            children: [
              Container(
                  width: 800,
                  margin:
                      const EdgeInsets.only(bottom: 45, left: 20, right: 20),
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 15, bottom: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset:
                            const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Text(text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize))),
              Positioned(
                  bottom: 20,
                  right: 35,
                  child: NewsStamp(
                      date: news["erstelltAm"],
                      isNew:
                          _checkIfNew(news["information"], news["erstelltVon"])))
            ],
          ),
        ),
      );
    }

    changePlaceDisplay(news, myLastLocationDate) {
      String newsUserId = news["erstelltVon"];
      Map newsUserProfil = getProfilFromHive(profilId: newsUserId);
      bool isFriend = ownProfil["friendlist"].contains(newsUserId);
      String text = "";
      String newsOrt = news["information"]["city"];
      String newsLand = news["information"]["countryname"];
      String ownOrt = ownProfil["ort"];
      var locationTimeCheck = DateTime.parse(news["erstelltAm"])
          .compareTo(DateTime.parse(myLastLocationDate));
      bool samePlaceAndTime = ownOrt == newsOrt &&
          locationTimeCheck >= 0 &&
          ownSettingProfil["showNewFamilyLocation"] == 1;

      if (newsUserProfil == null ||
          newsOrt == null ||
          newsLand == null ||
          ownSettingProfil["showFriendChangedLocation"] == 0 ||
          ownSettingProfil["showNewFamilyLocation"] == 0 ||
          !(isFriend || samePlaceAndTime)) {
        return const SizedBox.shrink();
      }

      String newsOrtInfo =
          newsLand == newsOrt ? newsLand : newsOrt + " / " + newsLand;

      if (isFriend && ownSettingProfil["showFriendChangedLocation"] == 1) {
        text = newsUserProfil["name"] +
            AppLocalizations.of(context).freundOrtsWechsel +
            "\n" +
            newsOrtInfo;
      } else if (ownOrt == newsOrt && samePlaceAndTime) {
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
          child: Stack(
            children: [
              Container(
                  width: 800,
                  margin:
                      const EdgeInsets.only(bottom: 45, left: 20, right: 20),
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 15, bottom: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset:
                            const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Text(text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize))),
              Positioned(
                  bottom: 20,
                  right: 35,
                  child: NewsStamp(
                      date: news["erstelltAm"],
                      isNew:
                          _checkIfNew(news["information"], news["erstelltVon"])))
            ],
          ),
        ),
      );
    }

    friendsNewTravelPlanDisplay(news) {
      String newsUserId = news["erstelltVon"];
      Map friendProfil = getProfilFromHive(profilId: newsUserId);
      bool isFriend = ownProfil["friendlist"].contains(newsUserId);

      if (!isFriend ||
          friendProfil == null ||
          ownSettingProfil["showFriendTravelPlan"] == 0) {
        return const SizedBox.shrink();
      }

      Map newTravelPlan = news["information"];
      String travelPlanVon =
          newTravelPlan["von"].split(" ")[0].split("-").reversed.join("-");
      String travelPlanbis =
          newTravelPlan["bis"].split(" ")[0].split("-").reversed.join("-");
      String travelPlanCity = newTravelPlan["ortData"]["city"];
      String travelPlanCountry = newTravelPlan["ortData"]["countryname"];
      String textTitle = friendProfil["name"] +
          AppLocalizations.of(context).friendNewTravelPlan;
      String textDate = travelPlanVon + " - " + travelPlanbis;
      String textLocation = travelPlanCity + " / " + travelPlanCountry;

      userNewsContent
          .add({"news": news["information"], "ersteller": news["erstelltVon"]});

      return InkWell(
        onTap: () {
          global_func.changePage(context, ShowProfilPage(profil: friendProfil));
        },
        child: Align(
          child: Stack(
            children: [
              Container(
                  width: 800,
                  margin:
                      const EdgeInsets.only(bottom: 45, left: 20, right: 20),
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 15, bottom: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset:
                            const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(textTitle,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: titleFontSize)),
                      const SizedBox(height: 10),
                      Text(textDate),
                      Text(textLocation),
                    ],
                  )),
              Positioned(
                  bottom: 20,
                  right: 35,
                  child: NewsStamp(
                      date: news["erstelltAm"],
                      isNew:
                          _checkIfNew(news["information"], news["erstelltVon"])))
            ],
          ),
        ),
      );
    }

    eventsDisplay(event, myLastLocationDate) {
      var locationTimeCheck = DateTime.parse(event["erstelltAm"])
          .compareTo(DateTime.parse(myLastLocationDate));
      bool isOnline = event["typ"] == "online";
      bool checkOfflineEvent = !isOnline &&
          locationTimeCheck >= 0 &&
          event["stadt"] == ownProfil["ort"];
      bool checkOnlineEvent = isOnline && _evenTagMatch(event["tags"]) != null;
      bool isPrivate = event["art"] == "privat" || event["art"] == "private";
      String eventText = "";

      if (!checkOfflineEvent && !checkOnlineEvent ||
          ownSettingProfil["showInterestingEvents"] == 0 ||
          event["erstelltVon"] == userId ||
          isPrivate) {
        return const SizedBox.shrink();
      }

      if(isOnline){
        eventText = AppLocalizations.of(context).newsPageOnlineEventVorschlag + _evenTagMatch(event["tags"]).toString();
      }else{
        eventText = AppLocalizations.of(context).newsPageOfflineEventVorschlag;
      }

      userNewsContent.add(
          {"news": event["beschreibung"], "ersteller": event["erstelltVon"]});

      return Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                EventCard(
                  margin: const EdgeInsets.all(15),
                  event: event,
                  withInteresse: true,
                ),
                Row(
                  children: [
                    SizedBox(width: 10),
                    Icon(
                      Icons.fiber_new,
                      size: 30,
                      color: _checkIfNew(event["beschreibung"], event["erstelltVon"])
                          ? null
                          : Colors.transparent,
                    ),
                    SizedBox(width: 70),
                    Expanded(child: Text(eventText)),
                    SizedBox(width: 10),
                    Text(event["erstelltAm"].split(" ")[0],
                        style: TextStyle(color: Colors.grey[600])),
                    SizedBox(width: 10),
                  ],
                )
              ],
            ),
          ));
    }

    neueStadtinformationDisplay(info, myLastLocationDate) {
      var locationTimeCheck = DateTime.parse(info["erstelltAm"])
          .compareTo(DateTime.parse(myLastLocationDate));

      if (!(locationTimeCheck >= 0 && info["ort"] == ownProfil["ort"]) ||
          info["erstelltVon"] == userId ||
          ownSettingProfil["showCityInformation"] == 0) {
        return const SizedBox.shrink();
      }

      bool spracheIstDeutsch = kIsWeb
          ? window.locale.languageCode == "de"
          : Platform.localeName == "de_DE";
      String textHeader =
          info["ort"] + AppLocalizations.of(context).hatNeueStadtinformation;
      String textBody =
          spracheIstDeutsch ? info["informationGer"] : info["informationEng"];

      userNewsContent.add({"news": textBody, "ersteller": info["erstelltVon"]});

      return InkWell(
        onTap: () {
          global_func.changePage(
              context, StadtinformationsPage(ortName: info["ort"]));
        },
        child: Align(
          child: Stack(
            children: [
              Container(
                  width: 800,
                  margin:
                      const EdgeInsets.only(bottom: 45, left: 20, right: 20),
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 15, bottom: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset:
                            const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(textHeader,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: titleFontSize)),
                      const SizedBox(height: 10),
                      Text(textBody),
                    ],
                  )),
              Positioned(
                  bottom: 20,
                  right: 35,
                  child: NewsStamp(
                      date: info["erstelltAm"],
                      isNew: _checkIfNew(textBody, info["erstelltVon"])))
            ],
          ),
        ),
      );
    }

    addLocationWelcome(news) {
      bool condition =
          news["typ"] == "ortswechsel" && news["erstelltVon"].contains(userId);
      if (!condition) return;

      userNewsContent
          .add({"news": news["information"], "ersteller": news["erstelltVon"]});

      var ortsName = news["information"]["city"];
      var locationUserInfos = getCityUserInfoFromHive(ortsName);

      newsFeed.add({
        "date": news["erstelltAm"],
        "newsWidget": InkWell(
          onTap: () {
            global_func.changePage(
                context,
                StadtinformationsPage(
                  ortName: ortsName,
                ));
          },
          child: Align(
            child: Stack(
              children: [
                Container(
                    width: 800,
                    margin:
                        const EdgeInsets.only(bottom: 45, left: 20, right: 20),
                    padding: const EdgeInsets.only(
                        left: 20, right: 20, top: 15, bottom: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                            AppLocalizations.of(context)
                                    .newsLocationBegruessung +
                                ortsName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: titleFontSize)),
                        const SizedBox(height: 5),
                        locationUserInfos.length == 0
                            ? Text(
                                AppLocalizations.of(context).erfahrungenTeilen)
                            : Text(AppLocalizations.of(context)
                                .erfahrungenAnschauenUndTeilen)
                      ],
                    )),
                Positioned(
                    bottom: 20,
                    right: 35,
                    child: NewsStamp(
                        date: news["erstelltAm"],
                        isNew: _checkIfNew(
                            news["information"], news["erstelltVon"])))
              ],
            ),
          ),
        ),
      });
    }

    addMonthYearDivider() {
      var latestMonthYear;

      for (var news in List.of(newsFeed)) {
        if (news["newsWidget"] is SizedBox) continue;

        var newsMonthYear =
            DateFormat.yMMMM().format(DateTime.parse(news["date"]));

        if (latestMonthYear == null || latestMonthYear != newsMonthYear) {
          var newDate = DateTime.parse(news["date"].split(" ")[0]);

          newsFeed.add({
            "date": newDate.toString(),
            "newsWidget": Center(
              child: Container(
                margin: EdgeInsets.only(bottom: 30),
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
                child: Text(
                  newsMonthYear,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          });
          latestMonthYear = newsMonthYear;
        }
      }
    }

    createNewsFeed() {
      newsFeed = [];
      var myLastLocationChangeDate = _getMyLastLocationChangeDate();

      for (var news in newsFeedData) {
        addLocationWelcome(news);
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

      addMonthYearDivider();
    }

    createNewsFeed();
    _sortNewsFeed();
    _updateHiveUserNewsContent();

    return Scaffold(
        floatingActionButtonAnimator: NoScalingAnimation(),
        floatingActionButtonLocation: scrollbarOnBottom
            ? FloatingActionButtonLocation.endTop
            : FloatingActionButtonLocation.endDocked,
        floatingActionButton: scrollbarOnBottom
            ? Container(
                margin: const EdgeInsets.only(top: 5),
                child: FloatingActionButton(
                  child: const Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => NewsPageSettingsPage(
                                  settingsProfil: ownSettingProfil)))
                      .whenComplete(() => setState(() {})),
                ),
              )
            : Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: FloatingActionButton(
                  heroTag: "first Position",
                  onPressed: () {
                    _controller.jumpTo(0);
                    setState(() {});
                  },
                  child: const Icon(Icons.arrow_upward),
                ),
              ),
        body: Container(
            padding: const EdgeInsets.only(top: 50),
            child: ListView(controller: _controller, children: [
              ..._getNewsWidgetList().reversed.toList(),
            ])));
  }
}

class NoScalingAnimation extends FloatingActionButtonAnimator {
  @override
  Offset getOffset({Offset begin, Offset end, double progress}) {
    return end;
  }

  @override
  Animation<double> getRotationAnimation({Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }

  @override
  Animation<double> getScaleAnimation({Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }
}

class NewsStamp extends StatelessWidget {
  var date;
  bool isNew;

  NewsStamp({this.date, this.isNew, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isNew)
          const Icon(
            Icons.fiber_new,
            size: 30,
          ),
        SizedBox(width: 10),
        Text(date.split(" ")[0], style: TextStyle(color: Colors.grey[600]))
      ],
    );
  }
}
