import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../functions/user_speaks_german.dart';
import '../../../global/global_functions.dart' as global_func;
import '../../../services/locationsService.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_like_button.dart';
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
  bool systemIsGerman =
      WidgetsBinding.instance.platformDispatcher.locales[0].languageCode == "de";

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
            ? CustomLikeButton(
                communityData: widget.community,
                afterLike: widget.afterFavorite,
              )
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      isAssetImage
                          ? Image.asset(widget.community["bild"], fit: BoxFit.fill)
                          : CachedNetworkImage(
                              imageUrl: widget.community["bild"],
                              fit: BoxFit.fill,
                            ),
                      if(widget.isCreator) Positioned(
                          right: 0, top: 0,
                          child: Banner(
                              message: AppLocalizations.of(context)!.besitzer,
                              location: BannerLocation.topEnd,
                              color: Theme.of(context).colorScheme.secondary
                          ))
                    ],
                  )),
            ),
            Container(
                padding: EdgeInsets.only(top: 10 * sizeRefactor, left: 5, right: 5),
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
                            fontSize: fontSize + 1,
                        color: Colors.black)),
                    SizedBox(height: 10 * sizeRefactor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.community["ort"],
                            style: TextStyle(fontSize: fontSize, color: Colors.black))
                      ],
                    ),
                    const SizedBox(height: 2.5),
                    if (widget.community["ort"] != widget.community["land"])
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(LocationService().transformCountryLanguage(widget.community["land"], showOnlyEnglisch: !systemIsGerman, showOnlyGerman: systemIsGerman),
                              style: TextStyle(fontSize: fontSize, color: Colors.black))
                        ],
                      ),
                  ],
                ))
          ],
        ));
  }
}