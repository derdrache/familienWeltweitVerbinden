import 'dart:convert';

import 'package:familien_suche/widgets/dialogWindow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as image_pack;

import '../global/custom_widgets.dart';
import '../services/database.dart';

class ImageGalerie extends StatefulWidget {
  var isCreator;
  var event;
  var child;

  ImageGalerie({Key key, this.child, this.isCreator, this.event})
      : super(key: key);

  @override
  _ImageGalerieState createState() => _ImageGalerieState();
}

class _ImageGalerieState extends State<ImageGalerie> {
  var isWebDesktop = kIsWeb &&
      (defaultTargetPlatform != TargetPlatform.iOS ||
          defaultTargetPlatform != TargetPlatform.android);
  double fontsize;
  List<Widget> allImages = [];
  var ownPictureKontroller = TextEditingController();
  var selectedImage = "";
  var windowSetState;
  var imagePaths;
  var imageLoading = false;

  @override
  void initState() {
    fontsize = isWebDesktop ? 12 : 16;

    _initImages();

    super.initState();
  }

  Future _initImages() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    imagePaths = manifestMap.keys
        .where((String key) => key.contains('assets/bilder/'))
        .where((String key) => key.contains('.jpg'))
        .toList();

    setState(() {});
  }

  saveChanges() {
    var oldImage = widget.event["bild"];

    if (selectedImage == "" && ownPictureKontroller.text == "") {
      customSnackbar(context, AppLocalizations.of(context).bitteBildAussuchen);
      return;
    }

    if (selectedImage == "") {
      selectedImage = ownPictureKontroller.text;
      widget.child = Image.network(selectedImage, fit: BoxFit.fitWidth);
    } else {
      widget.child = Image.asset(selectedImage, fit: BoxFit.fitWidth);
    }

    setState(() {
      imageLoading = false;
    });

    dbDeleteImage(oldImage);

    EventDatabase().update(
        "bild = '$selectedImage'", "WHERE id = '${widget.event["id"]}'");
  }

  pickAndUploadImage() async {
    var eventName = widget.event["name"] + "_";
    var pickedImage = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);

    setState(() {
      imageLoading = true;
    });

    var imageName = eventName + pickedImage.name;

    if (pickedImage == null) {
      customSnackbar(context, "Datei ist besch??digt");
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
    var minPixel = 1000;
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
    var imageJpgByte = image_pack.encodeJpg(imageResizeThumbnail, quality: 20);

    return imageJpgByte;
  }

  selectAndUploadImage() async {
    var imageName = await pickAndUploadImage();

    if (imageName == false) return;

    ownPictureKontroller.text =
        "https://families-worldwide.com/bilder/" + imageName;

    saveChanges();
  }

  @override
  Widget build(BuildContext context) {
    showImages() {
      List<Widget> allImages = [];

      for (var image in imagePaths) {
        var imageDecode = Uri.decodeComponent(image);

        allImages.add(InkWell(
          child: Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  border: Border.all(
                      width: selectedImage == imageDecode ? 3 : 1,
                      color: selectedImage == imageDecode
                          ? Colors.green
                          : Colors.black)),
              child: Image.asset(imageDecode,
                  fit: BoxFit.fill, width: 80, height: 60)),
          onTap: () {
            selectedImage = imageDecode;
            windowSetState(() {});
          },
        ));
      }

      return Wrap(
        children: allImages,
      );
    }

    ownLinkInput() {
      return SizedBox(
          width: 200,
          child: customTextInput(
              AppLocalizations.of(context).eigenesBildLinkEingeben,
              ownPictureKontroller, onSubmit: () {
            allImages.add(Image.network(ownPictureKontroller.text,
                fit: BoxFit.fill, width: 80, height: 60));

            ownPictureKontroller.clear();
            windowSetState(() {});
          }));
    }

    windowOptions() {
      return Container(
        margin: const EdgeInsets.only(right: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
            child: Text(AppLocalizations.of(context).abbrechen,
                style: TextStyle(fontSize: fontsize)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
              child: Text(AppLocalizations.of(context).speichern,
                  style: TextStyle(fontSize: fontsize)),
              onPressed: () {
                saveChanges();
                Navigator.pop(context);
              }),
        ]),
      );
    }

    windowChangeImageToPredetermined() async {
      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return StatefulBuilder(builder: (context, setState) {
              windowSetState = setState;
              return CustomAlertDialog(
                title: AppLocalizations.of(context).eventBildAendern,
                children: [
                  showImages(),
                  const SizedBox(height: 20),
                  windowOptions()
                ],
              );
            });
          });
    }

    windowChangeImageWithLink() async {
      return await showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).eventBildAendern,
              children: [
                ownLinkInput(),
                const SizedBox(height: 20),
                windowOptions()
              ],
            );
          });
    }

    _showChangeImagePopupMenu(tabPosition) async {
      final RenderBox overlay = Overlay.of(context).context.findRenderObject();

      await showMenu(
        context: context,
        position: RelativeRect.fromRect(
            tabPosition & const Size(40, 40), // smaller rect, the touch area
            Offset.zero & overlay.size // Bigger rect, the entire screen
            ),
        items: [
          PopupMenuItem(
              child: Text(AppLocalizations.of(context).bilderauswahl),
              onTap: () {
                Future.delayed(const Duration(seconds: 0),
                    () => windowChangeImageToPredetermined());
              }),
          PopupMenuItem(
            child: Text(AppLocalizations.of(context).link),
            onTap: () {
              Future.delayed(const Duration(seconds: 0),
                  () => windowChangeImageWithLink());
            },
          ),
          PopupMenuItem(
              child: Text(AppLocalizations.of(context).hochladen),
              onTap: () => selectAndUploadImage()),
        ],
        elevation: 8.0,
      );
    }

    return GestureDetector(
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 200,
          ),
          width: double.infinity,
          child: imageLoading
              ? Center(
                  child: Container(
                      margin: const EdgeInsets.all(10),
                      width: 100,
                      height: 100,
                      child: const CircularProgressIndicator()))
              : widget.child,
        ),
        onTapDown: !widget.isCreator
            ? null
            : (details) {
                var getTabPostion = details.globalPosition;
                _showChangeImagePopupMenu(getTabPostion);
              });
  }
}
