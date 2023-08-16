import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/informationen/bulletin_board/bulletin_board_page.dart';
import 'package:familien_suche/widgets/layout/ownIconButton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../global/style.dart' as style;
import '../../widgets/layout/badgeWidget.dart';
import '../informationen/community/community_page.dart';
import '../informationen/meetups/meetup_page.dart';
import 'location/location_page.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({Key? key}) : super(key: key);

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage>{
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
      const MeetupPage(),
      const CommunityPage(),
      const LocationPage(
        forCity: true,
      ),
      const LocationPage(
        forLand: true,
      ),
      const BulletinBoardPage()
    ];

    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    pageCards(title, icon, pageIndex, tooltipText) {
      return GestureDetector(
        onTap: () {
          changePage(context, pageList[pageIndex]);
        },
        child: Card(
          elevation: 25,
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
              width: 300,
              height: 80,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(15.0)),
              constraints: BoxConstraints(maxWidth: screenHeight / 2.5),
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Container(
                      padding: const EdgeInsets.only(left: 10),
                      child: OwnIconButton(
                        margin: EdgeInsets.all(5),
                        tooltipText: tooltipText,
                        image: icon,
                        bigButton: true,
                      )),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                  Container(
                    padding: const EdgeInsets.only(right: 10),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.black,
                    ),
                  )
                ],
              )),
        ),
      );
    }

    return Scaffold(
        body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 15),
            BadgeWidget(
                number: getNumberEventNotification(),
                child: pageCards("Meetups", "assets/icons/meetup.png", 0,
                    AppLocalizations.of(context)!.tooltipOpenMeetupPage
                )),
            const SizedBox(height: 30),
            BadgeWidget(
                number: getNumberCommunityNotification(),
                child: pageCards("Communities", "assets/icons/community.png", 1, AppLocalizations.of(context)!.tooltipOpenCommunityPage)),
            const SizedBox(height: 30),
            pageCards(AppLocalizations.of(context)!.cities, "assets/icons/village.png", 2, AppLocalizations.of(context)!.tooltipOpenCityPage),
            const SizedBox(height: 30),
            pageCards(AppLocalizations.of(context)!.countries, "assets/icons/country_flags.png", 3, AppLocalizations.of(context)!.tooltipOpenCountryPage),
            const SizedBox(height: 30),
            pageCards(AppLocalizations.of(context)!.schwarzesBrett,"assets/icons/schedule.png", 4, AppLocalizations.of(context)!.tooltipOpenBulletinBoardPage),
            const SizedBox(height: 15),
          ],
        ),
      ),
    ));
  }
}
