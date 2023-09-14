import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../../functions/user_speaks_german.dart';
import '../../../global/variablen.dart' as global_var;
import '../../../global/global_functions.dart' as global_func;
import '../../../services/database.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/layout/custom_like_button.dart';
import 'meetup_details.dart';

var userId = FirebaseAuth.instance.currentUser!.uid;

class MeetupCard extends StatefulWidget {
  final EdgeInsets margin;
  final Map meetupData;
  final bool withInteresse;
  final Function? afterPageVisit;
  final bool isCreator;
  final bool bigCard;
  final bool fromMeetupPage;
  final bool smallCard;
  final Function? afterFavorite;

  MeetupCard({
    Key? key,
    required this.meetupData,
    this.withInteresse = false,
    this.margin = const EdgeInsets.all(10),
    this.afterPageVisit,
    this.bigCard = false,
    this.fromMeetupPage = false,
    this.smallCard = false,
    this.afterFavorite,
  })  : isCreator = meetupData["erstelltVon"] == userId,
        super(key: key);

  @override
  State<MeetupCard> createState() => _MeetupCardState();
}

class _MeetupCardState extends State<MeetupCard> {
  late bool onAbsageList;
  late bool onZusageList;
  var shadowColor = Colors.grey.withOpacity(0.8);

  @override
  void initState() {
    onAbsageList = widget.meetupData["absage"].contains(userId);
    onZusageList = widget.meetupData["zusage"].contains(userId);

    super.initState();
  }

  takePartDecision(bool confirm) async {
    if (confirm) {
      if (!widget.meetupData["interesse"].contains(userId)) {
        widget.meetupData["interesse"].add(userId);
        MeetupDatabase().update(
            "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
            "WHERE id = '${widget.meetupData["id"]}'");
      }

      if (widget.meetupData["absage"].contains(userId)) {
        MeetupDatabase().update(
            "absage = JSON_REMOVE(absage, JSON_UNQUOTE(JSON_SEARCH(absage, 'one', '$userId'))),zusage = JSON_ARRAY_APPEND(zusage, '\$', '$userId')",
            "WHERE id = '${widget.meetupData["id"]}'");
      } else {
        MeetupDatabase().update(
            "zusage = JSON_ARRAY_APPEND(zusage, '\$', '$userId')",
            "WHERE id = '${widget.meetupData["id"]}'");
      }

      widget.meetupData["zusage"].add(userId);
      widget.meetupData["absage"].remove(userId);
    } else {
      if (widget.meetupData["zusage"].contains(userId)) {
        MeetupDatabase().update(
            "zusage = JSON_REMOVE(zusage, JSON_UNQUOTE(JSON_SEARCH(zusage, 'one', '$userId'))),absage = JSON_ARRAY_APPEND(absage, '\$', '$userId')",
            "WHERE id = '${widget.meetupData["id"]}'");
      } else {
        MeetupDatabase().update(
            "absage = JSON_ARRAY_APPEND(absage, '\$', '$userId')",
            "WHERE id = '${widget.meetupData["id"]}'");
      }

      widget.meetupData["zusage"].remove(userId);
      widget.meetupData["absage"].add(userId);
    }

    setState(() {});
  }

  createDatetimeText() {
    var datetimeText =
        widget.meetupData["wann"].split(" ")[0].split("-").reversed.join(".");
    var datetimeWann = DateTime.parse(widget.meetupData["wann"]);

    if (widget.meetupData["bis"] == null ||
        widget.meetupData["bis"] == "null") {
      return datetimeText;
    }
    var datetimeBis = DateTime.parse(widget.meetupData["bis"]);

    if (DateTime.now().compareTo(datetimeWann) > 0 &&
        datetimeBis.year.toString() == "0000") {
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
    int meetupZeitzone = widget.meetupData["zeitzone"] is String
        ? int.parse(widget.meetupData["zeitzone"])
        : widget.meetupData["zeitzone"];
    int deviceZeitzone = DateTime.now().timeZoneOffset.inHours;
    var meetupStart = widget.meetupData["wann"];

    meetupStart = DateTime.parse(meetupStart)
        .add(Duration(hours: deviceZeitzone - meetupZeitzone));

    return meetupStart.toString().split(" ")[1].toString().substring(0, 5);
  }

  getMeetupTitle() {
    String title;

    if (widget.isCreator) {
      title = widget.meetupData["name"];
    } else if (getUserSpeaksGerman()) {
      title = widget.meetupData["nameGer"];
    } else {
      title = widget.meetupData["nameEng"];
    }

    return title.isEmpty ? widget.meetupData["name"] : title;
  }

  @override
  Widget build(BuildContext context) {
    var sizeRefactor = widget.bigCard == true
        ? 1.4
        : widget.smallCard
            ? 0.5
            : 1.0;
    var fontSize = 14 * sizeRefactor;

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
      final RenderBox overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;

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
                  Text(AppLocalizations.of(context)!.teilnehmen),
                ],
              ),
              onTap: () => takePartDecision(true),
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
                  Text(AppLocalizations.of(context)!.absage),
                ],
              ),
              onTap: () => takePartDecision(false),
            ),
        ],
      );
    }

    return CustomCard(
      width: 160,
      height: 250,
      margin: widget.margin,
      likeButton: widget.withInteresse && !widget.isCreator && !widget.smallCard
          ? InteresseButton(
              hasIntereset: widget.meetupData["interesse"].contains(userId),
              id: widget.meetupData["id"],
              afterFavorite:
                  widget.afterFavorite != null ? widget.afterFavorite! : null)
          : null,
      onLongPressStart: widget.isCreator || forTeilnahmeFreigegeben
          ? (tapdownDetails) => cardMenu(tapdownDetails.globalPosition)
          : null,
      onTap: () => global_func.changePage(
          context,
          MeetupDetailsPage(
              meetupData: widget.meetupData,
              fromMeetupPage: widget.fromMeetupPage),
          whenComplete: () =>
              widget.afterPageVisit != null ? widget.afterPageVisit!() : null),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 115),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                  child: isAssetImage
                      ? Image.asset(widget.meetupData["bild"], fit: BoxFit.fill)
                      : CachedNetworkImage(
                          imageUrl: widget.meetupData["bild"],
                          fit: BoxFit.fill),
                ),
              ),
            ],
          ),
          Container(
              padding: EdgeInsets.only(top: 10 * sizeRefactor, left: 5, right: 5),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
              child: Column(
                children: [
                  Text(getMeetupTitle(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: fontSize + 1, color: Colors.black), ),
                  SizedBox(height: 10 * sizeRefactor),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.datum,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: fontSize, color: Colors.black)),
                      Text(createDatetimeText(),
                          style: TextStyle(fontSize: fontSize, color: Colors.black))
                    ],
                  ),
                  const SizedBox(height: 2.5),
                  if (isOffline)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.meetupData["stadt"],
                            style: TextStyle(fontSize: fontSize, color: Colors.black))
                      ],
                    ),
                  if (isOffline) const SizedBox(height: 2.5),
                  if (isOffline)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.meetupData["land"],
                            style: TextStyle(fontSize: fontSize, color: Colors.black))
                      ],
                    ),
                  if (!isOffline)
                    Row(
                      children: [
                        Text(AppLocalizations.of(context)!.uhrzeit,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: fontSize, color: Colors.black)),
                        Text(
                            createOnlineMeetupTime() +
                                " GMT " +
                                DateTime.now()
                                    .timeZoneOffset
                                    .inHours
                                    .toString(),
                            style: TextStyle(fontSize: fontSize, color: Colors.black))
                      ],
                    ),
                  if (!isOffline)
                    Row(
                      children: [
                        Text("Typ: ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: fontSize, color: Colors.black)),
                        Text(widget.meetupData["typ"],
                            style: TextStyle(fontSize: fontSize, color: Colors.black))
                      ],
                    )
                ],
              ))
        ],
      ),
    );
  }
}

class InteresseButton extends StatefulWidget {
  bool hasIntereset;
  String id;
  Function? afterFavorite;

  InteresseButton(
      {Key? key,
      required this.hasIntereset,
      required this.id,
      this.afterFavorite})
      : super(key: key);

  @override
  State<InteresseButton> createState() => _InteresseButtonState();
}

class _InteresseButtonState extends State<InteresseButton> {
  var color = Colors.black;

  Future<bool> setInteresse(isIntereset) async {
    var myInterestedMeetups = Hive.box('secureBox').get("interestEvents") ?? [];
    var meetupData = getMeetupFromHive(widget.id);
    widget.hasIntereset = !widget.hasIntereset;

    if (widget.hasIntereset) {
      meetupData["interesse"].add(userId);
      myInterestedMeetups.add(meetupData);

      MeetupDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id ='${widget.id}'");
    } else {
      meetupData["interesse"].remove(userId);
      myInterestedMeetups.removeWhere((meetup) => meetup["id"] == widget.id);
      MeetupDatabase().update(
          "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id ='${widget.id}'");
    }

    setState(() {});

    if (widget.afterFavorite != null) widget.afterFavorite!();

    return !isIntereset;
  }

  @override
  Widget build(BuildContext context) {
    return CustomLikeButton(
      isLiked: widget.hasIntereset,
      onLikeButtonTapped: setInteresse,
    );
  }
}
