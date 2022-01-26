import 'package:cloud_firestore/cloud_firestore.dart';
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
  var userName = FirebaseAuth.instance.currentUser!.displayName;
  var globalChatGroups = [];

  selectChatpartnerWindow() async {
    var personenSucheController = TextEditingController();
    var userProfil = await dbGetProfil(userName);
    var userFriendlist = userProfil["friendlist"] ?? [];


    return showDialog(
        context: context,
        builder: (BuildContext dialogContext){
          return AlertDialog(
            content: Scaffold(
              body: Container(
                height: 400,
                child: Column(
                  children: [
                    Row(
                        children: [
                          Container(
                            width: 168,
                            height: 40,
                            child: TextFormField(
                              controller: personenSucheController,
                                decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black),
                                    ),
                                    border: OutlineInputBorder(),
                                    hintText: "Person suchen",
                                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey)
                                )

                            ),
                          ),
                          TextButton(
                            child: Icon(Icons.search),
                            onPressed: () async {
                              var chatPartner = personenSucheController.text;
                              if(chatPartner != ""){
                                var userName = await findUserGetName(personenSucheController.text);

                                if(userName != null){
                                  validCheckAndOpenChatgroup(userName);
                                } else {
                                  personenSucheController.clear();
                                  customSnackbar(dialogContext, "Benutzer existiert nicht");
                                }
                              }
                            },
                          )
                        ]),
                    SizedBox(height: 20),
                    Align(alignment: Alignment.centerLeft, child: Text("Friendlist: ")),
                    SizedBox(height: 10),
                    createFriendlistBox(userFriendlist)
                  ]
                )
              ),
            ),
          );
   });
  }

  Widget createFriendlistBox(userFriendlist) {
    List<Widget> friendsBoxen = [];

    for(var friend in userFriendlist){
      friendsBoxen.add(
        GestureDetector(
          onTap: () => validCheckAndOpenChatgroup(friend),
          child: Container(
            margin: EdgeInsets.all(5),
            padding: EdgeInsets.all(15),
            width: 200,
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(15)
            ),
            child: Text(friend)
          ),
        )
      );
    }

    return Container(
      width: double.maxFinite,
      height: 250,
      padding: EdgeInsets.all(10),
      child: ListView(
          children: friendsBoxen
      ),
    );

  }

  findUserGetName(user) async {
    var foundOnName = await dbGetProfil(user) ;
    var foundOnEmail = await dbGetProfilFromEmail(user);


    if(foundOnName != null){
      return foundOnName["name"];
    } else if(foundOnEmail != null){
      return foundOnEmail["name"];
    } else {
      return null;
    }

  }

  validCheckAndOpenChatgroup(chatPartner) async {
    var checkAndIndex = checkNewChatGroup(chatPartner);

    Navigator.pop(context);

    if(checkAndIndex[0]){
      changePage(context, ChatDetailsPage(groupChatData: chatPartner, newChat: true));
    } else{
      changePage(context, ChatDetailsPage(groupChatData: globalChatGroups[checkAndIndex[1]]));
    }

  }

  checkNewChatGroup(chatPartner){
    var check = [true, -1];

    for(var i = 0;i < globalChatGroups.length; i++){

      if(globalChatGroups[i]["users"].contains(chatPartner)){
        check = [false,i];
      }
    }

    return check;
  }


  Widget build(BuildContext context){

    chatUserList(groupdata){
      List<Widget> groupContainer = [];

      for(var group in groupdata){
        var chatpartner = group["users"][0] == "dominik.mast.11@gmail.com" ?
                          group["users"][1] : group["users"][0];
        var lastMessage = group["lastMessage"];

        groupContainer.add(
          GestureDetector(
            onTap: () =>changePage(context, ChatDetailsPage(groupChatData: group)),
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
      ),
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("chats")
                .where("users", arrayContains: userName)
                .snapshots(),
              builder: (
                  BuildContext context,
                  AsyncSnapshot snapshot,
              ){
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasData) {
                  globalChatGroups = snapshot.data.docs;
                  return chatUserList(snapshot.data.docs);
                }
                return Text("error");
              })
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.create),
        onPressed: () => selectChatpartnerWindow(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}