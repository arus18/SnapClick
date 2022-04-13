
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:storage/chatRoom.dart';
import 'package:storage/home.dart';
import 'package:storage/signin.dart';



void main() {
 /* ErrorWidget.builder = (FlutterErrorDetails details) => Material(
          child: Center(
        child: Text(
          'an error occured close the app and restart',
          style: TextStyle(fontSize: 20),
        ),
      ));
  runApp(MaterialApp(
    home: StartUpScreen(),
  ));*/
  runApp(MaterialApp(home: Chatroom(),));
  
}
