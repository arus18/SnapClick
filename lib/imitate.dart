import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:storage/home.dart';

class CameraPreviewToImitate extends StatefulWidget {
  final bool isGoogleUserSignedIn;
  final String userIDwhoCreatedThisGrid;
  final String postID;
  final List<Image> previewImages;
  final FirebaseUser user;
  final String displayName;
  final String profilePhotoUrl;
  CameraPreviewToImitate(
      this.previewImages,
      this.postID,
      this.userIDwhoCreatedThisGrid,
      this.user,
      this.displayName,
      this.profilePhotoUrl,
      this.isGoogleUserSignedIn);
  @override
  State<StatefulWidget> createState() {
    return CameraPreviewToImitateState(
        previewImages,
        postID,
        userIDwhoCreatedThisGrid,
        user,
        displayName,
        profilePhotoUrl,
        isGoogleUserSignedIn);
  }
}

class CameraPreviewToImitateState extends State<CameraPreviewToImitate> {
  final bool isGoogleUserSignedIn;
  final String userIDwhoCreatedThisGrid;
  final String postID;
  final List<Image> previewImages;
  final FirebaseUser user;
  CameraPreviewToImitateState(
      this.previewImages,
      this.postID,
      this.userIDwhoCreatedThisGrid,
      this.user,
      this.displayName,
      this.profilePhotoUrl,
      this.isGoogleUserSignedIn);
  CameraController _controller;
  bool isInitialized = false;
  bool isTimedOut = false;
  bool isPreview = true;
  List<Image> imagesForGrid = new List<Image>();
  List<File> imageFiles = new List<File>();
  CameraDescription backCam;
  CameraDescription frontCam;
  bool initializationFailed = false;
  bool swapCameraInitializationFailed = false;
  bool writeError = false;
  bool captureClicked = false;
  bool swapClicked = false;
  int imgCount = 0;
  final String displayName;
  final String profilePhotoUrl;
  

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  _initApp() async {
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

  swapCamera() async {
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
          swapCameraInitializationFailed = true;
        });
      }
    }
  }

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
    double width = query.size.width;
    double height = query.size.height;
    return imagesForGrid.length != previewImages.length
        ? (isTimedOut && !initializationFailed)
            ? TimedOut(userIDwhoCreatedThisGrid, postID, previewImages, user,
                displayName, profilePhotoUrl, isGoogleUserSignedIn)
            : isPreview
                ? Scaffold(
                    body: swapCameraInitializationFailed
                        ? Center(
                            child: Text('camera initialization failed'),
                          )
                        : Center(child: previewImages[imgCount]),
                    floatingActionButton: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          swapClicked
                              ? IconButton(
                                  onPressed: () {},
                                  icon: (frontCam == null)
                                      ? Icon(Icons.camera_rear)
                                      : Icon(Icons.camera_front))
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
                                      ? Icon(
                                          Icons.camera_rear,
                                          color: Colors.deepOrangeAccent,
                                        )
                                      : Icon(Icons.camera_front,
                                          color: Colors.deepOrangeAccent),
                                ),
                          SizedBox(
                            width: 20,
                          ),
                          FloatingActionButton.extended(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            backgroundColor: Colors.deepOrangeAccent,
                            heroTag: 'readyBtn',
                            label: Text("When you're ready",
                                style: TextStyle(color: Colors.black)),
                            onPressed: () {
                              if (!swapCameraInitializationFailed &&
                                  isInitialized) {
                                if (mounted) {
                                  setState(() {
                                    isPreview = false;
                                    imgCount++;
                                  });
                                }
                              }
                            },
                          ),
                        ]))
                : Material(
                    color: Colors.black,
                    child: Stack(children: <Widget>[
                      writeError
                          ? Center(
                              child: Text('error writing temporary image file',
                                  style: TextStyle(color: Colors.white)))
                          : initializationFailed
                              ? Center(
                                  child: Text('camera initialization failed',
                                      style: TextStyle(color: Colors.white)),
                                )
                              : isInitialized
                                  ? Center(
                                      child: AspectRatio(
                                          aspectRatio:
                                              _controller.value.aspectRatio,
                                          child: CameraPreview(_controller)))
                                  : Center(
                                      child: Text('Loading',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                      Positioned(
                        top: height - 150,
                        width: width,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              (initializationFailed || writeError)
                                  ? Text(
                                      '0',
                                      style: TextStyle(
                                          fontSize: 50.0, color: Colors.white),
                                    )
                                  : isInitialized
                                      ? CountDown(this)
                                      : Text(
                                          '9',
                                          style: TextStyle(
                                              fontSize: 50.0,
                                              color: Colors.white),
                                        ),
                              Center(
                                child: isInitialized
                                    ? FloatingActionButton(
                                        heroTag: 'imitateCaptureBtn',
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
                                        onPressed: () {},
                                        backgroundColor: Colors.white,
                                      ),
                              ),
                            ]),
                      )
                    ]))
        : Grid(imagesForGrid, imageFiles, postID, userIDwhoCreatedThisGrid,
            user, displayName, profilePhotoUrl, isGoogleUserSignedIn);
  }

  capture() async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final path = join(directory.path, '${DateTime.now()}.png');
      await _controller.takePicture(path);
      ImageProperties properties =
          await FlutterNativeImage.getImageProperties(path);
      if (mounted) {
        setState(() {
          isPreview = true;
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
  final String userIDwhoCreatedThisGrid;
  final String postID;
  final List<Image> imagesForGrid;
  final List<File> imageFiles;
  final FirebaseUser user;
  final String displayName;
  final String profilePhotoUrl;
  final bool isGoogleUserSignedIn;
  Grid(
      this.imagesForGrid,
      this.imageFiles,
      this.postID,
      this.userIDwhoCreatedThisGrid,
      this.user,
      this.displayName,
      this.profilePhotoUrl,
      this.isGoogleUserSignedIn);
  @override
  State<StatefulWidget> createState() {
    return GridState(
        imagesForGrid,
        imageFiles,
        postID,
        userIDwhoCreatedThisGrid,
        user,
        displayName,
        profilePhotoUrl,
        isGoogleUserSignedIn);
  }
}

class GridState extends State<Grid> {
  final String userIDwhoCreatedThisGrid;
  final CollectionReference imitations =
      Firestore.instance.collection('imitations');
  final CollectionReference users = Firestore.instance.collection('users');
  final CollectionReference posts = Firestore.instance.collection('posts');
  final StorageReference storageReference = FirebaseStorage.instance.ref();
  final String postID;
  final List<Image> imagesForGrid;
  final List<File> imageFiles;
  final FirebaseUser user;
  final bool isGoogleUserSigneIn;
  bool postClicked = false;
  bool uploadFailed = false;
  final String displayName;
  final String profilePhotoUrl;
  GridState(
      this.imagesForGrid,
      this.imageFiles,
      this.postID,
      this.userIDwhoCreatedThisGrid,
      this.user,
      this.displayName,
      this.profilePhotoUrl,
      this.isGoogleUserSigneIn);

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
                onPressed: () async {
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
          height: (imageFiles.length > 4) ? 60: 20
        ),
        GridView(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: imageFiles.length ~/ 2),
            children: imagesForGrid),
      ]),
    );
  }

  upload() async {
    final bottomBarState = Home.bottombar.currentState;
    try {
      var i = 1;
      List<dynamic> imgUrlList = List<dynamic>();
      final imitationsForThisPost =
          imitations.document(postID).collection('imitations');
      final String imitationID = imitationsForThisPost.document().documentID;
      final String path = userIDwhoCreatedThisGrid +
          '/' +
          postID +
          '/imitations/' +
          imitationID;
      final imitationsForThisUserPosts = users
          .document(userIDwhoCreatedThisGrid)
          .collection('posts')
          .document(postID)
          .collection('imitations');
      bottomBarState.setState(() {
        bottomBarState.uploadStarted = true;
      });
      await Future.forEach(imageFiles, (file) async {
        final uploadtask = await (storageReference
                .child(path + '/img' + '$i')
                .putFile(file))
            .onComplete;
        final imgUrl = await uploadtask.ref.getDownloadURL();
        imgUrlList.add(imgUrl);
        bottomBarState.setState(() {
          bottomBarState.updateProgress((0.96/imageFiles.length), postID);
        });
        i++;
      });

      if (imgUrlList.length == 4) {
        await (imitationsForThisPost.document(imitationID).setData({
          'userIDwhoCreatedThisGrid': user.uid,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'imitationImg1': imgUrlList[0],
          'imitationImg2': imgUrlList[1],
          'imitationImg3': imgUrlList[2],
          'imitationImg4': imgUrlList[3],
          'timestamp': FieldValue.serverTimestamp()
        }));
        await (imitationsForThisUserPosts.document(imitationID).setData({
          'userIDwhoCreatedThisGrid': user.uid,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'imitationImg1': imgUrlList[0],
          'imitationImg2': imgUrlList[1],
          'imitationImg3': imgUrlList[2],
          'imitationImg4': imgUrlList[3],
          'timestamp': FieldValue.serverTimestamp()
        }));
      } else if (imgUrlList.length == 6) {
        await (imitationsForThisPost.document(imitationID).setData({
          'userIDwhoCreatedThisGrid': user.uid,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'imitationImg1': imgUrlList[0],
          'imitationImg2': imgUrlList[1],
          'imitationImg3': imgUrlList[2],
          'imitationImg4': imgUrlList[3],
          'imitationImg5': imgUrlList[4],
          'imitationImg6': imgUrlList[5],
          'timestamp': FieldValue.serverTimestamp()
        }));
        await (imitationsForThisUserPosts.document(imitationID).setData({
          'userIDwhoCreatedThisGrid': user.uid,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'imitationImg1': imgUrlList[0],
          'imitationImg2': imgUrlList[1],
          'imitationImg3': imgUrlList[2],
          'imitationImg4': imgUrlList[3],
          'imitationImg5': imgUrlList[4],
          'imitationImg6': imgUrlList[5],
          'timestamp': FieldValue.serverTimestamp()
        }));
      } else if (imgUrlList.length == 8) {
        await (imitationsForThisPost.document(imitationID).setData({
          'userIDwhoCreatedThisGrid': user.uid,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'imitationImg1': imgUrlList[0],
          'imitationImg2': imgUrlList[1],
          'imitationImg3': imgUrlList[2],
          'imitationImg4': imgUrlList[3],
          'imitationImg5': imgUrlList[4],
          'imitationImg6': imgUrlList[5],
          'imitationImg7': imgUrlList[6],
          'imitationImg8': imgUrlList[7],
          'timestamp': FieldValue.serverTimestamp()
        }));
        await (imitationsForThisUserPosts.document(imitationID).setData({
          'userIDwhoCreatedThisGrid': user.uid,
          'displayName': user.displayName,
          'profilePhotoUrl': user.photoUrl,
          'imitationImg1': imgUrlList[0],
          'imitationImg2': imgUrlList[1],
          'imitationImg3': imgUrlList[2],
          'imitationImg4': imgUrlList[3],
          'imitationImg5': imgUrlList[4],
          'imitationImg6': imgUrlList[5],
          'imitationImg7': imgUrlList[6],
          'imitationImg8': imgUrlList[7],
          'timestamp': FieldValue.serverTimestamp()
        }));
      }
      final snapshot = await posts.document(postID).get();
      final numberOfImitations = (snapshot.data['numberOfImitations']) + 1;
      await (posts
          .document(postID)
          .updateData({'numberOfImitations': numberOfImitations}));
      await (users
          .document(userIDwhoCreatedThisGrid)
          .collection('posts')
          .document(postID)
          .updateData({'numberOfImitations': numberOfImitations}));
      await (users
          .document(user.uid)
          .collection('favorites')
          .document(userIDwhoCreatedThisGrid)
          .setData({
        'userIDwhoCreatedThisGrid': userIDwhoCreatedThisGrid,
        'displayName': displayName,
        'profilePhotoUrl': profilePhotoUrl,
        'timestamp': FieldValue.serverTimestamp()
      }));
      bottomBarState.setState(() {
        bottomBarState.updateProgress(0.4, postID);
        bottomBarState.uploadFinished(postID);
      });
      Fluttertoast.showToast(
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

class TimedOut extends StatefulWidget {
  final bool isGoogleUserSignedIn;
  final String userIDwhoCreatedThisGrid;
  final String postID;
  final List<Image> previewImages;
  final FirebaseUser user;
  final String displayName;
  final String profilePhotoUrl;
  TimedOut(
      this.userIDwhoCreatedThisGrid,
      this.postID,
      this.previewImages,
      this.user,
      this.displayName,
      this.profilePhotoUrl,
      this.isGoogleUserSignedIn);
  @override
  State<StatefulWidget> createState() {
    return TimedOutState(userIDwhoCreatedThisGrid, postID, previewImages, user,
        displayName, profilePhotoUrl, isGoogleUserSignedIn);
  }
}

class TimedOutState extends State<TimedOut> {
  final bool isGoogleUserSignedIn;
  final String userIDwhoCreatedThisGrid;
  final String postID;
  final List<Image> previewImages;
  final FirebaseUser user;
  bool retry = false;
  final String displayName;
  final String profilePhotoUrl;
  TimedOutState(
      this.userIDwhoCreatedThisGrid,
      this.postID,
      this.previewImages,
      this.user,
      this.displayName,
      this.profilePhotoUrl,
      this.isGoogleUserSignedIn);
  @override
  Widget build(BuildContext context) {
    return retry
        ? CameraPreviewToImitate(
            previewImages,
            postID,
            userIDwhoCreatedThisGrid,
            user,
            displayName,
            profilePhotoUrl,
            isGoogleUserSignedIn)
        : Scaffold(
            body: Center(
              child: Text("Time's up",
                  style: TextStyle(color: Colors.red, fontSize: 50)),
            ),
            floatingActionButton: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FloatingActionButton.extended(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    backgroundColor: Colors.deepOrangeAccent,
                    heroTag: 'backBtn',
                    label: Text('Back', style: TextStyle(color: Colors.black)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  FloatingActionButton.extended(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    backgroundColor: Colors.deepOrangeAccent,
                    heroTag: 'retryBtn',
                    label: Text('Retry', style: TextStyle(color: Colors.black)),
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          retry = true;
                        });
                      }
                    },
                  )
                ]),
          );
  }
}

class CountDown extends StatefulWidget {
  final CameraPreviewToImitateState parent;
  CountDown(this.parent);
  @override
  State<StatefulWidget> createState() {
    return CountDownState(parent);
  }
}

class CountDownState extends State<CountDown> {
  final CameraPreviewToImitateState parent;
  CountDownState(this.parent);
  int countDown = 9;
  countDownTimer() async {
    await Future.delayed(Duration(seconds: 1));
    if (countDown > 0 && mounted) {
      setState(() {
        countDown--;
      });
    } else if (countDown == 0 && mounted) {
      parent.setState(() {
        parent.isTimedOut = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    countDownTimer();
    return Center(
      child: Text(
        '$countDown',
        style: TextStyle(fontSize: 50.0, color: Colors.white),
      ),
    );
  }
}
