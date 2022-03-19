import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../global/custom_widgets.dart';
import '../../global/search_autocomplete.dart';
import '../../global/widgets/eventCard.dart';
import '../../services/database.dart';


class EventsSuchenPage extends StatefulWidget {
  const EventsSuchenPage({Key key}) : super(key: key);

  @override
  _EventsSuchenPageState createState() => _EventsSuchenPageState();
}

class _EventsSuchenPageState extends State<EventsSuchenPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var filterList = [];

  @override
  Widget build(BuildContext context) {

    sucheBox(){
      return SearchAutocomplete();
    }

    createAllEventCards(events){
      List<Widget> allEvents = [];

      for(var event in events){
        allEvents.add(
            EventCard(event:event)
        );
      }


      return allEvents;
    }

    eventsShowBox(){
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: FutureBuilder(
            future: EventDatabase().getAllEvents(),
            builder: (
                BuildContext context,
                AsyncSnapshot snapshot,
                ){
              if (snapshot.data != null){
                return SingleChildScrollView(
                    child: Wrap(
                        children: createAllEventCards(snapshot.data)
                    ),
                );
              }
              return SizedBox.shrink();
            }
        ),
      );
    }


    meineEvents(events){
      List<Widget> meineEvents = [];

      for(var event in events){
        meineEvents.add(
            EventCard(
              margin: EdgeInsets.only(top: 10 , bottom: 10, left: 15, right: 15),
              withInteresse: true,
              event: event,
            )
        );
      }

      return meineEvents;
    }

    return Scaffold(
      appBar: customAppBar(
        title: "Events suchen"
      ),
      body: Container(
          padding: EdgeInsets.only(top:10),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sucheBox(),
              FutureBuilder(
                  future: EventDatabase().getAllEvents(),
                  builder: (
                      BuildContext context,
                      AsyncSnapshot snapshot,
                      ){
                    if (snapshot.data != null){
                      var events = [];
                      for(var event in snapshot.data){
                        if(event["erstelltVon"] != userId){
                          events.add(event);
                        }
                      }

                      return Expanded(
                        child: SingleChildScrollView(
                            child: Wrap(
                               children: meineEvents(events)
                            ),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }
              )
            ],
          )
      )
    );
  }
}
