import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:familien_suche/global/global_functions.dart'
    as global_functions;
import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/pages/chat/pin_messages.dart';
import 'package:familien_suche/pages/community/community_card.dart';
import 'package:familien_suche/pages/events/eventCard.dart';
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

import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';
import '../../widgets/text_with_hyperlink_detection.dart';
import '../../windows/all_user_select.dart';
import '../../widgets/strike_through_icon.dart';

class ChatDetailsPage extends StatefulWidget {
  String chatPartnerId;
  var chatPartnerName;
  String chatId;
  var groupChatData;

  ChatDetailsPage({
    Key key,
    this.chatPartnerId,
    this.chatPartnerName,
    this.chatId,
    this.groupChatData,
  }) : super(key: key);

  @override
  _ChatDetailsPageState createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage>
    with WidgetsBindingObserver {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var userName = FirebaseAuth.instance.currentUser.displayName;
  var nachrichtController = TextEditingController();
  Timer timer;
  List<dynamic> messages = [];
  var eventCardList = [];
  var chatPartnerProfil;
  bool bothDelete = false;
  var messageInputNode = FocusNode();
  var searchInputNode = FocusNode();
  var messageIdChange;
  String changeMessageModus;
  Widget extraInputInformationBox = const SizedBox.shrink();
  var _scrollController = ItemScrollController();
  var itemPositionListener = ItemPositionsListener.create();
  var scrollIndex = -1;
  var hasStartPosition = true;
  var startData;
  var counter = 0;
  var ownMessageBoxColor = Colors.greenAccent;
  var chatpartnerMessageBoxColor = Colors.white;
  var myChats = Hive.box("secureBox").get("myChats");
  var angehefteteMessageShowIndex;
  var isLoading = true;
  var textSearchIsActive = false;
  var searchTextKontroller = TextEditingController();
  var messagesWithSearchText = [];
  var isTextSearching = false;
  var searchTextIndex = 0;
  var allEvents = Hive.box('secureBox').get("events") ?? [];
  var allCommunities = Hive.box('secureBox').get("communities") ?? [];

  @override
  void dispose() {
    ProfilDatabase().updateProfil("activeChat = '" "'", "WHERE id = '$userId'");
    WidgetsBinding.instance.removeObserver(this);
    timer.cancel();
    messageInputNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ProfilDatabase().updateProfil(
          "activeChat = '$widget.chatId'", "WHERE id = '$userId'");
    } else {
      ProfilDatabase()
          .updateProfil("activeChat = '" "'", "WHERE id = '$userId'");
    }
  }

  @override
  void initState() {
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

    if (widget.groupChatData == null) {
      widget.chatId = global_functions.getChatID(widget.chatPartnerId);
    } else {
      widget.chatId = widget.groupChatData["id"];
    }

    _asyncMethod();

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  _asyncMethod() async {
    await createNewChat();
    await getAndSetChatData();
    if (messages.isEmpty) getAllDbMessages();
    writeActiveChat();
    await getChatPartnerProfil();

    if (widget.groupChatData != false) resetNewMessageCounter();

    setState(() {});

    timer = Timer.periodic(
        const Duration(seconds: 10), (Timer t) => getAllDbMessages());

  }

  createNewChat() async {
    if (widget.groupChatData != null) return;

    widget.chatPartnerId ??= await ProfilDatabase()
        .getData("id", "WHERE name = '${widget.chatPartnerName}'");
    widget.chatPartnerName ??= await ProfilDatabase()
        .getData("name", "WHERE id = '${widget.chatPartnerId}'");

    widget.groupChatData =
        await ChatDatabase().addNewChatGroup(widget.chatPartnerId);
  }

  getAndSetChatData() async {
    widget.chatId ??= widget.groupChatData["id"];
    var groupchatUsers = widget.groupChatData["users"];
    groupchatUsers.forEach((key, value) {
      if (key != userId) {
        widget.chatPartnerId = key;
      }
    });

    widget.chatPartnerName ??= await ProfilDatabase()
        .getData("name", "WHERE id = '${widget.chatPartnerId}'");
  }

  writeActiveChat() {
    ProfilDatabase()
        .updateProfil("activeChat = '$widget.chatId'", "WHERE id = '$userId'");
  }

  getChatPartnerProfil() async {
    chatPartnerProfil = await ProfilDatabase()
        .getData("*", "WHERE id = '${widget.chatPartnerId}'");
  }

  resetNewMessageCounter() async {
    var users = widget.groupChatData["users"];

    var usersChatNewMessages = users[userId]["newMessages"];

    if (usersChatNewMessages == 0) return;

    var usersAllNewMessages =
        await ProfilDatabase().getData("newMessages", "WHERE id = '$userId'");
    usersAllNewMessages = usersAllNewMessages - usersChatNewMessages < 0
        ? 0
        : usersAllNewMessages - usersChatNewMessages;

    ProfilDatabase().updateProfil(
        "newMessages = '$usersAllNewMessages'", "WHERE id ='$userId'");
    widget.groupChatData["users"][userId]["newMessages"] = 0;

    ChatDatabase().updateChatGroup(
        "users = '${json.encode(widget.groupChatData["users"])}'",
        "WHERE id = '${widget.groupChatData["id"]}'");
  }

  getAllDbMessages() async {
    if (widget.chatId == null && widget.groupChatData == null) return;

    var chatId = widget.chatId ?? widget.groupChatData["id"];

    List<dynamic> allDbMessages = await ChatDatabase().getAllMessages(chatId);
    allDbMessages.sort((a, b) => (a["date"]).compareTo(b["date"]));

    messages = allDbMessages;

    setState(() {
      isLoading = false;
    });
  }

  checkChatgroupUsers() {
    var chatUsers = widget.groupChatData["users"];

    if (chatUsers.length == 2) return;

    chatUsers.add({
      userId: {
        "name": widget.chatPartnerName.replaceAll("'", "''"),
        "newMessages": 0
      }
    });

    ChatDatabase().updateChatGroup("users = '${json.encode(chatUsers)}'",
        "WHERE id = '${widget.groupChatData["id"]}'");
  }

  messageToDbAndClearMessageInput(message) async {
    var userID = FirebaseAuth.instance.currentUser.uid;
    var checkMessage = nachrichtController.text.split("\n").join();

    if (checkMessage.isEmpty) return;

    var messageData = {
      "chatId": widget.chatId,
      "message": message,
      "von": userID,
      "date": DateTime.now().millisecondsSinceEpoch.toString(),
      "zu": widget.chatPartnerId,
      "responseId" : messageIdChange ??= "0"
    };

    setState(() {
      messages.add(messageData);
    });

    await ChatDatabase().addNewMessageAndSendNotification(
        widget.groupChatData, messageData, messageIdChange);

    if (messageData["message"].contains("</eventId=")) {
      messageData["message"] = "<Event Card>";
    }
    if (messageData["message"].contains("</communityId=")) {
      messageData["message"] = "<Community Card>";
    }

    ChatDatabase().updateChatGroup(
        "lastMessage = '${messageData["message"]}' , lastMessageDate = '${messageData["date"]}'",
        "WHERE id = '${widget.chatId}'");
  }

  openProfil() async {
    chatPartnerProfil ??= await ProfilDatabase()
        .getData("*", "WHERE id = '${widget.chatPartnerId}'");

    if (chatPartnerProfil == false) return;

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

  deleteChat({bothDelete = false}) {
    var chatUsers = widget.groupChatData["users"];
    var chatId = widget.groupChatData["id"];
    var myChatBox = Hive.box("secureBox");
    var myChats = myChatBox.get("myChats");

    if (chatUsers.length <= 1 || bothDelete) {
      var removeChat = {};

      for (var myChat in myChats) {
        if (myChat["id"] == widget.chatId) removeChat = myChat;
      }

      myChats.remove(removeChat);

      ChatDatabase().deleteChat(chatId);
      ChatDatabase().deleteMessages(chatId);
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
          "users = '${json.encode(newChatUsersData)}'", "WHERE id ='$chatId'");
    }

    global_functions.changePageForever(
        context,
        StartPage(
          selectedIndex: 4,
        ));
  }

  replyMessage(message) {
    messageIdChange = message["id"];
    setState((){
      changeMessageModus = "reply";
    });


    Future.delayed(const Duration(milliseconds: 50), () {
      messageInputNode.requestFocus();
    });

  }

  editMessage(message) {
    messageIdChange = message["id"];
    messageInputNode.requestFocus();
    nachrichtController.text = message["message"];
    changeMessageModus = "edit";
  }

  copyMessage(messageText) {
    Clipboard.setData(ClipboardData(text: messageText));
    customSnackbar(
        context, AppLocalizations.of(context).nachrichtZwischenAblage,
        color: Colors.green);
  }

  forwardedMessage(message) async {
    var allUserSelectWindow = AllUserSelectWindow(
        context: context,
        title: AppLocalizations.of(context).empfaengerWaehlen);
    var selectedId = await allUserSelectWindow.openWindow();
    var selectedChatId = global_functions.getChatID(selectedId);
    var chatGroupData =
        await ChatDatabase().getChatData("*", "WHERE id = '$selectedChatId'");

    var messageData = {
      "message": "<weiterleitung>",
      "von": userId,
      "date": DateTime.now().millisecondsSinceEpoch.toString(),
      "zu": selectedId,
      "forward": json.encode(message)
    };

    ChatDatabase().updateChatGroup(
        "lastMessage = '${messageData["message"]}' , lastMessageDate = '${messageData["date"]}'",
        "WHERE id = '$selectedChatId'");

    ChatDatabase()
        .addNewMessageAndSendNotification(chatGroupData, messageData, 0);
  }

  deleteMessage(messageId) {
    ChatDatabase().deleteMessages(messageId);

    messages.removeWhere((element) => element["id"] == messageId);

    setState(() {});
  }

  reportMessage(message) {
    ReportsDatabase().add(
        userId,
        "Message tableId: " + message["id"] + " gemeldet",
        message["message"]);

    customSnackbar(context, AppLocalizations.of(context).nachrichtGemeldet,
        color: Colors.green);
  }

  pinMessage(message) async {
    var messageIsPinned =
        widget.groupChatData["users"][userId]["pinnedMessages"];
    if (messageIsPinned != null && messageIsPinned.runtimeType == String) {
      messageIsPinned = json.decode(messageIsPinned);
    }

    if (messageIsPinned == null || messageIsPinned.isEmpty) {
      widget.groupChatData["users"][userId]
          ["pinnedMessages"] = [message["id"]];

      setState(() {
        angehefteteMessageShowIndex =
            widget.groupChatData["users"][userId]["pinnedMessages"].length - 1;
      });

      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.pinnedMessages', '${[
            message["id"]
          ]}')",
          "WHERE id = '${message["chatId"]}'");
    } else {
      messageIsPinned.add(message["id"]);
      widget.groupChatData["users"][userId]["pinnedMessages"] = messageIsPinned;

      setState(() {
        angehefteteMessageShowIndex = messageIsPinned.length - 1;
      });

      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$messageIsPinned')",
          "WHERE id = '${message["chatId"]}'");
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

    ChatDatabase().updateChatGroup(
        "users = JSON_SET(users, '\$.$userId.pinnedMessages', '$messageIsPinned')",
        "WHERE id = '${message["chatId"]}'");
  }

  resetExtraInputInformation() {
    messageIdChange = null;
    extraInputInformationBox = const SizedBox.shrink();
    nachrichtController.clear();
    changeMessageModus = null;
    messageInputNode.unfocus();

    setState(() {});
  }

  saveEditMessage() {
    for (var message in messages) {
      if (message["id"] == messageIdChange) {
        message["message"] = nachrichtController.text;
      }
    }

    ChatDatabase().updateMessage(
        "message = '${nachrichtController.text}', editDate = '${DateTime.now().millisecondsSinceEpoch}'",
        "WHERE tableId = '$messageIdChange'");
  }

  showAllPinMessages() {
    var allPinnedMessageIds =
        json.decode(widget.groupChatData["users"][userId]["pinnedMessages"]);
    var allPinMessages = [];

    for (var pinMessageId in allPinnedMessageIds) {
      for (var message in messages) {
        if (pinMessageId == int.parse(message["id"])) {
          allPinMessages.add(message);
        }
      }
    }

    global_functions.changePage(
        context, pinMessagesPage(pinMessages: allPinMessages));
  }

  jumpToMessageAndShowNextAngeheftet(index) {
    angehefteteMessageShowIndex = angehefteteMessageShowIndex - 1;
    if (angehefteteMessageShowIndex < 0) {
      angehefteteMessageShowIndex =
          widget.groupChatData["pinMessages"].length - 1;
    }

    scrollAndColoringMessage(index);
  }

  searchTextInMessages(searchText) {
    messagesWithSearchText = [];
    var index = -1;

    for (var message in messages) {
      index = index + 1;

      if (message["message"].contains(searchText)) {
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
    var scrollToIndex = messages.length - 1 - messageIndex  -1;
    if(scrollToIndex<0) scrollToIndex = 0;

    _scrollController.scrollTo(
        index: scrollToIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic);

    setState(() {
      scrollIndex = messageIndex;
    });

    Future.delayed(const Duration(milliseconds: 1300), () {
      setState(() {
        scrollIndex = -1;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    angehefteteNachrichten() {
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

      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white60, border: Border.all()),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => jumpToMessageAndShowNextAngeheftet(index),
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
      if (message["forward"].runtimeType == String) {
        message["forward"] = json.decode(message["forward"]);
      }
      var isInPinned = false;
      var angehefteteMessages =
          widget.groupChatData["users"][userId]["pinnedMessages"] ?? [];
      if (angehefteteMessages.runtimeType == String) {
        angehefteteMessages = json.decode(angehefteteMessages);
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
            Offset(0, screenHeight / 3) & const Size(40, 40),
            // smaller rect, the touch area
            Offset.zero & overlay.size // Bigger rect, the entire screen
            ),
        items: [
          PopupMenuItem(
            onTap: () {
              var replyUser = global_functions.getProfilFromHive(message["von"],
                  onlyName: true);

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
          if (isMyMessage)
            PopupMenuItem(
              onTap: () => deleteMessage(message["id"]),
              child: Row(
                children: [
                  const Icon(Icons.delete),
                  const SizedBox(width: 20),
                  Text(AppLocalizations.of(context).loeschenGross),
                ],
              ),
            ),
          if (!isMyMessage)
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

    eventMessage(index, textAlign, message, messageTime) {
      var eventId = message["message"].substring(10);
      var eventData;

      for (var event in allEvents) {
        if (event["id"] == eventId) {
          eventData = event;
          break;
        }
      }

      return AnimatedContainer(
        color: scrollIndex == index
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
        duration: const Duration(seconds: 1),
        curve: Curves.easeIn,
        child: Align(
            alignment: textAlign,
            child: Container(
              margin: const EdgeInsets.only(bottom: 25),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(width:180, height: 290 ),
                EventCard(
                  margin: const EdgeInsets.all(15),
                  withInteresse: true,
                  event: eventData,
                  afterPageVisit: () => setState(() {}),
                ),
                Positioned(
                  bottom: 0,
                  right: 15,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () {
                            var replyUser = global_functions.getProfilFromHive(
                                message["von"],
                                onlyName: true);

                            extraInputInformationBox = inputInformationBox(
                                Icons.reply, replyUser, message["message"]);
                            replyMessage(message);
                          },
                          child: Text(AppLocalizations.of(context).antworten)),
                      Text(messageTime,
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              ]),
            )),
      );
    }

    communityMessage(index, textAlign, message, messageTime) {
      var communityId = message["message"].substring(14);
      var communityData;

      for (var community in allCommunities) {
        if (community["id"] == communityId) {
          communityData = community;
          break;
        }
      }

      return AnimatedContainer(
          color: scrollIndex == index
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          duration: const Duration(seconds: 1),
          curve: Curves.easeIn,
          child: Align(
              alignment: textAlign,
              child: Container(
                margin: const EdgeInsets.only(bottom: 25),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(width:180, height: 290 ),
                  CommunityCard(
                    margin: const EdgeInsets.all(15),
                    withFavorite: true,
                    community: communityData,
                    afterPageVisit: () => setState(() {}),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 15,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () {
                              var replyUser = global_functions
                                  .getProfilFromHive(message["von"],
                                      onlyName: true);

                              extraInputInformationBox = inputInformationBox(
                                  Icons.reply, replyUser, message["message"]);
                              replyMessage(message);
                            },
                            child:
                                Text(AppLocalizations.of(context).antworten)),
                        Text(messageTime,
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                ]),
              )));
    }

    responseMessage(index, message, boxColor, messageTime, messageEdit) {
      var replyFromId =
          message["chatId"].replaceAll(userId, "").replaceAll("_", "");
      var messageFromProfil = global_functions.getProfilFromHive(replyFromId);
      var replyMessageText;
      var replyIndex = messages.length;


      for (var lookMessage in messages.reversed.toList()) {
        replyIndex -= 1;

        if (lookMessage["id"] == message["responseId"]) {
          replyMessageText = lookMessage;
          break;
        }
      }

      var isEvent = replyMessageText["message"].contains("</eventId=");
      var isCommunity = replyMessageText["message"].contains("</communityId=");
      var cardData = {};
      var textAddition = "";

      if(isEvent || isCommunity){
        if(isEvent){
          var eventId = replyMessageText["message"].substring(10);
          for(var event in allEvents){
            if(event["id"] == eventId){
              textAddition = "Event: ";
              cardData = event;
              break;
            }
          }
        }
        else if(isCommunity){
          var communityId = replyMessageText["message"].substring(14);
          for(var community in allCommunities){
            if(community["id"] == communityId){
              textAddition = "Community: ";
              cardData = community;
              break;
            }
          }
        }
      }

      return AnimatedContainer(
        color: scrollIndex == index
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
        duration: const Duration(seconds: 1),
        curve: Curves.easeIn,
        child: Row(
          children: [
            const Expanded(flex: 2, child: SizedBox.shrink()),
            Stack(
              children: [
                Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85),
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: boxColor,
                        border: Border.all(),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            scrollAndColoringMessage(replyIndex);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                                padding: const EdgeInsets.only(left: 5),
                                decoration: BoxDecoration(
                                    border: Border(
                                        left: BorderSide(
                                            width: 2,
                                            color: Color(messageFromProfil[
                                                    "bildStandardFarbe"])
                                                .withOpacity(1)))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(messageFromProfil["name"],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(messageFromProfil[
                                                    "bildStandardFarbe"])
                                                .withOpacity(1))),
                                    Text(
                                      cardData["name"] == null
                                          ? replyMessageText["message"]
                                          : textAddition + cardData["name"],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ],
                                )),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                              top: 5, left: 10, bottom: 7, right: 10),
                          child: Wrap(
                            children: [
                              TextWithHyperlinkDetection(
                                text: message["message"] ?? "",
                                fontsize: 16,
                                onTextTab: () =>
                                    openMessageMenu(message, index),
                              ),
                              SizedBox(
                                  width: message["editDate"] == null ? 40 : 110)
                            ],
                          ),
                        ),
                      ],
                    )),
                Positioned(
                  right: 20,
                  bottom: 15,
                  child: Text(messageEdit + " " + messageTime,
                      style: TextStyle(color: Colors.grey[600])),
                )
              ],
            ),
          ],
        ),
      );
    }

    forwardMessage(index, textAlign, message, boxColor, messageTime,
        messageEdit, forwardData) {
      var forwardProfil =
          global_functions.getProfilFromHive(forwardData["von"]);

      return AnimatedContainer(
        color: scrollIndex == index
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
        duration: const Duration(seconds: 1),
        curve: Curves.easeIn,
        child: Align(
          alignment: textAlign,
          child: Stack(
            children: [
              Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: boxColor,
                      border: Border.all(),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
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
                      Wrap(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(
                                top: 5, left: 10, bottom: 7, right: 10),
                            child: TextWithHyperlinkDetection(
                                text: forwardData["message"] ?? "",
                                fontsize: 16,
                                onTextTab: () =>
                                    openMessageMenu(message, index)),
                          ),
                          SizedBox(
                              width: message["editDate"] == null ? 40 : 110),
                        ],
                      ),
                    ],
                  )),
              Positioned(
                right: 20,
                bottom: 15,
                child: Text(messageEdit + " " + messageTime,
                    style: TextStyle(color: Colors.grey[600])),
              )
            ],
          ),
        ),
      );
    }

    normalMessage(
        index, textAlign, message, boxColor, messageTime, messageEdit) {
      return AnimatedContainer(
        color: scrollIndex == index
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
        duration: const Duration(seconds: 1),
        curve: Curves.easeIn,
        child: Align(
          alignment: textAlign,
          child: Stack(
            children: [
              Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: boxColor,
                      border: Border.all(),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: Wrap(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(
                            top: 5, left: 10, bottom: 7, right: 10),
                        child: TextWithHyperlinkDetection(
                            text: message["message"] ?? "",
                            fontsize: 16,
                            onTextTab: () => openMessageMenu(message, index)),
                      ),
                      SizedBox(width: message["editDate"] == null ? 40 : 110),
                    ],
                  )),
              Positioned(
                right: 20,
                bottom: 15,
                child: Text(messageEdit + " " + messageTime,
                    style: TextStyle(color: Colors.grey[600])),
              )
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
        var messageTime = DateFormat('HH:mm').format(messageDateTime);
        var messageEdit = message["editDate"] == null
            ? ""
            : AppLocalizations.of(context).bearbeitet;
        var textAlign = Alignment.centerLeft;
        var boxColor = chatpartnerMessageBoxColor;
        var forwardData = message["forward"].runtimeType == String
            ? json.decode(message["forward"])
            : message["forward"];
        forwardData ??= {};
        message["responseId"] ??= "0";

        if (message["message"] == "") continue;

        message["message"] = removeAllNewLineAtTheEnd(message["message"]);

        if (message["von"] == userId) {
          textAlign = Alignment.centerRight;
          boxColor = ownMessageBoxColor;
        }

        if(newMessageDate == null){
          newMessageDate = messageDate;
        }
        else if (newMessageDate != messageDate) {
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

        if (message["message"].contains("</eventId=")) {
          messageBox.add(eventMessage(i, textAlign, message, messageTime));
        }
        else if (message["message"].contains("</communityId=")) {
          messageBox.add(communityMessage(i, textAlign, message, messageTime));
        }
        else if (int.parse(message["responseId"]) != 0) {
          messageBox.add(
              responseMessage(i, message, boxColor, messageTime, messageEdit));
        }
        else if (forwardData.isNotEmpty) {
          messageBox.add(forwardMessage(i, textAlign, message, boxColor,
              messageTime, messageEdit, forwardMessage));
        }
        else {
          messageBox.add(normalMessage(
              i, textAlign, message, boxColor, messageTime, messageEdit));
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
      if (!isTextSearching) {
        return Container(
            constraints: const BoxConstraints(
              minHeight: 60,
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
                changeMessageModus != "edit"
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          checkChatgroupUsers();
                          messageToDbAndClearMessageInput(
                              nachrichtController.text);

                          resetExtraInputInformation();

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
      } else if (isTextSearching) {
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
      }
    }

    searchDialog() {
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

    pinDialog() {
      var chatIsPinned =
          widget.groupChatData["users"][userId]["pinned"] ?? false;
      chatIsPinned = chatIsPinned == "true";

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

          ChatDatabase().updateChatGroup(
              "users = JSON_SET(users, '\$.$userId.pinned', '${!chatIsPinned}')",
              "WHERE id = '${widget.chatId}'");
        },
      );
    }

    muteDialog() {
      var chatIsMute = widget.groupChatData["users"][userId]["mute"] ?? false;
      chatIsMute = chatIsMute == "true";

      return SimpleDialogOption(
        child: Row(
          children: [
            Icon(chatIsMute
                ? Icons.notifications_active
                : Icons.notifications_off),
            const SizedBox(width: 10),
            Text(chatIsMute
                ? AppLocalizations.of(context).stummEin
                : AppLocalizations.of(context).stummAus),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);

          setState(() {
            widget.groupChatData["users"][userId]["mute"] = !chatIsMute;
          });

          ChatDatabase().updateChatGroup(
              "users = JSON_SET(users, '\$.$userId.mute', '${!chatIsMute}')",
              "WHERE id = '${widget.chatId}'");
        },
      );
    }

    /*
    settingDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.settings),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).einstellungen),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);

          showDialog(
              context: context,
              builder: (BuildContext context) {
                return StatefulBuilder(builder: (ontext, setState) {
                  return CustomAlertDialog(
                    title: AppLocalizations.of(context).chatEinstellung,
                    height: 140,
                    children: [
                      const Center(child: Text("Message Input Größe")),
                      Slider(
                        max: 70,
                        min: 40,
                        value: 50,
                        onChanged: (value) {},
                      )
                    ],
                  );
                });
              });
        },
      );
    }

     */

    deleteDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.delete),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).chatLoeschen),
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
                    height: 140,
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
                          Text(AppLocalizations.of(context).auchBeiLoeschen +
                              widget.chatPartnerName)
                        ],
                      )
                    ],
                    actions: [
                      TextButton(
                        child: Text(AppLocalizations.of(context).loeschen),
                        onPressed: () async {
                          deleteChat(bothDelete: bothDelete);
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

    moreMenu() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 180,
                  child: SimpleDialog(
                    contentPadding: EdgeInsets.zero,
                    insetPadding:
                        const EdgeInsets.only(top: 40, left: 0, right: 10),
                    children: [
                      searchDialog(),
                      pinDialog(),
                      muteDialog(),
                      //settingDialog(),
                      const SizedBox(height: 10),
                      deleteDialog()
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
        return CustomAppBar(
          title: widget.chatPartnerName ?? "",
          profilBildProfil: chatPartnerProfil,
          onTap: () => openProfil(),
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
        resizeToAvoidBottomInset: false,
        appBar: showAppBar(),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            angehefteteNachrichten(),
            Expanded(child: messageAnzeige()),
            extraInputInformationBox,
            textEingabeFeld(),
          ],
        ),
      ),
    );
  }
}
