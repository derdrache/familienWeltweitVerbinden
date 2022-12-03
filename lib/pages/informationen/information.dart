import 'package:flutter/material.dart';
import 'package:familien_suche/global/global_functions.dart';

import '../informationen/community/community_page.dart';
import '../informationen/events/event_page.dart';
import '../informationen/stadtinformation/city_page.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    pageCards(title, icon, page){
      return GestureDetector(
        onTap: () => changePage(context, page),
        child: Container(
          margin: const EdgeInsets.only(left: 10, right: 10, top: 30, bottom: 30),
          child: Card(
            elevation: 25,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            color: Theme.of(context).colorScheme.primary,
            child: Container(
              width: 150,
              height: 220,
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white,size: 50,),
                  const SizedBox(height: 30),
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                ],
              )
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              pageCards("Events", Icons.calendar_month, const EventPage()),
              pageCards("Communities", Icons.home, const CommunityPage())
            ],),
            Row(mainAxisAlignment: MainAxisAlignment.center,children: [
              pageCards("Städte", Icons.location_city, null),
              //pageCards("Länder", Icons.flag, null)
            ],)
          ],
        ),
      ),
    );
  }
}
