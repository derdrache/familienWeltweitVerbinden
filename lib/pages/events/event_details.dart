import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/pages/events/event_card_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../services/database.dart';
import '../../global/style.dart' as global_style;


class EventDetailsPage extends StatefulWidget {
  var event;
  var teilnahme;
  var absage;

  EventDetailsPage({
    Key key,
    this.event,
  }) :
    teilnahme = event["zusage"].contains(userId),
    absage = event["absage"].contains(userId);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {


  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: customAppBar(
            title: "",
            buttons: [
              TextButton(
                style: global_style.textButtonStyle(),
                child: const Icon(Icons.message),
                onPressed: () => print("message"),
              ),
              TextButton(
                style: global_style.textButtonStyle(),
                child: const Icon(Icons.more_vert),
                onPressed: () => print("more"),
              ),

            ]
        ),
        body: Column(
          children: [
            EventCardDetails(
              event: widget.event,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.teilnahme != true) Container(
                  margin: EdgeInsets.only(left: 20, right: 20),
                  child: FloatingActionButton.extended(
                      heroTag: "teilnehmen",
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      onPressed: () async {

                        setState(() {
                          widget.teilnahme = true;
                          widget.absage = false;
                        });


                        var zusageListe = await EventDatabase().getOneData("zusage", widget.event["id"]);
                        zusageListe.add(userId);
                        EventDatabase().updateOne(widget.event["id"], "zusage", zusageListe);

                        var absageListe = await EventDatabase().getOneData("absage", widget.event["id"]);
                        absageListe.remove(userId);
                        EventDatabase().updateOne(widget.event["id"], "absage", absageListe);


                      },
                      label: Text("Teilnehmen")
                  ),
                ),
                if(widget.absage != true) Container(
                  margin: EdgeInsets.only(left: 20, right: 20),
                  child: FloatingActionButton.extended(
                    heroTag: "Absagen",
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    label: Text("Absagen"),
                    onPressed: () async {

                      setState(() {
                        widget.teilnahme = false;
                        widget.absage = true;
                      });

                      var zusageListe = await EventDatabase().getOneData("zusage", widget.event["id"]);
                      zusageListe.remove(userId);
                      EventDatabase().updateOne(widget.event["id"], "zusage", zusageListe);

                      var absageListe = await EventDatabase().getOneData("absage", widget.event["id"]);
                      absageListe.add(userId);
                      EventDatabase().updateOne(widget.event["id"], "absage", absageListe);


                    },

                  ),
                )
              ],
            )
          ],
        )
    );
  }
}





