import 'package:cached_network_image/cached_network_image.dart';
import 'package:familien_suche/widgets/layout/custom_like_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../global/global_functions.dart';
import '../../../services/database.dart';
import 'location_Information.dart';

class LocationCard extends StatefulWidget {
  Map location;
  bool fromCityPage;
  bool smallCard;

  LocationCard(
      {Key? key,
      required this.location,
      this.fromCityPage = false,
      this.smallCard = false})
      : super(key: key);

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  late bool hasInterest;
  late bool isCity;

  @override
  void initState() {
    isCity = widget.location["isCity"] == 1;

    super.initState();
  }

  getLocationImageWidget() {
    if (widget.location["bild"].isEmpty) {
      if (!isCity) return const AssetImage("assets/bilder/land.jpg");
      return const AssetImage("assets/bilder/city.jpg");
    } else {
      if (!isCity) {
        return AssetImage(
            "assets/bilder/flaggen/${widget.location["bild"]}.jpeg");
      }
      return CachedNetworkImageProvider(widget.location["bild"]);
    }
  }

  Future<bool> changeIntereset(hasInterest) async {
    if (hasInterest) {
      hasInterest = false;

      widget.location["interesse"].remove(userId);
      StadtinfoDatabase().update(
          "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id = '${widget.location["id"]}'");
    } else {
      hasInterest = true;

      widget.location["interesse"].add(userId);
      StadtinfoDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id = '${widget.location["id"]}'");
    }

    setState(() {});

    return hasInterest;
  }

  @override
  Widget build(BuildContext context) {
    double sizeRefactor = widget.smallCard ? 0.5 : 1;
    hasInterest = widget.location["interesse"].contains(userId);

    cityLayout() {
      return Container(
          width: 150 * sizeRefactor,
          height: 200 * sizeRefactor,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              image: DecorationImage(
                  fit: BoxFit.fill,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.7), BlendMode.dstATop),
                  image: getLocationImageWidget())),
          child: Center(
              child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.withOpacity(0.7)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              widget.location["ort"],
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22 * sizeRefactor, fontWeight: FontWeight.bold),
            ),
          )));
    }

    countryLayout() {
      return SizedBox(
          width: 150 * sizeRefactor,
          height: 200 * sizeRefactor,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey
                  : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                SizedBox(
                  width: 150 * sizeRefactor,
                  height: 87 * sizeRefactor,
                  child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(15),
                          topLeft: Radius.circular(15)),
                      child: Image(image: getLocationImageWidget(), fit: BoxFit.fitWidth,)),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.location["ort"],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22 * sizeRefactor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ));
    }

    return GestureDetector(
      onTap: () => changePage(
          context,
          LocationInformationPage(
              ortName: widget.location["ort"],
              fromCityPage: widget.fromCityPage)),
      child: Container(
        margin: const EdgeInsets.all(15),
        child: Stack(
          children: [
            Card(
              elevation: 5,
              shadowColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: isCity ? cityLayout() : countryLayout(),
            ),
            if (!widget.smallCard)
              Positioned(
                  top: likeButtonAbstandTop + 5,
                  right: likeButtonAbstandRight,
                  child: CustomLikeButton(
                    isLiked: hasInterest,
                    onLikeButtonTapped: changeIntereset,
                  ))
          ],
        ),
      ),
    );
  }
}
