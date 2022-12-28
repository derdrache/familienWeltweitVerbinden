import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../informationen/community/community_page.dart';
import '../informationen/events/event_page.dart';
import 'location/location_page.dart';

class InformationPage extends StatefulWidget {
  var pageSelection;
  InformationPage({Key key, this.pageSelection = 0}) : super(key: key);

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  var pageList = [
    "",
    const EventPage(),
    const CommunityPage(),
    LocationPage(forCity: true,),
    LocationPage(forLand: true,)
  ];


  @override
  Widget build(BuildContext context) {

    pageCards(title, icon, image, pageIndex) {
      return GestureDetector(
        onTap: () {
          setState(() {
            widget.pageSelection = pageIndex;
          });
        },
        child: Container(
          margin:
          const EdgeInsets.only(left: 10, right: 10, top: 30, bottom: 30),
          child: Card(
            elevation: 25,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Container(
                width: 160,
                height: 220,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    image: image == null ? null : DecorationImage(
                        fit: BoxFit.fitHeight,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.9), BlendMode.dstATop),
                        image: AssetImage(image))),
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.black,
                      size: 50,
                    ),
                    const SizedBox(height: 50),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )),
          ),
        ),
      );
    }

    return widget.pageSelection == 0 ? Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                pageCards(
                    "Events",
                    Icons.calendar_month,
                    "assets/bilder/museum.jpg",
                    1),
                pageCards(
                    "Communities",
                    Icons.home,
                    "assets/bilder/village.jpg",
                    2)
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                pageCards(
                    AppLocalizations.of(context).cities,
                    Icons.location_city,
                    "assets/bilder/city.jpg",
                    3),
                pageCards(
                    AppLocalizations.of(context).countries,
                    Icons.flag,
                    "assets/bilder/land.jpg",
                    4),
              ],
            )
          ],
        ),
      ),
    ) : pageList[widget.pageSelection];
  }
}
