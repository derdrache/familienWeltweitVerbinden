import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../../global/style.dart' as style;
import '../../services/database.dart';
import '../../../global/global_functions.dart' as global_func;
import '../informationen/location/location_details/information_main.dart';
import '../informationen/meetups/meetup_card.dart';
import '../show_profil.dart';
import 'news_page_settings.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> with WidgetsBindingObserver{
  String userId = checkUser ?? FirebaseAuth.instance.currentUser!.uid;
  late List newsFeedData;
  int displayDataEntries = 10;
  late List events;
  List cityUserInfo = Hive.box('secureBox').get("stadtinfoUser") ?? [];
  Map ownProfil = Hive.box('secureBox').get("ownProfil") ?? {};
  List userNewsContentHive = Hive.box('secureBox').get("userNewsContent") ?? [];
  var ownSettingProfil = Hive.box('secureBox').get("ownNewsSetting");
  List newsFeed = [];
  List newsFeedDateList = [];
  final _controller = ScrollController();
  bool scrollbarOnBottom = true;
  List userNewsContent = [];

  @override
  void initState() {
    if (ownSettingProfil == false || ownSettingProfil == null) {
      ownSettingProfil = _addNewSettingProfil();
    }

    _scrollBar();

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      refreshServerData();
    });
  }
  refreshServerData() async{
    await refreshHiveProfils();
    await refreshHiveNewsPage();
    setState(() {});
  }
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && mounted) {
      refreshServerData();
      setState(() {});
    }
  }

  _scrollBar() {
    _controller.addListener(() {
      bool isTop = _controller.position.pixels == 0;
      bool isBottom = _controller.position.atEdge;

      if (isTop) {
        if (!scrollbarOnBottom) {
          scrollbarOnBottom = true;
          setState(() {});
        }
      } else {
        if (scrollbarOnBottom) {
          scrollbarOnBottom = false;
          setState(() {});
        }
      }

      if (isBottom) {
        setState(() {
          displayDataEntries += 10;
        });
      }
    });
  }

  _addNewSettingProfil() {
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
    if (lastLocationChangeDate.isEmpty) {
      lastLocationChangeDate = newsPagePatchDate;
    }

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

    for (var item in newsFeed.reversed
        .toList()
        .take(displayDataEntries)
        .toList()
        .reversed
        .toList()) {
      widgetList.add(item["newsWidget"]);
    }

    if (_checkWidgetListIsEmpty(widgetList)) {
      widgetList.add(Center(
          child: Container(
              padding: EdgeInsets.only(top: screenHeight / 3),
              child: Text(
                AppLocalizations.of(context)!.keineNewsVorhanden,
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

  _getCombineInformationIfSameUser(news) {
    var lastNews = newsFeed.isNotEmpty ? newsFeed.last["news"] : null;
    var newInformation = {};

    if (lastNews == null) return news["information"];

    bool sameUser = lastNews["erstelltVon"] == news["erstelltVon"];
    bool sameTyp = lastNews["typ"] == news["typ"];

    if (!sameUser || !sameTyp) return news["information"];

    newsFeed.removeLast();

    bool isSingleNews = lastNews["information"]["von"].runtimeType == String;

    if (isSingleNews) {
      newInformation["von"] = [
        lastNews["information"]["von"],
        news["information"]["von"]
      ];
      newInformation["bis"] = [
        lastNews["information"]["bis"],
        news["information"]["bis"]
      ];
      newInformation["ortData"] = [
        lastNews["information"]["ortData"],
        news["information"]["ortData"]
      ];
    } else {
      newInformation["von"] = [
        ...lastNews["information"]["von"],
        news["information"]["von"]
      ];
      newInformation["bis"] = [
        ...lastNews["information"]["bis"],
        news["information"]["bis"]
      ];
      newInformation["ortData"] = [
        ...lastNews["information"]["ortData"],
        news["information"]["ortData"]
      ];
    }

    return newInformation;
  }

  @override
  Widget build(BuildContext context) {
    newsFeedData = Hive.box('secureBox').get("newsFeed") ?? [];
    events = Hive.box('secureBox').get("events") ?? [];
    ownSettingProfil = Hive.box('secureBox').get("ownNewsSetting");
    const double titleFontSize = 15;

    friendsDisplay(news) {
      String addedUser = news["information"].split(" ")[1];
      String newsUserId = news["erstelltVon"];
      Map? friendProfil = getProfilFromHive(profilId: newsUserId);
      String text = "";

      if (friendProfil == null ||
          !addedUser.contains(userId) ||
          ownSettingProfil["showFriendAdded"] == 0) {
        return const SizedBox.shrink();
      }

      if (news["information"].contains("added")) {
        text = friendProfil["name"] +
            AppLocalizations.of(context)!.alsFreundHinzugefuegt;
      }

      userNewsContent
          .add({"news": news["information"], "ersteller": news["erstelltVon"]});

      newsFeed.add({
        "newsWidget": InkWell(
          onTap: () {
            global_func.changePage(
                context, ShowProfilPage(profil: friendProfil));
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
                      borderRadius: BorderRadius.circular(style.roundedCorners),
                      border: Border.all(),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3),
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
                        isNew: _checkIfNew(
                            news["information"], news["erstelltVon"])))
              ],
            ),
          ),
        ),
        "date": news["erstelltAm"]
      });
    }

    changePlaceDisplay(news, myLastLocationDate) {
      String newsUserId = news["erstelltVon"];
      Map? familyProfil = getFamilyProfil(familyMemberId: newsUserId);
      Map? newsUserProfil = getProfilFromHive(
          profilId:
              familyProfil != null ? familyProfil["mainProfil"] : newsUserId);
      bool isFriend = ownProfil["friendlist"].contains(newsUserId);
      String text = "";
      String? newsOrt = news["information"]["city"];
      String? newsLand = news["information"]["countryname"];
      String ownOrt = ownProfil["ort"];
      var locationTimeCheck = DateTime.parse(news["erstelltAm"])
          .compareTo(DateTime.parse(myLastLocationDate));
      double distance = global_func.calculateDistance(
          ownProfil["latt"],
          ownProfil["longt"],
          news["information"]["latt"],
          news["information"]["longt"]);
      bool inDistance = distance <= (ownSettingProfil["distance"] ?? 50);
      bool samePlaceAndTime = (inDistance || ownOrt == newsOrt) &&
          locationTimeCheck >= 0 &&
          ownSettingProfil["showNewFamilyLocation"] == 1;
      bool sameFamily = familyProfil != null
          ? familyProfil["members"].contains(userId)
          : false;

      if (newsUserProfil == null ||
          newsOrt == null ||
          newsLand == null ||
          ownSettingProfil["showFriendChangedLocation"] == 0 ||
          ownSettingProfil["showNewFamilyLocation"] == 0 ||
          !(isFriend || samePlaceAndTime) ||
          sameFamily) {
        return const SizedBox.shrink();
      }

      String newsOrtInfo =
          newsLand == newsOrt ? newsLand : "$newsOrt / $newsLand";
      newsUserProfil = Map.from(newsUserProfil);
      if (familyProfil != null) {
        newsUserProfil["name"] =
            "${AppLocalizations.of(context)!.familie} ${familyProfil["name"]}";
      }

      if (isFriend && ownSettingProfil["showFriendChangedLocation"] == 1) {
        text = newsUserProfil["name"] +
            AppLocalizations.of(context)!.freundOrtsWechsel +
            "\n" +
            newsOrtInfo;
      } else if (ownOrt == newsOrt) {
        text = newsUserProfil["name"] +
            AppLocalizations.of(context)!.familieInDeinemOrt;
      } else if (inDistance) {
        text = newsUserProfil["name"] + AppLocalizations.of(context)!.imUmkreis;
      }

      userNewsContent
          .add({"news": news["information"], "ersteller": news["erstelltVon"]});

      newsFeed.add({
        "newsWidget": InkWell(
          onTap: () {
            global_func.changePage(
                context, ShowProfilPage(profil: newsUserProfil!));
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
                      borderRadius: BorderRadius.circular(style.roundedCorners),
                      border: Border.all(),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3),
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
                        isNew: _checkIfNew(
                            news["information"], news["erstelltVon"])))
              ],
            ),
          ),
        ),
        "date": news["erstelltAm"]
      });
    }

    friendsNewTravelPlanDisplay(news) {
      String newsUserId = news["erstelltVon"];
      Map? familyProfil = getFamilyProfil(familyMemberId: newsUserId);
      Map? friendProfil = getProfilFromHive(
          profilId:
              familyProfil != null ? familyProfil["mainProfil"] : newsUserId);
      bool isFamilymember = familyProfil != null
          ? familyProfil["members"].contains(userId)
          : false;
      bool isFriend = familyProfil != null
          ? ownProfil["friendlist"]
              .toSet()
              .intersection(familyProfil["members"].toSet())
              .isNotEmpty
          : ownProfil["friendlist"].contains(newsUserId);

      if (!isFriend ||
          friendProfil == null ||
          ownSettingProfil["showFriendTravelPlan"] == 0 ||
          isFamilymember) {
        return null;
      }

      Map newTravelPlan = _getCombineInformationIfSameUser(news);

      friendProfil = Map.from(friendProfil);
      if (familyProfil != null) {
        friendProfil["name"] = "Familie ${familyProfil["name"]}";
      }

      bool isSingleNews = newTravelPlan["von"].runtimeType == String;
      Widget newsWidget;

      if (isSingleNews) {
        bool isExact = newTravelPlan["von"].split(" ")[1] == "01:00:00.000";
        List travelPlanVon =
            newTravelPlan["von"].split(" ")[0].split("-").reversed.toList();
        List travelPlanbis =
            newTravelPlan["bis"].split(" ")[0].split("-").reversed.toList();

        if (!isExact) {
          travelPlanVon.removeAt(0);
          travelPlanbis.removeAt(0);
        }

        String travelPlanCity = newTravelPlan["ortData"]["city"];
        String travelPlanCountry = newTravelPlan["ortData"]["countryname"];
        String textTitle = friendProfil["name"] +
            "\n" +
            AppLocalizations.of(context)!.friendNewTravelPlan;
        String textDate =
            "${travelPlanVon.join("-")} - ${travelPlanbis.join("-")}";
        String textLocation = "$travelPlanCity / $travelPlanCountry";
        newsWidget = InkWell(
          onTap: () {
            global_func.changePage(
                context, ShowProfilPage(profil: friendProfil!));
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
                      borderRadius: BorderRadius.circular(style.roundedCorners),
                      border: Border.all(),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(textTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                        isNew: _checkIfNew(
                            news["information"], news["erstelltVon"])))
              ],
            ),
          ),
        );
      } else {
        String textTitle = friendProfil["name"] +
            "\n" +
            AppLocalizations.of(context)!.friendNewTravelPlan;
        List<Widget> columnItems = [];

        for (var i = 0; i < newTravelPlan["von"].length; i++) {
          bool isExact =
              newTravelPlan["von"][i].split(" ")[1] == "01:00:00.000";
          List travelPlanVon = newTravelPlan["von"][i]
              .split(" ")[0]
              .split("-")
              .reversed
              .toList();
          List travelPlanbis = newTravelPlan["bis"][i]
              .split(" ")[0]
              .split("-")
              .reversed
              .toList();

          if (!isExact) {
            travelPlanVon.removeAt(0);
            travelPlanbis.removeAt(0);
          }

          String travelPlanCity = newTravelPlan["ortData"][i]["city"];
          String travelPlanCountry = newTravelPlan["ortData"][i]["countryname"];

          String textDate =
              "${travelPlanVon.join("-")} - ${travelPlanbis.join("-")}";
          String textLocation = "$travelPlanCity / $travelPlanCountry";

          columnItems.add(Column(
            children: [
              const SizedBox(height: 10),
              Text(textDate),
              Text(textLocation),
            ],
          ));
        }

        newsWidget = InkWell(
          onTap: () {
            global_func.changePage(
                context, ShowProfilPage(profil: friendProfil!));
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
                      borderRadius: BorderRadius.circular(style.roundedCorners),
                      border: Border.all(),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(textTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: titleFontSize)),
                        ...columnItems
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
        );
      }

      userNewsContent
          .add({"news": news["information"], "ersteller": news["erstelltVon"]});

      newsFeed.add({
        "newsWidget": newsWidget,
        "date": news["erstelltAm"],
        "news": {
          "typ": news["typ"],
          "erstelltVon": news["erstelltVon"],
          "information": newTravelPlan
        }
      });
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

      if (isOnline) {
        eventText =
            AppLocalizations.of(context)!.newsPageOnlineMeetupVorschlag +
                _evenTagMatch(event["tags"]).toString();
      } else {
        eventText =
            AppLocalizations.of(context)!.newsPageOfflineMeetupVorschlag;
      }

      userNewsContent.add(
          {"news": event["beschreibung"], "ersteller": event["erstelltVon"]});

      newsFeed.add({
        "newsWidget": Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  MeetupCard(
                    margin: const EdgeInsets.all(15),
                    meetupData: event,
                    withInteresse: true,
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Icon(
                        Icons.fiber_new,
                        size: 30,
                        color: _checkIfNew(
                                event["beschreibung"], event["erstelltVon"])
                            ? null
                            : Colors.transparent,
                      ),
                      const SizedBox(width: 70),
                      Expanded(child: Text(eventText)),
                      const SizedBox(width: 10),
                      Text(event["erstelltAm"].split(" ")[0],
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 10),
                    ],
                  )
                ],
              ),
            )),
        "date": event["erstelltAm"]
      });
    }

    neueStadtinformationDisplay(info, myLastLocationDate) {
      var locationTimeCheck = DateTime.parse(info["erstelltAm"])
          .compareTo(DateTime.parse(myLastLocationDate));
      var locationData = getCityFromHive(cityId: info["locationId"]);
      var sameLocation = info["ort"] == ownProfil["ort"] || info["ort"].contains(ownProfil["land"]);

      if (!(locationTimeCheck >= 0 && sameLocation) ||
          info["erstelltVon"] == userId ||
          ownSettingProfil["showCityInformation"] == 0) {
        return const SizedBox.shrink();
      }

      bool spracheIstDeutsch = kIsWeb
          ? PlatformDispatcher.instance.locale.languageCode == "de"
          : Platform.localeName == "de_DE";
      String textHeader =
          info["ort"] + AppLocalizations.of(context)!.hatNeueStadtinformation;
      String infoTitle = spracheIstDeutsch ? info["titleGer"] : info["titleEng"];
      String infoDescription = spracheIstDeutsch ? info["informationGer"] : info["informationEng"];

      if (infoDescription.length > 100) infoDescription = "${infoDescription.substring(0, 97)}...";

      userNewsContent.add({"news": infoDescription, "ersteller": info["erstelltVon"]});

      newsFeed.add({
        "newsWidget": InkWell(
          onTap: () {
            global_func.changePage(
                context, LocationInformationPage(
                            ortName: locationData["ort"],
                            ortLatt: locationData["latt"].toDouble(),
                            insiderInfoId: info["id"],)
            );
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
                      borderRadius: BorderRadius.circular(style.roundedCorners),
                      border: Border.all(),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(textHeader,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: titleFontSize)),
                        const SizedBox(height: 15),
                        Text(infoTitle, style: const TextStyle(fontWeight: FontWeight.bold),),
                        const SizedBox(height: 5),
                        Text(infoDescription),
                      ],
                    )),
                Positioned(
                    bottom: 20,
                    right: 35,
                    child: NewsStamp(
                        date: info["erstelltAm"],
                        isNew: _checkIfNew(infoDescription, info["erstelltVon"])))
              ],
            ),
          ),
        ),
        "date": info["erstelltAm"]
      });
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
                LocationInformationPage(
                  ortName: ortsName,
                  ortLatt: news["information"]["latt"],
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
                      borderRadius: BorderRadius.circular(style.roundedCorners),
                      border: Border.all(),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                            AppLocalizations.of(context)!
                                    .newsLocationBegruessung +
                                ortsName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: titleFontSize)),
                        const SizedBox(height: 5),
                        locationUserInfos.length == 0
                            ? Text(
                                AppLocalizations.of(context)!.erfahrungenTeilen)
                            : Text(AppLocalizations.of(context)!
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
      String? latestMonthYear;

      for (var news in List.of(newsFeed)) {
        if (news["newsWidget"] is SizedBox) continue;

        var newsMonthYear =
            DateFormat.yMMMM().format(DateTime.parse(news["date"]));

        if (latestMonthYear == null || latestMonthYear != newsMonthYear) {
          var newDate = DateTime.parse(news["date"].split(" ")[0]).subtract(const Duration(seconds: 1));

          newsFeed.add({
            "date": newDate.toString(),
            "newsWidget": Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 30),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(style.roundedCorners),
                  border: Border.all(),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
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
          friendsDisplay(news);
        } else if (news["typ"] == "ortswechsel") {
          changePlaceDisplay(news, myLastLocationChangeDate);
        } else if (news["typ"] == "reiseplanung") {
          friendsNewTravelPlanDisplay(news);
        }
      }

      for (var event in events) {
        eventsDisplay(event, myLastLocationChangeDate);
      }

      for (var info in cityUserInfo) {
        neueStadtinformationDisplay(info, myLastLocationChangeDate);
      }

      addMonthYearDivider();
    }

    createNewsFeed();
    _sortNewsFeed();
    _updateHiveUserNewsContent();

    return Scaffold(
        floatingActionButtonLocation: scrollbarOnBottom
            ? FloatingActionButtonLocation.endTop
            : FloatingActionButtonLocation.endDocked,
        floatingActionButton: scrollbarOnBottom
            ? Container(
                margin: const EdgeInsets.only(top: 5),
                child: FloatingActionButton(
                  tooltip:
                      AppLocalizations.of(context)!.tooltipOpenNewsSettings,
                  onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => NewsPageSettingsPage(
                                  settingsProfil: ownSettingProfil)))
                      .whenComplete(() => setState(() {})),
                  child: Center(child: const Icon(Icons.settings)),
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

class NewsStamp extends StatelessWidget {
  final String date;
  final bool isNew;

  const NewsStamp({required this.date, required this.isNew, Key? key})
      : super(key: key);

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
        const SizedBox(width: 10),
        Text(date.split(" ")[0], style: TextStyle(color: Colors.grey[600]))
      ],
    );
  }
}
