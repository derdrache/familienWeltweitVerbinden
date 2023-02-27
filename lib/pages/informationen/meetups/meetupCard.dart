import 'dart:convert';

import 'package:familien_suche/services/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../../global/variablen.dart' as global_var;
import '../../../global/global_functions.dart' as global_func;
import 'meetup_details.dart';

var userId = FirebaseAuth.instance.currentUser.uid;

class MeetupCard extends StatefulWidget {
  EdgeInsets margin;
  Map meetupData;
  bool withInteresse;
  Function afterPageVisit;
  bool isCreator;
  bool bigCard;
  bool fromMeetupPage;

  MeetupCard({
    Key key,
    this.meetupData,
    this.withInteresse = false,
    this.margin =
        const EdgeInsets.only(top: 10, bottom: 0, right: 10, left: 10),
    this.afterPageVisit,
    this.bigCard = false,
    this.fromMeetupPage = false
  })  : isCreator = meetupData["erstelltVon"] == userId,
        super(key: key);

  @override
  _MeetupCardState createState() => _MeetupCardState();
}

class _MeetupCardState extends State<MeetupCard> {
  bool onAbsageList;
  bool onZusageList;
  var shadowColor = Colors.grey.withOpacity(0.8);

  @override
  void initState() {
    onAbsageList = widget.meetupData["absage"].contains(userId);
    onZusageList = widget.meetupData["zusage"].contains(userId);

    super.initState();
  }

  confirmMeetup(bool confirm) async {
    if (confirm) {
      var onInteresseList = widget.meetupData["interesse"].contains(userId);

      if (!onInteresseList) {
        widget.meetupData["interesse"].add(userId);
      }

      setState(() {
        widget.meetupData["zusage"].add(userId);
        widget.meetupData["absage"].remove(userId);
        onZusageList = true;
        onAbsageList = false;
      });
    } else {
      setState(() {
        widget.meetupData["absage"].add(userId);
        widget.meetupData["zusage"].remove(userId);
        onAbsageList = true;
        onZusageList = false;
      });
    }

    var dbData = await MeetupDatabase().getData(
        "absage, zusage, interesse", "WHERE id = '${widget.meetupData["id"]}'");

    var zusageList = dbData["zusage"];
    var absageList = dbData["absage"];
    var interessenList = dbData["interesse"];

    if (confirm) {
      if (!interessenList.contains(userId)) interessenList.add(userId);
      zusageList.add(userId);
      absageList.remove(userId);
    } else {
      zusageList.remove(userId);
      absageList.add(userId);
    }

    MeetupDatabase().update(
        "absage = '${json.encode(absageList)}', "
            "zusage = '${json.encode(zusageList)}', interesse = '${json.encode(interessenList)}'",
        "WHERE id = '${widget.meetupData["id"]}'");
  }

  createDatetimeText() {

    var datetimeText =
        widget.meetupData["wann"].split(" ")[0].split("-").reversed.join(".");
    var datetimeWann = DateTime.parse(widget.meetupData["wann"]);

    if(widget.meetupData["bis"] == null || widget.meetupData["bis"] =="null") return datetimeText;
    var datetimeBis = DateTime.parse(widget.meetupData["bis"]);

    if (DateTime.now().compareTo(datetimeWann) > 0 && datetimeBis.year.toString() == "0000") {
      return DateTime.now()
          .toString()
          .split(" ")[0]
          .split("-")
          .reversed
          .join(".");
    }

    return datetimeText;
  }

  createOnlineMeetupTime() {
    var meetupZeitzone = widget.meetupData["zeitzone"] is String
        ? int.parse(widget.meetupData["zeitzone"])
        : widget.meetupData["zeitzone"];
    var deviceZeitzone = DateTime.now().timeZoneOffset.inHours;
    var meetupStart = widget.meetupData["wann"];

    meetupStart = DateTime.parse(meetupStart).add(Duration(hours: deviceZeitzone - meetupZeitzone));

    return meetupStart.toString().split(" ")[1].toString().substring(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    var bigMultiplikator = widget.bigCard == true ? 1.4 : 1.0;
    double screenHeight = MediaQuery.of(context).size.height;
    var fontSize = screenHeight / 55 * bigMultiplikator;
    var forTeilnahmeFreigegeben = (widget.meetupData["art"] == "public" ||
            widget.meetupData["art"] == "öffentlich") ||
        widget.meetupData["freigegeben"].contains(userId);
    var isAssetImage =
        widget.meetupData["bild"].substring(0, 5) == "asset" ? true : false;
    var isOffline = widget.meetupData["typ"] == global_var.meetupTyp[0] ||
        widget.meetupData["typ"] == global_var.meetupTypEnglisch[0];

    if (widget.meetupData["zusage"].contains(userId)) {
      shadowColor = Colors.green.withOpacity(0.8);
    }
    if (widget.meetupData["absage"].contains(userId)) {
      shadowColor = Colors.red.withOpacity(0.8);
    }

    cardMenu(tapPosition) {
      final RenderBox overlay = Overlay.of(context).context.findRenderObject();

      showMenu(
        context: context,
        position: RelativeRect.fromRect(
            tapPosition & const Size(40, 40), Offset.zero & overlay.size),
        elevation: 8.0,
        items: [
          if (!onZusageList)
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.check_circle),
                  const SizedBox(width: 10),
                  Text(AppLocalizations.of(context).teilnehmen),
                ],
              ),
              onTap: () => confirmMeetup(true),
            ),
          if (!onAbsageList)
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(
                    Icons.cancel,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Text(AppLocalizations.of(context).absage),
                ],
              ),
              onTap: () => confirmMeetup(false),
            ),
        ],
      );
    }

    return GestureDetector(
      onLongPressStart: widget.isCreator || forTeilnahmeFreigegeben
          ? (tapdownDetails) => cardMenu(tapdownDetails.globalPosition)
          : null,
        onTap: () => global_func.changePage(
            context,
            MeetupDetailsPage(meetupData: widget.meetupData, fromMeetupPage: widget.fromMeetupPage),
            whenComplete: () =>  widget.afterPageVisit()),
      child: Container(
          width: (130 + ((screenHeight - 600) / 5)) * bigMultiplikator,
          height: screenHeight / 3.2 * bigMultiplikator,
          margin: widget.margin,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  spreadRadius: 8,
                  blurRadius: 7,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ]),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 70,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                      child: isAssetImage
                          ? Image.asset(widget.meetupData["bild"],
                              height: (70 + ((screenHeight - 600) / 4)) *
                                  bigMultiplikator,
                              width: (135 + ((screenHeight - 600) / 4)) *
                                  bigMultiplikator,
                              fit: BoxFit.fill)
                          : Image.network(widget.meetupData["bild"],
                              height: (70 + ((screenHeight - 600) / 4)) *
                                  bigMultiplikator,
                              width: (130 + ((screenHeight - 600) / 4)) *
                                  bigMultiplikator,
                              fit: BoxFit.fill),
                    ),
                  ),
                  if (widget.withInteresse && !widget.isCreator)
                    Positioned(
                        top: 2,
                        right: 8,
                        child: InteresseButton(
                          hasIntereset:
                              widget.meetupData["interesse"].contains(userId),
                          id: widget.meetupData["id"],
                        )),
                ],
              ),
              Expanded(
                child: Container(
                    padding: const EdgeInsets.only(top: 10, left: 5),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Text(widget.meetupData["name"],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: fontSize + 1)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(AppLocalizations.of(context).datum,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize)),
                            Text(createDatetimeText(),
                                style: TextStyle(fontSize: fontSize))
                          ],
                        ),
                        const SizedBox(height: 2.5),
                        if (isOffline)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(widget.meetupData["stadt"],
                                  style: TextStyle(fontSize: fontSize))
                            ],
                          ),
                        if (isOffline) const SizedBox(height: 2.5),
                        if (isOffline)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(widget.meetupData["land"],
                                  style: TextStyle(fontSize: fontSize))
                            ],
                          ),
                        if (!isOffline)
                          Row(
                            children: [
                              Text(AppLocalizations.of(context).uhrzeit,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: fontSize)),
                              Text(createOnlineMeetupTime() + " GMT " + DateTime.now().timeZoneOffset.inHours.toString(),
                                  style: TextStyle(fontSize: fontSize))
                            ],
                          ),
                        if (!isOffline)
                          Row(
                            children: [
                              Text("Typ: ",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: fontSize)),
                              Text(widget.meetupData["typ"],
                                  style: TextStyle(fontSize: fontSize))
                            ],
                          )
                      ],
                    )),
              )
            ],
          )),
    );
  }
}

class InteresseButton extends StatefulWidget {
  bool hasIntereset;
  String id;

  InteresseButton({Key key, this.hasIntereset, this.id}) : super(key: key);

  @override
  _InteresseButtonState createState() => _InteresseButtonState();
}

class _InteresseButtonState extends State<InteresseButton> {
  var color = Colors.black;

  setInteresse() async {
    var myInterestedMeetups = Hive.box('secureBox').get("interestEvents") ?? [];
    var meetupData = getMeetupFromHive(widget.id);
    var myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];
    widget.hasIntereset = !widget.hasIntereset;

    if (widget.hasIntereset) {
      meetupData["interesse"].add(userId);
      myInterestedMeetups.add(meetupData);
      MeetupDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id ='${widget.id}'");

      myGroupChats.add(getChatGroupFromHive(widget.id));
      ChatGroupsDatabase().updateChatGroup(
          "users = JSON_MERGE_PATCH(users, '${json.encode({userId : {"newMessages": 0}})}')",
          "WHERE connected LIKE '%${widget.id}%'");
    } else {
      meetupData["interesse"].remove(userId);
      myInterestedMeetups.removeWhere((meetup) => meetup["id"] == widget.id);
      MeetupDatabase().update(
          "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id ='${widget.id}'");

      myGroupChats.removeWhere((chatGroup){
        chatGroup["connected"].contains(widget.id);
      });
      ChatGroupsDatabase().updateChatGroup(
          "users = JSON_REMOVE(users, '\$.$userId')",
          "WHERE connected LIKE '%${widget.id}%'");
    }

    setState(() {   });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => setInteresse(),
        child: Icon(Icons.favorite,
            color: widget.hasIntereset ? Colors.red : Colors.black));
  }
}