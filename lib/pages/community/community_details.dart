import 'dart:convert';

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
import 'package:url_launcher/url_launcher.dart';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../widgets/dialogWindow.dart';
import '../../widgets/google_autocomplete.dart';
import '../../widgets/search_autocomplete.dart';
import '../start_page.dart';

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
  var imagePaths;
  var selectedImage;
  var allUserNames;
  var searchAutocomplete = SearchAutocomplete();

  @override
  void initState() {
    setCreatorText();
    _initImages();
    getDBDataSetAllUserNames();

    super.initState();
  }

  getDBDataSetAllUserNames() async {
    allUserNames = await ProfilDatabase().getData("name", "");

  }

  setCreatorText() async {
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

  changeImageWindow(tabPosition) async {
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
            Future.delayed(
                const Duration(seconds: 0), () => windowChangeImageWithLink());
          },
        ),
        PopupMenuItem(
            child: Text(AppLocalizations.of(context).hochladen),
            onTap: () => selectAndUploadImage()),
      ],
      elevation: 8.0,
    );
  }

  windowChangeImageToPredetermined() async {
    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(builder: (context, setState) {
            windowSetState = setState;
            return CustomAlertDialog(
              title: AppLocalizations.of(context).bildAendern,
              children: [
                showImages(),
                const SizedBox(height: 20),
                windowOptions(() => saveChangeImage())
              ],
            );
          });
        });
  }

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

  pickAndUploadImage() async {
    var eventName = widget.community["name"] + "_";
    var pickedImage = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);

    var imageName = eventName + pickedImage.name;

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

    saveChangeImage();
  }

  windowChangeImageWithLink() async {
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
              windowOptions(() => saveChangeImage())
            ],
          );
        });
  }

  windowOptions(saveFunction) {
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
            onPressed: () => saveFunction()),
      ]),
    );
  }

  saveChangeImage() {
    if (selectedImage == "" && ownPictureKontroller.text == "") {
      customSnackbar(context, AppLocalizations.of(context).bitteBildAussuchen);
      return;
    }

    if (selectedImage == "") {
      selectedImage = ownPictureKontroller.text;
      widget.community["bild"] = selectedImage;
    } else {
      widget.community["bild"] = selectedImage;
    }

    CommunityDatabase().update(
        "bild = '$selectedImage'", "WHERE id = '${widget.community["id"]}'");
  }

  changeNameWindow() {
    var newNameKontroller = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).nameAendern,
            children: [
              customTextInput(AppLocalizations.of(context).neuenNamenEingeben,
                  newNameKontroller),
              SizedBox(height: 15),
              windowOptions(() => saveChangeName(newNameKontroller.text))
            ],
          );
        });
  }

  saveChangeName(newName) {
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

  changeOrtWindow() {
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
              SizedBox(height: 15),
              windowOptions(() =>
                  saveChangeLocation(ortAuswahlBox.getGoogleLocationData()))
            ],
          );
        });
  }

  saveChangeLocation(newLocationData) {
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

  changeOrOpenLinkWindow(tabPosition) async {
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
                  const Duration(seconds: 0), () => changeLinkWindow());
            }),
        PopupMenuItem(
          child: Text(AppLocalizations.of(context).linkOeffnen),
          onTap: () {
            Navigator.pop(context);
            launch(widget.community["link"]);
          },
        ),
      ],
      elevation: 8.0,
    );
  }

  changeLinkWindow() {
    var newLinkKontroller = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).linkAendern,
            children: [
              customTextInput(AppLocalizations.of(context).neuenLinkEingeben,
                  newLinkKontroller),
              SizedBox(height: 15),
              windowOptions(() => saveChangeLink(newLinkKontroller.text))
            ],
          );
        });
  }

  saveChangeLink(newLink) {
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

  changeBeschreibungWindow() {
    var newBeschreibungKontroller = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).beschreibungAendern,
            children: [
              customTextInput(
                  AppLocalizations.of(context).neueBeschreibungEingeben,
                  newBeschreibungKontroller,
                  moreLines: 5,
                  textInputAction: TextInputAction.newline),
              SizedBox(height: 15),
              windowOptions(
                  () => saveChangeBeschreibung(newBeschreibungKontroller.text))
            ],
          );
        });
  }

  saveChangeBeschreibung(newBeschreibung) {
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

  _addMemberWindow() {
    var newUser = "";

    searchAutocomplete = SearchAutocomplete(
      searchableItems: allUserNames,
      onConfirm: () {
        newUser = searchAutocomplete.getSelected()[0];
      },
    );

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).mitgliedHinzufuegen,
            children: [
              searchAutocomplete,
              SizedBox(height: 15),
              windowOptions(() => saveNewMember(newUser))
            ],
          );
        });
  }

  saveNewMember(newMember) {
    if (widget.community["members"].contains(newMember)) {
      return;
    }

    setState(() {
      widget.community["members"].add(newMember);
    });

    CommunityDatabase()
        .update("members = ''", "WHERE id = '${widget.community["id"]}'");
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
            global_func.changePage(context, ShowProfilPage(
              userName: member["name"],
              profil: member,
            ));
          },
          child: Container(
            margin: EdgeInsets.all(10),
              child: Text(
            member["name"],
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
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

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    fontsize = isWebDesktop ? 12 : 16;
    var isCreator = widget.community["erstelltVon"].contains(userId);

    _deleteWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).eventLoeschen,
              height: 90,
              children: [
                const SizedBox(height: 10),
                Center(
                    child: Text(
                        AppLocalizations.of(context).communityWirklichLoeschen))
              ],
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: () {
                    CommunityDatabase().delete(widget.community["id"]);
                    deleteImage(widget.community["bild"]);
                    global_func.changePageForever(
                        context, StartPage(selectedIndex: 2));
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
                              "Melde Community id: " + widget.community["id"],
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
            Text(AppLocalizations.of(context).eventLoeschen),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          _deleteWindow();
        },
      );
    }

    moreMenu() {
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

    communityImage() {
      return GestureDetector(
        onTapDown: (details) {
          if (!isCreator) return;

          var getTabPostion = details.globalPosition;
          changeImageWindow(getTabPostion);
        },
        child: Image.asset(widget.community["bild"],
            height: screenHeight / 3, fit: BoxFit.fitWidth),
      );
    }

    communityInformation() {
      return Container(
        margin: const EdgeInsets.all(10),
        constraints: BoxConstraints(
          minHeight: screenHeight / 2.1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => isCreator ? changeNameWindow() : null,
              child: Center(
                  child: Text(
                widget.community["name"],
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              )),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => isCreator ? changeOrtWindow() : null,
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
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (tabDetails) {
                var getTabPostion = tabDetails.globalPosition;
                if (isCreator) changeOrOpenLinkWindow(getTabPostion);
                if (!isCreator) launch(widget.community["link"]);
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
            const SizedBox(height: 20),
            GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => isCreator ? changeBeschreibungWindow() : null,
                child: Text(widget.community["beschreibung"]))
          ],
        ),
      );
    }

    footbar() {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
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
            Expanded(child: SizedBox()),
            InkWell(
                onTap: () => global_func.changePage(
                    context,
                    ShowProfilPage(
                      userName: FirebaseAuth.instance.currentUser.displayName,
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

    return Scaffold(
        appBar: CustomAppBar(
          title: widget.community["name"],
          buttons: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => moreMenu(),
            )
          ],
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [communityImage(), communityInformation(), footbar()],
        ));
  }
}
