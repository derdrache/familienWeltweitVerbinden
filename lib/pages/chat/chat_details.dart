import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:familien_suche/services/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../global/custom_widgets.dart';

class ChatDetailsPage extends StatefulWidget {
  var groupChatData;
  bool newChat;
  var chatPartner;

  ChatDetailsPage({Key? key,required this.groupChatData,
    required this.chatPartner, this.newChat = false}) : super(key: key);

  @override
  _ChatDetailsPageState createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  var chatID;
  var chatPartnerID;
  var chatPartnerName;
  List<Widget> messagesList = [];
  var nachrichtController = TextEditingController();
  var userName = FirebaseAuth.instance.currentUser!.displayName;

  @override
  void initState() {
    chatID = widget.groupChatData["id"]?? "0";
    chatPartnerID = widget.chatPartner.keys.toList()[0];
    chatPartnerName = widget.chatPartner[chatPartnerID];
    super.initState();
  }

  messageToDbAndClearMessageInput(message)async {
    var userID = FirebaseAuth.instance.currentUser!.uid;

    nachrichtController.clear();

    var messageData = {
      "message" :message,
      "from": userID,
      "date": Timestamp.now().seconds
    };
    if(widget.newChat){
      widget.groupChatData = await ChatDatabaseKontroller()
          .addNewChatGroup({userID: userName, chatPartnerID: chatPartnerName});

      setState(() {
        chatID = widget.groupChatData["id"];
      });
    }

    await ChatDatabaseKontroller().addNewMessage(
        widget.groupChatData,
        messageData,
        newChat: widget.newChat
    );

    await ChatDatabaseKontroller().updateChatGroup(
        widget.groupChatData["id"],
        {
         "lastMessage": messageData["message"],
         "lastMessageDate": messageData["date"],
        }
    );

  }


  @override
  Widget build(BuildContext context) {

    messageList(messages){
      List<Widget> messageBox = [];

      for(var message in messages){
        if(message["message"] == ""){continue;}

        var textAlign = Alignment.centerLeft;
        var boxColor = Colors.grey;

        if(widget.groupChatData["users"][message["from"]] == userName){
          textAlign = Alignment.centerRight;
          boxColor = Colors.blue;
        }


        messageBox.add(
          Align(
            alignment: textAlign, //right and left
            child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: boxColor,
                  border: Border.all(),
                  borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                child: Text(message["message"] == null ? "": message["message"])
              ),
            ),
        );
      }

      return ListView(
          shrinkWrap: true,
          children: messageBox,
      );
    }

    showMessages(){

      return StreamBuilder(
          stream: ChatDatabaseKontroller().getAllMessagesStream(chatID),
          builder: (
              BuildContext context,
              AsyncSnapshot snap,
              ){
            if (snap.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snap.data.snapshot.value != null) {
              List<Map> messages = [];

              var messagesMap = snap.data.snapshot.value;

              messagesMap.forEach((key, value) {
                messages.add(value);
              });

              messages.sort((a, b) => (a["date"]).compareTo(b["date"]));

              return messageList(messages);
            }
            return Container();
          });
    }

    textEingabe(){
      return Container(
        padding: EdgeInsets.all(15),
        height: 50,
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey))),
        child: TextField(
          onSubmitted: (eingabe) async { messageToDbAndClearMessageInput(eingabe); },
          controller: nachrichtController,
          decoration: InputDecoration.collapsed(
            hintText: "Nachricht"
          ),
        ),

      );
    }



    return Scaffold(
      appBar: customAppBar(
        title: chatPartnerName,
        button: TextButton(
            onPressed: null,
            child: Icon(Icons.more_vert))
      ),
      body: Column(
        children: [
          Expanded(child: Container()),
          showMessages(),
          textEingabe()
        ],
      )
    );
  }
}
