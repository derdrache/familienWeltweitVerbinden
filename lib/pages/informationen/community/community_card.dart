import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../global/global_functions.dart' as global_func;

import 'community_details.dart';

var userId = FirebaseAuth.instance.currentUser!.uid;

class CommunityCard extends StatefulWidget {
  EdgeInsets margin;
  Map community;
  bool withFavorite;
  Function? afterPageVisit;
  bool isCreator;
  Function? afterFavorite;
  bool smallCard;

  CommunityCard({
    Key? key,
    required this.community,
    this.withFavorite = false,
    this.afterFavorite,
    this.margin =
        const EdgeInsets.only(top: 10, bottom: 0, right: 10, left: 10),
    this.afterPageVisit,
    this.smallCard = false
  })  : isCreator = community["erstelltVon"] == userId,
        super(key: key);

  @override
  _CommunityCardState createState() => _CommunityCardState();
}

class _CommunityCardState extends State<CommunityCard> {
  var shadowColor = Colors.grey.withOpacity(0.8);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double sizeRefactor = widget.smallCard ? 0.5 : 1;
    var fontSize = screenHeight / 55 * sizeRefactor;
    var isAssetImage =
        widget.community["bild"].substring(0, 5) == "asset" ? true : false;

    return GestureDetector(
     onTap: () => global_func.changePage(
          context, 
          CommunityDetails(community: widget.community),
          whenComplete: widget.afterPageVisit != null ? ()=>  widget.afterPageVisit :null),
      child: Container(
          width: (120 + ((screenHeight - 600) / 5)) * sizeRefactor,
          height: screenHeight / 3.2 * sizeRefactor,
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
                      minHeight: 70 *0.5,
                      maxHeight: 120
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                      child: isAssetImage
                          ? Image.asset(widget.community["bild"],
                              height: (70 + ((screenHeight - 600) / 4)) * sizeRefactor,
                              width: (135 + ((screenHeight - 600) / 4)),
                              fit: BoxFit.fill)
                          : Image.network(widget.community["bild"],
                              height: (70 + ((screenHeight - 600) / 4)) * sizeRefactor,
                              width: (135 + ((screenHeight - 600) / 4)),
                              fit: BoxFit.fill),
                    ),
                  ),
                  if (widget.withFavorite && !widget.isCreator)
                    Positioned(
                        top: 2,
                        right: 8,
                        child: InteresseButton(
                            communityData: widget.community,
                            afterFavorite: widget.afterFavorite != null ? widget.afterFavorite! : null)),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                        if (widget.community["ort"] != widget.community["land"])
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
  Map communityData;
  Function? afterFavorite;

  InteresseButton({Key? key, required this.communityData, required this.afterFavorite})
      : super(key: key);

  @override
  _InteresseButtonState createState() => _InteresseButtonState();
}

class _InteresseButtonState extends State<InteresseButton> {
  var color = Colors.black;
  late bool hasIntereset;


  setInteresse() async {
    String communityId = widget.communityData["id"];
    hasIntereset = !hasIntereset;

    if (hasIntereset) {
      widget.communityData["interesse"].add(userId);
      CommunityDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id ='$communityId'");
    }else{
      widget.communityData["interesse"].remove(userId);
      CommunityDatabase().update(
          "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id ='$communityId'");
    }

    updateHiveCommunity(communityId, "interesse", widget.communityData["interesse"]);
    setState(() {});

    widget.afterFavorite!();
  }


@override
  void initState() {
    hasIntereset = widget.communityData["interesse"].contains(userId);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => setInteresse(),
        child: Icon(Icons.star,
            size: 30,
            color: hasIntereset ? Colors.amberAccent : Colors.black));
  }
}
