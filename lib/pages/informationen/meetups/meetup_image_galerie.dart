import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:familien_suche/widgets/windowConfirmCancelBar.dart';
import 'package:familien_suche/windows/dialog_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../functions/upload_and_save_image.dart';
import '../../../services/database.dart';
import '../../../widgets/layout/custom_snackbar.dart';
import '../../../widgets/layout/custom_text_input.dart';

class MeetupImageGalerie extends StatefulWidget {
  bool isCreator;
  Map meetupData;
  Widget? child;

  MeetupImageGalerie({Key? key, this.child, required this.isCreator, required this.meetupData})
      : super(key: key);

  @override
  State<MeetupImageGalerie> createState() => _ImageMeetupGalerieState();
}

class _ImageMeetupGalerieState extends State<MeetupImageGalerie> {
  var isWebDesktop = kIsWeb &&
      (defaultTargetPlatform != TargetPlatform.iOS ||
          defaultTargetPlatform != TargetPlatform.android);
  double? fontsize;
  List<Widget> allImages = [];
  var ownPictureKontroller = TextEditingController();
  var selectedImage = "";
  var windowSetState;
  late List imagePaths;
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
      customSnackBar(context, AppLocalizations.of(context)!.bitteBildAussuchen);
      return;
    }

    if (selectedImage == "") {
      selectedImage = ownPictureKontroller.text;
      widget.child =
          CachedNetworkImage(imageUrl: selectedImage, fit: BoxFit.fitWidth);
    } else {
      widget.child = Image.asset(selectedImage, fit: BoxFit.fitWidth);
    }

    updateHiveMeetup(widget.meetupData["id"], "bild", selectedImage);

    setState(() {
      imageLoading = false;
    });

    dbDeleteImage(oldImage);

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
              child:
                  Image.asset(image, fit: BoxFit.fill, width: 80, height: 60)),
          onTap: () {
            selectedImage = image;
            windowSetState(() {});
          },
        ));
      }

      return Wrap(
        alignment: WrapAlignment.center,
        children: allImages,
      );
    }

    ownLinkInput() {
      return SizedBox(
          width: 200,
          child: CustomTextInput(
              AppLocalizations.of(context)!.eigenesBildLinkEingeben,
              ownPictureKontroller, onSubmit: () {
            allImages.add(CachedNetworkImage(
                imageUrl: ownPictureKontroller.text,
                fit: BoxFit.fill,
                width: 80,
                height: 60));

            ownPictureKontroller.clear();
            windowSetState(() {});
          }));
    }

    windowChangeImageToPredetermined() async {
      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return StatefulBuilder(builder: (context, setState) {
              windowSetState = setState;
              return CustomAlertDialog(
                title: AppLocalizations.of(context)!.meetupBildAendern,
                children: [
                  showImages(),
                  const SizedBox(height: 20),
                  WindowConfirmCancelBar(
                    onConfirm: () => saveChanges(),
                  )
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
              title: AppLocalizations.of(context)!.meetupBildAendern,
              children: [
                ownLinkInput(),
                const SizedBox(height: 20),
                WindowConfirmCancelBar(
                  onConfirm: () => saveChanges(),
                )
              ],
            );
          });
    }

    showChangeImagePopupMenu(tabPosition) async {
      final RenderBox overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;

      await showMenu(
        context: context,
        position: RelativeRect.fromRect(
            tabPosition & const Size(40, 40), // smaller rect, the touch area
            Offset.zero & overlay.size // Bigger rect, the entire screen
            ),
        items: [
          PopupMenuItem(
              child: Text(AppLocalizations.of(context)!.bilderauswahl),
              onTap: () {
                Future.delayed(const Duration(seconds: 0),
                    () => windowChangeImageToPredetermined());
              }),
          PopupMenuItem(
            child: Text(AppLocalizations.of(context)!.link),
            onTap: () {
              Future.delayed(const Duration(seconds: 0),
                  () => windowChangeImageWithLink());
            },
          ),
          PopupMenuItem(
              child: Text(AppLocalizations.of(context)!.hochladen),
              onTap: () async {
                var newImage = await uploadAndSaveImage(context, "meetup",
                    meetupCommunityData: widget.meetupData);
                setState(() {
                  widget.meetupData["bild"] = newImage[0];
                });
              }),
        ],
        elevation: 8.0,
      );
    }

    return GestureDetector(
        onTapDown: !widget.isCreator
            ? null
            : (details) {
                var getTabPostion = details.globalPosition;
                showChangeImagePopupMenu(getTabPostion);
              },
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
                        child: Text(AppLocalizations.of(context)!.bildLadezeit))
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
                          child: CachedNetworkImage(
                            imageUrl: widget.meetupData["bild"],
                          ))),
        ));
  }
}
