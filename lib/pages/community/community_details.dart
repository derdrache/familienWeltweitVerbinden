import 'dart:convert';

import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:familien_suche/global/global_functions.dart' as global_func;
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as image_pack;

import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../widgets/dialogWindow.dart';
import '../../widgets/google_autocomplete.dart';
import '../../widgets/search_autocomplete.dart';
import '../../widgets/text_with_hyperlink_detection.dart';
import '../start_page.dart';
import '../../global/variablen.dart' as global_var;

class CommunityDetails extends StatefulWidget {
  Map community;

  CommunityDetails({Key key, this.community}) : super(key: key);

  @override
  State<CommunityDetails> createState() => _CommunityDetailsState();
}

class _CommunityDetailsState extends State<CommunityDetails> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var isWebDesktop = kIsWeb &&
      (defaultTargetPlatform != TargetPlatform.iOS ||
          defaultTargetPlatform != TargetPlatform.android);
  var creatorText = "";
  Map creatorProfil;
  var ownPictureKontroller = TextEditingController();
  double fontsize;
  var windowSetState;
  List<String> imagePaths;
  String selectedImage;
  List allUserNames = [];
  List allUserIds = [];
  var searchAutocomplete = SearchAutocomplete();
  final _controller = ScrollController();
  var scrollbarOnBottom = true;
  var imageLoading = false;

  @override
  void initState() {
    _setCreatorText();
    _initImages();
    _getDBDataSetAllUserNames();

    if (!widget.community["link"].contains("http")) {
      widget.community["link"] = "http://" + widget.community["link"];
    }

    _controller.addListener(() {
      if (_controller.position.atEdge) {
        bool isTop = _controller.position.pixels == 0;
        if (isTop) {
          scrollbarOnBottom = false;
        } else {
          scrollbarOnBottom = true;
        }
        setState(() {});
      }
    });

    super.initState();
  }

  _getDBDataSetAllUserNames() async {
    var dbProfils = await ProfilDatabase().getData("name, id", "");

    for (var profil in dbProfils) {
      allUserNames.add(profil["name"]);
      allUserIds.add(profil["id"]);
    }
  }

  _setCreatorText() async {
    creatorProfil = await ProfilDatabase()
        .getData("*", "WHERE id = '${widget.community["erstelltVon"]}'");
    creatorText = creatorProfil["name"];

    setState(() {});
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

  _changeImageWindow(tabPosition) async {
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
                  () => _windowChangeImageToPredetermined());
            }),
        PopupMenuItem(
          child: Text(AppLocalizations.of(context).link),
          onTap: () {
            Future.delayed(
                const Duration(seconds: 0), () => _windowChangeImageWithLink());
          },
        ),
        PopupMenuItem(
            child: Text(AppLocalizations.of(context).hochladen),
            onTap: () => _selectAndUploadImage()),
      ],
      elevation: 8.0,
    );
  }

  _windowChangeImageToPredetermined() async {
    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(builder: (context, setState) {
            windowSetState = setState;
            return CustomAlertDialog(
              title: AppLocalizations.of(context).bildAendern,
              children: [
                _showImages(),
                const SizedBox(height: 20),
                _windowOptions(() => _saveChangeImage(null))
              ],
            );
          });
        });
  }

  _showImages() {
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

  _pickAndUploadImage() async {
    var eventName = widget.community["name"] + "_";
    var pickedImage = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedImage == null) return;

    setState(() {
      imageLoading = true;
    });

    var imageName = eventName + pickedImage.name;

    if (pickedImage == null) {
      customSnackbar(context, "Datei ist beschädigt");
      return false;
    }

    var imageByte = await _changeImageSize(pickedImage);

    await uploadImage(pickedImage.path, imageName, imageByte);

    return imageName;
  }

  _changeImageSize(pickedImage) async {
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

  _selectAndUploadImage() async {
    var imageName = await _pickAndUploadImage();
    var oldImage = widget.community["bild"];

    if (imageName == false) return;

    var image = "https://families-worldwide.com/bilder/" + imageName;
    _saveChangeImage(image);

    DbDeleteImage(oldImage);
  }

  _windowChangeImageWithLink() async {
    return await showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).bildAendern,
            children: [
              SizedBox(
                  width: 200,
                  child: customTextInput(
                      AppLocalizations.of(context).eigenesBildLinkEingeben,
                      ownPictureKontroller)),
              const SizedBox(height: 20),
              _windowOptions(() => _saveChangeImage(ownPictureKontroller.text))
            ],
          );
        });
  }

  _windowOptions(saveFunction) {
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
              saveFunction();
              Navigator.pop(context);
            }),
      ]),
    );
  }

  _saveChangeImage(image) async {
    var oldImage = widget.community["bild"];

    if (selectedImage == "" && (image == null || image.isEmpty)) {
      customSnackbar(context, AppLocalizations.of(context).bitteBildAussuchen);
      return;
    }

    if (image != null &&
        image.substring(0, 4) != "http" &&
        image.substring(0, 3) != "www") {
      customSnackbar(context, AppLocalizations.of(context).ungueltigerLink);
      return;
    }

    if (image != null) {
      selectedImage = image;
      widget.community["bild"] = image;
    } else {
      widget.community["bild"] = selectedImage;
    }

    DbDeleteImage(oldImage);

    await CommunityDatabase().update(
        "bild = '$selectedImage'", "WHERE id = '${widget.community["id"]}'");

    setState(() {
      imageLoading = false;
    });
  }

  _changeNameWindow() {
    var newNameKontroller = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).nameAendern,
            children: [
              customTextInput(AppLocalizations.of(context).neuenNamenEingeben,
                  newNameKontroller),
              const SizedBox(height: 15),
              _windowOptions(() => _saveChangeName(newNameKontroller.text))
            ],
          );
        });
  }

  _saveChangeName(newName) {
    if (newName.isEmpty) {
      customSnackbar(context, AppLocalizations.of(context).bitteNameEingeben);
      return;
    }

    setState(() {
      widget.community["name"] = newName;
    });

    Navigator.pop(context);

    CommunityDatabase()
        .update("name = '$newName'", "WHERE id = '${widget.community["id"]}'");
  }

  _changeOrtWindow() {
    var ortAuswahlBox = GoogleAutoComplete(
      hintText: AppLocalizations.of(context).ortEingeben,
    );

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).ortAendern,
            children: [
              ortAuswahlBox,
              const SizedBox(height: 15),
              _windowOptions(() =>
                  _saveChangeLocation(ortAuswahlBox.getGoogleLocationData()))
            ],
          );
        });
  }

  _saveChangeLocation(newLocationData) {
    if (newLocationData["city"].isEmpty) {
      customSnackbar(context, AppLocalizations.of(context).ortEingeben);
      return;
    }

    setState(() {
      widget.community["ort"] = newLocationData["city"];
      widget.community["land"] = newLocationData["land"];
      widget.community["latt"] = newLocationData["latt"];
      widget.community["longt"] = newLocationData["longt"];
    });

    Navigator.pop(context);

    CommunityDatabase().updateLocation(widget.community["id"], newLocationData);
  }

  _changeOrOpenLinkWindow(tabPosition) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();

    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
          tabPosition & const Size(40, 40), // smaller rect, the touch area
          Offset.zero & overlay.size // Bigger rect, the entire screen
          ),
      items: [
        PopupMenuItem(
            child: Text(AppLocalizations.of(context).linkBearbeiten),
            onTap: () {
              Future.delayed(
                  const Duration(seconds: 0), () => _changeLinkWindow());
            }),
        PopupMenuItem(
          child: Text(AppLocalizations.of(context).linkOeffnen),
          onTap: () {
            Navigator.pop(context);
            global_func.openURL(widget.community["link"]);
          },
        ),
      ],
      elevation: 8.0,
    );
  }

  _changeLinkWindow() {
    var newLinkKontroller = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).linkAendern,
            children: [
              customTextInput(AppLocalizations.of(context).neuenLinkEingeben,
                  newLinkKontroller),
              const SizedBox(height: 15),
              _windowOptions(() => _saveChangeLink(newLinkKontroller.text))
            ],
          );
        });
  }

  _saveChangeLink(newLink) {
    if (newLink.isEmpty) {
      customSnackbar(context, AppLocalizations.of(context).neuenLinkEingeben);
      return;
    }

    if (!newLink.contains("http") && !newLink.contains("www")) {
      customSnackbar(context, AppLocalizations.of(context).eingabeKeinLink);
      return;
    }

    setState(() {
      widget.community["link"] = newLink;
    });

    Navigator.pop(context);

    CommunityDatabase()
        .update("link = '$newLink'", "WHERE id = '${widget.community["id"]}'");
  }

  _changeBeschreibungWindow() {
    var newBeschreibungKontroller =
        TextEditingController(text: widget.community["beschreibung"]);

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).beschreibungAendern,
            children: [
              customTextInput(
                  AppLocalizations.of(context).neueBeschreibungEingeben,
                  newBeschreibungKontroller,
                  moreLines: 20,
                  textInputAction: TextInputAction.newline),
              const SizedBox(height: 15),
              _windowOptions(
                  () => _saveChangeBeschreibung(newBeschreibungKontroller.text))
            ],
          );
        });
  }

  _saveChangeBeschreibung(newBeschreibung) {
    if (newBeschreibung.isEmpty) {
      customSnackbar(context,
          AppLocalizations.of(context).bitteCommunityBeschreibungEingeben);
      return;
    }

    setState(() {
      widget.community["beschreibung"] = newBeschreibung;
    });

    Navigator.pop(context);

    CommunityDatabase().update("beschreibung = '$newBeschreibung'",
        "WHERE id = '${widget.community["id"]}'");
  }

  List<Widget> createFriendlistBox() {
    var userFriendlist = Hive.box('secureBox').get("ownProfil")["friendlist"];

    for (var i = 0; i < userFriendlist.length; i++) {
      for (var profil in Hive.box('secureBox').get("profils")) {
        if (profil["id"] == userFriendlist[i]) {
          userFriendlist[i] = profil["name"];
          break;
        }
      }
    }

    List<Widget> friendsBoxen = [];
    for (var friend in userFriendlist) {
      friendsBoxen.add(GestureDetector(
        onTap: () {
          _saveNewMember(friend);
          Navigator.pop(context);
        },
        child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        width: 1, color: global_var.borderColorGrey))),
            child: Text(friend)),
      ));
    }

    if (userFriendlist.isEmpty) {
      return [
        Center(
            heightFactor: 10,
            child: Text(AppLocalizations.of(context).nochKeineFreundeVorhanden,
                style: const TextStyle(color: Colors.grey)))
      ];
    }

    return friendsBoxen;
  }

  _addMemberWindow() {
    var newUser = "";

    searchAutocomplete = SearchAutocomplete(
      hintText: AppLocalizations.of(context).personSuchen,
      searchableItems: allUserNames,
      onConfirm: () {
        newUser = searchAutocomplete.getSelected()[0];
      },
    );

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            height: 600,
            title: AppLocalizations.of(context).mitgliedHinzufuegen,
            children: [
              searchAutocomplete,
              const SizedBox(height: 15),
              _windowOptions(() => _saveNewMember(newUser)),
              ...createFriendlistBox(),
            ],
          );
        });
  }

  _saveNewMember(newMember) {
    var userIndex = allUserNames.indexOf(newMember);
    var newMemberId = allUserIds[userIndex];

    if (widget.community["members"].contains(newMemberId)) {
      customSnackbar(context,
          newMember + AppLocalizations.of(context).istSchonMitgliedCommunity);
      return;
    }
    if (widget.community["einladung"].contains(newMemberId)) {
      customSnackbar(
          context,
          newMember +
              AppLocalizations.of(context).wurdeSchonEingeladenCommunity);
      return;
    }

    setState(() {
      widget.community["einladung"].add(newMemberId);
    });

    CommunityDatabase().update(
        "einladung = JSON_ARRAY_APPEND(einladung, '\$', '$newMemberId')",
        "WHERE id = '${widget.community["id"]}'");

    customSnackbar(context,
        newMember + AppLocalizations.of(context).wurdeEingeladenCommunity,
        color: Colors.green);
  }

  _showMembersWindow() async {
    var membersID = widget.community["members"];
    var allProfils = Hive.box("secureBox").get("profils");
    var membersProfils = [];
    List<Widget> membersBoxes = [];

    for (var memberId in membersID) {
      for (var profil in allProfils) {
        if (profil["id"] == memberId) {
          membersProfils.add(profil);
          break;
        }
      }
    }

    for (var member in membersProfils) {
      membersBoxes.add(InkWell(
          onTap: () {
            global_func.changePage(
                context,
                ShowProfilPage(
                  userName: member["name"],
                  profil: member,
                ));
          },
          child: Container(
              margin: const EdgeInsets.all(10),
              child: Text(
                member["name"],
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ))));
    }

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).member,
            children: membersBoxes,
          );
        });
  }

  _linkTeilenWindow() async {
    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(title: "Community link", children: [
            Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    border: Border.all()),
                child:
                    Text("</communityId=" + widget.community["id"].toString())),
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  Clipboard.setData(ClipboardData(
                      text: "</communityId=" +
                          widget.community["id"].toString()));

                  await showDialog(
                      context: context,
                      builder: (context) {
                        Future.delayed(const Duration(seconds: 1), () {
                          Navigator.of(context).pop(true);
                        });
                        return AlertDialog(
                          content: Text(
                              AppLocalizations.of(context).linkWurdekopiert),
                        );
                      });
                  Navigator.pop(context);
                },
                label: Text(AppLocalizations.of(context).linkKopieren),
                icon: const Icon(Icons.copy),
              ),
            ),
            const SizedBox(height: 10)
          ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    fontsize = isWebDesktop ? 12 : 16;
    var isCreator = widget.community["erstelltVon"].contains(userId);


    _deleteWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).communityLoeschen,
              height: 90,
              children: [
                Center(
                    child: Text(
                        AppLocalizations.of(context).communityWirklichLoeschen))
              ],
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: () async {

                    var communities = Hive.box('secureBox').get("communities");
                    communities.remove(widget.community);

                    await CommunityDatabase().delete(widget.community["id"]);

                    DbDeleteImage(widget.community["bild"]);

                    global_func.changePageForever(
                        context, StartPage(selectedIndex: 3));
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context).abbrechen),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            );
          });
    }

    _reportWindow() {
      var reportController = TextEditingController();

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
                height: 500,
                title: AppLocalizations.of(context).communityMelden,
                children: [
                  customTextInput(
                      AppLocalizations.of(context).communityMeldenFrage,
                      reportController,
                      moreLines: 10),
                  Container(
                    margin: const EdgeInsets.only(left: 30, top: 10, right: 30),
                    child: FloatingActionButton.extended(
                        onPressed: () {
                          Navigator.pop(context);
                          ReportsDatabase().add(
                              userId,
                              "Melde Community id: " + widget.community["id"].toString(),
                              reportController.text);
                        },
                        label: Text(AppLocalizations.of(context).senden)),
                  )
                ]);
          });
    }

    _reportDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.report),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).eventMelden),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          _reportWindow();
        },
      );
    }

    _addMemberDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.person_add),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).mitgliedHinzufuegen),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          _addMemberWindow();
        },
      );
    }

    _deleteDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.delete),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).communityLoeschen),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          _deleteWindow();
        },
      );
    }

    _moreMenu() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 250,
                  child: SimpleDialog(
                    contentPadding: EdgeInsets.zero,
                    insetPadding:
                        const EdgeInsets.only(top: 40, left: 0, right: 10),
                    children: [
                      if (!isCreator) _reportDialog(),
                      if (isCreator) _addMemberDialog(),
                      if (isCreator) _deleteDialog(),
                    ],
                  ),
                ),
              ],
            );
          });
    }

    _communityImage() {
      var isAssetImage =
          widget.community["bild"].substring(0, 5) == "asset" ? true : false;

      return GestureDetector(
        onTapDown: (details) {
          if (!isCreator) return;

          var getTabPostion = details.globalPosition;
          _changeImageWindow(getTabPostion);
        },
        child: isAssetImage
            ? Image.asset(widget.community["bild"], height: screenWidth > 600 ? screenHeight /3  : null)
            : Image.network(widget.community["bild"],
            height: screenHeight / 3, fit: screenWidth > 600 ? null :  BoxFit.fitWidth),
      );
    }

    _communityInformation() {
      var fremdeCommunity = widget.community["ownCommunity"] == 0;

      return [
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: InkWell(
            onTap: () => isCreator ? _changeNameWindow() : null,
            child: Center(
                child: Text(
                  widget.community["name"],
                  style:
                  const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                )),
          ),
        ),
        const SizedBox(height: 20),
        if (fremdeCommunity)
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: SizedBox(
              width: screenWidth * 0.9,
              child: Text(AppLocalizations.of(context).nichtTeilGemeinschaft,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                  maxLines: 2),
            ),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: InkWell(
            onTap: () => isCreator ? _changeOrtWindow() : null,
            child: Row(
              children: [
                Text(AppLocalizations.of(context).ort,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.community["ort"] +
                    " / " +
                    widget.community["land"])
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (tabDetails) {
              var getTabPostion = tabDetails.globalPosition;
              var link = widget.community["link"];
              if (!link.contains("http")) link = "http://" + link;

              if (isCreator) _changeOrOpenLinkWindow(getTabPostion);
              if (!isCreator) global_func.openURL(widget.community["link"]);
            },
            child: Row(
              children: [
                const Text(
                  "Link: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(widget.community["link"],
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary))
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: SizedBox(
            child: TextWithHyperlinkDetection(
                text: widget.community["beschreibung"],
              onTextTab: () => isCreator ? _changeBeschreibungWindow(): null,
            )

          ),
        )
      ];
    }

    _footbar() {
      return Container(
        width: screenWidth - 20,
        margin: const EdgeInsets.all(10),
        child: Row(
          //mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () => _showMembersWindow(),
              child: Text(
                widget.community["members"].length.toString() +
                    " " +
                    AppLocalizations.of(context).member,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
            Expanded(
                child: scrollbarOnBottom
                    ? const SizedBox()
                    : const Icon(Icons.arrow_downward)),
            InkWell(
                onTap: () => global_func.changePage(
                    context,
                    ShowProfilPage(
                      profil: creatorProfil,
                    )),
                child: Text(
                  creatorText,
                  style: TextStyle(
                      fontSize: fontsize,
                      color: Theme.of(context).colorScheme.secondary),
                ))
          ],
        ),
      );
    }

    return SelectionArea(
      child: Scaffold(
          appBar: CustomAppBar(
            title: widget.community["name"],
            buttons: [
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () => global_func.changePage(context, ChatDetailsPage(
                  connectedId: "</community="+widget.community["id"],
                  isChatgroup: true,
                )),
              ),
              IconButton(
                icon: const Icon(Icons.link),
                onPressed: () => _linkTeilenWindow(),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _moreMenu(),
              )
            ],
          ),
          body: Stack(
            children: [
              Container(
                height: screenHeight,
                padding: EdgeInsets.only(bottom: 50),
                child: ListView(
                  controller: _controller,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    imageLoading
                        ? Center(
                            child: Container(
                                margin: const EdgeInsets.all(10),
                                width: 100,
                                height: 100,
                                child: const CircularProgressIndicator()))
                        : _communityImage(),
                    SizedBox(height: 10),
                    ..._communityInformation()
                  ],
                ),
              ),
              Positioned(bottom: 0, child: _footbar())
            ],
          )),
    );
  }
}
