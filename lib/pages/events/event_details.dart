import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/pages/events/event_card_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../services/database.dart';
import '../../global/style.dart' as global_style;
import '../../widgets/badge_icon.dart';
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
  var searchAutocomplete;
  var allName;
  var userFriendlist;
  var eventDetails = {};
  var isNotPublic;

  @override
  void initState() {
    isCreator = widget.event["erstelltVon"] == userId;
    isApproved = isCreator ? true : widget.event["freigegeben"].contains(userId);
    isNotPublic = widget.event["art"] != "öffentlich" && widget.event["art"] != "public";

    eventDetails = {
      "zusagen": widget.event["zusage"].length,
      "absagen": widget.event["absage"].length,
      "interessierte": widget.event["interesse"].length,
      "freigegeben": widget.event["freigegeben"].length
    };

    getDatabaseData();

    super.initState();
  }

  getDatabaseData() async{
    allName = await ProfilDatabase().getOneDataFromAll("name");
    userFriendlist = await ProfilDatabase().getOneData("friendlist", "id", userId);
  }

  freischalten(user, angenommen, windowState) async {
    var eventId = widget.event["id"];

    widget.event["freischalten"].remove(user);
    windowState((){

    });


    var freischaltenList = await EventDatabase().getOneData("freischalten", eventId);
    freischaltenList.remove(user);
    EventDatabase().updateOne(eventId, "freischalten", freischaltenList);

    setState(() {});

    if(angenommen) return;
    
    var freigegebenListe = await EventDatabase().getOneData("freigegeben", eventId);
    freigegebenListe.add(user);
    EventDatabase().updateOne(eventId, "freigegeben", freigegebenListe);

    var receiverToken = await ProfilDatabase().getOneData("token", "id", user);

    var notificationInformation = {
      "to": receiverToken,
      "title": "Event Freigabe",
      "inhalt": "Du hast jetzt Zugriff auf folgendes Event: " + widget.event["name"],
      "changePageId": eventId,
      "typ": "event"
    };

    sendNotification(notificationInformation);
     
  }


  @override
  Widget build(BuildContext context) {

    deleteEventWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context){
            return AlertDialog(
              title: const Text("Event löschen"),
              content: const Text("Du möchtest das Event löschen?"),
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: (){
                    EventDatabase().delete(widget.event["id"]);
                    changePage(context, StartPage(selectedIndex: 1));
                  },
                ),
                TextButton(
                  child: const Text("Abbrechen"),
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
        title: AppLocalizations.of(context).eventMelden,
        children: [
          customTextInput(AppLocalizations.of(context).eventMeldenFrage, reportController, moreLines: 10),
          Container(
            margin: const EdgeInsets.only(left: 30, top: 10, right: 30),
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
                label: Text(AppLocalizations.of(context).senden)
            ),
          )
        ]
      );
    }

    deleteEventDialog(){
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.delete),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).eventLoeschen),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          deleteEventWindow();
        },
      );
    }

    reportEventDialog(){
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.report),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).eventMelden),
          ],
        ),
        onPressed: (){
          Navigator.pop(context);
          reportEventWindow();
        } ,
      );
    }

    eventDetailsDialog(){
      return SimpleDialogOption(
          child: Row(
            children: const [
              Icon(Icons.info),
              SizedBox(width: 10),
              Text("Event Info"),
            ],
          ),
        onPressed: () => CustomWindow(
          context: context,
          title: "Event Information",
          children: [
            const SizedBox(height: 10),
            Text(
                AppLocalizations.of(context).interessierte + eventDetails["interessierte"].toString(),
                style: TextStyle(fontSize: fontsize)
            ),
            const SizedBox(height: 10),
            Text(
                AppLocalizations.of(context).zusagen+ eventDetails["zusagen"].toString(),
                style: TextStyle(fontSize: fontsize)
            ),
            const SizedBox(height: 10),
            Text(
                AppLocalizations.of(context).absagen + eventDetails["absagen"].toString(),
                style: TextStyle(fontSize: fontsize)
            ),
            const SizedBox(height: 10),
            if(isNotPublic) Text(
                AppLocalizations.of(context).freigegeben + eventDetails["freigegeben"].toString(),
                style: TextStyle(fontSize: fontsize)
            )
          ]
        ),
      );
    }

    moreMenu(){
      showDialog(
        context: context,
        builder: (BuildContext context){
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 250,
                child: SimpleDialog(
                  contentPadding: EdgeInsets.zero,
                  insetPadding: const EdgeInsets.only(top:40, left: 0, right:10),
                  children: [
                    if(isCreator) eventDetailsDialog(),
                    if(isCreator) const SizedBox(height: 15),
                    if(isCreator) deleteEventDialog(),
                    if(!isCreator) reportEventDialog()
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
            margin: const EdgeInsets.only(left: 20, right: 20),
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
                label: Text(AppLocalizations.of(context).teilnehmen)
            ),
          ),
          if(widget.absage != true) Container(
            margin: const EdgeInsets.only(left: 20, right: 20),
            child: FloatingActionButton.extended(
              heroTag: "Absagen",
              backgroundColor: Theme.of(context).colorScheme.primary,
              label: Text(AppLocalizations.of(context).absagen),
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
                    const Expanded(child: SizedBox(width: 10)),
                    IconButton(
                        onPressed: () => freischalten(user, true, windowSetState),
                        icon: const Icon(Icons.check_circle, size: 27)
                    ),
                    IconButton(
                        onPressed: () => freischalten(user, false, windowSetState),
                        icon: const Icon(Icons.cancel, size: 27,)
                    ),
                  ],
                )
            )
        );
      }


      if(widget.event["freischalten"].length == 0) {
        freizugebenListe.add(
        Text(AppLocalizations.of(context).keineFamilienFreigebenVorhanden, style: const TextStyle(color: Colors.grey),)
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
                    title: Text(AppLocalizations.of(context).familienFreigeben),
                    content: FutureBuilder(
                      future: userFreischaltenList(windowSetState),
                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                        if(snapshot.hasData){
                          return Column(
                            children: snapshot.data,
                          );
                        } else{
                          return Column(
                            children: const [CircularProgressIndicator()],
                          );
                        }

                      },
                    ),
                  );
            });

          }
      );
    }

    linkTeilenWindow() async{
      return CustomWindow(
        context: context,
        title: "Event link",
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all()
            ),
            child: Text("</eventId=" + widget.event["id"])
          ),
          Container(
            margin: const EdgeInsets.only(left: 20, right: 20),
            child: FloatingActionButton.extended(
              onPressed: () async {
                Clipboard.setData(ClipboardData(text: "</eventId=" + widget.event["id"]));

                await showDialog(
                    context: context,
                    builder: (context) {
                      Future.delayed(const Duration(seconds: 1), () {
                        Navigator.of(context).pop(true);
                      });
                      return AlertDialog(
                        content: Text(AppLocalizations.of(context).linkWurdekopiert),
                      );
                    });
                Navigator.pop(context);
              },
              label: Text(AppLocalizations.of(context).linkKopieren),
              icon: const Icon(Icons.copy),
            ),
          )
        ]
      );
    }


    return Scaffold(
        appBar: customAppBar(
            title: "",
            buttons: [
              if(isCreator && isNotPublic) FutureBuilder(
                future: EventDatabase().getOneData("freischalten", widget.event["id"]),
                builder: (context, snap) {
                  var data = snap.hasData ? snap.data.length.toString() : "";
                  if(data == "0") data = "";

                  return TextButton(
                    style: global_style.textButtonStyle(),
                    child: BadgeIcon(
                      icon: Icons.event_available,
                      text: data.toString()
                    ),//const Icon(Icons.event_available),
                    onPressed: () => userfreischalteWindow()
                  );
                }
              ),
              TextButton(
                style: global_style.textButtonStyle(),
                child: const Icon(Icons.link),
                onPressed: () => linkTeilenWindow(),
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
        body:
            ListView(
              children: [
                EventCardDetails(
                  event: widget.event,
                  isApproved: isApproved,
                ),
                if(isApproved || !isNotPublic) teilnahmeButtonBox(),
              ],
            ),
    );
  }
}





