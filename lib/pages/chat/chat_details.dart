import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:familien_suche/global/global_functions.dart'
    as global_functions;
import 'package:familien_suche/global/variablen.dart'
    as global_var;
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
import '../informationen/stadtinformation/stadtinformation.dart';
import '../informationen/events/eventCard.dart';
import '../informationen/events/event_details.dart';
import '../../auth/secrets.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';
import '../../widgets/profil_image.dart';
import '../../widgets/text_with_hyperlink_detection.dart';
import '../../windows/all_user_select.dart';
import '../../widgets/strike_through_icon.dart';

class ChatDetailsPage extends StatefulWidget {
  String chatPartnerId;
  var chatPartnerName;
  String chatId;
  var groupChatData;
  bool backToChatPage;
  bool isChatgroup;
  String connectedId;

  ChatDetailsPage({
    Key key,
    this.chatPartnerId,
    this.chatPartnerName,
    this.chatId,
    this.groupChatData,
    this.backToChatPage = false,
    this.isChatgroup = false,
    this.connectedId,
  }) : super(key: key);

  @override
  _ChatDetailsPageState createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage>
    with WidgetsBindingObserver {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var nachrichtController = TextEditingController();
  Timer timer;
  List<dynamic> messages = [];
  var chatPartnerProfil;
  bool bothDelete = false;
  var messageInputNode = FocusNode();
  var searchInputNode = FocusNode();
  var messageExtraInformationId;
  String changeMessageInputModus;
  Widget extraInputInformationBox = const SizedBox.shrink();
  final _scrollController = ItemScrollController();
  var itemPositionListener = ItemPositionsListener.create();
  var hasStartPosition = true;
  var myChats = Hive.box("secureBox").get("myChats") ?? [];
  var myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];
  var allEvents = Hive.box('secureBox').get("events") ?? [];
  var allCommunities = Hive.box('secureBox').get("communities") ?? [];
  var ownProfil = Hive.box('secureBox').get("ownProfil");
  var angehefteteMessageShowIndex;
  var isLoading = true;
  var textSearchIsActive = false;
  var searchTextKontroller = TextEditingController();
  var messagesWithSearchText = [];
  var isTextSearching = false;
  var searchTextIndex = 0;
  var highlightMessages = [];
  var connectedData = {};
  var pageDetailsPage;
  var unreadMessages = 0;
  var adminList = [mainAdmin];
  final translator = GoogleTranslator();
  var myLanguage = WidgetsBinding.instance.window.locales[0].languageCode;

  @override
  void initState() {
    if (!widget.isChatgroup) createNewChat();

    getAndSetChatData();
    writeActiveChat();
    setScrollbarListener();

    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod());
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    messageInputNode.dispose();

    if (widget.groupChatData["users"][userId] != null) {
      Function databaseUpdate = widget.isChatgroup
          ? ChatGroupsDatabase().updateChatGroup
          : ChatDatabase().updateChatGroup;

      widget.groupChatData["users"][userId]["isActive"] = 0;
      databaseUpdate(
          "users = JSON_SET(users, '\$.$userId.isActive', ${0})",
          "WHERE id = '${widget.chatId}'");
    }

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Function databaseUpdate = widget.isChatgroup
        ? ChatGroupsDatabase().updateChatGroup
        : ChatDatabase().updateChatGroup;

    if (state == AppLifecycleState.resumed) {
      widget.groupChatData["users"][userId]["isActive"] = 1;
      databaseUpdate(
          "users = JSON_SET(users, '\$.$userId.isActive', ${1})",
          "WHERE id = '${widget.chatId}'");
    } else {
      widget.groupChatData["users"][userId]["isActive"] = 0;
      databaseUpdate(
          "users = JSON_SET(users, '\$.$userId.isActive', ${0})",
          "WHERE id = '${widget.chatId}'");
    }
  }

  createNewChat() {
    if (widget.groupChatData == null || widget.groupChatData["id"] == null) {
      widget.chatId ??= global_functions.getChatID(widget.chatPartnerId);

      for (var chat in myChats) {
        if (widget.chatId == chat["id"]) {
          widget.groupChatData = chat;
          return;
        }
      }
      widget.groupChatData =
          ChatDatabase().addNewChatGroup(widget.chatPartnerId);
    }
  }

  getAndSetChatData() {
    widget.connectedId ??= widget.groupChatData["connected"];
    widget.isChatgroup = widget.connectedId != null;

    if (!widget.isChatgroup) {
      var userIds = widget.groupChatData["id"].split("_");
      userIds.remove(userId);

      widget.chatPartnerId ??= userIds[0];
      widget.chatPartnerName ??=
          getProfilFromHive(profilId: widget.chatPartnerId, getNameOnly: true);
      chatPartnerProfil = getProfilFromHive(profilId: widget.chatPartnerId);
      if (widget.groupChatData["users"][userId] == null) {
        widget.groupChatData["users"][userId] = {"newMessages": 0};
        ChatDatabase().updateChatGroup(
            "users = JSON_MERGE(users, '${json.encode({
                  userId: {"newMessages": 0}
                })}')",
            "WHERE id = '${widget.groupChatData["id"]}'");
      }
    } else if (widget.isChatgroup) {
      var connectedId =
          widget.connectedId.isEmpty ? "" : widget.connectedId.split("=")[1];

      widget.groupChatData ??= getChatGroupFromHive(connectedId);

      if (widget.connectedId.contains("event")) {
        connectedData = getEventFromHive(connectedId);
        pageDetailsPage = EventDetailsPage(
          event: connectedData,
        );
        adminList.add(connectedData["erstelltVon"]);
      } else if (widget.connectedId.contains("community")) {
        connectedData = getCommunityFromHive(connectedId);
        pageDetailsPage = CommunityDetails(
          community: connectedData,
        );
        adminList.add(connectedData["erstelltVon"]);
      } else if (widget.connectedId.contains("stadt")) {
        connectedData = {
          "name": getCityFromHive(cityId: connectedId, getName: true),
          "bild": Hive.box('secureBox').get("allgemein")["cityImage"],
          "erstelltVon": ""
        };
        pageDetailsPage = StadtinformationsPage(
          ortName: connectedData["name"],
        );
      }
    }

    if (widget.groupChatData != null &&
        widget.groupChatData["users"][userId] != null) {
      unreadMessages += widget.groupChatData["users"][userId]["newMessages"];
    }

    widget.chatId ??= widget.groupChatData["id"].toString();
  }

  writeActiveChat() {
    Function databaseUpdate = widget.isChatgroup
        ? ChatGroupsDatabase().updateChatGroup
        : ChatDatabase().updateChatGroup;

    if (widget.groupChatData["users"][userId] == null) return;

    widget.groupChatData["users"][userId]["isActive"] = 1;

    databaseUpdate(
        "users = JSON_SET(users, '\$.$userId.isActive', ${1})",
        "WHERE id = '${widget.chatId}'");
  }

  setScrollbarListener() {
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
    });
  }

  _asyncMethod() async {
    await getAllDbMessages();

    resetNewMessageCounter();

    timer = Timer.periodic(
        const Duration(seconds: 30), (Timer t) => getAllDbMessages());
  }

  getAllDbMessages() async {
    var chatId = widget.chatId ?? widget.groupChatData["id"];

    List<dynamic> allDbMessages = widget.isChatgroup
        ? await ChatGroupsDatabase().getAllChatMessages(chatId)
        : await ChatDatabase().getAllChatMessages(chatId);

    allDbMessages.sort((a, b) => (a["date"]).compareTo(b["date"]));

    setState(() {
      messages = allDbMessages;
      isLoading = false;
    });
  }

  resetNewMessageCounter() async {
    var users = widget.groupChatData["users"];
    if (widget.groupChatData["users"][userId] == null) return;

    var usersChatNewMessages = users[userId]["newMessages"];

    if (usersChatNewMessages == 0) return;

    var ownAllMessages = ownProfil["newMessages"];
    var newOwnAllMessages = ownAllMessages - usersChatNewMessages < 0
        ? 0
        : ownAllMessages - usersChatNewMessages;

    ownProfil["newMessages"] = newOwnAllMessages;

    widget.groupChatData["users"][userId]["newMessages"] = 0;

    if (widget.isChatgroup) {
      ChatGroupsDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.newMessages', 0)",
          "WHERE id = '${widget.chatId}'");
    } else {
      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.newMessages', ${widget.groupChatData["users"][userId]["newMessages"]})",
          "WHERE id = '${widget.groupChatData["id"]}'");
    }
  }

  messageToDbAndClearMessageInput(message) async {
    var userID = FirebaseAuth.instance.currentUser.uid;
    var checkMessage = nachrichtController.text.split("\n").join();
    var languageCheck = await translator.translate(message);
    var languageCode = languageCheck.sourceLanguage.code;

    if (checkMessage.isEmpty) return;

    var messageData = {
      "chatId": widget.chatId,
      "message": message,
      "von": userID,
      "date": DateTime.now().millisecondsSinceEpoch.toString(),
      "zu": widget.chatPartnerId,
      "responseId": messageExtraInformationId ??= "0",
      "forward": "",
      "language": languageCode
    };

    setState(() {
      messages.add(messageData);
      widget.groupChatData["lastMessage"] = message;
    });

    saveMessageinDBAndRefresh(messageData);

    var groupText = messageData["message"];

    if (messageData["message"].contains("</eventId=")) {
      groupText = "<Event Card>";
    }
    if (messageData["message"].contains("</communityId=")) {
      groupText = "<Community Card>";
    }

    for (var myChat in myChats) {
      if (myChat["id"] == widget.chatId) {
        myChat["lastMessage"] = groupText;
        myChat["lastMessageDate"] = int.parse(messageData["date"]);
      }
    }

    if (widget.isChatgroup) {
      ChatGroupsDatabase().updateChatGroup(
          "lastMessage = '${messageData["message"]}' , lastMessageDate = '${messageData["date"]}'",
          "WHERE id = '${widget.chatId}'");
    } else {
      ChatDatabase().updateChatGroup(
          "lastMessage = '${messageData["message"]}' , lastMessageDate = '${messageData["date"]}'",
          "WHERE id = '${widget.chatId}'");
    }

    messageExtraInformationId = null;
  }

  saveMessageinDBAndRefresh(messageData) async {
    var isBlocked = ownProfil["geblocktVon"].contains(widget.chatPartnerId);
    if (widget.isChatgroup) {
      await ChatGroupsDatabase().addNewMessageAndNotification(
          widget.groupChatData["id"], messageData, isBlocked, connectedData["name"]);
    } else {
      await ChatDatabase().addNewMessageAndSendNotification(
          widget.groupChatData["id"], messageData, isBlocked);
    }

    getAllDbMessages();
  }

  openProfil() async {
    var noChatPartnerProfil = chatPartnerProfil == false;
    var chatgroupWithoutProfil = widget.isChatgroup && pageDetailsPage == null;

    if (noChatPartnerProfil || chatgroupWithoutProfil) return;

    global_functions.changePage(
        context,
        ShowProfilPage(
          profil: chatPartnerProfil,
        ));
  }

  removeAllNewLineAtTheEnd(message) {
    while (message.endsWith('\n')) {
      message = message.substring(0, message.length - 1);
    }

    return message;
  }

  deleteChat() {
    var chatUsers = widget.groupChatData["users"];

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

  replyMessage(message) {
    setState(() {
      messageExtraInformationId = message["id"];
      changeMessageInputModus = "reply";
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      messageInputNode.requestFocus();
    });
  }

  editMessage(message) {
    messageExtraInformationId = message["id"];
    nachrichtController.text = message["message"];

    setState(() {
      changeMessageInputModus = "edit";
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      messageInputNode.requestFocus();
    });
  }

  copyMessage(messageText) {
    Clipboard.setData(ClipboardData(text: messageText));
    customSnackbar(
        context, AppLocalizations.of(context).nachrichtZwischenAblage,
        color: Colors.green, duration: const Duration(seconds: 1));
  }

  forwardedMessage(message) async {
    var allUserSelectWindow = AllUserSelectWindow(
        context: context,
        title: AppLocalizations.of(context).empfaengerWaehlen);
    var selectedUserId = await allUserSelectWindow.openWindow();
    var selectedChatId = global_functions.getChatID(selectedUserId);
    var chatGroupData =
        await ChatDatabase().getChatData("*", "WHERE id = '$selectedChatId'");
    var forwardMessage = message["forward"];

    var messageData = {
      "message": message["message"],
      "von": userId,
      "date": DateTime.now().millisecondsSinceEpoch.toString(),
      "zu": selectedUserId,
      "forward": "userId:" +
          (forwardMessage.isEmpty
              ? message["von"]
              : forwardMessage.split(":")[1].toString()),
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

  deleteMessage(messageId) {
    Future.delayed(
        const Duration(seconds: 0),
        () => showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: AppLocalizations.of(context).nachrichtLoeschen,
                height: 100,
                children: [
                  Center(
                      child: Text(AppLocalizations.of(context)
                          .nachrichtWirklichLoeschen))
                ],
                actions: [
                  TextButton(
                    child: Text(AppLocalizations.of(context).loeschen),
                    onPressed: () {
                      checkIfLastMessageAndChangeChatGroup(messageId);

                      if (widget.isChatgroup) {
                        ChatGroupsDatabase().deleteMessages(messageId);
                      } else {
                        ChatDatabase().deleteMessages(messageId);
                      }

                      messages
                          .removeWhere((element) => element["id"] == messageId);



                      setState(() {});

                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: Text(AppLocalizations.of(context).abbrechen),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              );
            }));
  }

  checkIfLastMessageAndChangeChatGroup(messageId){
    var lastMessage = messages.last;
    var secondLastMessage = messages[messages.length -2];

    if(messageId != lastMessage["id"]) return;

    if (widget.isChatgroup) {
      ChatGroupsDatabase().updateChatGroup(
          "lastMessage = '${secondLastMessage["message"]}' , lastMessageDate = '${secondLastMessage["date"]}'",
          "WHERE id = '${widget.chatId}'");

    } else {
      ChatDatabase().updateChatGroup(
          "lastMessage = '${secondLastMessage["message"]}' , lastMessageDate = '${secondLastMessage["date"]}'",
          "WHERE id = '${widget.chatId}'");
    }
  }

  reportMessage(message) {
    ReportsDatabase().add(
        userId,
        "Message tableId in ${widget.isChatgroup ? "Chatgroup" : "Privatechat"}" +
            message["id"] +
            " gemeldet",
        message["message"]);

    customSnackbar(context, AppLocalizations.of(context).nachrichtGemeldet,
        color: Colors.green, duration: const Duration(seconds: 2));
  }

  pinMessage(message) async {
    var messageIsPinned =
        widget.groupChatData["users"][userId]["pinnedMessages"];
    if (messageIsPinned != null && messageIsPinned.runtimeType == String) {
      messageIsPinned = json.decode(messageIsPinned);
    }

    if (messageIsPinned == null || messageIsPinned.isEmpty) {
      widget.groupChatData["users"][userId]
          ["pinnedMessages"] = [int.parse(message["id"])];

      setState(() {
        angehefteteMessageShowIndex =
            widget.groupChatData["users"][userId]["pinnedMessages"].length - 1;
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
      messageIsPinned.add(int.parse(message["id"]));
      widget.groupChatData["users"][userId]["pinnedMessages"] = messageIsPinned;

      setState(() {
        angehefteteMessageShowIndex = messageIsPinned.length - 1;
      });

      if (widget.isChatgroup) {
        ChatGroupsDatabase().updateChatGroup(
            "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$messageIsPinned')",
            "WHERE id = '${message["chatId"]}'");
      } else {
        ChatDatabase().updateChatGroup(
            "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$messageIsPinned')",
            "WHERE id = '${message["chatId"]}'");
      }
    }
  }

  detachMessage(message, index) {
    var messageIsPinned =
        widget.groupChatData["users"][userId]["pinnedMessages"];
    if (messageIsPinned.runtimeType == String) {
      messageIsPinned = json.decode(messageIsPinned);
    }

    messageIsPinned.remove(int.parse(message["id"]));

    widget.groupChatData["users"][userId]["pinnedMessages"] = messageIsPinned;

    setState(() {
      angehefteteMessageShowIndex = messageIsPinned.length - 1;
    });

    if (widget.isChatgroup) {
      ChatGroupsDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$messageIsPinned')",
          "WHERE id = '${message["chatId"]}'");
    } else {
      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$messageIsPinned')",
          "WHERE id = '${message["chatId"]}'");
    }
  }

  resetExtraInputInformation() {
    extraInputInformationBox = const SizedBox.shrink();
    nachrichtController.clear();
    changeMessageInputModus = null;

    setState(() {});
  }

  saveEditMessage() {
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

  showAllPinMessages() {
    var allPinnedMessageIds =
        widget.groupChatData["users"][userId]["pinnedMessages"];
    if (allPinnedMessageIds.runtimeType == String) {
      allPinnedMessageIds = json.decode(allPinnedMessageIds);
    }
    var allPinMessages = [];

    for (var pinMessageId in allPinnedMessageIds) {
      for (var message in messages) {
        if (pinMessageId.toString() == message["id"]) {
          allPinMessages.add(message);
        }
      }
    }
    global_functions.changePage(
        context, pinMessagesPage(pinMessages: allPinMessages));
  }

  jumpToMessageAndShowNextAngeheftet(index) {
    angehefteteMessageShowIndex = angehefteteMessageShowIndex - 1;
    var pinnedMessages =
        widget.groupChatData["users"][userId]["pinnedMessages"];
    if (pinnedMessages.runtimeType == String) {
      widget.groupChatData["users"][userId]["pinnedMessages"] =
          json.decode(pinnedMessages);
    }

    if (angehefteteMessageShowIndex < 0) {
      angehefteteMessageShowIndex =
          widget.groupChatData["users"][userId]["pinnedMessages"].length - 1;
    }

    scrollAndColoringMessage(index);
  }

  searchTextInMessages(searchText) {
    messagesWithSearchText = [];
    var index = -1;

    for (var message in messages) {
      index = index + 1;

      if (message["message"].contains(searchText) ||
          message["message"].contains(searchText.toLowerCase())) {
        message["index"] = index;
        messagesWithSearchText.add(message);
      }
    }

    messagesWithSearchText = messagesWithSearchText.reversed.toList();
  }

  textSearchNext(direction) {
    var maxResults = messagesWithSearchText.length - 1;

    if (direction == "up") {
      searchTextIndex += 1;
      if (searchTextIndex > maxResults) searchTextIndex = 0;
    } else if (direction == "down") {
      searchTextIndex -= 1;
      if (searchTextIndex < 0) searchTextIndex = maxResults;
    }

    var searchScrollIndex = messagesWithSearchText[searchTextIndex]["index"];

    scrollAndColoringMessage(searchScrollIndex);
  }

  scrollAndColoringMessage(messageIndex) {
    var scrollToIndex = messages.length - 1 - messageIndex;
    if (scrollToIndex < 0) scrollToIndex = 0;

    _scrollController.scrollTo(
        index: scrollToIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic);

    setState(() {
      highlightMessages.add(messageIndex);
    });

    Future.delayed(const Duration(milliseconds: 1300), () {
      setState(() {
        highlightMessages.remove(messageIndex);
      });
    });
  }

  checkAndRemovePinnedMessage(message) {
    var pinnedMessages =
        widget.groupChatData["users"][userId]["pinnedMessages"] ?? [];

    if (pinnedMessages.runtimeType == String) {
      pinnedMessages = json.decode(pinnedMessages);
    }

    pinnedMessages.remove(int.parse(message["id"]));

    widget.groupChatData["users"][userId]["pinnedMessages"] = pinnedMessages;
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

  joinChatGroup() async {
    var newUserInformation = {"newMessages": 0};

    setState(() {
      widget.groupChatData["users"][userId] = newUserInformation;
    });

    await ChatGroupsDatabase().updateChatGroup(
        "users = JSON_MERGE_PATCH(users, '${json.encode({
              userId: newUserInformation
            })}')",
        "WHERE id = ${widget.chatId}");

    myGroupChats.add(widget.groupChatData);
    Hive.box("secureBox").put("myGroupChats", myGroupChats);

    writeActiveChat();
  }

  @override
  Widget build(BuildContext context) {
    var ownMessageBoxColor =
        Theme.of(context).colorScheme.secondary.withOpacity(0.7);
    var chatpartnerMessageBoxColor = Colors.white;
    var timeStampColor = Colors.grey[600];
    var userJoinedChat = widget.groupChatData["users"][userId] != null;
    connectedData["name"] ??= AppLocalizations.of(context).weltChat;
    connectedData["bild"] ??=
        Hive.box('secureBox').get("allgemein")["worldChatImage"];
    var _tabPosition;

    angehefteteNachrichten() {
      if (widget.groupChatData["users"][userId] == null) {
        return const SizedBox.shrink();
      }

      var chatAngeheftet =
          widget.groupChatData["users"][userId]["pinnedMessages"];

      if (chatAngeheftet.runtimeType == String) {
        chatAngeheftet = json.decode(chatAngeheftet);
      }

      if (widget.groupChatData == null ||
          chatAngeheftet == null ||
          chatAngeheftet.isEmpty) {
        return const SizedBox.shrink();
      }

      angehefteteMessageShowIndex ??= chatAngeheftet.length - 1;

      var pinMessageShow = chatAngeheftet[angehefteteMessageShowIndex];
      var fristPinText = "";
      var index = -1;

      for (var message in messages) {
        index = index + 1;
        if (message["id"] == pinMessageShow.toString()) {
          fristPinText = message["message"];
          break;
        }
      }

      return GestureDetector(
        onTap: () => jumpToMessageAndShowNextAngeheftet(index),
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
                      AppLocalizations.of(context).angehefteteNachrichten,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      fristPinText,
                      maxLines: 1,
                    )
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => showAllPinMessages(),
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

    inputInformationBox(icon, title, bodyText) {
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
                  offset: const Offset(0, -2), // changes position of shadow
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
                    Text(title,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold)),
                    Text(bodyText, maxLines: 1, overflow: TextOverflow.ellipsis)
                  ],
                ),
              ),
            if (bodyText.isEmpty)
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => resetExtraInputInformation(),
            )
          ]));
    }

    openMessageMenu(message, index) {
      final RenderBox overlay = Overlay.of(context).context.findRenderObject();
      var isMyMessage = message["von"] == userId;
      var isInPinned = false;
      var angehefteteMessages = [];

      if (userJoinedChat &&
          widget.groupChatData["users"][userId]["pinnedMessages"] != null) {
        var pinnedMessages =
            widget.groupChatData["users"][userId]["pinnedMessages"];
        angehefteteMessages = pinnedMessages is String
            ? json.decode(pinnedMessages)
            : pinnedMessages;
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
            (_tabPosition ?? const Offset(20, 250)) & const Size(40, 40),
            Offset.zero & overlay.size),
        items: [
          if (userJoinedChat)
            PopupMenuItem(
              onTap: () {
                var replyUser = getProfilFromHive(
                    profilId: message["von"], getNameOnly: true);

                extraInputInformationBox = inputInformationBox(
                    Icons.reply, replyUser, message["message"]);

                replyMessage(message);
              },
              child: Row(
                children: [
                  const Icon(Icons.reply),
                  const SizedBox(width: 20),
                  Text(AppLocalizations.of(context).antworten),
                ],
              ),
            ),
          if (userJoinedChat)
            PopupMenuItem(
              onTap: () => isInPinned
                  ? detachMessage(message, index)
                  : pinMessage(message),
              child: Row(
                children: [
                  isInPinned
                      ? StrikeThroughIcon(child: const Icon(Icons.push_pin))
                      : const Icon(Icons.push_pin),
                  const SizedBox(width: 20),
                  Text(isInPinned
                      ? AppLocalizations.of(context).losloesen
                      : AppLocalizations.of(context).anheften),
                ],
              ),
            ),
          if (isMyMessage)
            PopupMenuItem(
              onTap: () {
                extraInputInformationBox = inputInformationBox(Icons.edit,
                    AppLocalizations.of(context).nachrichtBearbeiten, "");

                editMessage(message);
              },
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 20),
                  Text(AppLocalizations.of(context).bearbeiten),
                ],
              ),
            ),
          PopupMenuItem(
            onTap: () => copyMessage(message["message"]),
            child: Row(
              children: [
                const Icon(Icons.copy),
                const SizedBox(width: 20),
                Text(AppLocalizations.of(context).textKopieren),
              ],
            ),
          ),
          if (userJoinedChat)
            PopupMenuItem(
              onTap: () => Future.delayed(
                  const Duration(seconds: 0), () => forwardedMessage(message)),
              child: Row(
                children: [
                  const Icon(Icons.forward),
                  const SizedBox(width: 20),
                  Text(AppLocalizations.of(context).weiterleiten),
                ],
              ),
            ),
          if (isMyMessage || adminList.contains(userId))
            PopupMenuItem(
              onTap: () {
                checkAndRemovePinnedMessage(message);
                deleteMessage(message["id"]);
              },
              child: Row(
                children: [
                  const Icon(Icons.delete),
                  const SizedBox(width: 20),
                  Text(AppLocalizations.of(context).loeschenGross),
                ],
              ),
            ),
          if (!isMyMessage && userJoinedChat)
            PopupMenuItem(
              onTap: () => reportMessage(message),
              child: Row(
                children: [
                  const Icon(Icons.report),
                  const SizedBox(width: 20),
                  Text(AppLocalizations.of(context).meldenGross),
                ],
              ),
            ),
        ],
        elevation: 4.0,
      );
    }

    translationButton(message) {
      return Positioned(
          right: 5,
          bottom: -10,
          child: TextButton(
              child: Text(AppLocalizations.of(context).uebersetzen),
              onPressed: () async {
                var translationMessage = message["message"].replaceAll("'", "");

                var translation = await translator.translate(translationMessage,
                    from: "auto", to: myLanguage);

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
                                Text(AppLocalizations.of(context).uebersetzen,
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
                                    label: Text(AppLocalizations.of(context)
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

    eventMessage(index, message, messageBoxInformation) {
      var messageSplit = message["message"].split(" ");
      var eventId = "";
      var eventData;
      var hasForward = message["forward"].isNotEmpty;
      var forwardProfil;
      var creatorData = getProfilFromHive(profilId: message["von"]);
      var creatorName = creatorData["name"];
      var creatorColor = creatorData["bildStandardFarbe"];

      if (hasForward) {
        var messageAutorId = message["forward"].split(":")[1];
        forwardProfil = getProfilFromHive(profilId: messageAutorId);
      }

      messageSplit.asMap().forEach((index, text) {
        if (text.contains("</eventId=")) {
          eventId = text.substring(10);
        }
      });

      message["message"] = messageSplit.join(" ");

      for (var event in allEvents) {
        if (event["id"] == eventId) {
          eventData = event;
          break;
        }
      }

      if (eventData == null) return const SizedBox.shrink();

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
                child: ProfilImage(creatorData)),
          AnimatedContainer(
            color: highlightMessages.contains(index)
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            duration: const Duration(seconds: 1),
            curve: Curves.easeIn,
            child: Align(
                alignment: messageBoxInformation["textAlign"],
                child: Column(children: [
                  if (widget.isChatgroup && message["von"] != userId)
                    GestureDetector(
                      onTap: () => global_functions.changePage(
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
                                color: Color(creatorColor)),
                          )),
                    ),
                  if (hasForward)
                    Container(
                      alignment: messageBoxInformation["textAlign"],
                      padding:
                          const EdgeInsets.only(top: 5, left: 10, right: 5),
                      child: GestureDetector(
                        onTap: () => global_functions.changePage(
                            context,
                            ShowProfilPage(
                              profil: forwardProfil,
                            )),
                        child: Text(
                          AppLocalizations.of(context).weitergeleitetVon +
                              forwardProfil["name"],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Container(
                    alignment: messageBoxInformation["textAlign"],
                    child: EventCard(
                      margin: const EdgeInsets.only(
                          left: 15, right: 15, top: 15, bottom: 0),
                      withInteresse: true,
                      event: eventData,
                      afterPageVisit: () => setState(() {}),
                    ),
                  ),
                  messageSplit.length == 1
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
                                  replyMessage(message);
                                },
                                child: Text(
                                    AppLocalizations.of(context).antworten)),
                            TextButton(
                                onPressed: () {
                                  forwardedMessage(message);
                                },
                                child: Text(
                                    AppLocalizations.of(context).weiterleiten)),
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
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.85),
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
                                          text: message["message"] ?? "",
                                          fontsize: 16,
                                          onTextTab: () =>
                                              openMessageMenu(message, index)),
                                      const SizedBox(width: 5),
                                      Text(
                                          messageBoxInformation["messageEdit"] +
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
                                        messageBoxInformation["messageTime"],
                                    style: TextStyle(color: timeStampColor)),
                              ),
                            ],
                          ),
                        )
                ])),
          ),
        ],
      );
    }

    communityMessage(index, message, messageBoxInformation) {
      var messageSplit = message["message"].split(" ");
      var communityId = "";
      var communityData;
      var hasForward = message["forward"].isNotEmpty;
      var forwardProfil;
      var creatorData = getProfilFromHive(profilId: message["von"]);
      var creatorName = creatorData["name"];
      var creatorColor = creatorData["bildStandardFarbe"];

      if (hasForward) {
        var messageAutorId = message["forward"].split(":")[1];
        forwardProfil = getProfilFromHive(profilId: messageAutorId);
      }

      for (var text in messageSplit) {
        if (text.contains("</communityId=")) communityId = text.substring(14);
      }

      for (var community in allCommunities) {
        if (community["id"] == communityId) {
          communityData = community;
          break;
        }
      }

      if (communityData == null) return const SizedBox.shrink();

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
                child: ProfilImage(creatorData)),
          AnimatedContainer(
            color: highlightMessages.contains(index)
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            duration: const Duration(seconds: 1),
            curve: Curves.easeIn,
            child: Align(
                alignment: messageBoxInformation["textAlign"],
                child: Column(children: [
                  if (widget.isChatgroup && message["von"] != userId)
                    GestureDetector(
                      onTap: () => global_functions.changePage(
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
                                color: Color(creatorColor)),
                          )),
                    ),
                  if (hasForward)
                    Container(
                      alignment: messageBoxInformation["textAlign"],
                      padding:
                          const EdgeInsets.only(top: 5, left: 10, right: 5),
                      child: GestureDetector(
                        onTap: () => global_functions.changePage(
                            context,
                            ShowProfilPage(
                              profil: forwardProfil,
                            )),
                        child: Text(
                          AppLocalizations.of(context).weitergeleitetVon +
                              forwardProfil["name"],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Container(
                    alignment: messageBoxInformation["textAlign"],
                    child: CommunityCard(
                      margin: const EdgeInsets.only(
                          left: 15, right: 15, top: 15, bottom: 0),
                      community: communityData,
                      afterPageVisit: () => setState(() {}),
                    ),
                  ),
                  messageSplit.length == 1
                      ? Row(
                          children: [
                            if (messageBoxInformation["textAlign"] ==
                                Alignment.centerLeft)
                              const SizedBox(width: 8),
                            TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {
                                  var replyUser = getProfilFromHive(
                                      profilId: message["von"],
                                      getNameOnly: true);

                                  extraInputInformationBox =
                                      inputInformationBox(Icons.reply,
                                          replyUser, message["message"]);
                                  replyMessage(message);
                                },
                                child: Text(
                                    AppLocalizations.of(context).antworten)),
                            TextButton(
                                onPressed: () {
                                  forwardedMessage(message);
                                },
                                child: Text(
                                    AppLocalizations.of(context).weiterleiten)),
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
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.85),
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
                                          text: message["message"] ?? "",
                                          fontsize: 16,
                                          onTextTab: () =>
                                              openMessageMenu(message, index)),
                                      const SizedBox(width: 5),
                                      Text(
                                          messageBoxInformation["messageEdit"] +
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
                                        messageBoxInformation["messageTime"],
                                    style: TextStyle(color: timeStampColor)),
                              )
                            ],
                          ),
                        )
                ])),
          ),
        ],
      );
    }

    responseMessage(index, message, messageBoxInformation) {
      var replyMessage;
      var replyIndex = messages.length;
      var cardData = {};
      var textAddition = "";
      var creatorData = getProfilFromHive(profilId: message["von"]);
      var creatorName = creatorData["name"];
      var creatorColor = creatorData["bildStandardFarbe"];

      for (var lookMessage in messages.reversed.toList()) {
        replyIndex -= 1;

        if (lookMessage["id"] == message["responseId"]) {
          replyMessage = lookMessage;
          break;
        }
      }

      replyMessage ??= {};
      var replyFromId = replyMessage["von"];
      var messageFromProfil = getProfilFromHive(profilId: replyFromId) ?? {};
      var replyColor = messageFromProfil["bildStandardFarbe"] == 4285132974
          ? Colors.greenAccent[100]
          : messageFromProfil["bildStandardFarbe"] != null
              ? Color(messageFromProfil["bildStandardFarbe"])
              : Colors.black;
      var isEvent = replyMessage.isEmpty
          ? false
          : replyMessage["message"].contains("</eventId=");
      var isCommunity = replyMessage.isEmpty
          ? false
          : replyMessage["message"].contains("</communityId=");

      if (isEvent || isCommunity) {
        if (isEvent) {
          var eventId = replyMessage["message"].substring(10);
          for (var event in allEvents) {
            if (event["id"] == eventId) {
              textAddition = "Event: ";
              cardData = event;
              break;
            }
          }
        } else if (isCommunity) {
          var communityId = replyMessage["message"].substring(14);
          for (var community in allCommunities) {
            if (community["id"] == communityId) {
              textAddition = "Community: ";
              cardData = community;
              break;
            }
          }
        }
      }

      return Listener(
        onPointerHover: (details) => _tabPosition = details.position,
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
                        onTap: () => global_functions.changePage(context, ShowProfilPage(
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
                                      onTap: () => global_functions.changePage(
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
                                        scrollAndColoringMessage(replyIndex);
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
                                                      color: replyColor))),
                                          child: Container(
                                            height:
                                                replyFromId != null ? 36 : 18,
                                            constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.7),
                                            child: replyFromId != null
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          messageFromProfil[
                                                              "name"] ?? "gelöschter Account",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  replyColor)),
                                                      const SizedBox(height: 3),
                                                      Flexible(
                                                        child: Text(
                                                          cardData["name"] ==
                                                                  null
                                                              ? replyMessage[
                                                                  "message"]
                                                              : textAddition +
                                                                  cardData[
                                                                      "name"],
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      )
                                                    ],
                                                  )
                                                : Text(
                                                    AppLocalizations.of(context)
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

    forwardMessage(index, message, messageBoxInformation) {
      var messageAutorId = message["forward"].split(":")[1];
      var forwardProfil = getProfilFromHive(profilId: messageAutorId);
      var creatorData = getProfilFromHive(profilId: message["von"]);

      return Listener(
        onPointerHover: (details) => _tabPosition = details.position,
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
                        onTap: () => global_functions.changePage(context, ShowProfilPage(
                          profil: creatorData,
                        )),
                      )
                    ),
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
                              onTap: () => global_functions.changePage(
                                  context,
                                  ShowProfilPage(
                                    profil: forwardProfil,
                                  )),
                              child: Text(
                                AppLocalizations.of(context).weitergeleitetVon +
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

    normalMessage(index, message, messageBoxInformation) {
      var creatorData = getProfilFromHive(profilId: message["von"]) ?? {};
      var creatorName = creatorData["name"];
      var creatorColor = creatorData["bildStandardFarbe"];

      if(creatorData.isEmpty) return const SizedBox.shrink();

      return Listener(
        onPointerHover: (details) {
          _tabPosition = details.position;
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
                      onTap: () => global_functions.changePage(context, ShowProfilPage(
                        profil: creatorData,
                      )),
                    )
                ),
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
                                onTap: () => global_functions.changePage(
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
                                          color: Color(creatorColor)),
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

    messageList(messages) {
      List<Widget> messageBox = [];
      var newMessageDate;

      for (var i = messages.length - 1; i >= 0; i--) {
        var message = messages[i];
        var messageDateTime =
            DateTime.fromMillisecondsSinceEpoch(int.parse(message["date"]));
        var messageDate = DateFormat('dd.MM.yy').format(messageDateTime);
        var forwardData = message["forward"];

        message["responseId"] ??= "0";
        var messageBoxInformation = {
          "messageBoxColor": chatpartnerMessageBoxColor,
          "textAlign": Alignment.centerLeft,
          "messageTime": DateFormat('HH:mm').format(messageDateTime),
          "messageEdit": message["editDate"] == null
              ? ""
              : AppLocalizations.of(context).bearbeitet + " "
        };

        if (message["message"] == "") continue;

        var checkTextAndPersonalLanguage = myLanguage ==
            (message["language"] == "auto" ? "en" : message["language"]);

        message["showTranslationButton"] =
            widget.isChatgroup && !checkTextAndPersonalLanguage;

        message["message"] = removeAllNewLineAtTheEnd(message["message"]);

        if (message["von"] == userId) {
          messageBoxInformation["textAlign"] = Alignment.centerRight;
          messageBoxInformation["messageBoxColor"] = ownMessageBoxColor;
          message["showTranslationButton"] = false;
        }

        if (newMessageDate == null) {
          newMessageDate = messageDate;
        } else if (newMessageDate != messageDate) {
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
                newMessageDate,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
            ),
          ));

          newMessageDate = messageDate;
        }

        if (unreadMessages != 0 &&
            (i == messages.length - 1 - unreadMessages)) {
          messageBox.add(Center(
              child: Text(
            AppLocalizations.of(context).ungeleseneNachrichten,
            style: const TextStyle(fontWeight: FontWeight.bold),
          )));
        }

        if (message["message"].contains("</eventId=")) {
          messageBox.add(eventMessage(i, message, messageBoxInformation));
        } else if (message["message"].contains("</communityId=")) {
          messageBox.add(communityMessage(i, message, messageBoxInformation));
        } else if (int.parse(message["responseId"]) != 0) {
          messageBox.add(responseMessage(i, message, messageBoxInformation));
        } else if (forwardData.isNotEmpty) {
          messageBox.add(forwardMessage(i, message, messageBoxInformation));
        } else {
          messageBox.add(normalMessage(i, message, messageBoxInformation));
        }
      }

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
            newMessageDate,
            style: const TextStyle(fontWeight: FontWeight.bold),
          )),
        ),
      ));

      return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          }),
          child: ScrollablePositionedList.builder(
            initialScrollIndex: unreadMessages != 0 ? unreadMessages - 1 : 0,
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
                      AppLocalizations.of(context).nochKeineNachrichtVorhanden,
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

    searchIndexKontrollButton(direction, icon) {
      return IconButton(
          iconSize: 30,
          padding: const EdgeInsets.all(3),
          onPressed: messagesWithSearchText.isEmpty
              ? null
              : () => textSearchNext(direction),
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
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                  child: Center(
                      child: Text(messagesWithSearchText.isEmpty
                          ? AppLocalizations.of(context).keineErgebnisse
                          : "${searchTextIndex + 1} von ${messagesWithSearchText.length}"))),
              searchIndexKontrollButton("up", Icons.keyboard_arrow_up),
              searchIndexKontrollButton("down", Icons.keyboard_arrow_down),
            ],
          ),
        );
      } else if (widget.groupChatData["users"][userId] == null) {
        return GestureDetector(
          onTap: () async => joinChatGroup(),
          child: Container(
              constraints: const BoxConstraints(
                minHeight: 60,
              ),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ]),
              child: Center(
                  child: Text(AppLocalizations.of(context).gruppeBeitreten))),
        );
      } else {
        return Container(
            constraints: const BoxConstraints(
              minHeight: 60,
              maxHeight: 200
            ),
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
                              const Offset(0, 3), // changes position of shadow
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
                      hintText: AppLocalizations.of(context).nachricht,
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
                          messageToDbAndClearMessageInput(
                              nachrichtController.text);

                          resetExtraInputInformation();

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
                          saveEditMessage();
                          resetExtraInputInformation();
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
            Text(AppLocalizations.of(context).suche),
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

    mitgliederWindow(){
      List<Widget> mitgliederList = [];
      var detailsButtonName = "Information";

      widget.groupChatData["users"].forEach((memberUserId, data) {
        var userProfil = getProfilFromHive(profilId: memberUserId) ?? {};
        var userName = userProfil["name"];

        if (userProfil.isEmpty) return;

        mitgliederList.add(GestureDetector(
          onTap: () => global_functions.changePage(
              context,
              ShowProfilPage(
                userName: userName,
                profil: userProfil,
              )),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(width: 1.0, color: global_var.borderColorGrey),
              ),
            ),
            child: Text(userName),
          ),
        ));
      });

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: connectedData["name"],
              children: [
                if (widget.chatId != "1") Container(
                  width: 100,
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 30, top: 10),
                  child: FittedBox(
                    child: FloatingActionButton.extended(
                      label: Text(detailsButtonName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      onPressed: () => global_functions.changePage(context, pageDetailsPage),
                    ),
                  ),
                ),
                Text(AppLocalizations.of(context).member, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...mitgliederList
              ],
            );
          });
    }

    mitgliederDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.groups),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).member),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          mitgliederWindow();
        },
      );
    }

    pinChatDialog() {
      var chatIsPinned =
          widget.groupChatData["users"][userId]["pinned"] ?? false;

      return SimpleDialogOption(
        child: Row(
          children: [
            chatIsPinned
                ? StrikeThroughIcon(child: const Icon(Icons.push_pin))
                : const Icon(Icons.push_pin),
            const SizedBox(width: 10),
            Text(chatIsPinned
                ? AppLocalizations.of(context).losloesen
                : AppLocalizations.of(context).anheften),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);

          setState(() {
            widget.groupChatData["users"][userId]["pinned"] = !chatIsPinned;
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
      var chatIsMute = widget.groupChatData["users"][userId]["mute"] ?? false;

      return SimpleDialogOption(
        child: Row(
          children: [
            Icon(chatIsMute
                ? Icons.notifications_active
                : Icons.notifications_off),
            const SizedBox(width: 10),
            Text(chatIsMute
                ? AppLocalizations.of(context).stummAus
                : AppLocalizations.of(context).stummEin),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);

          setState(() {
            widget.groupChatData["users"][userId]["mute"] = !chatIsMute;
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

    deleteDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.delete, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).chatLoeschen,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);

          showDialog(
              context: context,
              builder: (BuildContext context) {
                return StatefulBuilder(builder: (ontext, setState) {
                  return CustomAlertDialog(
                    title: AppLocalizations.of(context).chatLoeschen,
                    height: 150,
                    children: [
                      Center(
                          child: Text(AppLocalizations.of(context)
                              .chatWirklichLoeschen)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(
                              value: bothDelete,
                              onChanged: (value) => {
                                    setState(() {
                                      bothDelete = value;
                                    })
                                  }),
                          Expanded(
                            child: Text(
                                AppLocalizations.of(context).auchBeiLoeschen +
                                    widget.chatPartnerName),
                          )
                        ],
                      )
                    ],
                    actions: [
                      TextButton(
                        child: Text(AppLocalizations.of(context).loeschen),
                        onPressed: () async {
                          deleteChat();
                        },
                      ),
                      TextButton(
                        child: Text(AppLocalizations.of(context).abbrechen),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  );
                });
              });
        },
      );
    }

    leaveDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).gruppeVerlassen,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);

          showDialog(
              context: context,
              builder: (BuildContext context) {
                return CustomAlertDialog(
                  title: AppLocalizations.of(context).gruppeVerlassen,
                  height: 100,
                  children: [
                    Center(
                        child: Text(AppLocalizations.of(context)
                            .gruppeWirklichVerlassen)),
                  ],
                  actions: [
                    TextButton(
                      child: Text(AppLocalizations.of(context).gruppeVerlassen),
                      onPressed: () async {
                        Navigator.pop(context);

                        ChatGroupsDatabase().leaveChat(widget.connectedId);

                        setState(() {
                          widget.groupChatData["users"]
                              .removeWhere((key, value) => key == userId);
                        });
                      },
                    ),
                    TextButton(
                      child: Text(AppLocalizations.of(context).abbrechen),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                );
              });
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

    showAppBar() {
      if (textSearchIsActive) {
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
                  hintText: AppLocalizations.of(context).suche,
                  suffixIcon: CloseButton(
                    color: Colors.white,
                    onPressed: () {
                      searchTextKontroller.clear();
                    },
                  )),
              onSubmitted: (value) {
                searchTextInMessages(value);

                setState(() {
                  isTextSearching = true;
                });

                var searchScrollIndex = messagesWithSearchText[0]["index"];
                scrollAndColoringMessage(searchScrollIndex);
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
      } else if (chatPartnerProfil == false) {
        return CustomAppBar(
            title: AppLocalizations.of(context).geloeschterUser,
            buttons: [
              IconButton(
                  onPressed: () => moreMenu(),
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ))
            ]);
      } else if (chatPartnerProfil != false) {
        var chatImage = widget.isChatgroup ? connectedData : chatPartnerProfil;

        return CustomAppBar(
          title: widget.isChatgroup
              ? Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.chatPartnerName ??
                          connectedData["name"]),
                      const SizedBox(height: 3),
                      Text(
                        widget.groupChatData["users"].length.toString() +
                            AppLocalizations.of(context).teilnehmerSimple,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      )
                    ],
                  ),
                )
              : widget.chatPartnerName ?? connectedData["name"],
          leading: widget.backToChatPage
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_sharp),
                  onPressed: () => global_functions.changePageForever(
                      context,
                      StartPage(
                        selectedIndex: 4,
                      )))
              : null,
          profilBildProfil: chatImage,
          onTap: () => widget.isChatgroup ? mitgliederWindow() : openProfil(),
          buttons: [
            IconButton(
                onPressed: () => moreMenu(),
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ))
          ],
        );
      }
    }

    return SelectionArea(
      child: Scaffold(
        appBar: showAppBar(),
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
