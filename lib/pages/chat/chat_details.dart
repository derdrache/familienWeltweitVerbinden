import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:familien_suche/global/global_functions.dart'
    as global_functions;
import 'package:familien_suche/global/variablen.dart' as global_var;
import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/pages/chat/pin_messages.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:familien_suche/pages/start_page.dart';
import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:translator/translator.dart';

import '../informationen/community/community_card.dart';
import '../informationen/community/community_details.dart';
import '../informationen/meetups/meetupCard.dart';
import '../informationen/meetups/meetup_details.dart';
import '../../auth/secrets.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';
import '../../widgets/profil_image.dart';
import '../../widgets/text_with_hyperlink_detection.dart';
import '../../windows/all_user_select.dart';
import '../../widgets/strike_through_icon.dart';
import '../informationen/location/location_Information.dart';
import '../informationen/location/location_card.dart';

class ChatDetailsPage extends StatefulWidget {
  String? chatPartnerId;
  String? chatPartnerName;
  String? chatId;
  Map? groupChatData;
  bool backToChatPage;
  bool isChatgroup;
  String? connectedWith;
  int? chatPageSliderIndex;

  ChatDetailsPage(
      {Key? key,
      this.chatPartnerId,
      this.chatPartnerName,
      this.chatId,
      this.groupChatData,
      this.backToChatPage = false,
      this.isChatgroup = false,
      this.connectedWith,
      this.chatPageSliderIndex})
      : super(key: key);

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage>
    with WidgetsBindingObserver {
  TextEditingController nachrichtController = TextEditingController();
  String userId = FirebaseAuth.instance.currentUser!.uid;
  late Timer timer;
  List<dynamic> messages = [];
  Map? chatPartnerProfil;
  bool bothDelete = false;
  FocusNode messageInputNode = FocusNode();
  FocusNode searchInputNode = FocusNode();
  String? messageExtraInformationId;
  String? changeMessageInputModus;
  Widget extraInputInformationBox = const SizedBox.shrink();
  final _scrollController = ItemScrollController();
  var itemPositionListener = ItemPositionsListener.create();
  bool hasStartPosition = true;
  Map ownProfil = Hive.box('secureBox').get("ownProfil");
  int? angehefteteMessageShowIndex;
  bool isLoading = true;
  bool textSearchIsActive = false;
  TextEditingController searchTextKontroller = TextEditingController();
  List messagesWithSearchText = [];
  bool isTextSearching = false;
  int searchTextIndex = 0;
  List highlightMessages = [];
  Map connectedData = {};
  var pageDetailsPage;
  num unreadMessages = 0;
  List adminList = [mainAdmin];
  final translator = GoogleTranslator();
  String ownLanguage =
      WidgetsBinding.instance.platformDispatcher.locales[0].languageCode;
  int deletedUserColor = 4293467747;
  bool userJoinedChat = false;
  int displayDataEntries = 50;
  late int globalMessageIndex;
  int lastReadMessageIndex = 0;

  @override
  void initState() {
    _getAndSetChatData();
    widget.chatId ??= widget.groupChatData!["id"].toString();
    _setConnectionData();
    _checkSecretChatMember();
    _changeUserChatStatus(1);
    _setScrollbarListener();

    WidgetsBinding.instance.addPostFrameCallback((_) => _asyncMethod());
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    messageInputNode.dispose();

    _changeUserChatStatus(0);

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _changeUserChatStatus(1);
    } else {
      _changeUserChatStatus(0);
    }
  }

  _changeUserChatStatus(int status) {
    if (!userJoinedChat) return;

    Function databaseUpdate = widget.isChatgroup
        ? ChatGroupsDatabase().updateChatGroup
        : ChatDatabase().updateChatGroup;

    widget.groupChatData!["users"][userId]["isActive"] = status;
    databaseUpdate("users = JSON_SET(users, '\$.$userId.isActive', $status)",
        "WHERE id = '${widget.chatId}'");
  }

  _getAndSetChatData() {
    if (!widget.isChatgroup && widget.chatId != null) {
      widget.isChatgroup = !widget.chatId!.contains("_");
    }

    if (widget.isChatgroup) {
      widget.groupChatData ??= getChatGroupFromHive(
          chatId: widget.chatId, connectedWith: widget.connectedWith);

      if (widget.groupChatData == null) {
        widget.groupChatData ??= {
          "id": -1,
          "lastMessageDate": DateTime.now().millisecondsSinceEpoch,
          "lastMessage": "</neuer Chat",
          "users": {},
          "connected": widget.connectedWith
        };
        _createNewChatgroup();
      }
    } else {
      var chatPartnerId = widget.chatPartnerId;
      if (chatPartnerId == null && widget.chatId != null) {
        chatPartnerId = widget.chatId!.replaceAll(ownProfil["id"], "");
        chatPartnerId = chatPartnerId.replaceAll("_", "");
      }
      chatPartnerProfil = getProfilFromHive(
          profilId: chatPartnerId, profilName: widget.chatPartnerName);
      widget.groupChatData ??= getChatFromHive(widget.chatId ??
          global_functions.getChatID(chatPartnerProfil!["id"]));

      widget.groupChatData ??=
          ChatDatabase().addNewChatGroup(chatPartnerProfil!["id"]);
    }

    userJoinedChat = widget.groupChatData!["users"][userId] != null;

    if (userJoinedChat) {
      unreadMessages += widget.groupChatData!["users"][userId]["newMessages"];
    }
  }

  _createNewChatgroup() async {
    widget.groupChatData =
        await ChatGroupsDatabase().addNewChatGroup(null, widget.connectedWith);
  }

  _setConnectionData() {
    if (!widget.isChatgroup) return;

    var connectedId = widget.groupChatData!["connected"] == null
        ? ""
        : widget.groupChatData!["connected"].split("=")[1];

    if (widget.groupChatData!["connected"].contains("event")) {
      connectedData = getMeetupFromHive(connectedId);
      pageDetailsPage = MeetupDetailsPage(
        meetupData: connectedData,
      );
      adminList.add(connectedData["erstelltVon"]);
    } else if (widget.groupChatData!["connected"].contains("community")) {
      connectedData = getCommunityFromHive(connectedId);
      pageDetailsPage = CommunityDetails(
        community: connectedData,
      );
      adminList.add(connectedData["erstelltVon"]);
    } else if (widget.groupChatData!["connected"].contains("stadt")) {
      Map location = getCityFromHive(cityId: connectedId);
      bool iscity = location["isCity"] == 1;
      var cityImage = location["bild"].isEmpty
          ? Hive.box('secureBox').get("allgemein")["cityImage"]
          : location["bild"];
      var countryImage = location["bild"].isEmpty
          ? "assets/bilder/land.jpg"
          : "assets/bilder/flaggen/${location["bild"]}.jpeg";

      connectedData = {
        "name": location["ort"],
        "bild": iscity ? cityImage : countryImage
      };
      pageDetailsPage = LocationInformationPage(ortName: connectedData["name"]);
    } else if (widget.groupChatData!["connected"].contains("world")) {
      connectedData = {
        "name": "World Chat",
        "bild": Hive.box('secureBox').get("allgemein")["worldChatImage"]
      };
    } else if (widget.groupChatData!["connected"].contains("support")) {
      connectedData = {
        "name": "Support Chat",
        "bild": Hive.box('secureBox').get("allgemein")["worldChatImage"]
      };
    }
  }

  _setScrollbarListener() {
    itemPositionListener.itemPositions.addListener(() {
      if (itemPositionListener.itemPositions.value.first.index == 0 &&
          !hasStartPosition) {
        setState(() {
          hasStartPosition = true;
        });
      } else if (itemPositionListener.itemPositions.value.first.index != 0 &&
          hasStartPosition) {
        setState(() {
          hasStartPosition = false;
        });
      }

      var isBottom =
          itemPositionListener.itemPositions.value.last.itemTrailingEdge <= 1;
      if (isBottom) {
        setState(() {
          displayDataEntries += 50;
        });
      }
    });
  }

  _asyncMethod() async {
    messages = await _getAllDbMessages();
    await _checkCardDataForNewMessages();

    setState(() {
      isLoading = false;
    });

    _delayForPinnedMessages();

    timer = Timer.periodic(const Duration(seconds: 30), (Timer t) async {
      messages = await _getAllDbMessages();
      setState(() {});
    });
  }

  _delayForPinnedMessages() async {
    await Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {});
    });

    if(unreadMessages != 0){
      _scrollToMessage(lastReadMessageIndex);
      _resetNewMessageCounter();
    }
  }

  _getAllDbMessages() async {
    var chatId = widget.groupChatData!["id"];

    List<dynamic> allDbMessages = widget.isChatgroup
        ? await ChatGroupsDatabase().getAllChatMessages(chatId)
        : await ChatDatabase().getAllChatMessages(chatId);

    allDbMessages.sort((a, b) => (a["date"]).compareTo(b["date"]));

    return allDbMessages;
  }

  _checkCardDataForNewMessages() async {
    List newMessages = messages.take(unreadMessages.toInt()).toList();

    for (var message in newMessages) {
      if (message["message"].contains("</eventId=")) {
        await refreshHiveMeetups();
      } else if (message["message"].contains("</communityId=")) {
        await refreshHiveCommunities();
      } else if (message["message"].contains("</communityId=")) {
        await refreshHiveStadtInfo();
      }
    }
  }

  _resetNewMessageCounter() async {
    if (!userJoinedChat) return;

    widget.groupChatData!["users"][userId]["newMessages"] = 0;

    if (widget.isChatgroup) {
      ChatGroupsDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.newMessages', 0)",
          "WHERE id = '${widget.chatId}'");
    } else {
      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.newMessages', ${widget.groupChatData!["users"][userId]["newMessages"]})",
          "WHERE id = '${widget.groupChatData!["id"]}'");
    }
  }

  _saveNewMessage(String message) async {
    String ownProfilId = FirebaseAuth.instance.currentUser!.uid;
    String checkMessage = message.split("\n").join();
    if (checkMessage.isEmpty) return;

    var messageData = {
      "chatId": widget.groupChatData!["id"],
      "message": message,
      "von": ownProfilId,
      "date": DateTime.now().millisecondsSinceEpoch.toString(),
      "zu": widget.isChatgroup ? null : chatPartnerProfil!["id"],
      "responseId": messageExtraInformationId ??= "0",
      "forward": "",
      "language": "auto"
    };

    messages.add(messageData);
    widget.groupChatData!["lastMessage"] = message;
    widget.groupChatData!["lastMessageDate"] = int.parse(messageData["date"]);
    messageExtraInformationId = null;

    _saveNewMessageDB(messageData);
  }

  _restartTimer() {
    timer.cancel();
    timer = Timer.periodic(const Duration(seconds: 30), (Timer t) async {
      messages = await _getAllDbMessages();
      setState(() {});
    });
  }

  _saveNewMessageDB(messageData) async {
    var groupText = messageData["message"];

    if (messageData["message"].contains("</eventId=")) {
      groupText = "<Event Card>";
    }
    if (messageData["message"].contains("</communityId=")) {
      groupText = "<Community Card>";
    }
    if (messageData["message"].contains("</cityId=")) {
      groupText = "<Location Card>";
    }

    groupText = groupText.replaceAll("'", "''");

    if (widget.isChatgroup) {
      ChatGroupsDatabase().updateChatGroup(
          "lastMessage = '$groupText' , lastMessageDate = '${messageData["date"]}'",
          "WHERE id = '${widget.groupChatData!["id"]}'");

      var languageCheck = await translator.translate(messageData["message"]);
      var languageCode = languageCheck.sourceLanguage.code;
      messageData["language"] = languageCode;

      await ChatGroupsDatabase().addNewMessageAndNotification(
          widget.groupChatData!["id"], messageData, connectedData["name"]);
    } else {
      ChatDatabase().updateChatGroup(
          "lastMessage = '$groupText' , lastMessageDate = '${messageData["date"]}'",
          "WHERE id = '${widget.groupChatData!["id"]}'");

      var isBlocked =
          ownProfil["geblocktVon"].contains(chatPartnerProfil!["id"]);
      await ChatDatabase().addNewMessageAndSendNotification(
          widget.groupChatData!["id"], messageData, isBlocked);
    }
    messages = await _getAllDbMessages();
    setState(() {});
  }

  _openProfil() {
    if (chatPartnerProfil!.isEmpty || widget.isChatgroup) return;

    global_functions.changePage(
        context,
        ShowProfilPage(
          profil: chatPartnerProfil!,
        ));
  }

  _removeAllNewLineAtTheEnd(String message) {
    while (message.endsWith('\n')) {
      message = message.substring(0, message.length - 1);
    }

    return message;
  }

  _deletePrivatChat() {
    var chatUsers = widget.groupChatData!["users"];
    List myChats = Hive.box("secureBox").get("myChats") ?? [];

    if (chatUsers.length <= 1 || bothDelete) {
      for (var myChat in myChats) {
        if (myChat["id"] == widget.chatId) {
          myChat["users"] = {};
          myChat["id"] = "";
        }
      }

      ChatDatabase().deleteChat(widget.chatId);
      ChatDatabase().deleteAllMessages(widget.chatId);
    } else {
      var newChatUsersData = {};

      chatUsers.forEach((key, value) {
        if (key != userId) {
          newChatUsersData = {key: value};
        }
      });

      for (var myChat in myChats) {
        if (myChat["id"] == widget.chatId) {
          myChat["users"] = newChatUsersData;
        }
      }

      ChatDatabase().updateChatGroup(
          "users = '${json.encode(newChatUsersData)}'",
          "WHERE id ='${widget.chatId}'");
    }

    Navigator.pop(context);

    global_functions.changePageForever(
        context,
        StartPage(
          selectedIndex: 4,
        ));
  }

  _requestMessageInputNode() {
    Future.delayed(const Duration(milliseconds: 50), () {
      messageInputNode.requestFocus();
    });
  }

  _replyMessage(Map message) {
    setState(() {
      messageExtraInformationId = message["id"];
      changeMessageInputModus = "reply";
    });

    _requestMessageInputNode();
  }

  _editMessage(Map message) {
    messageExtraInformationId = message["id"];
    nachrichtController.text = message["message"];

    setState(() {
      changeMessageInputModus = "edit";
    });

    _requestMessageInputNode();
  }

  _copyMessage(String messageText) {
    Clipboard.setData(ClipboardData(text: messageText));
    customSnackbar(
        context, AppLocalizations.of(context)!.nachrichtZwischenAblage,
        color: Colors.green, duration: const Duration(seconds: 1));
  }

  _forwardedMessage(Map message) async {
    var allUserSelectWindow = AllUserSelectWindow(
        context: context,
        title: AppLocalizations.of(context)!.empfaengerWaehlen);
    var selectedUserId = await allUserSelectWindow.openWindow();
    var selectedChatId = global_functions.getChatID(selectedUserId);
    var chatGroupData =
        await ChatDatabase().getChatData("*", "WHERE id = '$selectedChatId'");
    var forwardMessage = message["forward"].isEmpty
        ? message["von"]
        : message["forward"].split(":")[1].toString();

    var messageData = {
      "message": message["message"],
      "von": userId,
      "date": DateTime.now().millisecondsSinceEpoch.toString(),
      "zu": selectedUserId,
      "forward": "userId:$forwardMessage",
      "responseId": "0"
    };

    ChatDatabase().updateChatGroup(
        "lastMessage = '${messageData["message"]}' , lastMessageDate = '${messageData["date"]}'",
        "WHERE id = '$selectedChatId'");

    var isBlocked = ownProfil["geblocktVon"].contains(userId);
    await ChatDatabase().addNewMessageAndSendNotification(
        chatGroupData["id"], messageData, isBlocked);

    global_functions.changePage(
        context,
        ChatDetailsPage(
            chatPartnerId: selectedUserId,
            groupChatData: chatGroupData,
            backToChatPage: true));
  }

  _deleteMessageWindow(messageId) {
    Future.delayed(
        const Duration(seconds: 0),
        () => showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: AppLocalizations.of(context)!.nachrichtLoeschen,
                height: 100,
                actions: [
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.loeschen),
                    onPressed: () {
                      _deleteMessage(messageId);
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.abbrechen),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
                children: [
                  Center(
                      child: Text(AppLocalizations.of(context)!
                          .nachrichtWirklichLoeschen))
                ],
              );
            }));
  }

  _deleteMessage(messageId) {
    _checkIfLastMessageAndChangeChatGroup(messageId);

    if (widget.isChatgroup) {
      ChatGroupsDatabase().deleteMessages(messageId);
    } else {
      ChatDatabase().deleteMessages(messageId);
    }

    messages.removeWhere((element) => element["id"] == messageId);
  }

  _checkIfLastMessageAndChangeChatGroup(messageId) {
    var lastMessage = messages.last;
    var secondLastMessage = messages[messages.length - 2];

    if (messageId != lastMessage["id"]) return;

    String messageText = secondLastMessage["message"];
    widget.groupChatData!["lastMessageDate"] =
        int.parse(secondLastMessage["date"]);

    if (messageText.contains("</eventId=")) {
      messageText = "<Event Card>";
    }
    if (messageText.contains("</communityId=")) {
      messageText = "<Community Card>";
    }
    if (messageText.contains("</cityId=")) {
      messageText = "<Location Card>";
    }

    if (widget.isChatgroup) {
      ChatGroupsDatabase().updateChatGroup(
          "lastMessage = '$messageText' , lastMessageDate = '${secondLastMessage["date"]}'",
          "WHERE id = '${widget.chatId}'");
    } else {
      ChatDatabase().updateChatGroup(
          "lastMessage = '${secondLastMessage["message"]}' , lastMessageDate = '${secondLastMessage["date"]}'",
          "WHERE id = '${widget.chatId}'");
    }
  }

  _reportMessage(Map message) {
    String reportTitle = widget.isChatgroup ? "Chatgroup" : "Privatechat";

    ReportsDatabase().add(
        userId,
        "Message ${message["id"]} in $reportTitle gemeldet",
        message["message"]);

    customSnackbar(context, AppLocalizations.of(context)!.nachrichtGemeldet,
        color: Colors.green, duration: const Duration(seconds: 2));
  }

  _getPinnedMessages() {
    var pinnedMessages =
        widget.groupChatData!["users"][userId]["pinnedMessages"];
    if (pinnedMessages.runtimeType == String) {
      return json.decode(pinnedMessages);
    }
    return pinnedMessages ?? [];
  }

  _pinMessage(Map message) async {
    List? pinnedMessages = _getPinnedMessages();

    if (pinnedMessages == null || pinnedMessages.isEmpty) {
      widget.groupChatData!["users"][userId]
          ["pinnedMessages"] = [int.parse(message["id"])];

      setState(() {
        angehefteteMessageShowIndex =
            widget.groupChatData!["users"][userId]["pinnedMessages"].length - 1;
      });

      if (widget.isChatgroup) {
        ChatGroupsDatabase().updateChatGroup(
            "users = JSON_SET(users, '\$.$userId.pinnedMessages', '${[
              message["id"]
            ]}')",
            "WHERE id = '${message["chatId"]}'");
      } else {
        ChatDatabase().updateChatGroup(
            "users = JSON_SET(users, '\$.$userId.pinnedMessages', '${[
              message["id"]
            ]}')",
            "WHERE id = '${message["chatId"]}'");
      }
    } else {
      pinnedMessages.add(int.parse(message["id"]));
      widget.groupChatData!["users"][userId]["pinnedMessages"] = pinnedMessages;

      setState(() {
        angehefteteMessageShowIndex = pinnedMessages.length - 1;
      });

      if (widget.isChatgroup) {
        ChatGroupsDatabase().updateChatGroup(
            "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$pinnedMessages')",
            "WHERE id = '${message["chatId"]}'");
      } else {
        ChatDatabase().updateChatGroup(
            "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$pinnedMessages')",
            "WHERE id = '${message["chatId"]}'");
      }
    }
  }

  _detachMessage(Map message, int index) {
    List pinnedMessages = _getPinnedMessages();

    pinnedMessages.remove(int.parse(message["id"]));

    widget.groupChatData!["users"][userId]["pinnedMessages"] = pinnedMessages;

    setState(() {
      angehefteteMessageShowIndex = pinnedMessages.length - 1;
    });

    if (widget.isChatgroup) {
      ChatGroupsDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$pinnedMessages')",
          "WHERE id = '${message["chatId"]}'");
    } else {
      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$pinnedMessages')",
          "WHERE id = '${message["chatId"]}'");
    }
  }

  _resetExtraInputInformation() {
    extraInputInformationBox = const SizedBox.shrink();
    nachrichtController.clear();
    changeMessageInputModus = null;

    setState(() {});
  }

  _saveEditMessage() {
    for (var message in messages) {
      if (message["id"] == messageExtraInformationId) {
        message["message"] = nachrichtController.text;
        message["editDate"] = DateTime.now();
      }
    }

    if (widget.isChatgroup) {
      ChatGroupsDatabase().updateMessage(
          "message = '${nachrichtController.text}', editDate = '${DateTime.now()}'",
          "WHERE id = '$messageExtraInformationId'");
    } else {
      ChatDatabase().updateMessage(
          "message = '${nachrichtController.text}', editDate = '${DateTime.now()}'",
          "WHERE id = '$messageExtraInformationId'");
    }
  }

  _showAllPinMessages() {
    List pinnedMessages = _getPinnedMessages();
    List allPinMessages = [];

    for (var pinMessageId in pinnedMessages) {
      for (var message in messages) {
        if (pinMessageId.toString() == message["id"]) {
          allPinMessages.add(message);
        }
      }
    }

    global_functions.changePage(
        context, pinMessagesPage(pinMessages: allPinMessages));
  }

  _jumpToMessageAndShowNextAngeheftet(int index) {
    angehefteteMessageShowIndex = angehefteteMessageShowIndex! - 1;

    if (angehefteteMessageShowIndex! < 0) {
      angehefteteMessageShowIndex = _getPinnedMessages().length - 1;
    }



    _scrollToMessage(index);
    _highlightMessage(index);
  }

  _searchTextInMessages(String searchText) {
    messagesWithSearchText = [];

    for (var message in messages) {
      if (message["message"].toLowerCase().contains(searchText.toLowerCase())) {
        messagesWithSearchText.add(message);
      }
    }

    messagesWithSearchText = messagesWithSearchText.reversed.toList();
  }

  _nextTextSearchItem(String direction) {
    var maxResults = messagesWithSearchText.length - 1;

    if (direction == "up") {
      searchTextIndex += 1;
      if (searchTextIndex > maxResults) searchTextIndex = 0;
    } else if (direction == "down") {
      searchTextIndex -= 1;
      if (searchTextIndex < 0) searchTextIndex = maxResults;
    }

    var searchScrollIndex = messagesWithSearchText[searchTextIndex]["index"];

    _scrollToMessage(searchScrollIndex);
    _highlightMessage(searchScrollIndex);
  }

  _scrollToMessage(int messageIndex) {
    int scrollToIndex = globalMessageIndex - 1 - messageIndex;

    if (scrollToIndex < 0) scrollToIndex = 0;

    _scrollController.scrollTo(
        index: scrollToIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic);
  }

  _highlightMessage(int messageIndex) {
    setState(() {
      highlightMessages.add(messageIndex);
    });

    Future.delayed(const Duration(milliseconds: 1300), () {
      setState(() {
        highlightMessages.remove(messageIndex);
      });
    });
  }

  _checkAndRemovePinnedMessage(Map message) {
    List pinnedMessages = _getPinnedMessages();

    pinnedMessages.remove(int.parse(message["id"]));

    widget.groupChatData!["users"][userId]["pinnedMessages"] = pinnedMessages;
    angehefteteMessageShowIndex = pinnedMessages.length - 1;

    if (widget.isChatgroup) {
      ChatGroupsDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$pinnedMessages')",
          "WHERE id = '${message["chatId"]}'");
    } else {
      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$pinnedMessages')",
          "WHERE id = '${message["chatId"]}'");
    }
  }

  _joinChatGroup() {
    List myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];
    Map newUserInformation = {"newMessages": 0};

    setState(() {
      widget.groupChatData!["users"][userId] = newUserInformation;
      userJoinedChat = true;
    });

    myGroupChats.add(widget.groupChatData);
    Hive.box("secureBox").put("myGroupChats", myGroupChats);

    ChatGroupsDatabase().updateChatGroup(
        "users = JSON_MERGE_PATCH(users, '${json.encode({
              userId: newUserInformation
            })}')",
        "WHERE id = ${widget.chatId}");

    _changeUserChatStatus(1);
  }

  _getDisplayedCard(cardType, data, {smallCard = false}) {
    if (cardType == "event") {
      return MeetupCard(
          margin:
              const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 0),
          withInteresse: true,
          meetupData: data,
          afterPageVisit: () => setState(() {}),
          smallCard: smallCard);
    } else if (cardType == "community") {
      return CommunityCard(
        margin: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 0),
        community: data,
        afterPageVisit: () => setState(() {}),
        smallCard: smallCard,
      );
    } else if (cardType == "location") {
      return LocationCard(location: data, smallCard: smallCard);
    }
  }

  _getInitialScrollIndex() {
    int index = 0;
    int noScrollCount = 4;

    if (unreadMessages == 0 || unreadMessages <= noScrollCount) return index;

    return unreadMessages - noScrollCount;
  }

  _getCardIdDataFromMessage(String message) {
    List messageSplit = message.replaceAll("\n", " ").split(" ");
    Map data = {
      "id": "",
      "typ": "",
      "text": "",
      "hasOnlyId": messageSplit.length == 1
    };

    for (var text in messageSplit) {
      if (text.contains("</eventId=")) {
        data["id"] = text.substring(10);
        data["typ"] = "event";
        data["text"] = "</eventId=${data["id"]}";
        break;
      } else if (text.contains("</communityId=")) {
        data["id"] = text.substring(14);
        data["typ"] = "community";
        data["text"] = "</communityId=${data["id"]}";
        break;
      } else if (text.contains("</cityId=")) {
        data["id"] = text.substring(9);
        data["typ"] = "city";
        data["text"] = "</cityId=${data["id"]}";
        break;
      }
    }

    return data;
  }

  _checkSecretChatMember() {
    if (connectedData.isEmpty) return;

    bool hasSecretChat = connectedData["secretChat"] == 1;

    if (!hasSecretChat) return;

    List removeUser = [];

    for (var user in widget.groupChatData!["users"].keys.toList()) {
      if (!connectedData["members"].contains(user)) removeUser.add(user);
    }

    for (var user in removeUser) {
      widget.groupChatData!["users"].remove(user);
    }
  }

  getLastReadMessageIndex(messageBox){
    int unreadMessagesCounter = unreadMessages as int;
    int lastReadMessageIndex = 0;

    for(var message in messageBox.reversed){
      lastReadMessageIndex += 1;

      if(message.runtimeType != Align){
        unreadMessagesCounter -= 1;
      }

      if(unreadMessagesCounter == 0) break;
    }

    return messageBox.length - lastReadMessageIndex;
  }

  @override
  Widget build(BuildContext context) {
    Color ownMessageBoxColor =
        Theme.of(context).colorScheme.secondary.withOpacity(0.7);
    Color chatpartnerMessageBoxColor = Colors.white;
    Color? timeStampColor = Colors.grey[600];
    Offset? tabPosition;

    angehefteteNachrichten() {
      if (!userJoinedChat) {
        return const SizedBox.shrink();
      }

      List? pinnedMessages = _getPinnedMessages();

      if (pinnedMessages == null || pinnedMessages.isEmpty) {
        return const SizedBox.shrink();
      }

      angehefteteMessageShowIndex ??= pinnedMessages.length - 1;
      int displayedMessageId = pinnedMessages[angehefteteMessageShowIndex!];
      String displayedMessageText = "";
      int messageIndex = 0;

      for (var message in messages) {
        if (message["id"] == displayedMessageId.toString()) {
          messageIndex = message["index"] ?? 0;
          displayedMessageText = message["message"];
          break;
        }
      }

      return GestureDetector(
        onTap: () => _jumpToMessageAndShowNextAngeheftet(messageIndex),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration:
              BoxDecoration(color: Colors.white60, border: Border.all()),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.angehefteteNachrichten,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      displayedMessageText,
                      maxLines: 1,
                    )
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showAllPinMessages(),
                child: const Icon(
                  Icons.manage_search,
                  size: 35,
                ),
              ),
            ],
          ),
        ),
      );
    }

    inputInformationBox(IconData icon, String? title, String bodyText) {
      return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: const BorderSide(color: Colors.grey),
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.3))),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 0,
                  blurRadius: 7,
                  offset: const Offset(0, -2),
                ),
              ]),
          child: Row(children: [
            const SizedBox(width: 5),
            const Icon(Icons.reply),
            const SizedBox(width: 20),
            if (bodyText.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title ?? AppLocalizations.of(context)!.geloeschterUser,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold)),
                    Text(bodyText, maxLines: 1, overflow: TextOverflow.ellipsis)
                  ],
                ),
              ),
            if (bodyText.isEmpty)
              Expanded(
                child: Text(title!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _resetExtraInputInformation(),
            )
          ]));
    }

    openMessageMenu(Map message, int index) {
      final RenderBox overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      bool isMyMessage = message["von"] == userId;
      bool isInPinned = false;
      List angehefteteMessages = [];

      if (userJoinedChat &&
          widget.groupChatData!["users"][userId]["pinnedMessages"] != null) {
        angehefteteMessages = _getPinnedMessages();
      }

      for (var pinId in angehefteteMessages) {
        if (pinId.toString() == message["id"]) {
          isInPinned = true;
          break;
        }
      }

      showMenu(
        context: context,
        position: RelativeRect.fromRect(
            (tabPosition ?? const Offset(20, 250)) & const Size(40, 40),
            Offset.zero & overlay.size),
        items: [
          if (userJoinedChat)
            PopupMenuItem(
              onTap: () {
                String? replyUserName = getProfilFromHive(
                    profilId: message["von"], getNameOnly: true);

                extraInputInformationBox = inputInformationBox(
                    Icons.reply, replyUserName, message["message"]);

                _replyMessage(message);
              },
              child: Row(
                children: [
                  const Icon(Icons.reply),
                  const SizedBox(width: 20),
                  Text(AppLocalizations.of(context)!.antworten),
                ],
              ),
            ),
          if (userJoinedChat)
            PopupMenuItem(
              onTap: () => isInPinned
                  ? _detachMessage(message, index)
                  : _pinMessage(message),
              child: Row(
                children: [
                  isInPinned
                      ? StrikeThroughIcon(child: const Icon(Icons.push_pin))
                      : const Icon(Icons.push_pin),
                  const SizedBox(width: 20),
                  Text(isInPinned
                      ? AppLocalizations.of(context)!.losloesen
                      : AppLocalizations.of(context)!.anheften),
                ],
              ),
            ),
          if (isMyMessage)
            PopupMenuItem(
              onTap: () {
                extraInputInformationBox = inputInformationBox(Icons.edit,
                    AppLocalizations.of(context)!.nachrichtBearbeiten, "");

                _editMessage(message);
              },
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 20),
                  Text(AppLocalizations.of(context)!.bearbeiten),
                ],
              ),
            ),
          PopupMenuItem(
            onTap: () => _copyMessage(message["message"]),
            child: Row(
              children: [
                const Icon(Icons.copy),
                const SizedBox(width: 20),
                Text(AppLocalizations.of(context)!.textKopieren),
              ],
            ),
          ),
          if (userJoinedChat)
            PopupMenuItem(
              onTap: () => Future.delayed(
                  const Duration(seconds: 0), () => _forwardedMessage(message)),
              child: Row(
                children: [
                  const Icon(Icons.forward),
                  const SizedBox(width: 20),
                  Text(AppLocalizations.of(context)!.weiterleiten),
                ],
              ),
            ),
          if (isMyMessage || adminList.contains(userId))
            PopupMenuItem(
              onTap: () {
                _checkAndRemovePinnedMessage(message);
                _deleteMessageWindow(message["id"]);
              },
              child: Row(
                children: [
                  const Icon(Icons.delete),
                  const SizedBox(width: 20),
                  Text(AppLocalizations.of(context)!.loeschenGross),
                ],
              ),
            ),
          if (!isMyMessage && userJoinedChat)
            PopupMenuItem(
              onTap: () => _reportMessage(message),
              child: Row(
                children: [
                  const Icon(Icons.report),
                  const SizedBox(width: 20),
                  Text(AppLocalizations.of(context)!.meldenGross),
                ],
              ),
            ),
        ],
        elevation: 4.0,
      );
    }

    translationButton(Map message) {
      return Positioned(
          right: 5,
          bottom: -10,
          child: TextButton(
              child: Text(AppLocalizations.of(context)!.uebersetzen),
              onPressed: () async {
                String translationMessage =
                    message["message"].replaceAll("'", "");

                var translation = await translator.translate(translationMessage,
                    from: "auto", to: ownLanguage);

                showModalBottomSheet<void>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    isScrollControlled: true,
                    context: context,
                    builder: (BuildContext context) {
                      return Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(
                                top: 30, left: 30, bottom: 20, right: 15),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(AppLocalizations.of(context)!.uebersetzen,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 15),
                                ListView(
                                  shrinkWrap: true,
                                  children: [
                                    Text(
                                      translation.toString(),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: double.maxFinite,
                                  child: FloatingActionButton.extended(
                                    onPressed: () => Navigator.pop(context),
                                    label: Text(AppLocalizations.of(context)!
                                        .uebersetzungSchliessen),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const Positioned(
                              top: 0,
                              right: 0,
                              child: CloseButton(
                                color: Colors.red,
                              ))
                        ],
                      );
                    });
              }));
    }

    cardMessage(
        int index, Map message, Map messageBoxInformation, String cardType) {
      Map cardData = {};
      bool hasForward = message["forward"].isNotEmpty;
      Map forwardProfil = {};
      Map creatorProfilData = getProfilFromHive(profilId: message["von"]) ?? {};
      String creatorName = creatorProfilData["name"] ??
          AppLocalizations.of(context)!.geloeschterUser;
      var creatorColor = creatorProfilData["bildStandardFarbe"] ?? deletedUserColor;
      bool isMyMessage = message["von"] == userId;

      if (hasForward) {
        var messageAutorId = message["forward"].split(":")[1];
        forwardProfil = getProfilFromHive(profilId: messageAutorId);
      }

      Map cardIdData = _getCardIdDataFromMessage(message["message"]);

      if (cardIdData["typ"] == "event") {
        cardData = getMeetupFromHive(cardIdData["id"]);
      } else if (cardIdData["typ"] == "community") {
        cardData = getCommunityFromHive(cardIdData["id"]);
      } else if (cardIdData["typ"] == "city") {
        cardData = getCityFromHive(cityId: cardIdData["id"]);
      }

      String replaceText = cardData["name"] ?? cardData["ort"];
      String removeId = cardIdData["text"];

      String? changedMessageText =
          message["message"].replaceAll(removeId, replaceText).trim();

      if (cardData.isEmpty) return const SizedBox.shrink();

      message["index"] = index;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            messageBoxInformation["textAlign"] == Alignment.centerLeft
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
        children: [
          if (widget.isChatgroup && message["von"] != userId)
            Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(left: 5, bottom: 10),
                child: ProfilImage(creatorProfilData)),
          AnimatedContainer(
            color: highlightMessages.contains(index)
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            duration: const Duration(seconds: 1),
            curve: Curves.easeIn,
            child: Align(
                alignment: messageBoxInformation["textAlign"],
                child: Column(
                    crossAxisAlignment: messageBoxInformation["textAlign"] ==
                            Alignment.centerLeft
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      if (widget.isChatgroup && message["von"] != userId)
                        GestureDetector(
                          onTap: creatorProfilData.isEmpty
                              ? null
                              : () => global_functions.changePage(
                                  context,
                                  ShowProfilPage(
                                    profil: creatorProfilData,
                                  )),
                          child: Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                creatorName,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(creatorColor)),
                              )),
                        ),
                      if (hasForward)
                        Container(
                          alignment: messageBoxInformation["textAlign"],
                          padding:
                              const EdgeInsets.only(top: 5, left: 10, right: 5),
                          child: GestureDetector(
                            onTap: forwardProfil.isEmpty
                                ? null
                                : () => () => global_functions.changePage(
                                    context,
                                    ShowProfilPage(
                                      profil: forwardProfil,
                                    )),
                            child: Text(
                              AppLocalizations.of(context)!.weitergeleitetVon +
                                  forwardProfil["name"],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      Container(
                          alignment: messageBoxInformation["textAlign"],
                          child: Stack(
                            children: [
                              _getDisplayedCard(cardType, cardData),
                              if (isMyMessage || adminList.contains(userId))
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: InkWell(
                                    onTap: () {
                                      _checkAndRemovePinnedMessage(message);
                                      _deleteMessageWindow(message["id"]);
                                    },
                                    child: const CircleAvatar(
                                        radius: 12.0,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close,
                                            color: Colors.white, size: 18)),
                                  ),
                                )
                            ],
                          )),
                      cardIdData["hasOnlyId"]
                          ? Row(
                              children: [
                                if (messageBoxInformation["textAlign"] ==
                                    Alignment.centerLeft)
                                  const SizedBox(width: 10),
                                TextButton(
                                    onPressed: () {
                                      var replyUser = getProfilFromHive(
                                          profilId: message["von"],
                                          getNameOnly: true);

                                      extraInputInformationBox =
                                          inputInformationBox(Icons.reply,
                                              replyUser, message["message"]);
                                      _replyMessage(message);
                                    },
                                    child: Text(AppLocalizations.of(context)!
                                        .antworten)),
                                TextButton(
                                    onPressed: () {
                                      _forwardedMessage(message);
                                    },
                                    child: Text(AppLocalizations.of(context)!
                                        .weiterleiten)),
                                Text(messageBoxInformation["messageTime"],
                                    style: TextStyle(color: timeStampColor)),
                                if (messageBoxInformation["textAlign"] ==
                                    Alignment.centerRight)
                                  const SizedBox(width: 10),
                              ],
                            )
                          : Align(
                              alignment: messageBoxInformation["textAlign"],
                              child: Stack(
                                children: [
                                  Container(
                                      constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.8),
                                      margin: const EdgeInsets.all(10),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: messageBoxInformation[
                                              "messageBoxColor"],
                                          border: Border.all(),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(10))),
                                      child: Wrap(
                                        alignment: WrapAlignment.end,
                                        children: [
                                          TextWithHyperlinkDetection(
                                              text: changedMessageText ?? "",
                                              fontsize: 16,
                                              onTextTab: () => openMessageMenu(
                                                  message, index)),
                                          const SizedBox(width: 5),
                                          Text(
                                              messageBoxInformation[
                                                      "messageEdit"] +
                                                  " " +
                                                  messageBoxInformation[
                                                      "messageTime"],
                                              style: const TextStyle(
                                                  color: Colors.transparent))
                                        ],
                                      )),
                                  Positioned(
                                    right: 20,
                                    bottom: 15,
                                    child: Text(
                                        messageBoxInformation["messageEdit"] +
                                            messageBoxInformation[
                                                "messageTime"],
                                        style:
                                            TextStyle(color: timeStampColor)),
                                  ),
                                ],
                              ),
                            )
                    ])),
          ),
        ],
      );
    }

    responseMessage(int index, Map message, Map messageBoxInformation) {
      Map replyMessage = {};
      int replyIndex = messages.length;
      Map cardData = {};
      String textAddition = "";
      Map creatorData = getProfilFromHive(profilId: message["von"]) ?? {};
      String creatorName =
          creatorData["name"] ?? AppLocalizations.of(context)!.geloeschterUser;
      var creatorColor = creatorData["bildStandardFarbe"] ?? deletedUserColor;

      for (Map lookMessage in messages.reversed.toList()) {
        replyIndex -= 1;

        if (lookMessage["id"] == message["responseId"]) {
          replyMessage = lookMessage;
          break;
        }
      }

      String? replyFromId = replyMessage["von"];
      Map messageFromProfil = getProfilFromHive(profilId: replyFromId) ?? {};
      var replyColor = messageFromProfil["bildStandardFarbe"] == deletedUserColor
          ? Colors.greenAccent[100]
          : messageFromProfil["bildStandardFarbe"] != null
              ? Color(messageFromProfil["bildStandardFarbe"])
              : Colors.black;
      bool isEvent = replyMessage.isEmpty
          ? false
          : replyMessage["message"].contains("</eventId=");
      bool isCommunity = replyMessage.isEmpty
          ? false
          : replyMessage["message"].contains("</communityId=");
      bool isLocation = replyMessage.isEmpty
          ? false
          : replyMessage["message"].contains("</cityId=");
      bool containsCard = isEvent || isCommunity || isLocation;
      String cardTyp = "";

      if (isEvent || isCommunity || isLocation) {
        Map cardIdData = _getCardIdDataFromMessage(replyMessage["message"]);

        if (cardIdData["typ"] == "event") {
          cardData = getMeetupFromHive(cardIdData["id"]);
          textAddition = "Event: ";
          cardTyp = "event";
        } else if (cardIdData["typ"] == "community") {
          cardData = getCommunityFromHive(cardIdData["id"]);
          textAddition = "Community: ";
          cardTyp = "community";
        } else if (cardIdData["typ"] == "city") {
          cardData = getCityFromHive(cityId: cardIdData["id"]);
          cardTyp = "location";
        }
      }

      message["index"] = index;

      return Listener(
        onPointerHover: (details) => tabPosition = details.position,
        child: AnimatedContainer(
          color: highlightMessages.contains(index)
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          duration: const Duration(seconds: 1),
          curve: Curves.easeIn,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                messageBoxInformation["textAlign"] == Alignment.centerLeft
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
            children: [
              if (widget.isChatgroup && message["von"] != userId)
                Container(
                    width: 50,
                    height: 50,
                    margin: EdgeInsets.only(
                        left: 5,
                        bottom: message["showTranslationButton"] ? 25 : 10),
                    child: GestureDetector(
                      child: ProfilImage(creatorData),
                      onTap: creatorData.isEmpty
                          ? null
                          : () => global_functions.changePage(
                              context,
                              ShowProfilPage(
                                profil: creatorData,
                              )),
                    )),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (messageBoxInformation["textAlign"] ==
                        Alignment.centerRight)
                      const Expanded(flex: 2, child: SizedBox.shrink()),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => openMessageMenu(message, index),
                          child: Container(
                              margin: EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                  top: 10,
                                  bottom: message["showTranslationButton"]
                                      ? 25
                                      : 10),
                              decoration: BoxDecoration(
                                  color:
                                      messageBoxInformation["messageBoxColor"],
                                  border: Border.all(),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.isChatgroup &&
                                      message["von"] != userId)
                                    GestureDetector(
                                      onTap: creatorData.isEmpty
                                          ? null
                                          : () => global_functions.changePage(
                                              context,
                                              ShowProfilPage(
                                                profil: creatorData,
                                              )),
                                      child: Container(
                                          margin: const EdgeInsets.only(
                                              left: 10, top: 10),
                                          child: Text(
                                            creatorName,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(creatorColor)),
                                          )),
                                    ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (replyFromId != null) {
                                        _scrollToMessage(replyIndex);
                                        _highlightMessage(replyIndex);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 10, top: 5),
                                      child: Container(
                                          padding: const EdgeInsets.only(
                                              left: 10, right: 10),
                                          decoration: BoxDecoration(
                                              border: Border(
                                                  left: BorderSide(
                                                      width: 2,
                                                      color: replyColor!))),
                                          child: Container(
                                            height: replyFromId != null
                                                ? containsCard
                                                    ? 142
                                                    : 39
                                                : 18,
                                            constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.70),
                                            child: replyFromId != null
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          messageFromProfil[
                                                                  "name"] ??
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .geloeschterUser,
                                                          style:
                                                              TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      replyColor)),
                                                      if (!containsCard)
                                                        const SizedBox(
                                                            height: 3),
                                                      Flexible(
                                                        child: !containsCard
                                                            ? Text(
                                                                cardData["name"] ==
                                                                        null
                                                                    ? replyMessage[
                                                                        "message"]
                                                                    : textAddition +
                                                                        cardData[
                                                                            "name"],
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              )
                                                            : _getDisplayedCard(
                                                                cardTyp,
                                                                cardData,
                                                                smallCard:
                                                                    true),
                                                      )
                                                    ],
                                                  )
                                                : Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .geloeschteNachricht,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                          )),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(
                                        top: 5, left: 10, bottom: 7, right: 10),
                                    constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.745),
                                    child: Wrap(
                                      children: [
                                        TextWithHyperlinkDetection(
                                          text: message["message"] ?? "",
                                          fontsize: 16,
                                          onTextTab: () =>
                                              openMessageMenu(message, index),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                            messageBoxInformation[
                                                    "messageEdit"] +
                                                " " +
                                                messageBoxInformation[
                                                    "messageTime"],
                                            style: const TextStyle(
                                                color: Colors.transparent))
                                      ],
                                    ),
                                  ),
                                ],
                              )),
                        ),
                        Positioned(
                          right: 20,
                          bottom: message["showTranslationButton"] ? 30 : 15,
                          child: GestureDetector(
                            onTap: () => openMessageMenu(message, index),
                            child: Text(
                                messageBoxInformation["messageEdit"] +
                                    " " +
                                    messageBoxInformation["messageTime"],
                                style: TextStyle(color: timeStampColor)),
                          ),
                        ),
                        if (message["showTranslationButton"])
                          translationButton(message)
                      ],
                    ),
                    if (messageBoxInformation["textAlign"] ==
                        Alignment.centerLeft)
                      const Expanded(flex: 2, child: SizedBox.shrink()),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    forwardMessage(int index, Map message, Map messageBoxInformation) {
      String messageAutorId = message["forward"].split(":")[1];
      Map forwardProfil = getProfilFromHive(profilId: messageAutorId);
      Map creatorData = getProfilFromHive(profilId: message["von"]);
      message["index"] = index;

      return Listener(
        onPointerHover: (details) => tabPosition = details.position,
        child: AnimatedContainer(
          color: highlightMessages.contains(index)
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          duration: const Duration(seconds: 1),
          curve: Curves.easeIn,
          child: Row(
            mainAxisAlignment:
                messageBoxInformation["textAlign"] == Alignment.centerLeft
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.isChatgroup && message["von"] != userId)
                Container(
                    margin: EdgeInsets.only(
                        left: 5,
                        bottom: message["showTranslationButton"] ? 25 : 10),
                    child: GestureDetector(
                      child: ProfilImage(creatorData),
                      onTap: creatorData.isEmpty
                          ? null
                          : () => global_functions.changePage(
                              context,
                              ShowProfilPage(
                                profil: creatorData,
                              )),
                    )),
              Stack(
                children: [
                  Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.85),
                      margin: EdgeInsets.only(
                          left: 10,
                          right: 10,
                          top: 10,
                          bottom: message["showTranslationButton"] ? 25 : 10),
                      decoration: BoxDecoration(
                          color: messageBoxInformation["messageBoxColor"],
                          border: Border.all(),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(
                                top: 5, left: 10, right: 5),
                            child: GestureDetector(
                              onTap: creatorData.isEmpty
                                  ? null
                                  : () => global_functions.changePage(
                                      context,
                                      ShowProfilPage(
                                        profil: forwardProfil,
                                      )),
                              child: Text(
                                AppLocalizations.of(context)!
                                        .weitergeleitetVon +
                                    forwardProfil["name"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => openMessageMenu(message, index),
                            child: Wrap(
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(
                                      top: 5, left: 10, bottom: 7, right: 10),
                                  child: TextWithHyperlinkDetection(
                                      text: message["message"] ?? "",
                                      fontsize: 16,
                                      onTextTab: () =>
                                          openMessageMenu(message, index)),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                    messageBoxInformation["messageEdit"] +
                                        " " +
                                        messageBoxInformation["messageTime"],
                                    style: const TextStyle(
                                        color: Colors.transparent))
                              ],
                            ),
                          ),
                        ],
                      )),
                  Positioned(
                    right: 20,
                    bottom: message["showTranslationButton"] ? 30 : 15,
                    child: Text(
                        messageBoxInformation["messageEdit"] +
                            " " +
                            messageBoxInformation["messageTime"],
                        style: TextStyle(color: timeStampColor)),
                  ),
                  if (message["showTranslationButton"])
                    translationButton(message)
                ],
              ),
            ],
          ),
        ),
      );
    }

    normalMessage(int index, Map message, Map messageBoxInformation) {
      Map creatorData = getProfilFromHive(profilId: message["von"]) ?? {};
      String creatorName =
          creatorData["name"] ?? AppLocalizations.of(context)!.geloeschterUser;
      var creatorColor = creatorData["bildStandardFarbe"];
      message["index"] = index;

      return Listener(
        onPointerHover: (details) {
          tabPosition = details.position;
        },
        child: AnimatedContainer(
          color: highlightMessages.contains(index)
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          duration: const Duration(seconds: 1),
          curve: Curves.easeIn,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                messageBoxInformation["textAlign"] == Alignment.centerLeft
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
            children: [
              if (widget.isChatgroup && message["von"] != userId)
                Container(
                    width: 50,
                    height: 50,
                    margin: EdgeInsets.only(
                        left: 5,
                        bottom: message["showTranslationButton"] ? 25 : 10),
                    child: GestureDetector(
                      child: ProfilImage(creatorData),
                      onTap: creatorData.isEmpty
                          ? null
                          : () => global_functions.changePage(
                              context,
                              ShowProfilPage(
                                profil: creatorData,
                              )),
                    )),
              GestureDetector(
                onTap: () => openMessageMenu(message, index),
                child: Stack(
                  children: [
                    Container(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width *
                                (widget.isChatgroup && message["von"] != userId
                                    ? 0.75
                                    : 0.85)),
                        margin: EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 10,
                            bottom: message["showTranslationButton"] ? 25 : 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: messageBoxInformation["messageBoxColor"],
                            border: Border.all(),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.isChatgroup && message["von"] != userId)
                              GestureDetector(
                                onTap: creatorData.isEmpty
                                    ? null
                                    : () => global_functions.changePage(
                                        context,
                                        ShowProfilPage(
                                          profil: creatorData,
                                        )),
                                child: Container(
                                    margin: const EdgeInsets.only(bottom: 5),
                                    child: Text(
                                      creatorName,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(creatorColor ?? deletedUserColor)),
                                    )),
                              ),
                            Wrap(
                              alignment: WrapAlignment.end,
                              children: [
                                TextWithHyperlinkDetection(
                                    text: message["message"] ?? "",
                                    fontsize: 16,
                                    onTextTab: () =>
                                        openMessageMenu(message, index)),
                                const SizedBox(width: 5),
                                Text(
                                    messageBoxInformation["messageEdit"] +
                                        messageBoxInformation["messageTime"],
                                    style: const TextStyle(
                                        color: Colors.transparent))
                              ],
                            ),
                          ],
                        )),
                    Positioned(
                      right: 20,
                      bottom: message["showTranslationButton"] ? 30 : 15,
                      child: Text(
                          messageBoxInformation["messageEdit"] +
                              messageBoxInformation["messageTime"],
                          style: TextStyle(color: timeStampColor)),
                    ),
                    if (message["showTranslationButton"])
                      translationButton(message)
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    messageList(List messages) {
      List<Widget> messageBox = [];
      var changedMessageList =
      messages.reversed.take(displayDataEntries).toList().reversed.toList();
      String oldMessageDate = DateFormat('dd.MM.yy').format(DateTime.fromMillisecondsSinceEpoch(int.parse(changedMessageList[0]["date"]))).toString();
      globalMessageIndex = 1;

      messageBox.add(Align(
        child: Container(
          width: 80,
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: const BorderRadius.all(Radius.circular(20))),
          child: Center(
              child: Text(
                oldMessageDate,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
        ),
      ));

      for(var checkMessage in changedMessageList){
        Map message = checkMessage;
        DateTime messageDateTime =
        DateTime.fromMillisecondsSinceEpoch(int.parse(message["date"]));
        String messageDate = DateFormat('dd.MM.yy').format(messageDateTime);
        var forwardData = message["forward"];

        message["responseId"] ??= "0";
        var messageBoxInformation = {
          "messageBoxColor": chatpartnerMessageBoxColor,
          "textAlign": Alignment.centerLeft,
          "messageTime": DateFormat('HH:mm').format(messageDateTime),
          "messageEdit": message["editDate"] == null
              ? ""
              : "${AppLocalizations.of(context)!.bearbeitet} "
        };

        if (message["message"] == "") continue;

        var checkTextAndPersonalLanguage = ownLanguage ==
            (message["language"] == "auto" ? "en" : message["language"]);

        message["showTranslationButton"] =
            widget.isChatgroup && !checkTextAndPersonalLanguage;

        message["message"] = _removeAllNewLineAtTheEnd(message["message"]);

        if (message["von"] == userId) {
          messageBoxInformation["textAlign"] = Alignment.centerRight;
          messageBoxInformation["messageBoxColor"] = ownMessageBoxColor;
          message["showTranslationButton"] = false;
        }

        if (oldMessageDate != messageDate) {
          messageBox.add(Align(
            child: Container(
              width: 80,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: const BorderRadius.all(Radius.circular(20))),
              child: Center(
                  child: Text(
                    messageDate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
            ),
          ));

          globalMessageIndex += 1;
          oldMessageDate = messageDate;
        }

        if (message["message"].contains("</eventId=")) {
          messageBox.add(cardMessage(globalMessageIndex, message, messageBoxInformation, "event"));
        } else if (message["message"].contains("</communityId=")) {
          messageBox.add(cardMessage(globalMessageIndex, message, messageBoxInformation, "community"));
        } else if (message["message"].contains("</cityId=")) {
          messageBox.add(cardMessage(globalMessageIndex, message, messageBoxInformation, "location"));
        } else if (int.parse(message["responseId"]) != 0) {
          messageBox.add(responseMessage(globalMessageIndex, message, messageBoxInformation));
        } else if (forwardData.isNotEmpty) {
          messageBox.add(forwardMessage(globalMessageIndex, message, messageBoxInformation));
        } else {
          messageBox.add(normalMessage(globalMessageIndex, message, messageBoxInformation));
        }
        globalMessageIndex += 1;
      }

      if (unreadMessages != 0) {
        lastReadMessageIndex = getLastReadMessageIndex(messageBox);
        messageBox.insert(lastReadMessageIndex, Center(
            child: Text(
              AppLocalizations.of(context)!.ungeleseneNachrichten,
              style: const TextStyle(fontWeight: FontWeight.bold),
            )));
      }

      messageBox = messageBox.reversed.toList();

      return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          }),
          child: ScrollablePositionedList.builder(
            initialScrollIndex: _getInitialScrollIndex(),
            itemScrollController: _scrollController,
            itemPositionsListener: itemPositionListener,
            reverse: true,
            itemCount: messageBox.length,
            itemBuilder: (context, index) {
              return messageBox[index];
            },
          ));
    }

    messageAnzeige() {
      return Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
                  ? Center(
                      child: Text(
                      AppLocalizations.of(context)!.nochKeineNachrichtVorhanden,
                      style: const TextStyle(fontSize: 20),
                    ))
                  : messageList(messages),
          if (!hasStartPosition)
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton(
                heroTag: "first Position",
                onPressed: () {
                  _scrollController.scrollTo(
                      index: 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic);
                  setState(() {});
                },
                child: const Icon(Icons.arrow_downward),
              ),
            )
        ],
      );
    }

    searchIndexKontrollButton(String direction, IconData icon) {
      return IconButton(
          iconSize: 30,
          padding: const EdgeInsets.all(3),
          onPressed: messagesWithSearchText.isEmpty
              ? null
              : () => _nextTextSearchItem(direction),
          icon: Icon(icon, color: Colors.black, size: 30));
    }

    textEingabeFeld() {
      if (isTextSearching) {
        return Container(
          constraints: const BoxConstraints(
            minHeight: 60,
          ),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                  child: Center(
                      child: Text(messagesWithSearchText.isEmpty
                          ? AppLocalizations.of(context)!.keineErgebnisse
                          : "${searchTextIndex + 1} von ${messagesWithSearchText.length}"))),
              searchIndexKontrollButton("up", Icons.keyboard_arrow_up),
              searchIndexKontrollButton("down", Icons.keyboard_arrow_down),
            ],
          ),
        );
      } else if (!userJoinedChat) {
        return GestureDetector(
          onTap: () => _joinChatGroup(),
          child: Container(
              constraints: const BoxConstraints(
                minHeight: 60,
              ),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ]),
              child: Center(
                  child: Text(AppLocalizations.of(context)!.gruppeBeitreten))),
        );
      } else {
        return Container(
            constraints: const BoxConstraints(minHeight: 60, maxHeight: 200),
            decoration: BoxDecoration(
                color: Colors.white,
                border: extraInputInformationBox.runtimeType == SizedBox
                    ? const Border(top: BorderSide(color: Colors.grey))
                    : null,
                boxShadow: extraInputInformationBox.runtimeType == SizedBox
                    ? [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3),
                        ),
                      ]
                    : []),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    maxLines: null,
                    focusNode: messageInputNode,
                    textInputAction: TextInputAction.newline,
                    controller: nachrichtController,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.nachricht,
                      hintStyle: const TextStyle(fontSize: 20),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
                changeMessageInputModus != "edit"
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          _restartTimer();
                          _saveNewMessage(nachrichtController.text);

                          _resetExtraInputInformation();

                          _scrollController.jumpTo(index: 0);

                          setState(() {
                            nachrichtController.clear();
                          });
                        },
                        icon: Icon(Icons.send,
                            size: 34,
                            color: Theme.of(context).colorScheme.secondary))
                    : IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          _saveEditMessage();
                          _resetExtraInputInformation();
                        },
                        icon: Icon(Icons.done,
                            size: 38,
                            color: Theme.of(context).colorScheme.secondary))
              ],
            ));
      }
    }

    searchMessageDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.suche),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);

          setState(() {
            textSearchIsActive = true;
          });

          searchInputNode.requestFocus();
        },
      );
    }

    getMemberList() {
      List<Widget> memberList = [];

      widget.groupChatData!["users"].forEach((memberUserId, data) {
        Map userProfil = getProfilFromHive(profilId: memberUserId) ?? {};

        if (userProfil.isEmpty) return;

        memberList.add(GestureDetector(
          onTap: userProfil.isEmpty
              ? null
              : () => global_functions.changePage(
                  context,
                  ShowProfilPage(
                    profil: userProfil,
                  )),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(width: 1.0, color: global_var.borderColorGrey),
              ),
            ),
            child: Text(userProfil["name"]),
          ),
        ));
      });

      return memberList;
    }

    mitgliederWindow() {
      List<Widget> mitgliederList = getMemberList();
      String detailsButtonName = "Information";

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Center(child: Text(connectedData["name"])),
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: 600,
                child: Column(children: [
                  const SizedBox(height: 10),
                  if (widget.chatId != "1")
                    Container(
                      width: 100,
                      height: 40,
                      margin: const EdgeInsets.only(bottom: 30, top: 10),
                      child: FittedBox(
                        child: FloatingActionButton.extended(
                          label: Text(detailsButtonName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          onPressed: () => global_functions.changePage(
                              context, pageDetailsPage),
                        ),
                      ),
                    ),
                  Text(AppLocalizations.of(context)!.member,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                      child: ListView(
                          shrinkWrap: true, children: [...mitgliederList]))
                ]),
              ),
            );
          });
    }

    mitgliederDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.groups),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.member),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          mitgliederWindow();
        },
      );
    }

    pinChatDialog() {
      bool chatIsPinned =
          widget.groupChatData!["users"][userId]["pinned"] ?? false;

      return SimpleDialogOption(
        child: Row(
          children: [
            chatIsPinned
                ? StrikeThroughIcon(child: const Icon(Icons.push_pin))
                : const Icon(Icons.push_pin),
            const SizedBox(width: 10),
            Text(chatIsPinned
                ? AppLocalizations.of(context)!.losloesen
                : AppLocalizations.of(context)!.anheften),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);

          setState(() {
            widget.groupChatData!["users"][userId]["pinned"] = !chatIsPinned;
          });

          if (widget.isChatgroup) {
            ChatGroupsDatabase().updateChatGroup(
                "users = JSON_SET(users, '\$.$userId.pinned', ${!chatIsPinned})",
                "WHERE id = '${widget.chatId}'");
          } else {
            ChatDatabase().updateChatGroup(
                "users = JSON_SET(users, '\$.$userId.pinned', ${!chatIsPinned})",
                "WHERE id = '${widget.chatId}'");
          }
        },
      );
    }

    muteDialog() {
      bool chatIsMute = widget.groupChatData!["users"][userId]["mute"] ?? false;

      return SimpleDialogOption(
        child: Row(
          children: [
            Icon(chatIsMute
                ? Icons.notifications_active
                : Icons.notifications_off),
            const SizedBox(width: 10),
            Text(chatIsMute
                ? AppLocalizations.of(context)!.stummAus
                : AppLocalizations.of(context)!.stummEin),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);

          setState(() {
            widget.groupChatData!["users"][userId]["mute"] = !chatIsMute;
          });

          if (widget.isChatgroup) {
            ChatGroupsDatabase().updateChatGroup(
                "users = JSON_SET(users, '\$.$userId.mute', ${!chatIsMute})",
                "WHERE id = '${widget.chatId}'");
          } else {
            ChatDatabase().updateChatGroup(
                "users = JSON_SET(users, '\$.$userId.mute', ${!chatIsMute})",
                "WHERE id = '${widget.chatId}'");
          }
        },
      );
    }

    deleteWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(builder: (ontext, setState) {
              return CustomAlertDialog(
                title: AppLocalizations.of(context)!.chatLoeschen,
                height: 150,
                actions: [
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.loeschen),
                    onPressed: () async {
                      _deletePrivatChat();
                    },
                  ),
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.abbrechen),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
                children: [
                  Center(
                      child: Text(
                          AppLocalizations.of(context)!.chatWirklichLoeschen)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                          value: bothDelete,
                          onChanged: (value) => {
                                setState(() {
                                  bothDelete = value!;
                                })
                              }),
                      Expanded(
                        child: Text(
                            AppLocalizations.of(context)!.auchBeiLoeschen +
                                chatPartnerProfil!["name"]),
                      )
                    ],
                  )
                ],
              );
            });
          });
    }

    deleteDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.delete, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.chatLoeschen,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          deleteWindow();
        },
      );
    }

    leaveWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context)!.gruppeVerlassen,
              height: 100,
              actions: [
                TextButton(
                  child: Text(AppLocalizations.of(context)!.gruppeVerlassen),
                  onPressed: () async {
                    Navigator.pop(context);

                    ChatGroupsDatabase()
                        .leaveChat(widget.groupChatData!["connected"]);

                    setState(() {
                      userJoinedChat = false;
                    });
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.abbrechen),
                  onPressed: () => Navigator.pop(context),
                )
              ],
              children: [
                Center(
                    child: Text(
                        AppLocalizations.of(context)!.gruppeWirklichVerlassen)),
              ],
            );
          });
    }

    leaveDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.gruppeVerlassen,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          leaveWindow();
        },
      );
    }

    moreMenuWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 205,
                  child: SimpleDialog(
                    contentPadding: EdgeInsets.zero,
                    insetPadding:
                        const EdgeInsets.only(top: 40, left: 0, right: 10),
                    children: [
                      searchMessageDialog(),
                      if (widget.isChatgroup) mitgliederDialog(),
                      if (userJoinedChat) pinChatDialog(),
                      if (userJoinedChat) muteDialog(),
                      if (!widget.isChatgroup) deleteDialog(),
                      if (connectedData["erstelltVon"] != userId &&
                          userJoinedChat &&
                          widget.isChatgroup)
                        leaveDialog(),
                      const SizedBox(height: 5)
                    ],
                  ),
                ),
              ],
            );
          });
    }

    appBarTextSearch() {
      return CustomAppBar(
          title: TextField(
            cursorColor: Colors.black,
            focusNode: searchInputNode,
            controller: searchTextKontroller,
            textInputAction: TextInputAction.search,
            maxLines: 1,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
                border: InputBorder.none,
                hintText: AppLocalizations.of(context)!.suche,
                suffixIcon: CloseButton(
                  color: Colors.white,
                  onPressed: () {
                    searchTextKontroller.clear();
                  },
                )),
            onSubmitted: (value) {
              _searchTextInMessages(value);

              setState(() {
                isTextSearching = true;
              });

              var searchScrollIndex = messagesWithSearchText[0]["index"];
              _scrollToMessage(searchScrollIndex);
              _highlightMessage(searchScrollIndex);
            },
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_sharp),
            onPressed: () {
              setState(() {
                textSearchIsActive = false;
                isTextSearching = false;
              });
            },
          ));
    }

    appBarChatGroup() {
      var chatConnectData = connectedData;
      String title = connectedData["name"];

      return CustomAppBar(
        title: Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 3),
              Text(
                widget.groupChatData!["users"].length.toString() +
                    AppLocalizations.of(context)!.teilnehmerSimple,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              )
            ],
          ),
        ),
        leading: widget.backToChatPage
            ? IconButton(
                icon: const Icon(Icons.arrow_back_sharp),
                onPressed: () async {
                  global_functions.changePageForever(
                      context,
                      StartPage(
                          selectedIndex: 3,
                          chatPageSliderIndex: widget.chatPageSliderIndex));
                })
            : null,
        profilBildProfil: chatConnectData,
        onTap: () => mitgliederWindow(),
        buttons: [
          IconButton(
              onPressed: () => moreMenuWindow(),
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
              ))
        ],
      );
    }

    appBarPrivatChat() {
      var chatImageProfil = chatPartnerProfil;
      String title = chatPartnerProfil!["name"];

      return CustomAppBar(
        title: title,
        fontSize: 20,
        leading: widget.backToChatPage
            ? IconButton(
                icon: const Icon(Icons.arrow_back_sharp),
                onPressed: () async {
                  global_functions.changePageForever(
                      context,
                      StartPage(
                          selectedIndex: 3,
                          chatPageSliderIndex: widget.chatPageSliderIndex));
                })
            : null,
        profilBildProfil: chatImageProfil,
        onTap: () => _openProfil(),
        buttons: [
          IconButton(
              onPressed: () => moreMenuWindow(),
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
              ))
        ],
      );
    }

    appBarDeletedUser() {
      return CustomAppBar(
          title: AppLocalizations.of(context)!.geloeschterUser,
          buttons: [
            IconButton(
                onPressed: () => moreMenuWindow(),
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ))
          ]);
    }

    return SelectionArea(
      child: Scaffold(
        appBar: textSearchIsActive
            ? appBarTextSearch()
            : widget.isChatgroup
                ? appBarChatGroup()
                : chatPartnerProfil != null
                    ? appBarPrivatChat()
                    : appBarDeletedUser(),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              angehefteteNachrichten(),
              Expanded(child: messageAnzeige()),
              extraInputInformationBox,
              textEingabeFeld(),
            ],
          ),
        ),
      ),
    );
  }
}
