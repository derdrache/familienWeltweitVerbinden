import 'dart:convert';

import 'package:familien_suche/widgets/dialogWindow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../functions/upload_and_save_image.dart';
import '../../../global/custom_widgets.dart';
import '../../../services/database.dart';

class MeetupImageGalerie extends StatefulWidget {
  var isCreator;
  var meetupData;
  var child;

  MeetupImageGalerie({Key key, this.child, this.isCreator, this.meetupData})
      : super(key: key);

  @override
  _ImageMeetupGalerieState createState() => _ImageMeetupGalerieState();
}

class _ImageMeetupGalerieState extends State<MeetupImageGalerie> {
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
    var oldImage = widget.meetupData["bild"];

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

    updateHiveMeetup(widget.meetupData["id"], "bild", selectedImage);

    setState(() {
      imageLoading = false;
    });

    DbDeleteImage(oldImage);

    MeetupDatabase().update(
        "bild = '$selectedImage'", "WHERE id = '${widget.meetupData["id"]}'");
  }

  @override
  Widget build(BuildContext context) {
    bool isAssetImage =
        widget.meetupData["bild"].substring(0, 5) == "asset" ? true : false;
    double screenHeight = MediaQuery.of(context).size.height;

    showImages() {
      List<Widget> allImages = [];

      for (var image in imagePaths) {

        allImages.add(InkWell(
          child: Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  border: Border.all(
                      width: selectedImage == image ? 3 : 1,
                      color: selectedImage == image
                          ? Colors.green
                          : Colors.black)),
              child: Image.asset(image,
                  fit: BoxFit.fill, width: 80, height: 60)),
          onTap: () {
            selectedImage = image;
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
                title: AppLocalizations.of(context).meetupBildAendern,
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
              title: AppLocalizations.of(context).meetupBildAendern,
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
              onTap: () async {
                var newImage = await uploadAndSaveImage(context, "meetup",
                    meetupCommunityData: widget.meetupData);
                setState(() {
                  widget.meetupData["bild"] = newImage[0];
                });

                //MeetupDatabase().update("bild = '${newImage[0]}'", "WHERE id = '${widget.meetupData["id"]}'");
              }),
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
                  child: Column(
                  children: [
                    Container(
                        margin: const EdgeInsets.all(10),
                        width: 80,
                        height: 80,
                        child: const CircularProgressIndicator()),
                    Center(
                        child: Text(AppLocalizations.of(context).bildLadezeit))
                  ],
                ))
              : ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                  child: isAssetImage
                      ? Image.asset(widget.meetupData["bild"],
                          fit: BoxFit.fitWidth)
                      : Container(
                          constraints:
                              BoxConstraints(maxHeight: screenHeight / 2.08),
                          child: Image.network(
                            widget.meetupData["bild"],
                          ))),
        ),
        onTapDown: !widget.isCreator
            ? null
            : (details) {
                var getTabPostion = details.globalPosition;
                _showChangeImagePopupMenu(getTabPostion);
              });
  }
}
