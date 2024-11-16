import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../functions/upload_and_save_image.dart';
import '../global/global_functions.dart';
import '../global/style.dart' as style;
import '../services/database.dart';
import '../windows/dialog_window.dart';
import 'layout/custom_snackbar.dart';
import 'layout/custom_text_input.dart';
import 'windowConfirmCancelBar.dart';

class ProfilImage extends StatefulWidget {
  Map profil;
  bool changeable;
  bool fullScreenWindow;
  bool onlyFullScreen;
  double size;
  Function? onTab;

  ProfilImage(this.profil,
      {Key? key,
      this.changeable = false,
      this.fullScreenWindow = false,
      this.onlyFullScreen = true,
      this.onTab,
      this.size = 30})
      : super(key: key);

  @override
  State<ProfilImage> createState() => _ProfilImageState();
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
      customSnackBar(context, AppLocalizations.of(context)!.ungueltigerLink);
      return;
    } else {
      newLink = [newLink];
    }

    if (widget.profil["bild"].isNotEmpty) {
      deleteOldImage(widget.profil["bild"][0]);
    }

    newLink[0] = sanitizeString(newLink[0]);

    widget.profil["bild"] = newLink;

    ProfilDatabase().updateProfil("bild = '${json.encode(newLink)}'",
        "WHERE id = '${widget.profil["id"]}'");
  }

  deleteOldImage(oldLink) {
    dbDeleteImage(oldLink);
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
            ? DefaultProfilImage(widget.profil, widget.size)
            : OwnProfilImage(
                widget.profil,
                fullScreenWindow: widget.fullScreenWindow,
                size: widget.size,
              );

    changeImageWindow() async {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context)!.profilbildAendern,
              children: [
                CustomTextInput(
                    AppLocalizations.of(context)!.linkProfilbildEingeben,
                    profilImageLinkKontroller),
                WindowConfirmCancelBar(
                  onConfirm: () => checkAndSaveImage(),
                )
              ],
            );
          });
    }

    showBigImage() {
      if (widget.profil["bild"] == null || widget.profil["bild"].contains("worldChat")
          || widget.profil["bild"].isEmpty) return;

      var image = widget.profil["bild"] is String ? widget.profil["bild"] : widget.profil["bild"][0];
      bool isUrl = image.contains("http");

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                insetPadding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                content: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(style.roundedCorners),
                      child: isUrl
                          ? CachedNetworkImage(imageUrl: image)
                          : Image.asset(image),
                    ),
                    Positioned(
                      height: 30,
                      right: -13,
                      top: -7,
                      child: InkResponse(
                          onTap: () => Navigator.pop(context),
                          child: const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.close,
                              size: 16,
                            ),
                          )),
                    )
                  ],
                ));
          });
    }

    showPopupMenu(tabPosition) async {
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;

      await showMenu(
        context: context,
        position: RelativeRect.fromRect(
            tabPosition & const Size(40, 40), // smaller rect, the touch area
            Offset.zero & overlay.size // Bigger rect, the entire screen
            ),
        items: [
          if (widget.profil["bild"].isNotEmpty)
          PopupMenuItem(
                child: Text(AppLocalizations.of(context)!.showFull),
                onTap: () => Future.delayed(
                    const Duration(seconds: 0), () => showBigImage()
                )),
          PopupMenuItem(
              child: Text(AppLocalizations.of(context)!.link),
              onTap: () => Future.delayed(
                  const Duration(seconds: 0), () => changeImageWindow()
              )),
          PopupMenuItem(
            child: Text(AppLocalizations.of(context)!.hochladen),
            onTap: () async {
              var newImage = await uploadAndSaveImage(context, "profil");

              setState(() {
                widget.profil["bild"] = newImage;
              });
            },
          ),
          if (widget.profil["bild"].isNotEmpty)
            PopupMenuItem(
                child: Text(AppLocalizations.of(context)!.loeschen),
                onTap: () {
                  deleteProfilImage();
                })
        ],
        elevation: 8.0,
      );
    }

    return Container(
      color: Colors.transparent,
      child: GestureDetector(
          onTapDown: (details) {
            var getTabPostion = details.globalPosition;

            if(widget.onTab != null){
              widget.onTab!();
              return;
            }


            if(widget.onlyFullScreen){
              showBigImage();
            }else{
              showPopupMenu(getTabPostion);
            }

          },
          child: profilImageWidget
      ),
    );
  }
}

class DefaultProfilImage extends StatelessWidget {
  Map profil;
  double size;

  DefaultProfilImage(this.profil, this.size, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var symbols =
        "QWERTZUIOPÜASDFGHJKLÖÄYXCVBNMqwertzuiopüasdfghjklöäyxcvbnm1234567890ß";
    var nameToList = profil["name"]?.split(" ") ?? ["Delete"];
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
    if(profil["name"] == "delete"){
      profil["bildStandardFarbe"] = Colors.red[900]!.value;
      imageText = "X";
    } else if (profil["bildStandardFarbe"] == null && profil.isNotEmpty) {
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

    return profil.isEmpty
        ? ImageCircleAvatar(
            size: size,
            childBackgroundColor: Colors.black,
            child: Center(
                child: Text(
              "X",
              style: TextStyle(
                  fontSize: size / 1.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            )))
        : ImageCircleAvatar(
            size: size,
            childBackgroundColor: Color(profil["bildStandardFarbe"]),
            child: Center(
                child: Text(
              imageText.toUpperCase(),
              style: TextStyle(
                  fontSize: size / 1.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            )),
          );
  }
}

class OwnProfilImage extends StatelessWidget {
  Map profil;
  bool fullScreenWindow;
  double size;

  OwnProfilImage(this.profil,
      {Key? key, this.fullScreenWindow = false, required this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var image = profil["bild"] is String ? profil["bild"] : profil["bild"][0];
    bool isUrl = image.contains("http");

    return Padding(
      padding: EdgeInsets.zero,
      child: isUrl
          ? CachedNetworkImage(
              imageUrl: image,
              imageBuilder: (context, imageProvider) => ImageCircleAvatar(
                    imageProvider: imageProvider,
                    size: size,
                  ),
              placeholder: (context, url) => Container(
                    color: Colors.black12,
                  ))
          : ImageCircleAvatar(
              imageProvider: Image.asset(image, fit: BoxFit.cover).image,
              size: size,
            ),
    );
  }
}

class ImageCircleAvatar extends StatelessWidget {
  ImageProvider? imageProvider;
  double size;
  Color? backgroundColor;
  Widget? child;
  Color? childBackgroundColor;

  ImageCircleAvatar(
      {super.key, this.imageProvider,
      required this.size,
      this.backgroundColor,
      this.child,
      this.childBackgroundColor});

  @override
  Widget build(BuildContext context) {
    Color alternativColor = Colors.white;

    return CircleAvatar(
      radius: size,
      backgroundColor: backgroundColor ?? alternativColor,
      child: CircleAvatar(
          radius: size - 3,
          backgroundColor: childBackgroundColor ?? alternativColor,
          backgroundImage: imageProvider,
          child: child),
    );
  }
}
