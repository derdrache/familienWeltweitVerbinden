import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../services/database.dart';
import '../../widgets/Window_topbar.dart';
import '../../widgets/search_autocomplete.dart';
import '../../global/variablen.dart' as global_var;
import 'chat_details.dart';

class ChatPage extends StatefulWidget{
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>{
  var userId = FirebaseAuth.instance.currentUser.uid;
  var userName = FirebaseAuth.instance.currentUser.displayName;
  var userEmail = FirebaseAuth.instance.currentUser.email;
  var globalChatGroups = [];
  var testWindow;
  var searchAutocomplete;
  var allName = [];
  var userFriendlist = [];
  var dbData = [];

  @override
  void initState() {

    super.initState();
  }


  initializer() async{
    await initilizeCreateChatData();

    return ChatDatabase().getChatData(
        "*", "WHERE id like '%$userId%' ORDER BY lastMessageDate ASC",
        returnList: true);
  }

  initilizeCreateChatData() async {
    dynamic userFriendIdList = await ProfilDatabase().getData("friendlist", "WHERE id = '$userId'");
    dbData = await ProfilDatabase().getData("name, id", "");

    for(var data in dbData){
      allName.add(data["name"]);

      for(var user in userFriendIdList){
        if(data["id"] == user){
          userFriendlist.add(data["name"]);
          break;
        }
      }
    }

  }

  selectChatpartnerWindow() async {
    if(dbData.isEmpty == null) await initilizeCreateChatData();
    userFriendlist??= [];

    return showDialog(
        context: context,
        builder: (BuildContext buildContext){
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: Scaffold(
              body: Container(
                    height: double.maxFinite,
                    width: double.maxFinite,
                    child: Stack(
                      overflow: Overflow.visible,
                      children: [
                        ListView(
                          children: [
                            WindowTopbar(title: AppLocalizations.of(context).neuenChatEroeffnen),
                            const SizedBox(height: 10),
                            personenSuchBox(buildContext, allName),
                            const SizedBox(height: 10),
                            ...createFriendlistBox(userFriendlist)
                          ]
                        ),
                        Positioned(
                          height: 30,
                          right: -13,
                          top: -7,
                          child: InkResponse(
                              onTap: () => Navigator.pop(context),
                              child: const CircleAvatar(
                                child: Icon(Icons.close, size: 16,),
                                backgroundColor: Colors.red,
                              )
                          ),
                        ),
                      ] ,
                    ),
                  ),
            ),

          );
        }
    );
  }

  searchUser() async {
    var chatPartner = searchAutocomplete.getSelected()[0];
    var chatPartnerId = await ProfilDatabase().getData("id", "WHERE name = '$chatPartner'");

    validCheckAndOpenChatgroup(chatPartnerID: chatPartnerId, name: chatPartner);
  }

  Widget personenSuchBox(buildContext, allName){
    searchAutocomplete = SearchAutocomplete(
      searchableItems: allName,
      withFilter: false,
      onConfirm: (){
        searchUser();
      },
    );

    return Center(
            child: SizedBox(
              width: 300,
              child: searchAutocomplete
            )
          );
  }

  List<Widget> createFriendlistBox(userFriendlist){
    List<Widget> friendsBoxen = [];

    for(var friend in userFriendlist){

      friendsBoxen.add(
          GestureDetector(
            onTap: () => validCheckAndOpenChatgroup(name: friend),
            child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(width: 1, color: global_var.borderColorGrey))
                ),
                child: Text(friend)
            ),
          )
      );
    }

    return friendsBoxen;
  }


  findUserGetId(user) async {
    var foundOnName = await ProfilDatabase().getData("id", "WHERE name = '$user'");
    var foundOnEmail = await ProfilDatabase().getData("id", "WHERE email = '$user'");

    if(foundOnName != null) return foundOnName;
    if(foundOnEmail != null) return foundOnEmail;

    return null;
  }

  validCheckAndOpenChatgroup({chatPartnerID, name}) async {

    if(chatPartnerID == null){
      chatPartnerID = await ProfilDatabase().getData("id", "WHERE name = '$name'");
    }
    var checkAndIndex = checkNewChatGroup(chatPartnerID);

    Navigator.pop(context);

    if(checkAndIndex[0]){
      Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailsPage(
            chatPartnerId: chatPartnerID,
            chatPartnerName: name,
          ))
      ).whenComplete(() => setState(() {}));


    } else{
      Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailsPage(
            groupChatData: globalChatGroups[checkAndIndex[1]],
          ))
      ).whenComplete(() => setState(() {}));

    }

  }

  checkNewChatGroup(chatPartnerId){
    var check = [true, -1];

    for(var i = 0;i < globalChatGroups.length; i++){
      var users = globalChatGroups[i]["users"];
      if(users[chatPartnerId] != null){
        check = [false,i];
      }
    }

    return check;
  }

  checkNewMessageCounter() async{
    var dbNewMessages = await ProfilDatabase().getData("newMessages", "WHERE id = '$userId'");
    num realNewMessages = 0;

    for(var group in globalChatGroups){
      var users = group["users"];
      realNewMessages += users[userId]["newMessages"];
    }

    if(dbNewMessages != realNewMessages){
      ProfilDatabase().updateProfil(userId, "newMessages", realNewMessages);
    }

  }

  cutMessage(message){
    if(message.length > 80) message = message.substring(0,80) +"...";
    var messageList = message.split("\n") ?? [];

    if(messageList.length > 2) message = [messageList[0] ?? " " + messageList[1] ?? " "].join("\n") + " ...";

    return message;
  }


  @override
  Widget build(BuildContext context){

    chatUserList(groupdata) {
      List<Widget> groupContainer = [];

      for(dynamic group in groupdata){
        var chatPartnerName = "";
        var chatPartnerId;
        var users = group["users"];

        users.forEach((key, value) async {
          if(key != userId){
            chatPartnerId = key;
          }
        });


        for(var data in dbData){
          if(data["id"] == chatPartnerId){
            chatPartnerName = data["name"];
            break;
          }
        }

        var lastMessage = cutMessage(group["lastMessage"]);
        var ownChatNewMessages = users[userId]["newMessages"];
        var lastMessageTime = DateTime.fromMillisecondsSinceEpoch(group["lastMessageDate"]);

        groupContainer.add(
          GestureDetector(
            onTap: () =>Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatDetailsPage(
                  groupChatData: group,
                ))
            ).whenComplete(() => setState(() {})),
            child: Container(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
                width: double.infinity,
                decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1, color: global_var.borderColorGrey),
                    )
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(chatPartnerName,style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Expanded(child: SizedBox.shrink()),
                      Text(DateFormat('dd-MM hh:mm').format(lastMessageTime), style: TextStyle(color: Colors.grey[600]))
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Text(lastMessage,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600])
                        )
                      ),
                      ownChatNewMessages== 0? const SizedBox.shrink(): Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                              color:Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle
                          ),
                          child: Center(
                            child: FittedBox(
                              child: Text(
                                ownChatNewMessages.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold,
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
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          }),
          child: ListView(
              shrinkWrap: true,
              children: groupContainer,
            ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: kIsWeb? 0: 24),
        child:
            FutureBuilder(
              future: initializer(),
                builder: (
                    BuildContext context,
                    AsyncSnapshot snapshot,
                ){
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: const CircularProgressIndicator()
                    );
                  } else if (snapshot.data != null) {
                    var chatGroups = snapshot.data;

                    checkNewMessageCounter();

                    globalChatGroups = chatGroups;
                    return chatUserList(chatGroups);
                  }
                  return const CircularProgressIndicator();
                }
            )
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "newChat",
        child: const Icon(Icons.create),
        onPressed: () => selectChatpartnerWindow(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}