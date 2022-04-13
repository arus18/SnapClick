import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:storage/profile_view.dart';


class PostsUserImitated extends StatelessWidget { 
  final bool isGoogleUserSignedIn;
  final FirebaseUser user;
  final String userIDforProfileView;
  final String displayName;
  PostsUserImitated(this.userIDforProfileView, this.user,
      this.isGoogleUserSignedIn, this.displayName);
  final CollectionReference users = Firestore.instance.collection('users');
  @override
  Widget build(BuildContext context) {
    final CollectionReference postsUserImitated =
        users.document(userIDforProfileView).collection('favorites');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: Text(
          'Favorites',
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: postsUserImitated
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if(snapshot.hasError){
            return Center(child:Text('${snapshot.error}'));
          }else if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: Text('Loading'),);
          }
          else {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  final post = snapshot.data.documents[index];
                  return Card(
                    child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProfileView(
                                     
                                      isGoogleUserSignedIn,
                                      user,
                                      post['userIDwhoCreatedThisGrid'],
                                      post['displayName'])));
                        },
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children:<Widget>[Row(
                          children: <Widget>[
                            SizedBox(
                                height: 80,
                                child: ProfilePhoto(post['profilePhotoUrl'])),
                            SizedBox(
                              width: 20,
                            ),
                            Text(
                              post['displayName'],
                              style: TextStyle(fontSize: 20),
                            ),
                            
                          ],
                        ),(user.uid == userIDforProfileView)
                                ? IconButton(
                                    onPressed: () {
                                      users
                                          .document(user.uid)
                                          .collection('favorites')
                                          .document(post['userIDwhoCreatedThisGrid'])
                                          .delete();
                                    },
                                    color: Colors.red,
                                    icon: Icon(Icons.remove_circle_outline),
                                  )
                                : Container()])),
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

class ProfilePhoto extends StatefulWidget {
  final String profilePhotoUrl;
  ProfilePhoto(this.profilePhotoUrl);
  @override
  State<StatefulWidget> createState() {
    return ProfilePhotoState(profilePhotoUrl);
  }
}

class ProfilePhotoState extends State<ProfilePhoto> {
  final String profilePhotoUrl;
  ProfilePhotoState(this.profilePhotoUrl);
  Image profilePhoto;
  bool isDownloadComplete = false;
  bool networkErr = false;
  @override
  void initState() {
    super.initState();
    download();
  }

  Future<void> download() async {
    try {
      profilePhoto = Image.file(
          await DefaultCacheManager().getSingleFile(profilePhotoUrl));
          setState(() {
        isDownloadComplete = true;
      });
    } catch (err) {
      networkErr = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return (isDownloadComplete && !networkErr) ? profilePhoto : Text('img');
  }
}
