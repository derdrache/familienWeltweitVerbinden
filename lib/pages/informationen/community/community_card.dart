import 'package:cached_network_image/cached_network_image.dart';
import 'package:familien_suche/services/database.dart';
import 'package:familien_suche/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../functions/user_speaks_german.dart';
import '../../../global/global_functions.dart' as global_func;

import '../../../widgets/layout/custom_like_button.dart';
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

  CommunityCard(
      {Key? key,
      required this.community,
      this.withFavorite = false,
      this.afterFavorite,
      this.margin = const EdgeInsets.all(10),
      this.afterPageVisit,
      this.smallCard = false})
      : isCreator = community["erstelltVon"] == userId,
        super(key: key);

  @override
  State<CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends State<CommunityCard> {
  var shadowColor = Colors.grey.withOpacity(0.8);

  getCommunityTitle() {
    String? title;

    if (widget.isCreator) {
      title = widget.community["name"];
    } else if (getUserSpeaksGerman()) {
      title = widget.community["nameGer"];
    } else {
      title = widget.community["nameEng"];
    }

    return title!.isNotEmpty ? title : widget.community["name"];
  }

  @override
  Widget build(BuildContext context) {
    double sizeRefactor = widget.smallCard ? 0.5 : 1;
    var fontSize = 14 * sizeRefactor;
    var isAssetImage =
        widget.community["bild"].substring(0, 5) == "asset" ? true : false;

    return CustomCard(
        sizeRefactor: sizeRefactor,
        width: 160,
        height: 225,
        margin: widget.margin,
        likeButton: widget.withFavorite && !widget.isCreator
            ? InteresseButton(
                communityData: widget.community,
                afterFavorite:
                    widget.afterFavorite != null ? widget.afterFavorite! : null)
            : null,
        onTap: () => global_func.changePage(
            context, CommunityDetails(community: widget.community),
            whenComplete: widget.afterPageVisit),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 100),
              child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                  child: isAssetImage
                      ? Image.asset(widget.community["bild"], fit: BoxFit.fill)
                      : CachedNetworkImage(
                          imageUrl: widget.community["bild"],
                          fit: BoxFit.fill,
                        )),
            ),
            Container(
                padding: EdgeInsets.only(top: 10 * sizeRefactor, left: 5),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                ),
                child: Column(
                  children: [
                    Text(getCommunityTitle(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize + 1)),
                    SizedBox(height: 10 * sizeRefactor),
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
                ))
          ],
        ));
  }
}

class InteresseButton extends StatefulWidget {
  Map communityData;
  Function? afterFavorite;

  InteresseButton(
      {Key? key, required this.communityData, required this.afterFavorite})
      : super(key: key);

  @override
  State<InteresseButton> createState() => _InteresseButtonState();
}

class _InteresseButtonState extends State<InteresseButton> {
  var color = Colors.black;
  late bool hasInterest;

  Future<bool> setInteresse(isIntereset) async {
    String communityId = widget.communityData["id"];
    hasInterest = !hasInterest;

    if (hasInterest) {
      widget.communityData["interesse"].add(userId);
      CommunityDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id ='$communityId'");
    } else {
      widget.communityData["interesse"].remove(userId);
      CommunityDatabase().update(
          "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id ='$communityId'");
    }

    updateHiveCommunity(
        communityId, "interesse", widget.communityData["interesse"]);

    if (widget.afterFavorite != null) widget.afterFavorite!();

    return !isIntereset;
  }

  @override
  void initState() {
    hasInterest = widget.communityData["interesse"].contains(userId);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomLikeButton(
      isLiked: hasInterest,
      onLikeButtonTapped: setInteresse,
    );
  }
}
