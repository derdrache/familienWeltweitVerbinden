import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../global/global_functions.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_like_button.dart';
import 'location_details/information_main.dart';

class LocationCard extends StatefulWidget {
  final Map location;
  final bool fromCityPage;
  final bool smallCard;
  final Function? afterLike;

  const LocationCard(
      {Key? key,
      required this.location,
      this.fromCityPage = false,
      this.smallCard = false,
      this.afterLike})
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

  @override
  Widget build(BuildContext context) {
    double sizeRefactor = widget.smallCard ? 0.5 : 1;
    hasInterest = widget.location["interesse"].contains(userId);

    cityLayout() {
      return Container(
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
                color: Colors.white.withOpacity(0.7),
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
      return Column(
        children: [
          Container(
            width: 150 * sizeRefactor,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey))
            ),
            constraints: BoxConstraints(
              maxHeight: 80 * sizeRefactor,
            ),
            child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15)),
                child: Image(
                  image: getLocationImageWidget(),
                  fit: BoxFit.fitWidth,
                )),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(5),
                child: Text(
                  widget.location["ort"],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                      fontSize: 20 * sizeRefactor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CustomCard(
      sizeRefactor: sizeRefactor,
      width: 150,
      height: 200,
      margin: const EdgeInsets.all(15),
      likeButton: CustomLikeButton(
        locationData: widget.location,
        afterLike: widget.afterLike,
      ),
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        changePage(
            context,
            LocationInformationPage(
                ortName: widget.location["ort"],
                ortLatt: widget.location["latt"] + 0.0,
                fromCityPage: widget.fromCityPage));
      } ,
      child: isCity ? cityLayout() : countryLayout(),
    );
  }
}
