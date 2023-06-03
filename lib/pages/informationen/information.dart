import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../global/style.dart';
import '../informationen/community/community_page.dart';
import '../informationen/meetups/meetup_page.dart';
import 'location/location_page.dart';
import '../../services/database.dart';

class InformationPage extends StatefulWidget {
  var pageSelection;
  InformationPage({Key key, this.pageSelection = 0}) : super(key: key);

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> with WidgetsBindingObserver{
  var pageList = [
    "",
    const MeetupPage(),
    const CommunityPage(),
    LocationPage(forCity: true,),
    LocationPage(forLand: true,)
  ];

  getNumberEventNotification(){
    var eventNotification = 0;
    var myMeetups = Hive.box('secureBox').get("myEvents") ?? [];

    for (var meetup in myMeetups) {
      bool isOwner = meetup["erstelltVon"] == userId;
      bool isNotPublic = meetup["art"] != "public" && meetup["art"] != "öffentlich";

      if(isOwner && isNotPublic){
        eventNotification += meetup["freischalten"].length;
      }
    }

    return eventNotification;
  }

  getNumberCommunityNotification(){
    var communityNotifikation = 0;
    var allCommunities = Hive.box('secureBox').get("communities") ?? [];

    for (var community in allCommunities) {
      if (community["einladung"].contains(userId)) communityNotifikation += 1;
    }

    return communityNotifikation;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && this.mounted) {
      await _refreshData();
      setState(() {});
    }
  }

  _refreshData() async{
    refreshHiveStadtInfo();
    refreshHiveStadtInfoUser();
    refreshHiveNewsPage();
    refreshHiveChats();
    refreshHiveMeetups();
    refreshHiveProfils();
    refreshHiveCommunities();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery. of(context). size. width;
    double screenHeight = MediaQuery. of(context). size. height;
    double handyScreenWidth = 400;
    double cardAbstandWidth = screenWidth > handyScreenWidth ? screenWidth / 17.5 : 0;

    pageCards(title, icon, image, pageIndex) {
      var h1FontSize = getResponsiveFontSize(context, "h1");


      return GestureDetector(
        onTap: () {
          setState(() {
            widget.pageSelection = pageIndex;
          });
        },
        child: Container(
          margin: EdgeInsets.only(left: 10, right: 10),
          child: Card(
            elevation: 25,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Container(
                width: (screenWidth / 2) -40,
                height: (screenHeight / 3.5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    image: image == null ? null : DecorationImage(
                        fit: BoxFit.fill,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.9), BlendMode.dstATop),
                        image: AssetImage(image))),
                constraints: BoxConstraints(
                  maxWidth: screenHeight / 2.5
                ),
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(
                            fontSize: h1FontSize, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )),
          ),
        ),
      );
    }

    badgeCard(card, number){
      return Stack(clipBehavior: Clip.none, children: [
        card,
        if(number != 0) Positioned(top: -15, right: 0,child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            color: Theme.of(context).colorScheme.secondary,
          ),
          child: Center(child: Text(number.toString(), style: const TextStyle(fontSize: 20,fontWeight: FontWeight.bold, color: Colors.white),)),
        ))
      ],);
    }


    return widget.pageSelection == 0 ? Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                badgeCard(
                  pageCards(
                      "Meetups",
                      Icons.calendar_month,
                      "assets/bilder/museum.jpg",
                      1),
                    getNumberEventNotification()
                ),
                SizedBox(width: cardAbstandWidth),
                badgeCard(
                  pageCards(
                      "Communities",
                      Icons.home,
                      "assets/bilder/village.jpg",
                      2),
                  getNumberCommunityNotification()
                )
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                pageCards(
                    AppLocalizations.of(context).cities,
                    Icons.location_city,
                    "assets/bilder/city.jpg",
                    3),
                SizedBox(width: cardAbstandWidth),
                pageCards(
                    AppLocalizations.of(context).countries,
                    Icons.flag,
                    "assets/bilder/land.jpg",
                    4),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ) : pageList[widget.pageSelection];
  }
}
