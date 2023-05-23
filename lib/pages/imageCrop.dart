import 'dart:convert';

import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/global_functions.dart';
import '../services/database.dart';
import '../widgets/loading_button.dart';

class ImageCrop extends StatefulWidget {
  var imageData;
  var typ;
  var meetupCommunityData;

  ImageCrop({Key key, this.imageData, this.typ, this.meetupCommunityData})
      : super(key: key);

  @override
  State<ImageCrop> createState() => _ImageCropState();
}

class _ImageCropState extends State<ImageCrop> {
  final _controller = CropController();
  Map onwProfil = Hive.box("secureBox").get("ownProfil");
  bool isLoading = false;

  _save(image) async {
    widget.imageData["byte"] = image;

    var imageList = await uploadAndDeleteOldImage();

    if (widget.typ == "profil") {
      saveDBProfil(imageList);
    } else if (widget.typ == "meetup") {
      saveDBMeetup(imageList);
    } else if (widget.typ == "community") {
      saveDBCommunity(imageList);
    }
  }

  uploadAndDeleteOldImage() async {
    var imageName = widget.imageData["name"];
    imageName = sanitizeString(imageName);
    var imageSavePath = "https://families-worldwide.com/bilder/" + imageName;
    var imageList = [imageSavePath];

    await uploadImage(
        widget.imageData["path"], imageName, widget.imageData["byte"]);

    if (onwProfil["bild"].isNotEmpty) DbDeleteImage(onwProfil["bild"][0]);

    return imageList;
  }

  saveDBProfil(imageList) {
    if (onwProfil["bild"].isNotEmpty) DbDeleteImage(onwProfil["bild"][0]);

    updateHiveOwnProfil("bild", imageList);
    ProfilDatabase().updateProfil("bild = '${json.encode(imageList)}'",
        "WHERE id = '${onwProfil["id"]}'");
  }

  saveDBMeetup(imageList) {
    var oldImage = widget.meetupCommunityData["bild"];
    DbDeleteImage(oldImage);

    updateHiveMeetup(widget.meetupCommunityData["id"], "bild", imageList[0]);
    MeetupDatabase().update("bild = '${imageList[0]}'",
        "WHERE id = '${widget.meetupCommunityData["id"]}'");
  }

  saveDBCommunity(imageList) {
    var oldImage = widget.meetupCommunityData["bild"];
    DbDeleteImage(oldImage);

    updateHiveCommunity(widget.meetupCommunityData["id"], "bild", imageList[0]);
    CommunityDatabase().update("bild = '${imageList[0]}'",
        "WHERE id = '${widget.meetupCommunityData["id"]}'");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations
              .of(context)
              .bildBearbeiten,
          buttons: [
            isLoading
                ? LoadingButton()
                : IconButton(onPressed: () async {
                    _controller.crop();
                  }, icon: const Icon(Icons.done))
          ],
        ),
        body: Crop(
          image: widget.imageData["byte"],
          controller: _controller,
          onCropped: (image) async {
            setState(() {
              isLoading = true;
            });

            await _save(image);

            setState(() {
              isLoading = false;
            });

            Navigator.pop(context);
          },
        )
    );
  }
}
