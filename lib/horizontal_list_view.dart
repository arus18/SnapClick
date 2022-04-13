import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_admob/native_admob_controller.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:storage/imageView.dart';
import 'package:storage/imitate.dart';
import 'package:storage/profile_view.dart';
import 'package:storage/view_all.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_native_admob/flutter_native_admob.dart';

class HorizontalListView extends StatelessWidget {
  final CollectionReference imitations;
  final String postID;
  final List<String> imgUrlList;
  final numberOfImitations;
  final FirebaseUser _user;
  final String userIDwhoCreatedThisGrid;
  final String displayName;
  final String profilePhotoUrl;
  final bool isGoogleUserSignedIn;
  final bool forProfileView;
  final bool withAds;

  HorizontalListView(
      this.imitations,
      this.postID,
      this.imgUrlList,
      this.numberOfImitations,
      this._user,
      this.userIDwhoCreatedThisGrid,
      this.displayName,
      this.profilePhotoUrl,
      this.isGoogleUserSignedIn,
      {this.forProfileView: false,
      this.withAds: false});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: imitations.orderBy('timestamp').limit(5).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        final List<Widget> gridList = new List<Widget>();
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingGrid(imgUrlList.length);
        } else {
          if (forProfileView) {
            gridList.insert(
                0,
                Grid(
                  postID,
                  imgUrlList,
                  _user,
                  userIDwhoCreatedThisGrid,
                  displayName,
                  profilePhotoUrl,
                  isGoogleUserSignedIn,
                  numberOfImitations: numberOfImitations,
                  forProfileView: true,
                ));
          } else {
            gridList.insert(
                0,
                Grid(
                  postID,
                  imgUrlList,
                  _user,
                  userIDwhoCreatedThisGrid,
                  displayName,
                  profilePhotoUrl,
                  isGoogleUserSignedIn,
                  isOriginalImg: true,
                  numberOfImitations: numberOfImitations,
                  withAds: withAds,
                ));
          }
          if (snapshot.hasData) {
            final count = snapshot.data.documents.length;
            for (var i = 0; i < count; i++) {
              final imitation = snapshot.data.documents[i];
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
              } else if (length == 12) {
                imgUrlList.add(imitation['imitationImg1']);
                imgUrlList.add(imitation['imitationImg2']);
                imgUrlList.add(imitation['imitationImg3']);
                imgUrlList.add(imitation['imitationImg4']);
                imgUrlList.add(imitation['imitationImg5']);
                imgUrlList.add(imitation['imitationImg6']);
                imgUrlList.add(imitation['imitationImg7']);
                imgUrlList.add(imitation['imitationImg8']);
              }
              if (i == 4) {
                gridList.add(Grid(
                  postID,
                  imgUrlList,
                  _user,
                  imitation['userIDwhoCreatedThisGrid'],
                  imitation['displayName'],
                  imitation['profilePhotoUrl'],
                  isGoogleUserSignedIn,
                  withViewAll: true,
                  withAds: withAds,
                ));
              } else {
                gridList.add(Grid(
                  postID,
                  imgUrlList,
                  _user,
                  imitation['userIDwhoCreatedThisGrid'],
                  imitation['displayName'],
                  imitation['profilePhotoUrl'],
                  isGoogleUserSignedIn,
                  withAds: withAds,
                ));
              }
            }
          }
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: gridList,
          ),
        );
      },
    );
  }
}

class Grid extends StatefulWidget {
  final String postID;
  final List<String> imgUrlList;
  final numberOfImitations;
  final bool isOriginalImg;
  final FirebaseUser _user;
  final String userIDwhoCreatedThisGrid;
  final String displayName;
  final String profilePhotoUrl;
  final bool withViewAll;
  final bool isGoogleUserSignedIn;
  final bool forProfileView;
  final bool withAds;

  Grid(this.postID, this.imgUrlList, this._user, this.userIDwhoCreatedThisGrid,
      this.displayName, this.profilePhotoUrl, this.isGoogleUserSignedIn,
      {this.isOriginalImg: false,
      this.withViewAll: false,
      this.numberOfImitations,
      this.forProfileView: false,
      this.withAds: false});
  @override
  State<StatefulWidget> createState() {
    return GridState(postID, imgUrlList, _user, userIDwhoCreatedThisGrid,
        displayName, profilePhotoUrl, isGoogleUserSignedIn,
        isOriginalImg: isOriginalImg,
        withViewAll: withViewAll,
        numberOfImitations: numberOfImitations,
        forProfileView: forProfileView,
        withAds: withAds);
  }
}

class GridState extends State<Grid> {
  final List<String> imgUrlList;
  final String postID;
  final numberOfImitations;
  final bool isOriginalImg;
  final bool withViewAll;
  final FirebaseUser _user;
  final String userIDwhoCreatedThisGrid;
  final String displayName;
  final String profilePhotoUrl;
  final bool forProfileView;
  bool isDownloadComplete = false;
  bool networkError = false;
  final bool isGoogleUserSignedIn;
  List<Image> images = List<Image>();
  List<Image> imagesForImageView = List<Image>();
  Image profilePhoto;
  bool removeInOriginalClicked = false;
  final CollectionReference users = Firestore.instance.collection('users');
  final CollectionReference imitations =
      Firestore.instance.collection('imitations');
  final CollectionReference posts = Firestore.instance.collection('posts');
  final bool withAds;
  static const _adUnitID = "ca-app-pub-7282852941650188/1241234524";
  final _nativeAdController = NativeAdmobController();
  double _height = 0;
  StreamSubscription _subscription;

  @override
  initState() {
    super.initState();
    _subscription = _nativeAdController.stateChanged.listen(_onStateChanged);
    downloadImages();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _nativeAdController.dispose();
    super.dispose();
  }

  void _onStateChanged(AdLoadState state) {
    switch (state) {
      case AdLoadState.loading:
        setState(() {
          _height = 0;
        });
        break;

      case AdLoadState.loadCompleted:
        setState(() {
          _height = 130;
        });
        break;

      default:
        break;
    }
  }

  downloadImages() async {
    try {
      profilePhoto = Image.file(await DefaultCacheManager()
          .getSingleFile(profilePhotoUrl + "?height=500"));
      await Future.forEach(imgUrlList, (url) async {
        final img = await imageWithFit(
            (await DefaultCacheManager().getSingleFile(url)));
        images.add(img);
      });

      if (mounted) {
        setState(() {
          isDownloadComplete = true;
        });
      }
    } catch (err) {
      networkError = true;
    }
  }

  Future<Image> imageWithFit(File imgFile) async {
    imagesForImageView.add(Image.file(imgFile));
    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(imgFile.path);
    if (properties.width > properties.height) {
      return Image.file(
        imgFile,
        fit: BoxFit.fitHeight,
      );
    }
    return Image.file(
      imgFile,
      fit: BoxFit.fitWidth,
    );
  }

  GridState(
      this.postID,
      this.imgUrlList,
      this._user,
      this.userIDwhoCreatedThisGrid,
      this.displayName,
      this.profilePhotoUrl,
      this.isGoogleUserSignedIn,
      {this.isOriginalImg: false,
      this.withViewAll: false,
      this.numberOfImitations,
      this.forProfileView: false,
      this.withAds: false});

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final width = query.orientation == Orientation.portrait
        ? query.size.width
        : query.size.height;
    return isDownloadComplete
        ? networkError
            ? LoadingGrid(
                imgUrlList.length,
                networkErr: true,
              )
            : SizedBox(
                width: width - 50,
                child: Column(
                  crossAxisAlignment: withViewAll
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: <Widget>[
                    Card(
                      child: GestureDetector(
                          onTap: () {
                            if (!forProfileView) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ProfileView(
                                          isGoogleUserSignedIn,
                                          _user,
                                          userIDwhoCreatedThisGrid,
                                          displayName)));
                            }
                          },
                          child: rowForCard()),
                    ),
                    GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ImageView(imagesForImageView)));
                        },
                        child: GridView.count(
                          padding: EdgeInsets.all(1),
                          mainAxisSpacing: 1,
                          crossAxisSpacing: 1,
                          shrinkWrap: true,
                          physics: ScrollPhysics(),
                          crossAxisCount: imgUrlList.length ~/ 2,
                          children: images,
                        )),
                    (isOriginalImg && (_user.uid != userIDwhoCreatedThisGrid) ||
                            forProfileView &&
                                (_user.uid != userIDwhoCreatedThisGrid))
                        ? SizedBox(
                            height: 30,
                            child: FloatingActionButton.extended(
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                heroTag: 'imitateBtnfor' + postID,
                                backgroundColor: Colors.deepOrangeAccent,
                                label: Center(
                                    child: Text('imitate',
                                        style: TextStyle(color: Colors.black))),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              CameraPreviewToImitate(
                                                  imagesForImageView,
                                                  postID,
                                                  userIDwhoCreatedThisGrid,
                                                  _user,
                                                  displayName,
                                                  profilePhotoUrl,
                                                  isGoogleUserSignedIn)));
                                }))
                        : withViewAll
                            ? SizedBox(
                                height: 30,
                                child: FloatingActionButton.extended(
                                    heroTag: 'viewAllBtnfor' + postID,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    backgroundColor: Colors.deepOrangeAccent,
                                    label: Text('view all',
                                        style: TextStyle(color: Colors.black)),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => ViewAll(
                                                  postID,
                                                  _user,
                                                  userIDwhoCreatedThisGrid,
                                                  displayName,
                                                  profilePhotoUrl,
                                                  isGoogleUserSignedIn)));
                                    }))
                            : SizedBox(
                                height: 30,
                                child: MaterialButton(
                                  onPressed: () {},
                                )),
                    withAds
                        ? Container(
                            height: _height,
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.only(bottom: 20.0),
                            child: NativeAdmob(
                              // Your ad unit id
                              adUnitID: _adUnitID,
                              controller: _nativeAdController,

                              // Don't show loading widget when in loading state
                              loading: Center(child: Text('Ad')),
                            ),
                          )
                        : Container()
                  ],
                ))
        : LoadingGrid(imgUrlList.length);
  }

  Widget rowForCard() {
    if (isOriginalImg) {
      return RowForOriginalImg(profilePhoto, displayName, numberOfImitations);
    } else if (forProfileView && (_user.uid == userIDwhoCreatedThisGrid)) {
      return RowForProfileView(
        numberOfImitations,
        withRemoveButton: true,
        postID: postID,
        userID: _user.uid,
      );
    } else if (forProfileView) {
      return RowForProfileView(numberOfImitations);
    } else {
      return RowForImitateImage(profilePhoto, displayName);
    }
  }
}

class LoadingGrid extends StatelessWidget {
  final bool networkErr;
  final int numOfPics;
  LoadingGrid(this.numOfPics, {this.networkErr: false});
  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    double width = query.size.width;
    if (query.orientation == Orientation.landscape) {
      width = query.size.height;
    }
    return Column(children: <Widget>[
      SizedBox(
        height: 50,
      ),
      SizedBox(
          width: width - 50,
          child: GridView.count(
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
            shrinkWrap: true,
            physics: ScrollPhysics(),
            crossAxisCount: numOfPics ~/ 2,
            children: numOfPics == 4
                ? <Widget>[
                    LoadingBox(
                      networkErr: networkErr,
                    ),
                    LoadingBox(
                      networkErr: networkErr,
                    ),
                    LoadingBox(
                      networkErr: networkErr,
                    ),
                    LoadingBox(
                      networkErr: networkErr,
                    )
                  ]
                : numOfPics == 6
                    ? <Widget>[
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        )
                      ]
                    : <Widget>[
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        ),
                        LoadingBox(
                          networkErr: networkErr,
                        )
                      ],
          )),
      SizedBox(
          height: 30,
          child: MaterialButton(
            onPressed: () {},
          ))
    ]);
  }
}

class LoadingBox extends StatelessWidget {
  final bool networkErr;
  LoadingBox({this.networkErr: false});
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.grey,
        child: Center(
          child: Text(networkErr ? 'Network err' : 'Loading'),
        ));
  }
}

class RowForOriginalImg extends StatelessWidget {
  final Image profilePhoto;
  final String displayName;
  final numberOfImitations;
  RowForOriginalImg(
      this.profilePhoto, this.displayName, this.numberOfImitations);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        SizedBox(height: 50, child: profilePhoto),
        Text(displayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
        Column(
          children: <Widget>[
            (numberOfImitations != 0)
                ? Text('$numberOfImitations ')
                : Container(),
          ],
        )
      ],
    );
  }
}

class RowForImitateImage extends StatelessWidget {
  final Image profilePhoto;
  final String displayName;

  RowForImitateImage(this.profilePhoto, this.displayName);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(height: 50, child: profilePhoto),
        SizedBox(
          width: 10,
        ),
        Text(displayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }
}

class RowForProfileView extends StatelessWidget {
  final numberOfImitations;
  final bool withRemoveButton;
  final String postID;
  final String userID;
  final CollectionReference users = Firestore.instance.collection('users');
  final CollectionReference imitations =
      Firestore.instance.collection('imitations');
  final StorageReference storageReference = FirebaseStorage.instance.ref();
  final CollectionReference posts = Firestore.instance.collection('posts');
  RowForProfileView(this.numberOfImitations,
      {this.withRemoveButton: false, this.postID, this.userID});
  @override
  Widget build(BuildContext context) {
    return withRemoveButton
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '  $numberOfImitations' + '  Imitations',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(
                    height: 50,
                  )
                ],
              ),
              IconButton(
                color: Colors.red,
                icon: Icon(Icons.remove_circle_outline),
                onPressed: () {
                  posts.document(postID).delete();
                  imitations.document(postID).delete();
                  users
                      .document(userID)
                      .collection('posts')
                      .document(postID)
                      .delete();
                },
              )
            ],
          )
        : Row(
            children: <Widget>[
              Text(
                '  $numberOfImitations' + '  Imitations',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(
                height: 50,
              )
            ],
          );
  }
}
