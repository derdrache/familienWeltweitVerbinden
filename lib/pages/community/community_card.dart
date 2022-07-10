import 'dart:convert';

import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'community_details.dart';

var userId = FirebaseAuth.instance.currentUser.uid;

class CommunityCard extends StatefulWidget {
  EdgeInsets margin;
  Map community;
  bool withFavorite;
  Function afterPageVisit;
  bool isCreator;
  bool bigCard;

  CommunityCard({
    Key key,
    this.community,
    this.withFavorite = false,
    this.margin =
        const EdgeInsets.only(top: 10, bottom: 0, right: 10, left: 10),
    this.afterPageVisit,
    this.bigCard = false,
  })  : isCreator = community["erstelltVon"] == userId,
        super(key: key);

  @override
  _CommunityCardState createState() => _CommunityCardState();
}

class _CommunityCardState extends State<CommunityCard> {
  var shadowColor = Colors.grey.withOpacity(0.8);

  @override
  Widget build(BuildContext context) {
    var bigMultiplikator = widget.bigCard == true ? 1.4 : 1.0;
    double screenHeight = MediaQuery.of(context).size.height;
    var fontSize = screenHeight / 55 * bigMultiplikator;
    var isAssetImage =
        widget.community["bild"].substring(0, 5) == "asset" ? true : false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CommunityDetails(community: widget.community)))
            .whenComplete(() => widget.afterPageVisit());

      },
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
                          ? Image.asset(widget.community["bild"],
                              height: (70 + ((screenHeight - 600) / 4)) *
                                  bigMultiplikator,
                              width: (135 + ((screenHeight - 600) / 4)) *
                                  bigMultiplikator,
                              fit: BoxFit.fill)
                          : Image.network(widget.community["bild"],
                              height: (70 + ((screenHeight - 600) / 4)) *
                                  bigMultiplikator,
                              width: (135 + ((screenHeight - 600) / 4)) *
                                  bigMultiplikator,
                              fit: BoxFit.fill),
                    ),
                  ),
                  if (widget.withFavorite && !widget.isCreator)
                    Positioned(
                        top: 2,
                        right: 8,
                        child: InteresseButton(
                          hasIntereset:
                              widget.community["interesse"].contains(userId),
                          id: widget.community["id"].toString(),
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
                        Text(widget.community["name"],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: fontSize + 1)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.community["ort"],
                                style: TextStyle(fontSize: fontSize))
                          ],
                        ),
                        const SizedBox(height: 2.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.community["land"],
                                style: TextStyle(fontSize: fontSize))
                          ],
                        ),
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
    widget.hasIntereset = widget.hasIntereset ? false : true;

    setState(() {});

    var interesseList =
        await CommunityDatabase().getData("interesse", "WHERE id = '${widget.id}'");

    if (widget.hasIntereset) {
      interesseList.add(userId);
    } else {
      interesseList.remove(userId);
    }

    CommunityDatabase().update("interesse = '${json.encode(interesseList)}'",
        "WHERE id ='${widget.id}'");
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => setInteresse(),
        child: Icon(Icons.star, size: 30,
            color: widget.hasIntereset ? Colors.amberAccent : Colors.black));
  }
}
