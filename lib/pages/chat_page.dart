import 'package:flutter/material.dart';

import '../services/database.dart';

class ChatPage extends StatefulWidget{
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>{
  

  @override
  void initState(){
    loadChatdataFromDb();
  }

  loadChatdataFromDb() async {
    await dbGetAllUsersChats("dominik.mast.11@gmail.com");
  }

  openThisChat(messages){
    print(messages);
  }


  Widget build(BuildContext context){


    topBar(){
      return Container(
        margin: EdgeInsets.only(top: 25),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 1,
                    color: Colors.grey
                )
            )
        ),
        child: Row(
          children: [
            Expanded(child: SizedBox()),
            Text("Chat", style: TextStyle(fontSize: 22),),
            Expanded(child: SizedBox()),
            TextButton(onPressed: null, child: Icon(Icons.search, size: 30,))
          ],
        ),
      );
    }

    chatUserList(groupdata){
      List<Widget> groupContainer = [];

      for(var group in groupdata){
        group["users"].remove("dominik.mast.11@gmail.com");

        groupContainer.add(
          GestureDetector(
            onTap: openThisChat(group["messages"]),
            child: Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(),
                    )
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group["users"][0],style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("letzte Nachricht")
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
      body: Column(
        children: [
          topBar(),
          FutureBuilder(
            future: dbGetAllUsersChats("dominik.mast.11@gmail.com"),
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