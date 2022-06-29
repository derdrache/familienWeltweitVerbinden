import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../global/custom_widgets.dart';
import '../services/database.dart';
import 'dialogWindow.dart';

class ProfilImage extends StatefulWidget {
  var profil;
  var changeable;
  var fullScreenWindow;

  ProfilImage(this.profil,
      {Key key, this.changeable = false, this.fullScreenWindow = false}) : super(key: key);

  @override
  _ProfilImageState createState() => _ProfilImageState();
}

class _ProfilImageState extends State<ProfilImage> {
  var profilImageLinkKontroller = TextEditingController();

  checkAndSaveImage() {
    dynamic newLink = profilImageLinkKontroller.text;

    if (newLink.isEmpty) {
      newLink = [];
    } else if (newLink.substring(0, 4) != "http" &&
        newLink.substring(0, 3) != "www") {
      customSnackbar(context, "ungültiger Link");
    } else {
      newLink = [newLink];
    }

    setState(() {
      widget.profil["bild"] = newLink;
    });

    ProfilDatabase().updateProfil("bild = '${json.encode(newLink)}'",
        "WHERE id = '${widget.profil["id"]}'");

    Navigator.pop(context);
  }

  pickAndUploadImage() async {
    var userName = FirebaseAuth.instance.currentUser.displayName;
    var pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    var imageByte = await pickedImage.readAsBytes();
    var imageNameEndung = pickedImage.name.split(".").last;

    uploadImage(userName+"." + imageNameEndung, imageByte);


  }

  @override
  Widget build(BuildContext context) {
    var profilImageWidget =
        widget.profil["bild"] == null || widget.profil["bild"].isEmpty
            ? DefaultProfilImage(widget.profil)
            : OwnProfilImage(widget.profil,
                fullScreenWindow: widget.fullScreenWindow);

    changeImageWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).profilbildAendern,
              children: [
                customTextInput(
                    AppLocalizations.of(context).linkProfilbildEingeben,
                    profilImageLinkKontroller)
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
                child: InkWell(
                    onTap: () => changeImageWindow(),
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

  OwnProfilImage(this.profil, {Key key, this.fullScreenWindow}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    showBigImage() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                backgroundColor: Colors.transparent,
                content: Image.network(profil["bild"][0])
            );
          });
    }

    return InkWell(
        onTap: fullScreenWindow ? () => showBigImage() : null,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: profil["bild"][0].contains("http") ? CachedNetworkImage(
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                imageUrl: profil["bild"][0],
                placeholder: (context, url) => Container(
                      color: Colors.black12,
                    )
                ) : Image.asset(
                profil["bild"][0],
                width: 60,
                height: 60,
                fit: BoxFit.cover
            )
        )
    );
  }
}
