import 'dart:async';
import 'dart:convert';
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
  bool backToChatPage;

  ChatDetailsPage({
    Key key,
    this.chatPartnerId,
    this.chatPartnerName,
    this.chatId,
    this.groupChatData,
    this.backToChatPage = false,
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
  var scrollIndex = -1;
  var hasStartPosition = true;
  var myChats = Hive.box("secureBox").get("myChats");
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

  @override
  void initState() {
    createNewChat();
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
    ProfilDatabase().updateProfil("activeChat = '" "'", "WHERE id = '$userId'");

    WidgetsBinding.instance.removeObserver(this);

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
    widget.chatPartnerId ??=
        getProfilFromHive(profilName: widget.chatPartnerName, getIdOnly: true);
    widget.chatPartnerName ??=
        getProfilFromHive(profilId: widget.chatPartnerId, getNameOnly: true);

    widget.chatId ??= widget.groupChatData["id"];
    chatPartnerProfil = getProfilFromHive(profilId: widget.chatPartnerId);

    if (widget.groupChatData["users"][userId] == null) {
      widget.groupChatData["users"][userId] = {"newMessages": 0};
      ChatDatabase().updateChatGroup(
          "users = JSON_MERGE(users, '${json.encode({
                userId: {"newMessages": 0}
              })}')",
          "WHERE id = '${widget.groupChatData["id"]}'");
    }
  }

  writeActiveChat() {
    ProfilDatabase()
        .updateProfil("activeChat = '$widget.chatId'", "WHERE id = '$userId'");
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
        const Duration(seconds: 10), (Timer t) => getAllDbMessages());
  }

  getAllDbMessages() async {
    var chatId = widget.chatId ?? widget.groupChatData["id"];
    List<dynamic> allDbMessages =
        await ChatDatabase().getAllChatMessages(chatId);
    allDbMessages.sort((a, b) => (a["date"]).compareTo(b["date"]));

    setState(() {
      messages = allDbMessages;
      isLoading = false;
    });
  }

  resetNewMessageCounter() async {
    var users = widget.groupChatData["users"];
    var usersChatNewMessages = users[userId]["newMessages"];

    if (usersChatNewMessages == 0) return;

    var ownAllMessages = ownProfil["newMessages"];
    var newOwnAllMessages = ownAllMessages - usersChatNewMessages < 0
        ? 0
        : ownAllMessages - usersChatNewMessages;

    ownProfil["newMessages"] = newOwnAllMessages;

    ProfilDatabase().updateProfil(
        "newMessages = '$newOwnAllMessages'", "WHERE id ='$userId'");

    widget.groupChatData["users"][userId]["newMessages"] = 0;

    ChatDatabase().updateChatGroup(
        "users = JSON_SET(users, '\$.$userId.newMessages', ${widget.groupChatData["users"][userId]["newMessages"]})",
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
      "responseId": messageExtraInformationId ??= "0"
    };

    setState(() {
      messages.add(messageData);
    });

    var isBlocked = ownProfil["geblocktVon"].contains(widget.chatPartnerId);
    await ChatDatabase().addNewMessageAndSendNotification(
        widget.groupChatData, messageData, isBlocked);

    if (messageData["message"].contains("</eventId=")) {
      messageData["message"] = "<Event Card>";
    }
    if (messageData["message"].contains("</communityId=")) {
      messageData["message"] = "<Community Card>";
    }

    for (var myChat in myChats) {
      if (myChat["id"] == widget.chatId) {
        myChat["lastMessage"] = messageData["message"];
        myChat["lastMessageDate"] = int.parse(messageData["date"]);
      }
    }

    ChatDatabase().updateChatGroup(
        "lastMessage = '${messageData["message"]}' , lastMessageDate = '${messageData["date"]}'",
        "WHERE id = '${widget.chatId}'");
  }

  openProfil() async {
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
    messageExtraInformationId = message["id"];

    setState(() {
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
        color: Colors.green);
  }

  forwardedMessage(message) async {
    var allUserSelectWindow = AllUserSelectWindow(
        context: context,
        title: AppLocalizations.of(context).empfaengerWaehlen);
    var selectedUserId = await allUserSelectWindow.openWindow();
    var selectedChatId = global_functions.getChatID(selectedUserId);
    var chatGroupData =
        await ChatDatabase().getChatData("*", "WHERE id = '$selectedChatId'");

    var messageData = {
      "message": "<weiterleitung>",
      "von": userId,
      "date": DateTime.now().millisecondsSinceEpoch.toString(),
      "zu": selectedUserId,
      "forward": json.encode(message),
      "responseId": "0"
    };

    ChatDatabase().updateChatGroup(
        "lastMessage = '${messageData["message"]}' , lastMessageDate = '${messageData["date"]}'",
        "WHERE id = '$selectedChatId'");

    var isBlocked = ownProfil["geblocktVon"].contains(userId);
    await ChatDatabase().addNewMessageAndSendNotification(
        chatGroupData, messageData, isBlocked);

    global_functions.changePage(
        context,
        ChatDetailsPage(
            chatPartnerId: selectedUserId,
            groupChatData: chatGroupData,
            backToChatPage: true));
  }

  deleteMessage(messageId) {
    ChatDatabase().deleteMessages(messageId);

    messages.removeWhere((element) => element["id"] == messageId);

    setState(() {});
  }

  reportMessage(message) {
    ReportsDatabase().add(userId,
        "Message tableId: " + message["id"] + " gemeldet", message["message"]);

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
          ["pinnedMessages"] = [int.parse(message["id"])];

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
      messageIsPinned.add(int.parse(message["id"]));
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
    messageExtraInformationId = null;
    extraInputInformationBox = const SizedBox.shrink();
    nachrichtController.clear();
    changeMessageInputModus = null;
    messageInputNode.unfocus();

    setState(() {});
  }

  saveEditMessage() {
    for (var message in messages) {
      if (message["id"] == messageExtraInformationId) {
        message["message"] = nachrichtController.text;
        message["editDate"] = DateTime.now().millisecondsSinceEpoch;
      }
    }

    ChatDatabase().updateMessage(
        "message = '${nachrichtController.text}', editDate = '${DateTime.now().millisecondsSinceEpoch}'",
        "WHERE id = '$messageExtraInformationId'");
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
    var scrollToIndex = messages.length - 1 - messageIndex - 1;
    if (scrollToIndex < 0) scrollToIndex = 0;

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
    var ownMessageBoxColor = Colors.greenAccent;
    var chatpartnerMessageBoxColor = Colors.white;

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

    eventMessage(index, message, messageBoxInformation) {
      var messageSplit = message["message"].split(" ");
      var eventId = "";
      var eventData;

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

      return AnimatedContainer(
        color: scrollIndex == index
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
        duration: const Duration(seconds: 1),
        curve: Curves.easeIn,
        child: Align(
            alignment: messageBoxInformation["textAlign"],
            child: Container(
              child: Column(children: [
                Container(
                  alignment: messageBoxInformation["textAlign"],
                  child: EventCard(
                    margin: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 0),
                    withInteresse: true,
                    event: eventData,
                    afterPageVisit: () => setState(() {}),
                  ),
                ),
                messageSplit.length == 1
                    ? Row(
                  mainAxisAlignment: messageBoxInformation["textAlign"] == Alignment.centerLeft
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                        children: [
                          SizedBox(width: 70),
                          TextButton(
                              onPressed: () {
                                var replyUser = getProfilFromHive(
                                    profilId: message["von"],
                                    getNameOnly: true);

                                extraInputInformationBox = inputInformationBox(
                                    Icons.reply, replyUser, message["message"]);
                                replyMessage(message);
                              },
                              child:
                                  Text(AppLocalizations.of(context).antworten)),
                          Text(messageBoxInformation["messageTime"],
                              style: TextStyle(color: Colors.grey[600])),
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
                                    color: messageBoxInformation["messageBoxColor"],
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
                                    Text(messageBoxInformation["messageEdit"] + " " + messageBoxInformation["messageTime"],
                                        style: const TextStyle(
                                            color: Colors.transparent))
                                  ],
                                )),
                            Positioned(
                              right: 20,
                              bottom: 15,
                              child: Text(messageBoxInformation["messageEdit"] + messageBoxInformation["messageTime"],
                                  style: TextStyle(color: Colors.grey[600])),
                            )
                          ],
                        ),
                      )
              ]),
            )),
      );
    }

    communityMessage(index,message, messageBoxInformation) {
      var messageSplit = message["message"].split(" ");
      var communityId = "";
      var communityData;

      for (var text in messageSplit) {
        if (text.contains("</communityId=")) communityId = text.substring(14);
      }

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
            alignment: messageBoxInformation["textAlign"],
            child: Container(
              child: Column(children: [
                Container(
                  alignment: messageBoxInformation["textAlign"],
                  child: CommunityCard(
                    margin: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 0),
                    community: communityData,
                    afterPageVisit: () => setState(() {}),
                  ),
                ),
                messageSplit.length == 1
                    ? Row(
                        mainAxisAlignment: messageBoxInformation["textAlign"] == Alignment.centerLeft
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        children: [
                          SizedBox(width: 70),
                          TextButton(
                              onPressed: () {
                                var replyUser = getProfilFromHive(
                                    profilId: message["von"],
                                    getNameOnly: true);

                                extraInputInformationBox = inputInformationBox(
                                    Icons.reply, replyUser, message["message"]);
                                replyMessage(message);
                              },
                              child:
                                  Text(AppLocalizations.of(context).antworten)),
                          Text(messageBoxInformation["messageTime"],
                              style: TextStyle(color: Colors.grey[600])),
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
                                    color: messageBoxInformation["messageBoxColor"],
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
                                    Text(messageBoxInformation["messageEdit"] + " " + messageBoxInformation["messageTime"],
                                        style: const TextStyle(
                                            color: Colors.transparent))
                                  ],
                                )),
                            Positioned(
                              right: 20,
                              bottom: 15,
                              child: Text(messageBoxInformation["messageEdit"] + messageBoxInformation["messageTime"],
                                  style: TextStyle(color: Colors.grey[600])),
                            )
                          ],
                        ),
                      )
              ]),
            )),
      );
    }

    responseMessage(index, message,messageBoxInformation) {
      var replyFromId =
          message["chatId"].replaceAll(userId, "").replaceAll("_", "");
      var messageFromProfil = getProfilFromHive(profilId: replyFromId);
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

      if (isEvent || isCommunity) {
        if (isEvent) {
          var eventId = replyMessageText["message"].substring(10);
          for (var event in allEvents) {
            if (event["id"] == eventId) {
              textAddition = "Event: ";
              cardData = event;
              break;
            }
          }
        } else if (isCommunity) {
          var communityId = replyMessageText["message"].substring(14);
          for (var community in allCommunities) {
            if (community["id"] == communityId) {
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
                        color: messageBoxInformation["messageBoxColor"],
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
                              const SizedBox(width: 5),
                              Text(messageBoxInformation["messageEdit"] + " " + messageBoxInformation["messageTime"],
                                  style: const TextStyle(
                                      color: Colors.transparent))
                            ],
                          ),
                        ),
                      ],
                    )),
                Positioned(
                  right: 20,
                  bottom: 15,
                  child: Text(messageBoxInformation["messageEdit"] + " " + messageBoxInformation["messageTime"],
                      style: TextStyle(color: Colors.grey[600])),
                )
              ],
            ),
          ],
        ),
      );
    }

    forwardMessage(index, message, forwardData,messageBoxInformation) {
      var forwardProfil = getProfilFromHive(profilId: forwardData["von"]);

      return AnimatedContainer(
        color: scrollIndex == index
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
        duration: const Duration(seconds: 1),
        curve: Curves.easeIn,
        child: Align(
          alignment: messageBoxInformation["textAlign"],
          child: Stack(
            children: [
              Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: messageBoxInformation["messageBoxColor"],
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
                          const SizedBox(width: 5),
                          Text(messageBoxInformation["messageEdit"] + " " + messageBoxInformation["messageTime"],
                              style: const TextStyle(color: Colors.transparent))
                        ],
                      ),
                    ],
                  )),
              Positioned(
                right: 20,
                bottom: 15,
                child: Text(messageBoxInformation["messageEdit"] + " " + messageBoxInformation["messageTime"],
                    style: TextStyle(color: Colors.grey[600])),
              )
            ],
          ),
        ),
      );
    }

    normalMessage(index, message, messageBoxInformation) {
      return AnimatedContainer(
        color: scrollIndex == index
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
        duration: const Duration(seconds: 1),
        curve: Curves.easeIn,
        child: Align(
          alignment: messageBoxInformation["textAlign"],
          child: Stack(
            children: [
              Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85),
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: messageBoxInformation["messageBoxColor"],
                      border: Border.all(),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      TextWithHyperlinkDetection(
                          text: message["message"] ?? "",
                          fontsize: 16,
                          onTextTab: () => openMessageMenu(message, index)),
                      const SizedBox(width: 5),
                      Text(messageBoxInformation["messageEdit"] + " " + messageBoxInformation["messageTime"],
                          style: const TextStyle(color: Colors.transparent))
                    ],
                  )),
              Positioned(
                right: 20,
                bottom: 15,
                child: Text(messageBoxInformation["messageEdit"] + messageBoxInformation["messageTime"],
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
        var forwardData = message["forward"].runtimeType == String
            ? json.decode(message["forward"])
            : message["forward"];
        forwardData ??= {};
        message["responseId"] ??= "0";
        var messageBoxInformation = {
          "messageBoxColor" : chatpartnerMessageBoxColor,
          "textAlign": Alignment.centerLeft,
          "messageTime": DateFormat('HH:mm').format(messageDateTime),
          "messageEdit": message["editDate"] == null
              ? ""
              : AppLocalizations.of(context).bearbeitet + " "
        };

        if (message["message"] == "") continue;

        message["message"] = removeAllNewLineAtTheEnd(message["message"]);

        if (message["von"] == userId) {
          messageBoxInformation["textAlign"] = Alignment.centerRight;
          messageBoxInformation["messageBoxColor"] = ownMessageBoxColor;
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

        if (message["message"].contains("</eventId=")) {
          messageBox.add(eventMessage(i, message, messageBoxInformation));
        } else if (message["message"].contains("</communityId=")) {
          messageBox.add(communityMessage(i, message, messageBoxInformation));
        } else if (int.parse(message["responseId"]) != 0) {
          messageBox.add(responseMessage(i, message, messageBoxInformation));
        } else if (forwardData.isNotEmpty) {
          messageBox.add(forwardMessage(i, message, forwardData, messageBoxInformation));
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
                changeMessageInputModus != "edit"
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          //checkChatgroupUsers();
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

          ChatDatabase().updateChatGroup(
              "users = JSON_SET(users, '\$.$userId.pinned', ${!chatIsPinned})",
              "WHERE id = '${widget.chatId}'");
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

          ChatDatabase().updateChatGroup(
              "users = JSON_SET(users, '\$.$userId.mute', ${!chatIsMute})",
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
                      pinChatDialog(),
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
          leading: widget.backToChatPage
              ? IconButton(
                  icon: Icon(Icons.arrow_back_sharp),
                  onPressed: () => global_functions.changePageForever(
                      context,
                      StartPage(
                        selectedIndex: 4,
                      )))
              : null,
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
