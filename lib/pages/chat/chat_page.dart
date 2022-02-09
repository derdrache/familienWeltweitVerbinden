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
  var userId = FirebaseAuth.instance.currentUser!.uid;
  var userName = FirebaseAuth.instance.currentUser!.displayName;
  var userEmail = FirebaseAuth.instance.currentUser!.email;
  var globalChatGroups = [];


  selectChatpartnerWindow() async {
    var personenSucheController = TextEditingController();
    var userProfil = await ProfilDatabaseKontroller().getProfil(userId);
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
                              if(chatPartner != "" && chatPartner != userName && chatPartner != userEmail){
                                var userID = await findUserGetName(personenSucheController.text);

                                if(userID != null){
                                  validCheckAndOpenChatgroup(userID);
                                } else {
                                  personenSucheController.clear();
                                  customSnackbar(dialogContext, "Benutzer existiert nicht");
                                }
                              } else{
                                personenSucheController.text = "";
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

    if(userFriendlist["empty"] == true) {
      userFriendlist= [];
    } else{
      userFriendlist = userFriendlist.keys;
    }



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
    var foundOnName = await ProfilDatabaseKontroller().getProfilId("name", user);
    var foundOnEmail = await ProfilDatabaseKontroller().getProfilId("email", user);

    if(foundOnName != null){
      return foundOnName;
    } else if(foundOnEmail != null){
      return foundOnEmail;
    } else {
      return null;
    }

  }

  validCheckAndOpenChatgroup(chatPartnerID) async {
    var checkAndIndex = checkNewChatGroup(chatPartnerID);
    var chatPartnerName = await ProfilDatabaseKontroller().getOneData(chatPartnerID, "name");

    var userData = {
      "users": {
        chatPartnerID: {"name": chatPartnerName, "newMessages": 0},
        userId: {"name": userName, "newMessages": 0},
      }
    };

    Navigator.pop(context);

    if(checkAndIndex[0]){
      changePage(context, ChatDetailsPage(
          groupChatData: userData,
          newChat: true
      ));
    } else{
      changePage(context, ChatDetailsPage(
        groupChatData: globalChatGroups[checkAndIndex[1]],
      ));
    }

  }

  checkNewChatGroup(chatPartner){
    var check = [true, -1];

    for(var i = 0;i < globalChatGroups.length; i++){
      if(globalChatGroups[i]["users"][userId] != null){
        check = [false,i];
      }
    }

    return check;
  }



  Widget build(BuildContext context){

    chatUserList(groupdata) {
      List<Widget> groupContainer = [];

      for(var group in groupdata){
        var chatPartnerName;
        var chatPartnerID;


        group["users"].forEach((key, value) async {
          if(key != userId){
            chatPartnerName = value["name"];
            chatPartnerID = key;
          }
        });

        var lastMessage = group["lastMessage"];
        var ownChatNewMessages = group["users"][userId]["newMessages"];
        var lastMessageTime = dbSecondsToTimeString(group["lastMessageDate"]);

        groupContainer.add(
          GestureDetector(
            onTap: () =>changePage(context, ChatDetailsPage(
              groupChatData: group,
            )),
            child: Container(
                padding: EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
                width: double.infinity,
                decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(),
                    )
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(chatPartnerName,style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Expanded(child: SizedBox()),
                      Text(lastMessageTime, style: TextStyle(color: Colors.grey[600]),)
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text(lastMessage, style: TextStyle(fontSize: 16, color: Colors.grey[600]),),
                      Expanded(child: SizedBox.shrink()),
                      ownChatNewMessages== 0? SizedBox.shrink(): Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle
                          ),
                          child: Center(
                            child: FittedBox(
                              child: Text(
                                ownChatNewMessages.toString(),
                                style: TextStyle(fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          )
                      )
                    ],
                  )

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
      body: Padding(
        padding: const EdgeInsets.only(top: 25),
        child: Column(
          children: [
            StreamBuilder(
              stream: ChatDatabaseKontroller()
                  .getAllChatgroupsFromUserStream(userId, userName),
                builder: (
                    BuildContext context,
                    AsyncSnapshot snapshot,
                ){
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.data.snapshot.value != null) {
                    var chatGroups = [];
                    var chatgroupsMap = Map<String, dynamic>.from(snapshot.data.snapshot.value);

                    chatgroupsMap.forEach((key, value) {
                      chatGroups.add(value);
                    });

                    globalChatGroups = chatGroups;
                    return chatUserList(chatGroups);
                  }
                  return Container();
                }
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.create),
        onPressed: () => selectChatpartnerWindow(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}