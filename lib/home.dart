import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:storage/horizontal_list_view.dart';
import 'package:storage/new_post.dart';
import 'package:storage/profile_view.dart';

class Home extends StatelessWidget {
  final bool isGoogleUserSignedIn;
  final FirebaseUser _user;
  static final GlobalKey<BottomBarState> bottombar =
      GlobalKey<BottomBarState>();
  Home(this._user, this.isGoogleUserSignedIn);
  final CollectionReference posts = Firestore.instance.collection('posts');
  final CollectionReference imitations =
      Firestore.instance.collection('imitations');
  @override
  Widget build(BuildContext context) {
 return Scaffold(
      bottomNavigationBar: BottomBar(_user, isGoogleUserSignedIn, bottombar),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.deepOrangeAccent,
        title: Text(
          'SnapClick',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Fascinate',
            fontSize: 25,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: posts.orderBy('timestamp', descending: true).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Text('Loading'),
            );
          } else {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  final withAds = ((index+1)%4 == 0) ? true:false;
                  final post = snapshot.data.documents[index];
                  final imitationsForThisPost = imitations
                      .document(post.documentID)
                      .collection('imitations');
                  List<String> imgUrlList = List<String>();
                  final length = post.data.length;
                  if(length == 9){
                    imgUrlList.add(post['originalImg1']);
                    imgUrlList.add(post['originalImg2']);
                    imgUrlList.add(post['originalImg3']);
                    imgUrlList.add(post['originalImg4']);
                  }else if(length == 11){
                    imgUrlList.add(post['originalImg1']);
                    imgUrlList.add(post['originalImg2']);
                    imgUrlList.add(post['originalImg3']);
                    imgUrlList.add(post['originalImg4']);
                    imgUrlList.add(post['originalImg5']);
                    imgUrlList.add(post['originalImg6']);           
                  }else if(length == 13){
                    imgUrlList.add(post['originalImg1']);
                    imgUrlList.add(post['originalImg2']);
                    imgUrlList.add(post['originalImg3']);
                    imgUrlList.add(post['originalImg4']);
                    imgUrlList.add(post['originalImg5']);
                    imgUrlList.add(post['originalImg6']);
                    imgUrlList.add(post['originalImg7']);
                    imgUrlList.add(post['originalImg8']);
                  }
                  return HorizontalListView(
                    imitationsForThisPost,
                    post.documentID,
                    imgUrlList,
                    post['numberOfImitations'],
                    _user,
                    post['userIDwhoCreatedThisGrid'],
                    post['displayName'],
                    post['profilePhotoUrl'],
                    isGoogleUserSignedIn,
                    withAds:withAds,
                    
                  );
                },
              );
            }else{
              return Container();
            }
          }
        },
      ),
    );
  }
}

class BottomBar extends StatefulWidget {
  final FirebaseUser _user;
  final bool isGoogleUserSignedIn;

  BottomBar(this._user, this.isGoogleUserSignedIn, Key key) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return BottomBarState(
      _user,
      isGoogleUserSignedIn,
    );
  }
}

class BottomBarState extends State<BottomBar> {
  bool uploadStarted = false;
  
  Map<String, double> uploadList = {'': 0.10};
  final FirebaseUser _user;
  final bool isGoogleUserSignedIn;
  BottomBarState(
    this._user,
    this.isGoogleUserSignedIn,
  );
  updateProgress(double progress, String uploadID) {
    setState(() {
      if (uploadList.containsKey(uploadID)) {
        uploadList.update(uploadID, (_) => uploadList[uploadID] + progress);
      } else {
        uploadList[uploadID] = progress;
      }
    });
  }

  uploadFinished(String uploadID) {
    setState(() {
      uploadList.remove(uploadID);
      if(uploadList.length == 1){
        uploadStarted = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return uploadStarted
        ? BottomNavigationBar(
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black,
            onTap: (item) {
              if (item == 0) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SelectNoOfPics(_user)));
              } else if(item == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  if (isGoogleUserSignedIn) {
                    return ProfileView(
                      true,
                      _user,
                      _user.uid,
                      _user.displayName,
                    );
                  } else {
                    return ProfileView(
                        false, _user, _user.uid, _user.displayName);
                  }
                }));
              }
            },
            items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle),
                  title: Text('New post'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  title: Text('Profile'),
                ),
                BottomNavigationBarItem(
                    title: Text('uploading...'),
                    icon: Stack(
                        children: uploadList.values.map((progress) {
                      return CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.deepOrangeAccent),
                        value: progress,
                      );
                    }).toList()))
              ])
        : BottomNavigationBar(
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black,
            onTap: (item) {
              if (item == 0) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SelectNoOfPics(_user)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  if (isGoogleUserSignedIn) {
                    return ProfileView(
                      true,
                      _user,
                      _user.uid,
                      _user.displayName,
                    );
                  } else {
                    return ProfileView(
                        false, _user, _user.uid, _user.displayName);
                  }
                }));
              }
            },
            items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle),
                  title: Text('New post'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  title: Text('Profile'),
                )
              ]);
  }
}
