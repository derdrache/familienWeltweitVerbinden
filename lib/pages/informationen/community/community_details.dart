import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:familien_suche/widgets/custom_like_button.dart';
import 'package:familien_suche/widgets/windowConfirmCancelBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:translator/translator.dart';

import '../../../functions/upload_and_save_image.dart';
import '../../../functions/user_speaks_german.dart';
import '../../../services/database.dart';
import '../../../services/notification.dart';
import '../../../widgets/automatic_translation_notice.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/strike_through_icon.dart';
import '../../../windows/custom_popup_menu.dart';
import '../../../windows/dialog_window.dart';
import '../../../widgets/google_autocomplete.dart';
import '../../../widgets/layout/custom_snackbar.dart';
import '../../../widgets/layout/custom_text_input.dart';
import '../../../widgets/text_with_hyperlink_detection.dart';
import '../../../global/style.dart' as style;
import '../../../global/global_functions.dart' as global_func;
import '../../../windows/all_user_select.dart';
import '../../chat/chat_details.dart';
import '../../show_profil.dart';
import '../../start_page.dart';
import '../location/location_details/information_main.dart';
import 'community_page.dart';

class CommunityDetails extends StatefulWidget {
  Map community;
  bool? toMainPage;

  CommunityDetails({Key? key, required this.community, this.toMainPage})
      : super(key: key);

  @override
  State<CommunityDetails> createState() => _CommunityDetailsState();
}

class _CommunityDetailsState extends State<CommunityDetails> {
  String userId = FirebaseAuth.instance.currentUser!.uid;
  var isWebDesktop = kIsWeb &&
      (defaultTargetPlatform != TargetPlatform.iOS ||
          defaultTargetPlatform != TargetPlatform.android);
  var creatorName = "";
  late Map creatorProfil;
  var ownPictureKontroller = TextEditingController();
  late double fontsize;
  late var windowSetState;
  late List<String> imagePaths;
  String? selectedImage;
  List<String> allUserNames = [];
  List allUserIds = [];
  final scrollController = ScrollController();
  bool moreContent = false;
  bool imageLoading = false;
  final translator = GoogleTranslator();
  late bool isCreator;
  late bool isMember;
  List allMemberProfils = [];
  late bool isLiked;
  Map originalContent = {};
  Map translationContent = {};
  bool showOriginalContent = false;
  bool showOnlyOriginal = false;

  @override
  void initState() {
    isCreator = widget.community["erstelltVon"].contains(userId);
    isLiked = widget.community["interesse"].contains(userId);

    createMemberList();
    if (widget.community["beschreibungGer"].isEmpty) {
      widget.community["beschreibungGer"] = widget.community["beschreibung"];
    }
    if (widget.community["beschreibungEng"].isEmpty) {
      widget.community["beschreibungEng"] = widget.community["beschreibung"];
    }

    setCreatorData();
    _initImages();
    _getDBDataSetAllUserNames();
    checkAndSetTextVariations();

    if (!widget.community["link"].contains("http")) {
      widget.community["link"] = "http://${widget.community["link"]}";
    }

    addScrollListener();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => scrollbarCheckForMoreContent());

    super.initState();
  }

  addScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.atEdge) {
        bool isTop = scrollController.position.pixels == 0;
        if (isTop) {
          moreContent = true;
        } else {
          moreContent = false;
        }
        setState(() {});
      }
    });
  }

  scrollbarCheckForMoreContent() {
    if (scrollController.position.maxScrollExtent > 0) {
      setState(() {
        moreContent = true;
      });
    }
  }

  createMemberList(){
    List allMemberIds = widget.community["members"];

    for(String memberId in allMemberIds){
      Map? memberProfil = getProfilFromHive(profilId: memberId);
      if(memberProfil != null) allMemberProfils.add(memberProfil);
    }
  }

  _getDBDataSetAllUserNames() async {
    var allProfils = Hive.box('secureBox').get("profils");

    for (var profil in allProfils) {
      allUserNames.add(profil["name"]);
      allUserIds.add(profil["id"]);
    }
  }

  setCreatorData() {
    creatorProfil = getProfilFromHive(profilId: widget.community["erstelltVon"]) ?? {};
    creatorName = creatorProfil["name"] ?? "";
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
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

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
                  () => _windowChangeImageToPredetermined());
            }),
        PopupMenuItem(
          child: Text(AppLocalizations.of(context)!.link),
          onTap: () {
            Future.delayed(
                const Duration(seconds: 0), () => _windowChangeImageWithLink());
          },
        ),
        PopupMenuItem(
            child: Text(AppLocalizations.of(context)!.hochladen),
            onTap: () async {
              var newImage = await uploadAndSaveImage(context, "community",
                  meetupCommunityData: widget.community);

              setState(() {
                widget.community["bild"] = newImage[0];
              });
            }),
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
              title: AppLocalizations.of(context)!.bildAendern,
              children: [
                _showImages(),
                const SizedBox(height: 20),
                WindowConfirmCancelBar(
                  confirmTitle: AppLocalizations.of(context)!.speichern,
                  onConfirm: () => _saveChangeImage(null),
                )
              ],
            );
          });
        });
  }

  _showImages() {
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

  _windowChangeImageWithLink() async {
    return await showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context)!.bildAendern,
            children: [
              SizedBox(
                  width: 200,
                  child: CustomTextInput(
                      AppLocalizations.of(context)!.eigenesBildLinkEingeben,
                      ownPictureKontroller)),
              const SizedBox(height: 20),
              WindowConfirmCancelBar(
                confirmTitle: AppLocalizations.of(context)!.speichern,
                onConfirm: () => _saveChangeImage(ownPictureKontroller.text),
              )
            ],
          );
        });
  }

  _saveChangeImage(image) async {
    var oldImage = widget.community["bild"];

    if (selectedImage == "" && (image == null || image.isEmpty)) {
      customSnackBar(context, AppLocalizations.of(context)!.bitteBildAussuchen);
      return;
    }

    if (image != null &&
        image.substring(0, 4) != "http" &&
        image.substring(0, 3) != "www") {
      customSnackBar(context, AppLocalizations.of(context)!.ungueltigerLink);
      return;
    }

    if (image != null) {
      selectedImage = image;
      widget.community["bild"] = image;
    } else {
      widget.community["bild"] = selectedImage;
    }

    dbDeleteImage(oldImage);

    CommunityDatabase().update(
        "bild = '$selectedImage'", "WHERE id = '${widget.community["id"]}'");

    setState(() {
      imageLoading = false;
    });
  }

  _changeNameWindow() {
    var newNameKontroller =
        TextEditingController(text: widget.community["name"]);

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context)!.nameAendern,
            children: [
              CustomTextInput(AppLocalizations.of(context)!.neuenNamenEingeben,
                  newNameKontroller,maxLength: 40),
              const SizedBox(height: 15),
              WindowConfirmCancelBar(
                confirmTitle: AppLocalizations.of(context)!.speichern,
                onConfirm: () => _saveChangeName(newNameKontroller.text),
              )
            ],
          );
        });
  }

  _saveChangeName(newName) async {
    if (newName.isEmpty) {
      customSnackBar(context, AppLocalizations.of(context)!.bitteNameEingeben);
      return;
    }

    updateHiveCommunity(widget.community["id"], "name", newName);

    setState(() {
      widget.community["name"] = newName;
    });

    var languageCheck = await translator.translate(newName);
    bool textIsGerman = languageCheck.sourceLanguage.code == "de";
    widget.community["name"] = newName;

    if (textIsGerman) {
      widget.community["nameGer"] = newName;
      var translation = await _descriptionTranslation(newName, "auto");
      widget.community["nameEng"] = translation;
    } else {
      widget.community["nameEng"] = newName;
      var translation = await _descriptionTranslation(newName, "de");
      widget.community["nameGer"] = translation;
    }


    newName = newName.replaceAll("'", "''");
    var newNameGer = widget.community["nameGer"].replaceAll("'", "''");
    var newNameEng = widget.community["nameEng"].replaceAll("'", "''");

    CommunityDatabase()
        .update("name = '$newName', nameGer = '$newNameGer', nameEng = '$newNameEng'", "WHERE id = '${widget.community["id"]}'");
  }

  _changeOrtWindow() {
    var ortAuswahlBox = GoogleAutoComplete(
      hintText: AppLocalizations.of(context)!.ortEingeben,
      withWorldwideLocation: true,
      withOwnLocation: true,
    );

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context)!.ortAendern,
            children: [
              ortAuswahlBox,
              const SizedBox(height: 15),
              WindowConfirmCancelBar(
                confirmTitle: AppLocalizations.of(context)!.speichern,
                onConfirm: () {
                  var newLocation = ortAuswahlBox.getGoogleLocationData();
                  if (newLocation["city"].isEmpty) {
                    customSnackBar(
                        context, AppLocalizations.of(context)!.ortEingeben);
                    return;
                  }
                  _saveChangeLocation(newLocation);
                },
              )
            ],
          );
        });
  }

  _saveChangeLocation(newLocationData) {
    setState(() {
      widget.community["ort"] = newLocationData["city"];
      widget.community["land"] = newLocationData["countryname"];
      widget.community["latt"] = newLocationData["latt"];
      widget.community["longt"] = newLocationData["longt"];
    });

    updateHiveCommunity(widget.community["id"], "ort", newLocationData["city"]);
    updateHiveCommunity(
        widget.community["id"], "land", newLocationData["countryname"]);
    updateHiveCommunity(
        widget.community["id"], "latt", newLocationData["latt"]);
    updateHiveCommunity(
        widget.community["id"], "longt", newLocationData["longt"]);

    newLocationData["city"] = newLocationData["city"].replaceAll("'", "''");
    newLocationData["countryname"] =
        newLocationData["countryname"].replaceAll("'", "''");

    CommunityDatabase().updateLocation(widget.community["id"], newLocationData);
  }

  _changeOrOpenLinkWindow(tabPosition) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
          tabPosition & const Size(40, 40), // smaller rect, the touch area
          Offset.zero & overlay.size // Bigger rect, the entire screen
          ),
      items: [
        PopupMenuItem(
            child: Text(AppLocalizations.of(context)!.linkBearbeiten),
            onTap: () {
              Future.delayed(
                  const Duration(seconds: 0), () => _changeLinkWindow());
            }),
        PopupMenuItem(
          child: Text(AppLocalizations.of(context)!.linkOeffnen),
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
            title: AppLocalizations.of(context)!.linkAendern,
            children: [
              CustomTextInput(AppLocalizations.of(context)!.neuenLinkEingeben,
                  newLinkKontroller),
              const SizedBox(height: 15),
              WindowConfirmCancelBar(
                confirmTitle: AppLocalizations.of(context)!.speichern,
                onConfirm: () => _saveChangeLink(newLinkKontroller.text),
              )
            ],
          );
        });
  }

  _saveChangeLink(newLink) {
    if (newLink.isEmpty) {
      customSnackBar(context, AppLocalizations.of(context)!.neuenLinkEingeben);
      return;
    }

    if (!newLink.contains("http") && !newLink.contains("www")) {
      customSnackBar(context, AppLocalizations.of(context)!.eingabeKeinLink);
      return;
    }

    setState(() {
      widget.community["link"] = newLink;
    });

    updateHiveCommunity(widget.community["id"], "link", newLink);

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
            title: AppLocalizations.of(context)!.beschreibungAendern,
            children: [
              CustomTextInput(
                  AppLocalizations.of(context)!.neueBeschreibungEingeben,
                  newBeschreibungKontroller,
                  moreLines: 13,
                  textInputAction: TextInputAction.newline),
              WindowConfirmCancelBar(
                confirmTitle: AppLocalizations.of(context)!.speichern,
                onConfirm: () {
                  String newBeschreibung = newBeschreibungKontroller.text;
                  if (newBeschreibung.isEmpty) {
                    customSnackBar(
                        context,
                        AppLocalizations.of(context)!
                            .bitteCommunityBeschreibungEingeben);
                    return;
                  }

                  _saveChangeBeschreibung(newBeschreibung);
                },
              )
            ],
          );
        });
  }

  _saveChangeBeschreibung(newBeschreibung) async {
    setState(() {
      widget.community["beschreibung"] = newBeschreibung;
    });

    var languageCheck = await translator.translate(newBeschreibung);
    bool descriptionIsGerman = languageCheck.sourceLanguage.code == "de";

    if (descriptionIsGerman) {
      widget.community["beschreibung"] = newBeschreibung;
      widget.community["beschreibungGer"] = newBeschreibung;
      var translation = await _descriptionTranslation(newBeschreibung, "auto");
      widget.community["beschreibungEng"] = translation;
    } else {
      widget.community["beschreibung"] = newBeschreibung;
      widget.community["beschreibungEng"] = newBeschreibung;
      var translation = await _descriptionTranslation(newBeschreibung, "de");
      widget.community["beschreibungGer"] = translation;
    }

    newBeschreibung = newBeschreibung.replaceAll("'", "''");
    var beschreibungGer =
        widget.community["beschreibungGer"].replaceAll("'", "''");
    var beschreibungEng =
        widget.community["beschreibungEng"].replaceAll("'", "''");

    CommunityDatabase().update(
        "beschreibung = '$newBeschreibung', beschreibungGer = '$beschreibungGer', beschreibungEng = '$beschreibungEng'",
        "WHERE id = '${widget.community["id"]}'");
  }

  _descriptionTranslation(text, targetLanguage) async {
    text = text.replaceAll("'", "");

    var translation =
        await translator.translate(text, from: "auto", to: targetLanguage);

    return translation.toString();
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
                        width: 1, color: style.borderColorGrey))),
            child: Text(friend)),
      ));
    }

    if (userFriendlist.isEmpty) {
      return [
        Center(
            heightFactor: 10,
            child: Text(AppLocalizations.of(context)!.nochKeineFreundeVorhanden,
                style: const TextStyle(color: Colors.grey)))
      ];
    }

    return friendsBoxen;
  }

  _saveNewMember(newMemberId) {
    if (widget.community["members"].contains(newMemberId)) {
      customSnackBar(context,
          AppLocalizations.of(context)!.istSchonMitgliedCommunity);
      return;
    }
    if (widget.community["einladung"].contains(newMemberId)) {
      customSnackBar(
          context,
           AppLocalizations.of(context)!.wurdeSchonEingeladenCommunity);
      return;
    }

    setState(() {
      widget.community["einladung"].add(newMemberId);
    });

    updateHiveCommunity(
        widget.community["id"], "einladung", widget.community["einladung"]);

    CommunityDatabase().update(
        "einladung = JSON_ARRAY_APPEND(einladung, '\$', '$newMemberId')",
        "WHERE id = '${widget.community["id"]}'");

    if (!widget.community["interesse"].contains(newMemberId)) {
      CommunityDatabase().update(
          "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$newMemberId')",
          "WHERE id = '${widget.community["id"]}'");
    }

    prepareAddMemberNotification(widget.community, newMemberId);

    customSnackBar(context,
        AppLocalizations.of(context)!.wurdeEingeladenCommunity,
        color: Colors.green);
  }

  _openGroupChat() {
    bool hasSecretChat = widget.community["secretChat"] == true || widget.community["secretChat"] == 1;
    bool hasAccess = !hasSecretChat || isMember || isCreator;

    if (!hasAccess) {
      customSnackBar(context, AppLocalizations.of(context)!.geheimerChatMeldung);
      return;
    }

    global_func.changePage(
        context,
        ChatDetailsPage(
          connectedWith: "</community=${widget.community["id"]}",
          isChatgroup: true,
        ));
  }

  _changeSecretChatOption(newValue) {
    int secretChat = newValue ? 1 : 0;

    updateHiveCommunity(widget.community["id"], "secretChat", secretChat);
    CommunityDatabase().update(
        "secretChat = '$secretChat'", "WHERE id = '${widget.community["id"]}'");
  }

  _removeMember(memberId){
    setState(() {
      widget.community["members"].remove(memberId);
    });

    CommunityDatabase().update(
        "members = JSON_REMOVE(members, JSON_UNQUOTE(JSON_SEARCH(members, 'one', '$memberId')))",
        "WHERE id ='${widget.community["id"]}'"
    );
  }

  checkAndSetTextVariations() {
    String systemLanguage =
        WidgetsBinding.instance.platformDispatcher.locales[0].languageCode;
    Map ownProfil = Hive.box('secureBox').get("ownProfil");
    bool communityLanguageGerman = widget.community["sprache"] == "de";
    bool userSpeakGerman = getUserSpeaksGerman();
    bool userSpeakEnglish = ownProfil["sprachen"].contains("Englisch") ||
        ownProfil["sprachen"].contains("english") ||
        systemLanguage == "en";
    bool bothGerman = communityLanguageGerman && userSpeakGerman;
    bool bothEnglish = !communityLanguageGerman && userSpeakEnglish;

    if (bothGerman || bothEnglish || isCreator) {
      showOriginalContent = true;
      showOnlyOriginal = true;
    }

    if (communityLanguageGerman) {
      originalContent["title"] = widget.community["nameGer"];
      originalContent["description"] = widget.community["beschreibungGer"];
      translationContent["title"] = widget.community["nameEng"];
      translationContent["description"] = widget.community["beschreibungEng"];
    } else {
      originalContent["title"] = widget.community["nameEng"];
      originalContent["description"] = widget.community["beschreibungEng"];
      translationContent["title"] = widget.community["nameGer"];
      translationContent["description"] = widget.community["beschreibungGer"];
    }

  }

  changeLanguage() {
    setState(() {
      showOriginalContent = !showOriginalContent;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    fontsize = isWebDesktop ? 12 : 16;
    isCreator = widget.community["erstelltVon"].contains(userId);
    isMember = widget.community["members"].contains(userId);


    showMembersWindow() async {
      List<Widget> membersBoxes = [];

      for (var member in allMemberProfils) {
        membersBoxes.add(Row(
          children: [
            InkWell(
                onTap: () {
                  global_func.changePage(
                      context,
                      ShowProfilPage(
                        profil: member,
                      ));
                },
                child: Container(
                    margin: const EdgeInsets.all(10),
                    child: Text(
                      member["name"],
                      style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                    ))),
            const Expanded(child: SizedBox()),
            if(isCreator && member["id"] != userId) CloseButton(
                color: Colors.red,
                onPressed: () {
                  Navigator.pop(context);
                  _removeMember(member["id"]);
                }),
          ],
        ));
      }

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context)!.member,
              children: membersBoxes,
            );
          });
    }

    deleteWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context)!.communityLoeschen,
              children: [
                const SizedBox(height: 30,),
                Center(
                    child: Text(
                        AppLocalizations.of(context)!.communityWirklichLoeschen)),
                const SizedBox(height: 30,),
                WindowConfirmCancelBar(
                  onConfirm: () async {
                    CommunityDatabase().delete(widget.community["id"]);
                    ChatGroupsDatabase().deleteChat(getChatGroupFromHive(
                        connectedWith:
                        "</community=${widget.community["id"]}")["id"]);

                    var communities = Hive.box('secureBox').get("communities");
                    communities.removeWhere((community) =>
                    community["id"] == widget.community["id"]);

                    dbDeleteImage(widget.community["bild"]);

                    global_func.changePage(context, StartPage(selectedIndex: 2,));
                    global_func.changePage(context, const CommunityPage());
                  },
                )
              ],
            );
          });
    }

    reportWindow() {
      var reportController = TextEditingController();

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
                title: AppLocalizations.of(context)!.communityMelden,
                children: [
                  CustomTextInput(
                      AppLocalizations.of(context)!.communityMeldenFrage,
                      reportController,
                      moreLines: 8),
                  Container(
                    margin: const EdgeInsets.only(left: 30, top: 10, right: 30),
                    child: FloatingActionButton.extended(
                        onPressed: () {
                          Navigator.pop(context);

                          var text = "event id: ${widget.community["id"]}\n\n${reportController.text}";

                          ReportsDatabase().add(
                              userId,
                              "Melde Community: ${widget.community["name"]}",
                              text);
                        },
                        label: Text(AppLocalizations.of(context)!.senden)),
                  )
                ]);
          });
    }

    reportDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.report),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.communityMelden),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          reportWindow();
        },
      );
    }

    showMemberDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.group),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.member),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          showMembersWindow();
        },
      );
    }

    addMemberWindow() async{
      String selectedUserId = await AllUserSelectWindow(
        context: context,
        title: AppLocalizations.of(context)!.personSuchen,
      ).openWindow();

      _saveNewMember(selectedUserId);
    }

    addMemberDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.person_add),
            const SizedBox(width: 10),
            Flexible(child: Text(AppLocalizations.of(context)!.mitgliedHinzufuegen, maxLines: 2,)),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          addMemberWindow();
        },
      );
    }

    settingDialog() {
      return SimpleDialogOption(
          child: Row(
            children: [
              const Icon(Icons.settings),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.settings),
            ],
          ),
          onPressed: () {
            Navigator.pop(context);

            showDialog(
                context: context,
                builder: (BuildContext buildContext) {
                  return StatefulBuilder(
                      builder: (buildContext, dialogSetState) {
                    return CustomAlertDialog(
                        title: AppLocalizations.of(context)!.settings,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(AppLocalizations.of(context)!
                                      .geheimerChat)),
                              Switch(
                                value: widget.community["secretChat"]?.isOdd ??
                                    false,
                                inactiveThumbColor: Colors.grey[700],
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                                onChanged: (value) {
                                  _changeSecretChatOption(value);
                                  dialogSetState(() {});
                                  setState(() {});
                                },
                              )
                            ],
                          )
                        ]);
                  });
                });
          });
    }

    deleteDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.delete, color: Colors.red),
            const SizedBox(width: 10),
            Flexible(child: Text(AppLocalizations.of(context)!.communityLoeschen, maxLines: 2 ,style: const TextStyle(color: Colors.red),)),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          deleteWindow();
        },
      );
    }

    leaveDialog(){
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red,),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.verlassen, style: const TextStyle(color: Colors.red),),
          ],
        ),
        onPressed: () {
          _removeMember(userId);

          widget.community["interesse"].remove(userId);
          updateHiveCommunity(widget.community["id"], "interesse", widget.community["interesse"]);

          global_func.changePage(context, StartPage(selectedIndex: 2,));
          global_func.changePage(context, const CommunityPage());
        },
      );
    }

    moreMenu() {
      CustomPopupMenu(context, children: [
        showMemberDialog(),
        if (!isCreator) reportDialog(),
        if (isCreator) addMemberDialog(),
        if (isCreator) settingDialog(),
        if (isCreator) const SizedBox(height: 15),
        if (isCreator) deleteDialog(),
        if (!isCreator && isMember) leaveDialog()
      ]);
    }

    communityImage() {
      var isAssetImage =
          widget.community["bild"].substring(0, 5) == "asset" ? true : false;

      return GestureDetector(
        onTapDown: (details) {
          if (!isCreator) return;

          var getTabPostion = details.globalPosition;
          _changeImageWindow(getTabPostion);
        },
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: screenHeight / 3
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      isAssetImage
                        ? Image.asset(widget.community["bild"],fit: BoxFit.fill, height: screenHeight / 3,)
                        : CachedNetworkImage(imageUrl: widget.community["bild"],
                            fit: BoxFit.fill),
                      if(isCreator) Positioned(
                          right: 0, top: 0,
                          child: Banner(
                              message: AppLocalizations.of(context)!.besitzer,
                              location: BannerLocation.topEnd,
                              color: Theme.of(context).colorScheme.secondary
                          ))
                    ],
                  ),
                ),
              ),
            ),
            if(!isCreator) Positioned(
              right: 5,
                top: 5,
                child: CustomLikeButton(communityData: widget.community,)
            ),
          ],
        ));
    }

    communityInformation() {
      bool fremdeCommunity = widget.community["ownCommunity"] == 0;
      bool isWorldwide = widget.community["ort"] == "worldwide"
          || widget.community["ort"]== "Weltweit";
      String title;
      String discription;

      if (isCreator || showOriginalContent) {
        title = originalContent["title"];
        discription = originalContent["description"];
      } else{
        title = translationContent["title"];
        discription = translationContent["description"];
      }

      return [
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: InkWell(
            onTap: () => isCreator ? _changeNameWindow() : null,
            child: Center(
                child: Text(
                  title.isNotEmpty ? title : widget.community["name"],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            )),
          ),
        ),
        //const SizedBox(height: 20),
        if (fremdeCommunity)
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
            child: SizedBox(
              width: screenWidth * 0.9,
              child: Text(AppLocalizations.of(context)!.nichtTeilGemeinschaft,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                  maxLines: 2),
            ),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: InkWell(
            onTap: isWorldwide && !isCreator ? null : () => isCreator
                ? _changeOrtWindow()
                : global_func.changePage(context,
                    LocationInformationPage(ortName: widget.community["ort"], ortLatt: widget.community["latt"],)),
            child: Row(
              children: [
                Text(AppLocalizations.of(context)!.ort,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                         decoration: isCreator || isWorldwide ? TextDecoration.none : TextDecoration.underline)),
                Text(
                  widget.community["ort"],
                  style: TextStyle(decoration: isCreator ? TextDecoration.none : TextDecoration.underline),
                )
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
              if (!link.contains("http")) link = "http://$link";

              if (isCreator) _changeOrOpenLinkWindow(getTabPostion);
              if (!isCreator) global_func.openURL(widget.community["link"]);
            },
            child: Row(
              children: [
                const Text(
                  "Link: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Flexible(
                  child: Text(widget.community["link"],
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary)),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
              child: Column(
                children: [
                  TextWithHyperlinkDetection(
            text: discription.isNotEmpty ? discription : widget.community["beschreibung"],
            textColor: Colors.black,
            withoutActiveHyperLink: isCreator,
            onTextTab: () => isCreator ? _changeBeschreibungWindow() : null,
          ),
                  AutomaticTranslationNotice(translated: !showOriginalContent && !isCreator,)
                ],
              )),
        )
      ];
    }

    footbar() {
      return Container(
        width: screenWidth - 20,
        margin: const EdgeInsets.all(10),
        child: Row(

          children: [
            InkWell(
              onTap: () => showMembersWindow(),
              child: Text(
                "${allMemberProfils.length} ${AppLocalizations.of(context)!.member}",
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
            Expanded(
                child: moreContent
                    ? const Center(child: Icon(Icons.arrow_downward))
                    : const SizedBox()),
            InkWell(
                onTap: () => global_func.changePage(
                    context,
                    ShowProfilPage(
                      profil: creatorProfil,
                    )),
                child: Text(
                  creatorName,
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
        backgroundColor: Colors.white,
          appBar: CustomAppBar(
            title: "",
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                  if(widget.toMainPage ?? false){
                    global_func.changePage(context, const CommunityPage(toInformationPage: true,));
                  } else{
                    Navigator.of(context).pop();
                  }
                }
            ),
            buttons: [
              if (!showOnlyOriginal)
                IconButton(
                    onPressed: () => changeLanguage(),
                    tooltip: AppLocalizations.of(context)!.tooltipSpracheWechseln,
                    icon: showOriginalContent ?  const Icon(Icons.translate ): const StrikeThroughIcon(child: Icon(Icons.translate),)),
              IconButton(
                icon: const Icon(Icons.chat),
                tooltip: AppLocalizations.of(context)!.tooltipGroupChatOpen,
                onPressed: () => _openGroupChat(),
              ),
              IconButton(
                icon: const Icon(Icons.link),
                tooltip: AppLocalizations.of(context)!.tooltipLinkKopieren,
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: "</communityId=${widget.community["id"]}"));

                  customSnackBar(
                      context, AppLocalizations.of(context)?.linkWurdekopiert,
                      color: Colors.green);
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => moreMenu(),
              )
            ],
          ),
          body: SafeArea(
            child: Center(
              child: Container(
                width: 600,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  elevation: 12,
                  child: Column(
                    children: [
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            shrinkWrap: true,
                            children: [
                              imageLoading
                                  ? Center(
                                      child: Container(
                                          margin: const EdgeInsets.all(10),
                                          width: 100,
                                          height: 100,
                                          child: const CircularProgressIndicator()))
                                  : communityImage(),
                              const SizedBox(height: 10),
                              ...communityInformation()
                            ],
                          ),
                        ),
                      footbar()
                    ],
                  ),
                ),
              ),
            ),
          )),
    );
  }
}
