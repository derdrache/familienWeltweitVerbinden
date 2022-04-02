import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'event_details.dart';

var userId = FirebaseAuth.instance.currentUser.uid;

class EventCard extends StatefulWidget {
  var margin;
  var event;
  var withInteresse;
  var afterPageVisit;
  var isCreator;

  EventCard({
    Key key,
    this.event,
    this.withInteresse = false,
    this.margin = const EdgeInsets.only(top:10, bottom: 10, right: 10, left: 10),
    this.afterPageVisit,
  }): isCreator = event["erstelltVon"] == userId;

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  var shadowColor = Colors.grey.withOpacity(0.8);

  @override
  Widget build(BuildContext context) {
    widget.event["bild"] ??= "assets/bilder/strand.jpg";
    double screenHeight = MediaQuery.of(context).size.height; //laptop: 619 -  Android 737
    var fontSize = screenHeight / 52; //Android 14   51,58  => 52,6
    var forTeilnahmeFreigegeben = (widget.event["art"] == "public" ||
        widget.event["art"] == "öffentlich") || widget.event["freigegeben"].contains(userId);
    var isAssetImage = widget.event["bild"].substring(0,5) == "asset" ? true : false;


    if(widget.event["zusage"].contains(userId)) shadowColor = Colors.green.withOpacity(0.8);
    if(widget.event["absage"].contains(userId)) shadowColor = Colors.red.withOpacity(0.8);


    cardMenu(tapPosition){
      var onAbsageList = widget.event["absage"].contains(userId);
      var onZusageList = widget.event["zusage"].contains(userId);
      final RenderBox overlay = Overlay.of(context).context.findRenderObject();

      showMenu(
        context: context,
        position: RelativeRect.fromRect(
            tapPosition & const Size(40, 40),
            Offset.zero & overlay.size
        ),
        elevation: 8.0,
        items: [
          if(!onZusageList) PopupMenuItem(
            child: Row(
              children: [
                const Icon(Icons.check_circle),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).teilnehmen),
              ],
            ),
            onTap: () async{
              setState(() {
                widget.event["zusage"].add(userId);
                widget.event["absage"].remove(userId);
                onZusageList = true;
                onAbsageList = false;
              });

              var zusageList = await EventDatabase().getOneData("zusage", widget.event["id"]);
              zusageList.add(userId);
              EventDatabase().updateOne(widget.event["id"], "zusage", zusageList);

              var absageList = await EventDatabase().getOneData("absage", widget.event["id"]);
              absageList.remove(userId);
              EventDatabase().updateOne(widget.event["id"], "absage", absageList);

            },
          ),
          if(!onAbsageList) PopupMenuItem(
            child: Row(
              children:[
                const Icon(Icons.cancel, color: Colors.red,),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).absage),
              ],
            ),
            onTap: () async{
              setState(() {
                widget.event["absage"].add(userId);
                widget.event["zusage"].remove(userId);
                onAbsageList = true;
                onZusageList = false;
              });

              var absageList = await EventDatabase().getOneData("absage", widget.event["id"]);
              absageList.add(userId);
              EventDatabase().updateOne(widget.event["id"], "absage", absageList);

              var zusageList = await EventDatabase().getOneData("zusage", widget.event["id"]);
              zusageList.remove(userId);
              EventDatabase().updateOne(widget.event["id"], "zusage", zusageList);

            },
          ),
        ],
      );
    }


    return GestureDetector(
      onLongPressStart: widget.isCreator || forTeilnahmeFreigegeben ?
          (tapdownDetails) => cardMenu(tapdownDetails.globalPosition) : null,
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailsPage(
                event: widget.event
            )
            )).whenComplete(() => widget.afterPageVisit());
      },
      child: Container(
          width: 130 + ((screenHeight-600)/5), //  Android 165
          height: screenHeight / 3.2, // Android 220 ~3,4
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
              ]
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 100,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                      child: isAssetImage ? Image.asset(
                          widget.event["bild"],
                          height: 70 + ((screenHeight-600)/5),
                          width: 130 + ((screenHeight-600)/5),
                          fit: BoxFit.fill
                      ) : Image.network(
                          widget.event["bild"],
                          height: 70 + ((screenHeight-600)/5),
                          width: 130 + ((screenHeight-600)/5),
                          fit: BoxFit.fill
                      ),
                    ),
                  ),
                  if(widget.withInteresse  && !widget.isCreator) Positioned(
                      top: 2,
                      right: 8,
                      child: InteresseButton(
                        hasIntereset: widget.event["interesse"].contains(userId),
                        id: widget.event["id"],
                      )
                  ),
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
                        Text(widget.event["name"],
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(AppLocalizations.of(context).datum, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            Text(
                                widget.event["wann"].split(" ")[0].split("-").reversed.join("."),
                                style: TextStyle(fontSize: fontSize))
                          ],
                        ),
                        const SizedBox(height: 2.5),
                        Row(
                          children: [
                            Text(AppLocalizations.of(context).stadt, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            Text(widget.event["stadt"], style: TextStyle(fontSize: fontSize))
                          ],
                        ),
                        const SizedBox(height: 2.5),
                        Row(
                          children: [
                            Text(AppLocalizations.of(context).land, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                            Text(widget.event["land"], style: TextStyle(fontSize: fontSize))
                          ],
                        ),
                      ],
                    )
                ),
              )
            ],
          )
      ),
    );
  }
}


class InteresseButton extends StatefulWidget {
  var hasIntereset;
  var id;

  InteresseButton({Key key, this.hasIntereset, this.id}) : super(key: key);

  @override
  _InteresseButtonState createState() => _InteresseButtonState();
}

class _InteresseButtonState extends State<InteresseButton> {
  var color = Colors.black;


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        widget.hasIntereset = widget.hasIntereset ? false : true;

        setState(() {});

        var interesseList = await EventDatabase().getOneData("interesse", widget.id);

        if(widget.hasIntereset){
          interesseList.add(userId);
        } else{
          interesseList.remove(userId);
        }

        EventDatabase().updateOne(widget.id, "interesse", interesseList);


      },
      child: Icon(Icons.favorite, color: widget.hasIntereset ? Colors.red : Colors.black)
    );
  }
}
