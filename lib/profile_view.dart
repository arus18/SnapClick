import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:storage/horizontal_list_view.dart';
import 'package:storage/favorites.dart';
import 'package:storage/signin.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileView extends StatelessWidget {
  final bool isGoogleUserSignedIn;
  final FirebaseUser user;
  final String displayName;
  final String userIDforProfileView;
  ProfileView(
    this.isGoogleUserSignedIn,
    this.user,
    this.userIDforProfileView,
    this.displayName,
  );
  final CollectionReference users = Firestore.instance.collection('users');
  @override
  Widget build(BuildContext context) {
    final CollectionReference posts =
        users.document(userIDforProfileView).collection('posts');
    return  Scaffold(
            bottomNavigationBar: (user.uid == userIDforProfileView)
                ? BottomNavigationBar(
                    selectedItemColor: Colors.black,
                    unselectedItemColor: Colors.black,
                    onTap: (item) {
                      if (item == 0) {
                        Navigator.pop(context);
                      } else if (item == 1) {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          if (isGoogleUserSignedIn) {
                            return PostsUserImitated(
                                userIDforProfileView, user, true, displayName);
                          } else {
                            return PostsUserImitated(
                                userIDforProfileView, user, false, displayName);
                          }
                        }));
                      } else {
                        final googleSignIn = GoogleSignIn();
                        final facebookLogin = FacebookLogin();

                        if (isGoogleUserSignedIn) {
                          googleSignIn.signOut().whenComplete(() {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => StartUpScreen()),
                                (Route<dynamic> route) => false);
                          });
                        } else {
                          facebookLogin.logOut().whenComplete(() {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => StartUpScreen()),
                                (Route<dynamic> route) => false);
                          });
                        }
                      }
                    },
                    items: [
                        BottomNavigationBarItem(
                            icon: Icon(Icons.home), title: Text('Home')),
                        BottomNavigationBarItem(
                          icon: Icon(FontAwesomeIcons.heart),
                          title: Text('Favourites'),
                        ),
                        BottomNavigationBarItem(
                            icon: Icon(Icons.exit_to_app),
                            title: Text('Sign out'))
                      ])
                : BottomNavigationBar(
                    selectedItemColor: Colors.black,
                    unselectedItemColor: Colors.black,
                    onTap: (item) {
                      if (item == 0) {
                        Navigator.pop(context);
                      } else {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          if (isGoogleUserSignedIn) {
                            return PostsUserImitated(
                                userIDforProfileView, user, true, displayName);
                          } else {
                            return PostsUserImitated(
                                userIDforProfileView, user, false, displayName);
                          }
                        }));
                      }
                    },
                    items: [
                        BottomNavigationBarItem(
                            icon: Icon(Icons.home), title: Text('Home')),
                        BottomNavigationBarItem(
                          icon: Icon(FontAwesomeIcons.heart),
                          title: Text('Favourites'),
                        ),
                      ]),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.deepOrangeAccent,
              centerTitle: true,
              title: Text(
                displayName,
                style: TextStyle(color: Colors.black, fontFamily: 'Fascinate'),
              ),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: posts.orderBy('timestamp', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: Text('Loading'),
                  );
                } else {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data.documents.length,
                      itemBuilder: (context, index) {
                        final post = snapshot.data.documents[index];
                        final imitationsForThisPost = posts
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
                          user,
                          post['userIDwhoCreatedThisGrid'],
                          post['displayName'],
                          post['profilePhotoUrl'],
                          isGoogleUserSignedIn,
                          forProfileView: true,
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
