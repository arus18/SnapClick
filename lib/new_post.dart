import 'dart:core';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:storage/home.dart';


class SelectNoOfPics extends StatefulWidget {
  final FirebaseUser user;
  SelectNoOfPics(this.user);
  @override
  State<StatefulWidget> createState() {
    return SelectNoOfPicsState(user);
  }
}

class SelectNoOfPicsState extends State<SelectNoOfPics> {
  final FirebaseUser user;
  int noOfPics = 4;
  bool switchCamera = false;
  SelectNoOfPicsState(this.user);
  @override
  Widget build(BuildContext context) {
    return switchCamera
        ? CamPreview(user, noOfPics)
        : Scaffold(
            floatingActionButton: FloatingActionButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                heroTag: 'nextbutton',
                child: Icon(Icons.arrow_forward),
                backgroundColor: Colors.deepOrangeAccent,
                onPressed: () {
                  setState(() {
                    switchCamera = true;
                  });
                }),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Select number of pics',
                    style:
                        TextStyle(color: Colors.deepOrangeAccent, fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  IconButton(
                    iconSize: 35,
                    color: Colors.deepOrangeAccent,
                    onPressed: () {
                      setState(() {
                        if (noOfPics < 8) {
                          noOfPics += 2;
                        }
                      });
                    },
                    icon: Icon(Icons.arrow_drop_up),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text('$noOfPics',
                      style: TextStyle(
                          color: Colors.deepOrangeAccent, fontSize: 50)),
                  SizedBox(
                    height: 10,
                  ),
                  IconButton(
                    iconSize: 35,
                    color: Colors.deepOrangeAccent,
                    onPressed: () {
                      setState(() {
                        if (noOfPics > 4) {
                          noOfPics -= 2;
                        }
                      });
                    },
                    icon: Icon(Icons.arrow_drop_down),
                  )
                ],
              ),
            ),
          );
  }
}

class CamPreview extends StatefulWidget {
  final FirebaseUser user;
  final int numOfPics;
  CamPreview(this.user, this.numOfPics);
  @override
  _CamPreviewState createState() => _CamPreviewState(user, numOfPics);
}

class _CamPreviewState extends State<CamPreview> {
  final int numOfPics;
  final FirebaseUser user;
  CameraController _controller;
  bool isInitialized = false;
  List<Image> imagesForGrid = new List<Image>();
  List<File> imageFiles = new List<File>();
  List<Container> previewImageList = new List<Container>();
  CameraDescription backCam;
  CameraDescription frontCam;
  bool initializationFailed = false;
  bool writeError = false;
  bool captureClicked = false;
  bool swapClicked = false;
  String error = '';

  int imgCount = 1;
  _CamPreviewState(this.user, this.numOfPics);

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await (SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]));
      List<CameraDescription> cameras = await availableCameras();
      if (cameras.length > 1) {
        cameras.forEach((camera) async {
          if (camera.lensDirection == CameraLensDirection.front) {
            frontCam = camera;
            _controller = CameraController(frontCam, ResolutionPreset.medium);
            await (_controller.initialize());
            if (mounted) {
              setState(() {
                isInitialized = true;
              });
            }
          }
        });
      } else {
        cameras.forEach((camera) async {
          if (camera.lensDirection == CameraLensDirection.back) {
            backCam = camera;
            _controller = CameraController(backCam, ResolutionPreset.medium);
            await (_controller.initialize());
            if (mounted) {
              setState(() {
                isInitialized = true;
              });
            }
          }
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          initializationFailed = true;
        });
      }
    }
  }

  Future<void> swapCamera() async {
    try {
      List<CameraDescription> cameras = await availableCameras();
      if (cameras.length > 1) {
        if (backCam == null) {
          cameras.forEach((camera) async {
            if (camera.lensDirection == CameraLensDirection.back) {
              frontCam = null;
              backCam = camera;
              _controller = CameraController(backCam, ResolutionPreset.medium);
              await (_controller.initialize());
              if (mounted) {
                setState(() {
                  isInitialized = true;
                });
              }
            }
          });
        } else {
          cameras.forEach((camera) async {
            if (camera.lensDirection == CameraLensDirection.front) {
              backCam = null;
              frontCam = camera;
              _controller = CameraController(frontCam, ResolutionPreset.medium);
              await (_controller.initialize());
              if (mounted) {
                setState(() {
                  isInitialized = true;
                });
              }
            }
          });
        }
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          initializationFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp
    ]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData query = MediaQuery.of(context);
    final double width = query.orientation == Orientation.portrait
        ? query.size.width
        : query.size.height;
    final double height = query.orientation == Orientation.portrait
        ? query.size.height
        : query.size.width;
    return imagesForGrid.length != numOfPics
        ? Material(
            color: Colors.black,
            child: Stack(children: <Widget>[
              writeError
                  ? Center(
                      child: Text('error writing temporary image file',
                          style: TextStyle(color: Colors.white)))
                  : initializationFailed
                      ? Center(
                          child: Text(
                            'camera initialization failed',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : isInitialized
                          ? Center(
                              child: AspectRatio(
                                  aspectRatio: _controller.value.aspectRatio,
                                  child: CameraPreview(_controller)))
                          : Center(
                              child: Text('Loading',
                                  style: TextStyle(color: Colors.white)),
                            ),
              Positioned(
                top: height - 150,
                width: width,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text(
                        '$imgCount',
                        style: TextStyle(fontSize: 50.0, color: Colors.white),
                      ),
                      Center(
                        child: (isInitialized && !captureClicked)
                            ? FloatingActionButton(
                                heroTag: 'captureBtn',
                                onPressed: () {
                                  if (!initializationFailed &&
                                      !captureClicked) {
                                    captureClicked = true;
                                    capture().whenComplete(() {
                                      captureClicked = false;
                                    });
                                  }
                                },
                                backgroundColor: Colors.white,
                              )
                            : FloatingActionButton(
                                heroTag: 'dummy',
                                backgroundColor: Colors.white,
                                onPressed: () {},
                              ),
                      ),
                      swapClicked
                          ? IconButton(
                              onPressed: () {},
                              icon: (frontCam == null)
                                  ? Icon(
                                      Icons.camera_rear,
                                      color: Colors.white,
                                    )
                                  : Icon(
                                      Icons.camera_front,
                                      color: Colors.white,
                                    ))
                          : IconButton(
                              onPressed: () {
                                if (!initializationFailed &&
                                    !swapClicked &&
                                    isInitialized) {
                                  swapClicked = true;
                                  swapCamera().whenComplete(() {
                                    swapClicked = false;
                                  });
                                }
                              },
                              icon: (frontCam == null)
                                  ? Icon(Icons.camera_rear, color: Colors.white)
                                  : Icon(Icons.camera_front,
                                      color: Colors.white)),
                      
                    ]),
              )
            ]))
        : Grid(imagesForGrid, user, imageFiles);
  }
  
  Future<void> capture() async {
    try {
      Directory directory = await getTemporaryDirectory();
      final path = join(directory.path, '${DateTime.now()}.png');
      await (_controller.takePicture(path));
      ImageProperties properties =
          await FlutterNativeImage.getImageProperties(path);
      if (mounted) {
        setState(() {
          imgCount++;
          imageFiles.add(File(path));

          if (properties.width > properties.height) {
            imagesForGrid.add(Image.file(
              File(path),
              fit: BoxFit.fitHeight,
            ));
          } else {
            imagesForGrid.add(Image.file(
              File(path),
              fit: BoxFit.fitWidth,
            ));
          }
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          writeError = true;
        });
      }
    }
  }
}

class Grid extends StatefulWidget {
  final FirebaseUser user;
  final List<Image> imagesForGrid;
  final List<File> imageFiles;
  Grid(
    this.imagesForGrid,
    this.user,
    this.imageFiles,
  );
  @override
  State<StatefulWidget> createState() {
    return GridState(imagesForGrid, user, imageFiles);
  }
}

class GridState extends State<Grid> {
  var i = 1;
  List<dynamic> imgUrlList = List<dynamic>();
  final FirebaseUser user;
  final CollectionReference posts = Firestore.instance.collection('posts');
  final CollectionReference users = Firestore.instance.collection('users');
  final StorageReference storageReference = FirebaseStorage.instance.ref();
  final List<Image> imagesForGrid;
  final List<File> imageFiles;
  GridState(this.imagesForGrid, this.user, this.imageFiles);
  bool postClicked = false;
  bool uploadFailed = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
        FloatingActionButton.extended(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          heroTag: 'homebtn',
          backgroundColor: Colors.deepOrangeAccent,
          onPressed: () => Navigator.pop(context),
          label: Icon(Icons.arrow_back),
        ),
        postClicked
            ? FloatingActionButton.extended(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                heroTag: 'postandupdatebtndummy',
                icon: Icon(Icons.arrow_forward),
                backgroundColor: Colors.grey,
                label: Text('Post'),
                onPressed: () {})
            : FloatingActionButton.extended(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                heroTag: 'postandupdatebtn',
                icon: Icon(Icons.arrow_forward),
                backgroundColor: Colors.deepOrangeAccent,
                label: Text('Post'),
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      postClicked = true;
                    });
                  }
                  Navigator.pop(context);
                  upload();
                })
      ]),
      body: Column(children: <Widget>[
        SizedBox(
          height: (imageFiles.length > 4) ? 60 : 20,
        ),
        GridView(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: imageFiles.length ~/ 2),
            children: imagesForGrid),
      ]),
    );
  }

  Future<void> upload() async {
    final bottomBarState = Home.bottombar.currentState;
    try {
      final String postID = posts.document().documentID;
      final String userID = user.uid;
      final String path = userID + '/' + postID;
      final postsOfUser = users.document(userID).collection('posts');
      bottomBarState.setState(() {
        bottomBarState.uploadStarted = true;
      });
      await Future.forEach(imageFiles, (file) async {
        final uploadtask =
            await (storageReference.child(path + '/img' + '$i').putFile(file))
                .onComplete;
        final imgUrl = await uploadtask.ref.getDownloadURL();
        imgUrlList.add(imgUrl);
        bottomBarState.setState(() {
          bottomBarState.updateProgress((0.96 / imageFiles.length), postID);
        });
        i++;
      });

      if (imgUrlList.length == 4) {
        await (posts.document(postID).setData({
          'userIDwhoCreatedThisGrid': userID,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'originalImg1': imgUrlList[0],
          'originalImg2': imgUrlList[1],
          'originalImg3': imgUrlList[2],
          'originalImg4': imgUrlList[3],
          'numberOfImitations': 0,
          'timestamp': FieldValue.serverTimestamp()
        }));
        await (postsOfUser.document(postID).setData({
          'userIDwhoCreatedThisGrid': userID,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'originalImg1': imgUrlList[0],
          'originalImg2': imgUrlList[1],
          'originalImg3': imgUrlList[2],
          'originalImg4': imgUrlList[3],
          'numberOfImitations': 0,
          'timestamp': FieldValue.serverTimestamp()
        }));
      } else if (imgUrlList.length == 6) {
        await (posts.document(postID).setData({
          'userIDwhoCreatedThisGrid': userID,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'originalImg1': imgUrlList[0],
          'originalImg2': imgUrlList[1],
          'originalImg3': imgUrlList[2],
          'originalImg4': imgUrlList[3],
          'originalImg5': imgUrlList[4],
          'originalImg6': imgUrlList[5],
          'numberOfImitations': 0,
          'timestamp': FieldValue.serverTimestamp()
        }));
        await (postsOfUser.document(postID).setData({
          'userIDwhoCreatedThisGrid': userID,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'originalImg1': imgUrlList[0],
          'originalImg2': imgUrlList[1],
          'originalImg3': imgUrlList[2],
          'originalImg4': imgUrlList[3],
          'originalImg5': imgUrlList[4],
          'originalImg6': imgUrlList[5],
          'numberOfImitations': 0,
          'timestamp': FieldValue.serverTimestamp()
        }));
      } else if (imgUrlList.length == 8) {
        await (posts.document(postID).setData({
          'userIDwhoCreatedThisGrid': userID,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'originalImg1': imgUrlList[0],
          'originalImg2': imgUrlList[1],
          'originalImg3': imgUrlList[2],
          'originalImg4': imgUrlList[3],
          'originalImg5': imgUrlList[4],
          'originalImg6': imgUrlList[5],
          'originalImg7': imgUrlList[6],
          'originalImg8': imgUrlList[7],
          'numberOfImitations': 0,
          'timestamp': FieldValue.serverTimestamp()
        }));
        await (postsOfUser.document(postID).setData({
          'userIDwhoCreatedThisGrid': userID,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'originalImg1': imgUrlList[0],
          'originalImg2': imgUrlList[1],
          'originalImg3': imgUrlList[2],
          'originalImg4': imgUrlList[3],
          'originalImg5': imgUrlList[4],
          'originalImg6': imgUrlList[5],
          'originalImg7': imgUrlList[6],
          'originalImg8': imgUrlList[7],
          'numberOfImitations': 0,
          'timestamp': FieldValue.serverTimestamp()
        }));
        
      }
      bottomBarState.setState(() {
        bottomBarState.updateProgress(0.4, postID);
        bottomBarState.uploadFinished(postID);
      });
      Fluttertoast.showToast(
        timeInSecForIos: 10,
        msg: uploadFailed ? 'Upload failed' : 'Upload complete',
        gravity: ToastGravity.CENTER,
      );
    } catch (err) {
      bottomBarState.setState(() {
        bottomBarState.uploadStarted = false;
      });
      uploadFailed = true;
    }
  }
}
