import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../global/variablen.dart' as global_var;
import '../../../global/global_functions.dart' as global_functions;
import 'events_erstellen.dart';

class EventPage extends StatefulWidget{
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage>{
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

    meineErstellenEventsBox(){
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
                  "Meine Events",
                  style: TextStyle(fontSize: 20),
                )
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