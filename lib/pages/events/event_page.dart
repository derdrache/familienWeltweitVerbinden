import 'package:familien_suche/pages/events/events_suchen.dart';
import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../global/variablen.dart' as global_var;
import '../../../global/global_functions.dart' as global_functions;
import 'eventCard.dart';
import 'event_details.dart';
import 'events_erstellen.dart';

class EventPage extends StatefulWidget{
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage>{
  var userId = FirebaseAuth.instance.currentUser.uid;

  Widget build(BuildContext context){

    createEventCards(events, withInteresse){
      List<Widget> eventCards = [];

      for(var event in events){
        eventCards.add(
            EventCard(
              event: event,
              withInteresse: withInteresse,
              afterPageVisit: ()=> setState(() {})
              /*
              changePage: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventDetailsPage(
                    event: event
                  )
                  )).whenComplete(() => setState(() {})),

               */
            )
        );
      }

      return eventCards;
    }

    meineInteressiertenEventsBox(){
      return Container(
        padding: const EdgeInsets.only(top: 10),
        width: double.infinity,
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(width: 1, color: global_var.borderColorGrey))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                margin: const EdgeInsets.only(left: 10),
                child: Text(
                  AppLocalizations.of(context).favoritenEvents,
                  style: const TextStyle(fontSize: 20),
                )
            ),
            FutureBuilder(
                future: EventDatabase().getEventsCheckList(userId, "interesse"),
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
                            children: createEventCards(snapshot.data, true)
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
            )
          ],
        )
      );
    }

    meineErstellenEventsBox(){
      return Container(
        padding: const EdgeInsets.only(top:10),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 10),
              child: Text(
                AppLocalizations.of(context).meineEvents,
                style: const TextStyle(fontSize: 20),
              )
            ),
            FutureBuilder(
              future: EventDatabase().getEvents("erstelltVon = '"+userId+"'"),
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
                            children: createEventCards(snapshot.data, false)
                          ),
                      ),
                  );
                }
                return const SizedBox.shrink();
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
              const SizedBox(height: 30)
            ]
          )
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "event suchen",
              child: const Icon(Icons.search),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventsSuchenPage()
                  )).whenComplete(() => setState(() {}))
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              heroTag: "event hinzufügen",
              child: const Icon(Icons.add),
              onPressed: () => global_functions.changePage(context, const EventErstellen())
            ),
          ],
        ),
    );
  }
}