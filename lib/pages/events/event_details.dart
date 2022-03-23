import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/pages/events/event_card_details.dart';
import 'package:familien_suche/pages/events/event_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../services/database.dart';
import '../../global/style.dart' as global_style;
import '../start_page.dart';


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
  var userId = FirebaseAuth.instance.currentUser.uid;
  var isCreator;
  var isApproved;

  @override
  void initState() {
    isCreator = widget.event["erstelltVon"] == userId;
    isApproved = isCreator ? true : widget.event["freigegeben"].contains(userId);
    super.initState();
  }

  freischalten(user, angenommen, windowState) async {
    widget.event["freischalten"].remove(user);
    windowState((){

    });


    var freischaltenList = await EventDatabase().getOneData("freischalten", widget.event["id"]);
    freischaltenList.remove(user);
    EventDatabase().updateOne(widget.event["id"], "freischalten", freischaltenList);

    setState(() {});

    if(angenommen){
      var freigegebenListe = await EventDatabase().getOneData("freigegeben", widget.event["id"]);
      freigegebenListe.add(user);
      EventDatabase().updateOne(widget.event["id"], "freigegeben", freigegebenListe);
    } else{
      print("abgelehnt");
    }
  }


  @override
  Widget build(BuildContext context) {

    deleteEventWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context){
            return AlertDialog(
              title: Text("Event löschen"),
              content: Text("Du möchtest das Event löschen?"),
              actions: [
                TextButton(
                  child: Text("Ok"),
                  onPressed: (){
                    EventDatabase().delete(widget.event["id"]);
                    changePageForever(context, StartPage(selectedIndex: 1));
                  },
                ),
                TextButton(
                  child: Text("Abbrechen"),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            );
          }
      );
    }

    reportEventWindow(){
      var reportController = TextEditingController();

      CustomWindow(
        context: context,
        height: 500,
        title: "Event melden",
        children: [
          customTextInput("Warum möchtest du das Event melden?", reportController, moreLines: 10),
          Container(
            margin: EdgeInsets.only(left: 30, top: 10, right: 30),
            child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.pop(context);
                  ReportsDatabase().add(
                      userId,
                      "Melde Event id: " + widget.event["id"],
                      reportController.text
                  );
                  // send to db
                },
                label: Text("Senden")
            ),
          )
        ]
      );
    }

    moreMenu(){

      showDialog(
        context: context,
        builder: (BuildContext context){
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 180,
                child: SimpleDialog(
                  contentPadding: EdgeInsets.zero,
                  insetPadding: EdgeInsets.only(top:40, left: 0, right:10),
                  children: [
                    if(isCreator) SimpleDialogOption(
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 10),
                          Text("Event löschen"),
                        ],
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        deleteEventWindow();
                      },
                    ),
                    if(!isCreator) SimpleDialogOption(
                      child: Row(
                        children: [
                          Icon(Icons.report),
                          SizedBox(width: 10),
                          Text("Event melden"),
                        ],
                      ),
                      onPressed: (){
                        Navigator.pop(context);
                        reportEventWindow();
                      } ,
                    )
                  ],
                ),
              ),
            ],
          );
        }
      );
    }

    teilnahmeButtonBox(){
      return Row(
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
      );
    }

    userFreischaltenList(windowSetState) async {
      List<Widget>freizugebenListe = [];

      for(var user in widget.event["freischalten"]){
        var name = await ProfilDatabase().getOneData("name", "id", user);

        freizugebenListe.add(
            Container(
                child: Row(
                  children: [
                    Text(name),
                    Expanded(child: SizedBox(width: 10)),
                    IconButton(
                        onPressed: () => freischalten(user, true, windowSetState),
                        icon: Icon(Icons.check_circle, size: 27)
                    ),
                    IconButton(
                        onPressed: () => freischalten(user, false, windowSetState),
                        icon: Icon(Icons.cancel, size: 27,)
                    ),
                  ],
                )
            )
        );
      }

      return freizugebenListe;
    }

    userfreischalteWindow() async{
      var windowSetState;

      showDialog(
          context: context,
          builder: (BuildContext context){
            return StatefulBuilder(
                builder: (context, setState){
                  windowSetState = setState;
                  return AlertDialog(
                    title: Text("Familien freigeben"),
                    content: FutureBuilder(
                      future: userFreischaltenList(windowSetState),
                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                        if(snapshot.hasData){
                          return Column(
                            children: snapshot.data,
                          );
                        } else{
                          return Column(
                            children: [CircularProgressIndicator()],
                          );
                        }

                      },
                    ),
                  );
            });

          }
      );
    }


    return Scaffold(
        appBar: customAppBar(
            title: "",
            buttons: [
              if(isCreator && widget.event["art"] != "Öffentlich") TextButton(
                style: global_style.textButtonStyle(),
                child: const Icon(Icons.event_available),
                onPressed: () => userfreischalteWindow(),
              ),
              TextButton(
                style: global_style.textButtonStyle(),
                child: const Icon(Icons.link),
                onPressed: () => print("teilen"),
              ),
              if(!isCreator) TextButton(
                style: global_style.textButtonStyle(),
                child: const Icon(Icons.message),
                onPressed: () => changePage(context, ChatDetailsPage(
                  chatPartnerId: widget.event["erstelltVon"]
                )),
              ),
              TextButton(
                style: global_style.textButtonStyle(),
                child: const Icon(Icons.more_vert),
                onPressed: () => moreMenu(),
              ),

            ]
        ),
        body: Stack(
          children: [
            Column(
              children: [
                EventCardDetails(
                  event: widget.event,
                  isApproved: isApproved,
                ),
                if(isApproved) teilnahmeButtonBox(),
              ],
            ),
          ],
        )
    );
  }
}





