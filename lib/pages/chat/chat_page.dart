import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/database.dart';
import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart';
import 'chat_details.dart';

class ChatPage extends StatefulWidget{
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>{
  var userEmail = FirebaseAuth.instance.currentUser!.email;


  getMessagesToChatgroup(chatgroups) async {
    var newChatgroups = [];
    for(var group in chatgroups){
      group["messages"] = await dbGetMessagesFromChatgroup(group);
      newChatgroups.add(group);
    }
    return newChatgroups;
  }

  getAllDbData() async {
    var chatGroups = await dbGetAllUsersChats(userEmail);
    chatGroups = await getMessagesToChatgroup(chatGroups);

    return chatGroups;
  }


  openThisChat(groupChatData){
    changePage(context, ChatDetailsPage(groupChatData: groupChatData));
  }




  Widget build(BuildContext context){

    chatUserList(groupdata){
      List<Widget> groupContainer = [];

      for(var group in groupdata){
        var chatpartner = group["users"][0] == "dominik.mast.11@gmail.com" ?
                          group["users"][1] : group["users"][0];
        var lastMessage = group["messages"].last["message"];

        groupContainer.add(
          GestureDetector(
            onTap: () => openThisChat(group)
            ,
            child: Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(),
                    )
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chatpartner,style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text(lastMessage)
                ],
              )
            ),
          )
        );
      }

      return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView(
          shrinkWrap: true,
          children: groupContainer,
        ),
      );
    }



    return Scaffold(
      appBar: customAppBar(
        title: "Chat",
        button: TextButton(
          child: Icon(Icons.search),
          onPressed: null,
        )

      ),
      body: Column(
        children: [
          FutureBuilder(
            future: getAllDbData(),
              builder: (
                  BuildContext context,
                  AsyncSnapshot snapshot,
              ){
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.connectionState == ConnectionState.done) {
                  return chatUserList(snapshot.data);
                }
                return Container();
              })
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.create),
        onPressed: null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}