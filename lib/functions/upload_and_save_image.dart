import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../auth/secrets.dart';
import '../global/global_functions.dart';
import '../services/database.dart';

uploadAndSaveImage(context, typ, {folder = "",meetupCommunityData}) async{
    var ownProfil = Hive.box("secureBox").get("ownProfil");
    var imageData = await pickImage(ownProfil, meetupCommunityData);
    var imageName = imageData["name"];
    imageName = imageName.replaceAll("/", "_");
    imageName = sanitizeString(imageName);

    var imageSavePath = bilderPath + folder + imageName;
    var imageList = [imageSavePath];

    if(imageData == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageData["path"],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: AppLocalizations.of(context)!.bildBearbeiten,
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
        ),
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    await uploadFile(imageName, await croppedFile?.readAsBytes(), folder);

    if (typ == "profil") {
      saveDBProfil(imageList, ownProfil);
    } else if (typ == "meetup") {
      saveDBMeetup(imageList, meetupCommunityData);
    } else if (typ == "community") {
      saveDBCommunity(imageList, meetupCommunityData);
    }

    return imageList;
  }

pickImage(profil, meetupCommunityData) async{
  var userName = meetupCommunityData == null ? profil["name"] : meetupCommunityData["name"];
  var pickedImage = await ImagePicker()
      .pickImage(source: ImageSource.gallery, imageQuality: 50);

  if (pickedImage == null) return;

  var imageByte = await changeImageSize(pickedImage);


  return {
    "name" : userName + pickedImage.name,
    "path": pickedImage.path,
    "byte": imageByte
  };
}

saveDBProfil(imageList, ownProfil) {
  if (ownProfil["bild"].isNotEmpty) dbDeleteImage(ownProfil["bild"][0]);

  updateHiveOwnProfil("bild", imageList);
  ProfilDatabase().updateProfil("bild = '${json.encode(imageList)}'",
      "WHERE id = '${ownProfil["id"]}'");
}

saveDBMeetup(imageList, meetupData) {
  var oldImage = meetupData["bild"];
  dbDeleteImage(oldImage);

  updateHiveMeetup(meetupData["id"], "bild", imageList[0]);
  MeetupDatabase().update("bild = '${imageList[0]}'",
      "WHERE id = '${meetupData["id"]}'");
}

saveDBCommunity(imageList, communityData) {
  var oldImage = communityData["bild"];
  dbDeleteImage(oldImage);

  updateHiveCommunity(communityData["id"], "bild", imageList[0]);
  CommunityDatabase().update("bild = '${imageList[0]}'",
      "WHERE id = '${communityData["id"]}'");
}