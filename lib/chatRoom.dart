import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class Chatroom extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ChatroomState();
  }
}

class ChatroomState extends State<Chatroom> {
  final Firestore _db = Firestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging();
  final CollectionReference msgs = Firestore.instance.collection('conversations/conversationID1/msgs');
  final msgController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fcm.subscribeToTopic('conversations/conversationID1/msgs'); 
    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
                content: ListTile(
                  title: Text(message['notification']['title']),
                  subtitle: Text(message['notification']['body']),
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Ok'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        // TODO optional
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        // TODO optional
      },
    );
  }

  @override
  void dispose() {
    msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool focus = false;
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        centerTitle: true,
        title: Text('ChatRoom'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream: msgs.orderBy('timestamp', descending: true).snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error),
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: Text('Loading'),
                  );
                } else {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data.documents.length,
                      itemBuilder: (context, index) {
                        final msgSnapShot = snapshot.data.documents[index];
                        return composeMessage(msgSnapShot['message']);
                      },
                    );
                  }
                }
              },
            ),
          ),
          Container(
            margin: EdgeInsets.all(15),
            child: TextField(
              autofocus: focus,
              controller: msgController,
              decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    onPressed: () {
                      sendMessage(msgController.text);
                    },
                    icon: Icon(Icons.send),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(
                    const Radius.circular(25.0),
                  ))),
            ),
          )
        ],
      ),
    );
  }

  sendMessage(String msg) {
    msgs
        .document()
        .setData({'message': msg, 'timestamp': FieldValue.serverTimestamp()});
  }

  composeMessage(String msg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Container(
            padding: EdgeInsets.all(10),
            child: Text(
              msg,
              style: TextStyle(fontSize: 25),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
            ))
      ],
    );
  }
}
