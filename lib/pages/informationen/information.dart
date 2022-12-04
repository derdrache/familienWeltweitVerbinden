import 'package:flutter/material.dart';
import 'package:familien_suche/global/global_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../informationen/community/community_page.dart';
import '../informationen/events/event_page.dart';
import '../informationen/stadtinformation/city_page.dart';


class InformationPage extends StatefulWidget {
  const InformationPage({Key key}) : super(key: key);

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  @override
  Widget build(BuildContext context) {

    pageCards(title, icon, image, page) {
      return GestureDetector(
        onTap: () => changePage(context, page),
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
                width: 150,
                height: 220,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    image: image == null ? null : DecorationImage(
                        fit: BoxFit.fitHeight,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.8), BlendMode.dstATop),
                        image: AssetImage(image))),
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.black,
                      size: 50,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                )),
          ),
        ),
      );
    }

    return EventPage();

    return Scaffold(
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
                    const EventPage()),
                pageCards(
                    "Communities",
                    Icons.home,
                    "assets/bilder/village.jpg",
                    const CommunityPage())
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                pageCards(
                    AppLocalizations.of(context).cities,
                    Icons.location_city,
                    "assets/bilder/city.jpg",
                    const CityPage()),
                //pageCards("Länder", Icons.flag, null)
              ],
            )
          ],
        ),
      ),
    );
  }
}

/*
class InformationPage extends StatelessWidget {
  const InformationPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    pageCards(title, icon, image, page) {
      return GestureDetector(
        onTap: () => changePage(context, page),
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
                width: 150,
                height: 220,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    image: image == null ? null : DecorationImage(
                        fit: BoxFit.fitHeight,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.8), BlendMode.dstATop),
                        image: AssetImage(image))),
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.black,
                      size: 50,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                )),
          ),
        ),
      );
    }

    return Scaffold(
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
                    const EventPage()),
                pageCards(
                    "Communities",
                    Icons.home,
                    "assets/bilder/village.jpg",
                    const CommunityPage())
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                pageCards(
                    AppLocalizations.of(context).cities,
                    Icons.location_city,
                    "assets/bilder/city.jpg",
                    const CityPage()),
                //pageCards("Länder", Icons.flag, null)
              ],
            )
          ],
        ),
      ),
    );
  }
}

 */
