import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:like_button/like_button.dart';

import '../services/database.dart';

class CustomLikeButton extends StatefulWidget {
  Map? communityData;
  Map? meetupData;
  Map? locationData;
  Function? afterLike;

  CustomLikeButton({
    super.key,
    this.communityData,
    this.meetupData,
    this.locationData,
    this.afterLike
  });

  @override
  State<CustomLikeButton> createState() => _CustomLikeButtonState();
}

class _CustomLikeButtonState extends State<CustomLikeButton> {
  String userId = FirebaseAuth.instance.currentUser!.uid;
  late bool isLiked;

  Future<bool> changeInterest(hasInterest) async {
    isLiked = !isLiked;

    if(widget.communityData != null) updateCommunity(hasInterest);
    if(widget.meetupData != null) updateMeetup(hasInterest);
    if(widget.locationData != null) updateLocation(hasInterest);

    if (widget.afterLike != null) widget.afterLike!();

    return !hasInterest;
  }

  updateCommunity(hasInterest){
    String communityId = widget.communityData!["id"];

    if (!hasInterest) {
      widget.communityData!["interesse"].add(userId);
      CommunityDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id ='$communityId'");
    } else {
      widget.communityData!["interesse"].remove(userId);
      CommunityDatabase().update(
          "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id ='$communityId'");
    }
  }

  updateMeetup(hasInterest){
    String meetupId = widget.meetupData!["id"];

    if (!hasInterest) {
      widget.meetupData!["interesse"].add(userId);
      Hive.box('secureBox').get("interestEvents").add(widget.meetupData);
      MeetupDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id ='$meetupId'");
    } else {
      widget.meetupData!["interesse"].remove(userId);
      Hive.box('secureBox').get("interestEvents").remove(widget.meetupData);
      MeetupDatabase().update(
          "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id ='$meetupId'");
    }

  }

  updateLocation(hasInterest){
    String locationId = widget.locationData!["id"].toString();

    if (!hasInterest) {
      widget.locationData!["interesse"].add(userId);
      StadtinfoDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
          "WHERE id ='$locationId'");
    } else {
      widget.locationData!["interesse"].remove(userId);
      StadtinfoDatabase().update(
          "interesse = JSON_REMOVE(interesse, JSON_UNQUOTE(JSON_SEARCH(interesse, 'one', '$userId')))",
          "WHERE id ='$locationId'");
    }
  }

  updateIsLike(){
    if(widget.communityData!= null){
      isLiked = widget.communityData!["interesse"].contains(userId);
    }else if(widget.meetupData!= null){
      isLiked = widget.meetupData!["interesse"].contains(userId);
    }else if(widget.locationData!= null){
      isLiked = widget.locationData!["interesse"].contains(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    updateIsLike();

    return LikeButton(
      isLiked: isLiked,
      likeBuilder: (bool hasIntereset) {
        return Icon(
          Icons.favorite,
          color: hasIntereset ? Colors.red : Colors.black,
          size: 26,
        );
      },
      onTap: changeInterest,
    );
  }
}
