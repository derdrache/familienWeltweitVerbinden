import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as image_pack;

import '../global/custom_widgets.dart';
import '../services/database.dart';
import 'dialogWindow.dart';

class ProfilImage extends StatefulWidget {
  var profil;
  var changeable;
  var fullScreenWindow;

  ProfilImage(this.profil,
      {Key key, this.changeable = false, this.fullScreenWindow = false})
      : super(key: key);

  @override
  _ProfilImageState createState() => _ProfilImageState();
}

class _ProfilImageState extends State<ProfilImage> {
  var profilImageLinkKontroller = TextEditingController();

  checkAndSaveImage() {
    dynamic newLink = profilImageLinkKontroller.text;

    if (newLink.isEmpty) {
      newLink = [];
      return;
    } else if (newLink.substring(0, 4) != "http" &&
        newLink.substring(0, 3) != "www") {
      customSnackbar(context, AppLocalizations.of(context).ungueltigerLink);
      return;
    } else {
      newLink = [newLink];
    }

    if (widget.profil["bild"].isNotEmpty) {
      deleteOldImage(widget.profil["bild"][0]);
    }

    setState(() {
      widget.profil["bild"] = newLink;
    });

    ProfilDatabase().updateProfil("bild = '${json.encode(newLink)}'",
        "WHERE id = '${widget.profil["id"]}'");
  }

  deleteOldImage(oldLink) {
    dbDeleteImage(oldLink);
  }

  pickAndUploadImage() async {
    var userName = FirebaseAuth.instance.currentUser.displayName;
    var pickedImage = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);

    var imageName = userName + pickedImage.name;

    if (pickedImage == null) {
      customSnackbar(context, "Datei ist beschädigt");
      return false;
    }

    var imageByte = await changeImageSize(pickedImage);

    await uploadImage(pickedImage.path, imageName, imageByte);

    return imageName;
  }

  changeImageSize(pickedImage) async {
    var imageByte = image_pack.decodeImage(await pickedImage.readAsBytes());
    var originalWidth = imageByte.width;
    var originalHeight = imageByte.height;
    var minPixel = 400;
    var newWidth = 0;
    var newHeight = 0;

    if (originalWidth > originalHeight) {
      var factor = originalWidth / originalHeight;
      newHeight = minPixel;
      newWidth = (minPixel * factor).round();
    } else {
      var factor = originalHeight / originalWidth;
      newWidth = minPixel;
      newHeight = (minPixel * factor).round();
    }

    var imageResizeThumbnail =
        image_pack.copyResize(imageByte, width: newWidth, height: newHeight);
    var imageJpgByte = image_pack.encodeJpg(imageResizeThumbnail, quality: 25);

    return imageJpgByte;
  }

  deleteProfilImage() async {
    deleteOldImage(widget.profil["bild"][0]);

    ProfilDatabase().updateProfil(
        "bild = '${json.encode([])}'", "WHERE id = '${widget.profil["id"]}'");

    setState(() {
      widget.profil["bild"] = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    var profilImageWidget =
        widget.profil["bild"] == null || widget.profil["bild"].isEmpty
            ? DefaultProfilImage(widget.profil)
            : OwnProfilImage(widget.profil,
                fullScreenWindow: widget.fullScreenWindow);

    changeImageWindow() async {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).profilbildAendern,
              children: [
                customTextInput(
                    AppLocalizations.of(context).linkProfilbildEingeben,
                    profilImageLinkKontroller),
              ],
              actions: [
                TextButton(
                  child: Text(AppLocalizations.of(context).speichern),
                  onPressed: () => checkAndSaveImage(),
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context).abbrechen),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            );
          });
    }

    _showPopupMenu(tabPosition) async {
      final RenderBox overlay = Overlay.of(context).context.findRenderObject();

      await showMenu(
        context: context,
        position: RelativeRect.fromRect(
            tabPosition & const Size(40, 40), // smaller rect, the touch area
            Offset.zero & overlay.size // Bigger rect, the entire screen
            ),
        items: [
          PopupMenuItem(
              child: Text(AppLocalizations.of(context).link),
              onTap: () => Future.delayed(
                  const Duration(seconds: 0), () => changeImageWindow())),
          PopupMenuItem(
            child: Text(AppLocalizations.of(context).hochladen),
            onTap: () async {
              var imageName = await pickAndUploadImage();

              if (imageName == false) return;
              profilImageLinkKontroller.text =
                  "https://families-worldwide.com/bilder/" + imageName;
              checkAndSaveImage();
            },
          ),
          if (widget.profil["bild"].isNotEmpty)
            PopupMenuItem(
                child: Text(AppLocalizations.of(context).loeschen),
                onTap: () {
                  deleteProfilImage();
                })
        ],
        elevation: 8.0,
      );
    }

    return Container(
      width: widget.changeable ? 65 : null,
      height: widget.changeable ? 65 : null,
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          profilImageWidget,
          if (widget.changeable)
            Positioned(
                bottom: -3,
                right: -3,
                child: GestureDetector(
                    onTapDown: (details) {
                      var getTabPostion = details.globalPosition;
                      _showPopupMenu(getTabPostion);
                    },
                    child: const Icon(Icons.change_circle)))
        ],
      ),
    );
  }
}

class DefaultProfilImage extends StatelessWidget {
  var profil;

  DefaultProfilImage(this.profil, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var symbols =
        "QWERTZUIOPÜASDFGHJKLÖÄYXCVBNMqwertzuiopüasdfghjklöäyxcvbnm1234567890ß";
    var nameToList = profil["name"].split(" ");
    var imageText = "";

    for (var letter in nameToList[0].split("")) {
      if (symbols.contains(letter)) {
        imageText = letter;
        break;
      }
    }

    if (nameToList.length > 1) {
      for (var letter in nameToList.last.split("")) {
        if (symbols.contains(letter)) {
          imageText += letter;
          break;
        }
      }
    }

    if (profil["bildStandardFarbe"] == null) {
      var colorList = [
        Colors.blue,
        Colors.red,
        Colors.orange,
        Colors.green,
        Colors.purple,
        Colors.pink,
        Colors.greenAccent
      ];
      var selectColor = (colorList..shuffle()).first.value;
      profil["bildStandardFarbe"] = selectColor;

      ProfilDatabase().updateProfil(
          "bildStandardFarbe = '$selectColor'", "WHERE id = '${profil["id"]}'");
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: Color(profil["bildStandardFarbe"]),
      child: Center(
          child: Text(
        imageText.toUpperCase(),
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      )),
    );
  }
}

class OwnProfilImage extends StatelessWidget {
  var profil;
  var fullScreenWindow;

  OwnProfilImage(this.profil, {Key key, this.fullScreenWindow})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    showBigImage() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                backgroundColor: Colors.transparent,
                content: Image.network(profil["bild"][0]));
          });
    }

    return InkWell(
        onTap: fullScreenWindow ? () => showBigImage() : null,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: profil["bild"][0].contains("http")
                ? CachedNetworkImage(
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    imageUrl: profil["bild"][0],
                    placeholder: (context, url) => Container(
                          color: Colors.black12,
                        ))
                : Image.asset(profil["bild"][0],
                    width: 60, height: 60, fit: BoxFit.cover)));
  }
}
