import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/pages/events/event_card_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/search_autocomplete.dart';
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
    teilnahme = event["zusage"] == null ? [] :event["zusage"].contains(userId),
    absage = event["absage"] == null ? [] :event["absage"].contains(userId);

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
      "zusagen": widget.event["zusage"] == null ? [] :widget.event["zusage"].length,
      "absagen": widget.event["absage"] == null ? [] :widget.event["absage"].length,
      "interessierte": widget.event["interesse"] == null ? [] :widget.event["interesse"].length,
      "freigegeben": widget.event["freigegeben"] == null ? [] :widget.event["freigegeben"].length
    };

    getDatabaseData();

    super.initState();
  }

  getDatabaseData() async{
    allName = await ProfilDatabase().getData("name", "");

    userFriendlist = await ProfilDatabase().getData("friendlist", "WHERE id = '${userId}'");
  }

  freischalten(user, angenommen, windowState) async {
    var eventId = widget.event["id"];

    widget.event["freischalten"].remove(user);
    widget.event["freigegeben"].add(user);
    windowState((){

    });


    var freischaltenList = await EventDatabase().getOneData("freischalten", eventId);
    freischaltenList.remove(user);
    EventDatabase().updateOne(eventId, "freischalten", freischaltenList);

    if(!angenommen) return;

    var freigegebenListe = await EventDatabase().getOneData("freigegeben", eventId);
    freigegebenListe.add(user);
    EventDatabase().updateOne(eventId, "freigegeben", freigegebenListe);

    setState(() {

    });

    var receiverToken = await ProfilDatabase().getData("token", "WHERE id = '${user}'");

    var notificationInformation = {
      "to": receiverToken,
      "title": AppLocalizations.of(context).eventFreigeben,
      "inhalt": AppLocalizations.of(context).zugriffFolgendesEvent + widget.event["name"],
      "changePageId": eventId,
      "typ": "event",
      "toId": user
    };
    sendNotification(notificationInformation);
     
  }

  freigegebenEntfernen(user, windowState) async{
    var eventId = widget.event["id"];

    windowState((){
      widget.event["freigegeben"].remove(user);
    });

    var freigegebenList = await EventDatabase().getOneData("freigegeben", eventId);
    freigegebenList.remove(user);
    EventDatabase().updateOne(eventId, "freigegeben", freigegebenList);
  }

  changeOrganisatorWindow(){
    var inputKontroller = TextEditingController();

    searchAutocomplete = SearchAutocomplete(
      searchKontroller: inputKontroller,
      searchableItems: allName,
      withFilter: false,
      onConfirm: (){
        inputKontroller.text= searchAutocomplete.getSelected()[0];
      },
    );

    CustomWindow(
      context: context,
      height: 300,
      title: AppLocalizations.of(context).organisatorAbgeben,
      children: [
        searchAutocomplete,
        SizedBox(height: 40),
        FloatingActionButton.extended(
          label: Text(AppLocalizations.of(context).uebertragen),
          onPressed: () async{
            var selectedUserId = await ProfilDatabase().getData("id", "WHERE name = '${inputKontroller.text}'");
            await EventDatabase().updateOne(widget.event["id"], "erstelltVon", selectedUserId);
            setState(() {

            });

            Navigator.pop(context);

            customSnackbar(
              context,
                AppLocalizations.of(context).eventUebergebenAn1
                    + inputKontroller.text + AppLocalizations.of(context).eventUebergebenAn2,
              color: Colors.green
            );
          },
        )
      ]
    );
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

    changeOrganisatorDialog(){
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.change_circle),
            const SizedBox(width: 10),
            Text("Organisator abgeben"),
          ],
        ),
        onPressed: (){
          Navigator.pop(context);
          changeOrganisatorWindow();
        } ,
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
                    if(!isCreator) reportEventDialog(),
                    if(isCreator) eventDetailsDialog(),
                    if(isCreator) changeOrganisatorDialog(),
                    if(isCreator) const SizedBox(height: 15),
                    if(isCreator) deleteEventDialog(),

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
                    widget.event["zusage"].add(userId);
                    widget.event["absage"].remove(userId);
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
              label: Text(AppLocalizations.of(context).absage),
              onPressed: () async {

                setState(() {
                  widget.teilnahme = false;
                  widget.absage = true;
                  widget.event["zusage"].remove(userId);
                  widget.event["absage"].add(userId);
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
        var name = await ProfilDatabase().getData("name", "WHERE id = '${user}'");

        freizugebenListe.add(
            Container(
                margin: EdgeInsets.only(left: 20),
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
          Padding(
            padding: const EdgeInsets.only(top:50),
            child: Center(
              child: Text(
                AppLocalizations.of(context).keineFamilienFreigebenVorhanden,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        );
      }

      return ListView(
        shrinkWrap: true,
        children: freizugebenListe
      );
    }

    freigeschalteteUser(windowSetState) async{
      List<Widget>freigeschlatetList = [];

      for(var user in widget.event["freigegeben"]){
        var name = await ProfilDatabase().getData("name", "WHERE id = '${user}'");

        freigeschlatetList.add(
            Container(
                margin: EdgeInsets.only(left: 20),
                child: Row(
                  children: [
                    Text(name),
                    const Expanded(child: SizedBox(width: 10)),
                    IconButton(
                        onPressed: () => freigegebenEntfernen(user, windowSetState),
                        icon: const Icon(Icons.cancel, size: 27,)
                    ),
                  ],
                )
            )
        );
      }


      if(widget.event["freischalten"].length == 0) {
        freigeschlatetList.add(
            Padding(
              padding: const EdgeInsets.only(top:50),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).keineFamilienFreigebenVorhanden,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
        );
      }

      return ListView(
          shrinkWrap: true,
          children: freigeschlatetList
      );
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
                    contentPadding: EdgeInsets.zero,
                    content: Stack(
                      clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 600,
                            width: 600,
                            child: Column(children: [
                              Container(
                                margin: EdgeInsets.all(10),
                                child: Text(
                                  AppLocalizations.of(context).familienFreigeben,
                                  style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: FutureBuilder(
                                  future: userFreischaltenList(windowSetState),
                                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                    if(snapshot.hasData){
                                      return Column(
                                        children: [
                                        snapshot.data,
                                        ],
                                      );
                                    }
                                    return SizedBox.shrink();
                                  },
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.all(10),
                                child: Text(
                                  AppLocalizations.of(context).freigegebeneFamilien,
                                  style: TextStyle(fontSize: fontsize, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: FutureBuilder(
                                  future: freigeschalteteUser(windowSetState),
                                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                    if(snapshot.hasData){
                                      return Column(
                                        children: [
                                          snapshot.data,
                                        ],
                                      );
                                    }
                                    return SizedBox.shrink();
                                  },
                                ),
                              )

                            ])
                      ),
                        Positioned(
                          height: 30,
                          right: -13,
                          top: -7,
                          child: InkResponse(
                              onTap: () => Navigator.pop(context),
                              child: const CircleAvatar(
                                child: Icon(Icons.close, size: 16,),
                                backgroundColor: Colors.red,
                              )
                          ),
                        ),
                    ]
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
          context: context,
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





