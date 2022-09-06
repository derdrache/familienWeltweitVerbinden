import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:familien_suche/global/global_functions.dart'
    as global_functions;
import 'package:familien_suche/global/custom_widgets.dart';
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
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';

class ChatDetailsPage extends StatefulWidget {
  String chatPartnerId;
  String chatPartnerName;
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
  Widget MessagesPufferList = const Center(child: CircularProgressIndicator());
  var eventCardList = [];
  var chatPartnerProfil;
  bool bothDelete = false;
  var myFocusNode = FocusNode();
  var messageIdChange;
  String changeMessageModus;
  Widget extraInputInformationBox = const SizedBox.shrink();
  var _scrollController = ItemScrollController();
  var itemPositionListener = ItemPositionsListener.create();
  var scrollIndex = -1;
  var hasStartPosition = true;
  var startData;
  var counter = 0;
  bool emojisShowing = false;

  @override
  void dispose() {
    ProfilDatabase().updateProfil("activeChat = '" "'", "WHERE id = '$userId'");
    WidgetsBinding.instance.removeObserver(this);
    timer.cancel();
    myFocusNode.dispose();
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
      var scrollValue = itemPositionListener.itemPositions.value;

      if (startData != scrollValue.first.index + 1 &&
          hasStartPosition == true &&
          startData != null) {
        setState(() {
          hasStartPosition = false;
        });
      } else if (startData == scrollValue.first.index + 1 &&
          hasStartPosition == false) {
        setState(() {
          hasStartPosition = true;
        });
      }

      startData ??= scrollValue.first.index;
    });

    widget.chatId = widget.groupChatData["id"];
    _asyncMethod();

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  _asyncMethod() async {
    await createNewChat();
    await getAndSetChatData();
    writeActiveChat();
    await getChatPartnerProfil();

    if (widget.groupChatData != false) resetNewMessageCounter();

    setState(() {});

    timer = Timer.periodic(
        const Duration(seconds: 10), (Timer t) => checkNewMessages());
  }

  createNewChat() async {
    if (widget.groupChatData["id"] != null) return;

    var userID = FirebaseAuth.instance.currentUser.uid;
    widget.chatPartnerId ??= await ProfilDatabase()
        .getData("id", "WHERE name = '${widget.chatPartnerName}'");
    widget.chatPartnerName ??= await ProfilDatabase()
        .getData("name", "WHERE id = '${widget.chatPartnerId}'");

    var chatUsers = {
      userID: userName,
      widget.chatPartnerId: widget.chatPartnerName
    };

    widget.groupChatData = await ChatDatabase().addNewChatGroup(chatUsers);
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

  checkNewMessages() {
    setState(() {});
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
      "message": message,
      "von": userID,
      "date": DateTime.now().millisecondsSinceEpoch.toString(),
      "zu": widget.chatPartnerId
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

  getAllMessages() async {
    if (widget.chatId != null) {
      return await ChatDatabase().getAllMessages(widget.chatId);
    }

    return null;
  }

  replyMessage(message) {
    messageIdChange = message["tableId"];
    myFocusNode.requestFocus();
    changeMessageModus = "reply";
  }

  editMessage(message) {
    messageIdChange = message["tableId"];
    myFocusNode.requestFocus();
    nachrichtController.text = message["message"];
    changeMessageModus = "edit";
  }

  copyMessage(messageText) {
    Clipboard.setData(ClipboardData(text: messageText));
    customSnackbar(
        context, AppLocalizations.of(context).nachrichtZwischenAblage,
        color: Colors.green);
  }

  forwardMessage() {
    //Gruppen / Personen aussuchen, die diese Nachricht bekommen
    // möglichkeit noch einen Text mitzugeben
  }

  deleteMessage(messageId) {
    ChatDatabase().deleteMessages(messageId);
  }

  reportMessage(message) {
    ReportsDatabase().add(
        userId,
        "Message tableId: " + message["tableId"] + " gemeldet",
        message["message"]);

    customSnackbar(context, AppLocalizations.of(context).nachrichtGemeldet,
        color: Colors.green);
  }

  resetExtraInputInformation() {
    messageIdChange = null;
    extraInputInformationBox = const SizedBox.shrink();
    nachrichtController.clear();
    changeMessageModus = null;
    myFocusNode.unfocus();

    setState(() {});
  }

  saveEditMessage() {
    for (var message in messages) {
      if (message["tableId"] == messageIdChange) {
        message["message"] = nachrichtController.text;
      }
    }

    ChatDatabase().updateMessage(
        "message = '${nachrichtController.text}', editDate = '${DateTime.now().millisecondsSinceEpoch}'",
        "WHERE tableId = '$messageIdChange'");
  }

  @override
  Widget build(BuildContext context) {
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

    openMessageMenu(tapPosition, message) {
      final RenderBox overlay = Overlay.of(context).context.findRenderObject();
      var isMyMessage = message["von"] == userId;

      showMenu(
        context: context,
        position: RelativeRect.fromRect(
            tapPosition & const Size(40, 40), // smaller rect, the touch area
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
            onTap: () => forwardMessage(),
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
              onTap: () => deleteMessage(message["tableId"]),
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

    messageList(messages) {
      List<Widget> messageBox = [];

      for (var i = messages.length-1; i >= 0; i--) {
        var message = messages[i];
        var messageTime = DateFormat('dd-MM HH:mm').format(
            DateTime.fromMillisecondsSinceEpoch(int.parse(message["date"])));
        var messageEdit = message["editDate"] == null
            ? ""
            : AppLocalizations.of(context).bearbeitet;
        var textAlign = Alignment.centerLeft;
        var boxColor = Colors.white;
        message["responseId"] ??= "0";

        if (message["message"] == "") continue;

        message["message"] = removeAllNewLineAtTheEnd(message["message"]);

        if (message["von"] == userId) {
          textAlign = Alignment.centerRight;
          boxColor = Colors.greenAccent;
        }

        if (message["message"].contains("</eventId=")) {
          messageBox.add(AnimatedContainer(
            color: scrollIndex == i
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            duration: const Duration(seconds: 1),
            curve: Curves.easeIn,
            child: Align(
              alignment: textAlign,
              child: FutureBuilder(
                  future: EventDatabase().getData(
                      "*", "WHERE id = '${message["message"].substring(10)}'"),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != false) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 25),
                        child: Stack(clipBehavior: Clip.none, children: [
                          EventCard(
                            margin: const EdgeInsets.all(15),
                            withInteresse: true,
                            event: snapshot.data,
                            afterPageVisit: () => setState(() {}),
                          ),
                          Positioned(
                            bottom: -25,
                            right: 15,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                    onPressed: () {
                                      var replyUser = global_functions
                                          .getProfilFromHive(message["von"],
                                              onlyName: true);

                                      extraInputInformationBox =
                                          inputInformationBox(Icons.reply,
                                              replyUser, message["message"]);
                                      replyMessage(message);
                                    },
                                    child: Text(AppLocalizations.of(context)
                                        .antworten)),
                                Text(messageTime,
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          )
                        ]),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
            ),
          ));
          continue;
        }
        if (message["message"].contains("</communityId=")) {
          messageBox.add(AnimatedContainer(
            color: scrollIndex == i
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            duration: const Duration(seconds: 1),
            curve: Curves.easeIn,
            child: Align(
              alignment: textAlign,
              child: FutureBuilder(
                  future: CommunityDatabase().getData(
                      "*", "WHERE id = '${message["message"].substring(14)}'"),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != false) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 25),
                        child: Stack(clipBehavior: Clip.none, children: [
                          CommunityCard(
                            margin: const EdgeInsets.all(15),
                            withFavorite: true,
                            community: snapshot.data,
                            afterPageVisit: () => setState(() {}),
                          ),
                          Positioned(
                            bottom: -15,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                    onPressed: () {
                                      var replyUser = global_functions
                                          .getProfilFromHive(message["von"],
                                              onlyName: true);

                                      extraInputInformationBox =
                                          inputInformationBox(Icons.reply,
                                              replyUser, message["message"]);
                                      replyMessage(message);
                                    },
                                    child: Text(AppLocalizations.of(context)
                                        .antworten)),
                                Text(messageTime,
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          )
                        ]),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
            ),
          ));
          continue;
        }

        if (int.parse(message["responseId"]) == 0) {
          messageBox.add(AnimatedContainer(
            color: scrollIndex == i
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            duration: const Duration(seconds: 1),
            curve: Curves.easeIn,
            child: Align(
              alignment: textAlign,
              child: GestureDetector(
                onTapDown: (tapDetails) =>
                    openMessageMenu(tapDetails.globalPosition, message),
                child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85),
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: boxColor,
                        border: Border.all(),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10))),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      alignment: WrapAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                              top: 5, left: 10, bottom: 7, right: 10),
                          child: Text(message["message"] ?? "",
                              style: const TextStyle(fontSize: 16)),
                        ),
                        Container(
                          padding: const EdgeInsets.only(bottom: 5, right: 10),
                          child: Text(messageEdit + " " + messageTime,
                              style: TextStyle(color: Colors.grey[600])),
                        )
                      ],
                    )),
              ),
            ),
          ));
        } else {
          var replyFromId =
              message["id"].replaceAll(userId, "").replaceAll("_", "");
          var messageFromProfil =
              global_functions.getProfilFromHive(replyFromId);
          var replyMessage;
          var replyIndex = messages.length;

          for (var lookMessage in messages.reversed.toList()) {
            replyIndex -= 1;

            if (lookMessage["tableId"] == message["responseId"]) {
              replyMessage = lookMessage;
              break;
            }
          }

          messageBox.add(AnimatedContainer(
            color: scrollIndex == i
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            duration: const Duration(seconds: 1),
            curve: Curves.easeIn,
            child: Row(
              children: [
                const Expanded(flex: 2, child: SizedBox.shrink()),
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
                            _scrollController.scrollTo(
                                index: replyIndex,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic);
                            setState(() {
                              scrollIndex = replyIndex;
                            });

                            Future.delayed(const Duration(milliseconds: 1300),
                                () {
                              setState(() {
                                scrollIndex = -1;
                              });
                            });
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
                                      replyMessage["message"],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ],
                                )),
                          ),
                        ),
                        GestureDetector(
                          onTapDown: (tapDetails) => openMessageMenu(
                              tapDetails.globalPosition, message),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.end,
                            alignment: WrapAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.only(
                                    top: 5, left: 10, bottom: 7, right: 10),
                                child: Text(message["message"] ?? "",
                                    style: const TextStyle(fontSize: 16)),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.only(bottom: 5, right: 10),
                                child: Text(messageEdit + " " + messageTime,
                                    style: TextStyle(color: Colors.grey[600])),
                              )
                            ],
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          ));
        }
      }

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
          FutureBuilder(
              future: getAllMessages(),
              builder: (
                BuildContext context,
                AsyncSnapshot snap,
              ) {
                if (snap.hasData) {
                  messages = snap.data;

                  if (messages.length == 0) {
                    return Center(
                        child: Text(
                      AppLocalizations.of(context).nochKeineNachrichtVorhanden,
                      style: const TextStyle(fontSize: 20),
                    ));
                  }

                  messages.sort((a, b) => (a["date"]).compareTo(b["date"]));

                  MessagesPufferList = messageList(messages);
                  return MessagesPufferList;
                }

                return MessagesPufferList;
              }),
          if (!hasStartPosition)
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton(
                onPressed: () {
                  _scrollController.scrollTo(
                      index: messages.length,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic);
                  setState(() {

                  });
                },
                child: Icon(Icons.arrow_downward),
              ),
            )
        ],
      );
    }

    textEingabeFeld() {
      return Column(
        children: [
          Container(
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
                            offset: const Offset(
                                0, 3), // changes position of shadow
                          ),
                        ]
                      : []),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      emojisShowing = !emojisShowing;

                      if(emojisShowing == true){
                        myFocusNode.unfocus();
                      } else{
                        myFocusNode.requestFocus();
                      }

                      setState(() {});
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    icon: Icon(Icons.mood),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      maxLines: null,
                      focusNode: myFocusNode,
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
              )),
          if(emojisShowing) SizedBox(
            height: 250,
            child: EmojiPicker(
              textEditingController: nachrichtController,
              config: Config(
                columns: 7,
                emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                // Issue: https://github.com/flutter/flutter/issues/28894
                verticalSpacing: 0,
                horizontalSpacing: 0,
                gridPadding: EdgeInsets.zero,
                initCategory: Category.RECENT,
                bgColor: Color(0xFFF2F2F2),
                indicatorColor: Colors.blue,
                iconColor: Colors.grey,
                iconColorSelected: Colors.blue,
                progressIndicatorColor: Colors.blue,
                backspaceColor: Colors.blue,
                skinToneDialogBgColor: Colors.white,
                skinToneIndicatorColor: Colors.grey,
                enableSkinTones: true,
                showRecentsTab: true,
                recentsLimit: 28,
                noRecents: const Text(
                  'No Recents',
                  style: TextStyle(fontSize: 20, color: Colors.black26),
                  textAlign: TextAlign.center,
                ),
                tabIndicatorAnimDuration: kTabScrollDuration,
                categoryIcons: const CategoryIcons(),
                buttonMode: ButtonMode.MATERIAL,
              ),
            ),
          )
        ],
      );
    }

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
                    children: [deleteDialog()],
                  ),
                ),
              ],
            );
          });
    }

    return Scaffold(
      appBar: chatPartnerProfil != false
          ? CustomAppBar(
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
            )
          : CustomAppBar(
              title: AppLocalizations.of(context).geloeschterUser,
              buttons: [
                  IconButton(
                      onPressed: () => moreMenu(),
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                      ))
                ]),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(child: messageAnzeige()),
          extraInputInformationBox,
          textEingabeFeld(),
        ],
      ),
    );
  }
}
