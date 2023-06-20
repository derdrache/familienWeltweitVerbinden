import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/informationen/bulletin_board/bulletin_board_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../informationen/community/community_page.dart';
import '../informationen/meetups/meetup_page.dart';
import 'location/location_page.dart';
import '../../services/database.dart';


class InformationPage extends StatefulWidget {
  InformationPage({Key? key}) : super(key: key);

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage>
    with WidgetsBindingObserver {
  var userId = FirebaseAuth.instance.currentUser!.uid;
  late List<Widget> pageList;

  getNumberEventNotification() {
    num eventNotification = 0;
    var myMeetups = Hive.box('secureBox').get("myEvents") ?? [];

    for (var meetup in myMeetups) {
      bool isOwner = meetup["erstelltVon"] == userId;
      bool isNotPublic =
          meetup["art"] != "public" && meetup["art"] != "öffentlich";

      if (isOwner && isNotPublic) {
        eventNotification += meetup["freischalten"].length;
      }
    }

    return eventNotification;
  }

  getNumberCommunityNotification() {
    var communityNotifikation = 0;
    var allCommunities = Hive.box('secureBox').get("communities") ?? [];

    for (var community in allCommunities) {
      if (community["einladung"].contains(userId)) communityNotifikation += 1;
    }

    return communityNotifikation;
  }

  @override
  void initState() {
    pageList = [
      MeetupPage(),
      CommunityPage(),
      LocationPage(
        forCity: true,
      ),
      LocationPage(
        forLand: true,
      ),
      BulletinBoardPage()
    ];

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

  _refreshData() async {
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
    double screenHeight = MediaQuery.of(context).size.height;

    pageCards(title, icon, image, pageIndex) {
      return GestureDetector(
        onTap: () {
          changePage(context, pageList[pageIndex]);
        },
        child: Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          child: Card(
            elevation: 25,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Container(
                width: 300,
                height: 80,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0)
                ),
                constraints: BoxConstraints(maxWidth: screenHeight / 2.5),
                padding: const EdgeInsets.all(5),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 10), child: Container(width:30, height: 30, child: Image.asset("assets/community.png"))
                    ),

                    Container(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: SizedBox.shrink()),
                    Container(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.arrow_forward, color: Colors.black,),
                    )
                  ],
                )),
          ),
        ),
      );
    }

    badgeCard(card, number) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          if (number != 0)
            Positioned(
                top: -15,
                right: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Center(
                      child: Text(
                        number.toString(),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      )),
                ))
        ],
      );
    }

    return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 15),
                badgeCard(
                    pageCards("Meetups", Icons.calendar_month,
                        "assets/bilder/museum.jpg", 0),
                    getNumberEventNotification()),
                const SizedBox(height: 30),
                badgeCard(
                    pageCards(
                        "Communities", Icons.home, "assets/bilder/village.jpg", 1),
                    getNumberCommunityNotification()),
                const SizedBox(height: 30),
                pageCards(AppLocalizations.of(context)!.cities, Icons.location_city,
                    "assets/bilder/city.jpg", 2),
                const SizedBox(height: 30),
                pageCards(AppLocalizations.of(context)!.countries, Icons.flag,
                    "assets/bilder/land.jpg", 3),
                const SizedBox(height: 30),
                pageCards("Schwarzes Brett", Icons.flag,
                    "assets/bilder/wandern.jpg", 4),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ));
  }
}