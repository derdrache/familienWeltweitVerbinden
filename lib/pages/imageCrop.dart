import 'dart:convert';

import 'package:familien_suche/pages/start_page.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:hive/hive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/global_functions.dart';
import '../services/database.dart';

class ImageCrop extends StatefulWidget {
  var imageData;

  ImageCrop({Key key, this.imageData}) : super(key: key);

  @override
  State<ImageCrop> createState() => _ImageCropState();
}

class _ImageCropState extends State<ImageCrop> {
  final _controller = CropController();
  Map onwProfil = Hive.box("secureBox").get("ownProfil");

  saveAndUploadImage() async{
    var imageName = widget.imageData["name"];
    imageName = sanitizeString(imageName);
    var imageSavePath = "https://families-worldwide.com/bilder/" + imageName;
    var imageList = [imageSavePath];

    await uploadImage(widget.imageData["path"], imageName, widget.imageData["byte"]);


    if (onwProfil["bild"].isNotEmpty) DbDeleteImage(onwProfil["bild"][0]);


    updateHiveOwnProfil("bild", imageList);
    await ProfilDatabase().updateProfil("bild = '${json.encode(imageList)}'",
        "WHERE id = '${onwProfil["id"]}'");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).bildBearbeiten,
        buttons: [
          IconButton(onPressed: () async{
            _controller.crop();
          }, icon: Icon(Icons.done))
        ],
      ),
      body: Crop(
        image: widget.imageData["byte"],
        controller: _controller,
        onCropped: (image) async {
          widget.imageData["byte"] = image;

          await saveAndUploadImage();
          changePageForever(context, StartPage(selectedIndex: 4,));
        },
      )
    );
  }
}
