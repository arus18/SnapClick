import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:storage/horizontal_list_view.dart';

class ViewAll extends StatelessWidget {
  final String postID;
  final FirebaseUser user;
  final String userIDwhoCreatedThisGrid;
  final String displayName;
  final String profilePhotoUrl;
  final bool isGoogleUserSignedIn;
  ViewAll(this.postID, this.user, this.userIDwhoCreatedThisGrid,
      this.displayName, this.profilePhotoUrl, this.isGoogleUserSignedIn);
  final CollectionReference imitations =
      Firestore.instance.collection('imitations');
  @override
  Widget build(BuildContext context) {
    final allImitations = imitations.document(postID).collection('imitations');
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepOrangeAccent,
          title: Text('All imitations'),
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: allImitations.snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Text('Loading'),
                );
              } else {
                final List<Grid> gridList = new List<Grid>();

                if (snapshot.hasData) {
                  snapshot.data.documents.forEach((imitation) {
                    List<String> imgUrlList = List<String>();
                    final length = imitation.data.length;
                    if (length == 8) {
                      imgUrlList.add(imitation['imitationImg1']);
                      imgUrlList.add(imitation['imitationImg2']);
                      imgUrlList.add(imitation['imitationImg3']);
                      imgUrlList.add(imitation['imitationImg4']);
                    } else if (length == 10) {
                      imgUrlList.add(imitation['imitationImg1']);
                      imgUrlList.add(imitation['imitationImg2']);
                      imgUrlList.add(imitation['imitationImg3']);
                      imgUrlList.add(imitation['imitationImg4']);
                      imgUrlList.add(imitation['imitationImg5']);
                      imgUrlList.add(imitation['imitationImg6']);
                    } else if(length == 12) {
                      imgUrlList.add(imitation['imitationImg1']);
                      imgUrlList.add(imitation['imitationImg2']);
                      imgUrlList.add(imitation['imitationImg3']);
                      imgUrlList.add(imitation['imitationImg4']);
                      imgUrlList.add(imitation['imitationImg5']);
                      imgUrlList.add(imitation['imitationImg6']);
                      imgUrlList.add(imitation['imitationImg7']);
                      imgUrlList.add(imitation['imitationImg8']);
                    }
                    gridList.add(Grid(
                        postID,
                        imgUrlList,
                        user,
                        imitation['userIDwhoCreatedThisGrid'],
                        imitation['displayName'],
                        imitation['profilePhotoUrl'],
                        isGoogleUserSignedIn));
                  });
                }
                return ListView.builder(
                  itemCount: gridList.length,
                  itemBuilder: (context, index) => gridList[index],
                );
              }
            }));
  }
}
