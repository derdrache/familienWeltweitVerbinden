import 'package:familien_suche/pages/events/events_suchen.dart';
import 'package:familien_suche/pages/start_page.dart';
import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../../global/variablen.dart' as global_var;
import '../../../global/global_functions.dart' as global_functions;
import '../../global/global_functions.dart';
import '../../widgets/badge_icon.dart';
import 'eventCard.dart';
import 'events_erstellen.dart';

class EventPage extends StatefulWidget {
  const EventPage({Key key}) : super(key: key);

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  double textSizeHeadline = 20.0;

  @override
  Widget build(BuildContext context) {

    createEventCards(events, withInteresse) {
      List<Widget> eventCards = [];

      for (var event in events) {
        bool isOwner = event["erstelltVon"] == userId;

        eventCards.add(Stack(
          children: [
            EventCard(
                event: event,
                withInteresse: withInteresse,
                afterPageVisit: () => changePage(
                    context,
                    StartPage(
                      selectedIndex: 1,
                    ))),
            if (isOwner)
              Positioned(
                right: 10,
                top: 10,
                child: FutureBuilder(
                    future: EventDatabase()
                        .getData("freischalten", "WHERE id = '${event["id"]}'"),
                    builder: (context, snap) {
                      var data =
                          snap.hasData ? snap.data.length.toString() : "";
                      if (data == "0") data = "";

                      return BadgeIcon(
                        text: data.toString(),
                      );
                    }),
              )
          ],
        ));
      }

      return eventCards;
    }

    meineInteressiertenEventsBox() {
      return Container(
          padding: const EdgeInsets.only(top: 10),
          width: double.infinity,
          decoration: BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(width: 1, color: global_var.borderColorGrey))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: Text(
                    AppLocalizations.of(context).favoritenEvents,
                    style: TextStyle(fontSize: textSizeHeadline),
                  )),
              FutureBuilder(
                  future: EventDatabase().getData("*",
                      "WHERE JSON_CONTAINS(interesse, '\"$userId\"') > 0 AND erstelltVon != '$userId' ORDER BY wann ASC",
                      returnList: true),
                  builder: (context, snapshot) {
                    var secureBox = Hive.box('secureBox');
                    dynamic data = secureBox.get("interestEvents");

                    if (snapshot.hasData) {
                      data = snapshot.data == false ? [] : snapshot.data;
                      secureBox.put("interestEvents", data);
                    }

                    if (data != null && data.isNotEmpty) {
                      return Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                              direction: Axis.vertical,
                              children: createEventCards(data, true)),
                        ),
                      );
                    }

                    return Center(
                        heightFactor: 5,
                        child: Text(
                          AppLocalizations.of(context)
                              .nochKeineEventsAusgewaehlt,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: textSizeHeadline, color: Colors.grey),
                        ));
                  }),
            ],
          ));
    }

    meineErstellenEventsBox() {
      return Container(
          padding: const EdgeInsets.only(top: 10),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: Text(
                    AppLocalizations.of(context).meineEvents,
                    style: TextStyle(fontSize: textSizeHeadline),
                  )),
              FutureBuilder(
                  future: EventDatabase().getData("*",
                      "WHERE erstelltVon = '" + userId + "' ORDER BY wann ASC",
                      returnList: true),
                  builder: (context, snapshot) {
                    var secureBox = Hive.box('secureBox');
                    dynamic data = secureBox.get("myEvents");

                    if (snapshot.hasData) {
                      data = snapshot.data == false ? [] : snapshot.data;
                      secureBox.put("myEvents", data);
                    }

                    if (data != null && data.isNotEmpty) {
                      return Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                              direction: Axis.vertical,
                              children: createEventCards(data, false)),
                        ),
                      );
                    }

                    return Center(
                        heightFactor: 5,
                        child: Text(
                          AppLocalizations.of(context).nochKeineEventsErstellt,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: textSizeHeadline, color: Colors.grey),
                        ));
                  }),
            ],
          ));
    }

    return Scaffold(
      body: Container(
          padding: const EdgeInsets.only(top: kIsWeb ? 0 : 24),
          child: Column(children: [
            Expanded(child: meineInteressiertenEventsBox()),
            Expanded(child: meineErstellenEventsBox()),
            const SizedBox(height: 50)
          ])),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
              heroTag: "alleEvents",
              child: const Icon(Icons.search),
              onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EventsSuchenPage()))
                  .whenComplete(() => setState(() {}))),
          const SizedBox(width: 10),
          FloatingActionButton(
              heroTag: "event hinzuf??gen",
              child: const Icon(Icons.add),
              onPressed: () =>
                  global_functions.changePage(context, const EventErstellen())),
        ],
      ),
    );
  }
}
