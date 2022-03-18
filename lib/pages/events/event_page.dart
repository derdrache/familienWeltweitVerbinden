import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../global/variablen.dart' as global_var;
import '../../../global/global_functions.dart' as global_functions;
import '../../global/widgets/eventCard.dart';
import 'events_erstellen.dart';

class EventPage extends StatefulWidget{
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage>{
  var userId = FirebaseAuth.instance.currentUser.uid;

  Widget build(BuildContext context){

    meineInteressiertenEventsBox(){
      return Container(
        padding: EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(width: 1, color: global_var.borderColorGrey))
        ),
        child: Column(
          children: const [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Events für die ich mich interessiere",
                  style: TextStyle(fontSize: 20),
                )
            )
          ],
        )
      );
    }

    meineEvents(events){
      List<Widget> meineEvents = [];

      for(var event in events){
        meineEvents.add(
            EventCard(
              title: event["name"],
              bild: "assets/bilder/strand.jpg",
              date: "23.03.2022 10:00",
              stadt: event["stadt"],
            )
        );
      }

      return meineEvents;
    }

    meineErstellenEventsBox(){
      return Container(
        padding: EdgeInsets.only(top:10),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(width: 1, color: global_var.borderColorGrey))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 10),
              child: Text(
                "Meine Events",
                style: TextStyle(fontSize: 20),
              )
            ),
            FutureBuilder(
              future: EventDatabase().getEvents(userId),
              builder: (
                BuildContext context,
                AsyncSnapshot snapshot,
              ){
                if (snapshot.data != null){
                  return Expanded(
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                            direction: Axis.vertical,
                            children: meineEvents(snapshot.data)
                          ),
                      ),
                  );
                }
                return SizedBox.shrink();
              }
            )
          ],
        )
      );
    }

    return Scaffold(
        body: Container(
          padding: const EdgeInsets.only(top: kIsWeb? 0: 24),
          child: Column(
            children: [
              Expanded(child: meineInteressiertenEventsBox()),
              Expanded(child: meineErstellenEventsBox()),
              SizedBox(height: 90)
            ]
          )
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "event suchen",
              child: Icon(Icons.search),
              onPressed: null
            ),
            SizedBox(width: 10),
            FloatingActionButton(
              heroTag: "event hinzufügen",
              child: Icon(Icons.add),
              onPressed: () => global_functions.changePage(context, EventErstellen())
            ),
          ],
        ),
    );
  }
}