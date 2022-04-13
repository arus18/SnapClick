import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:storage/home.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrangeAccent,
      body: Center(
        child: Text('SnapClick',
            style: TextStyle(fontSize: 50, fontFamily: 'Fascinate')),
      ),
    );
  }
}

class StartUpScreen extends StatefulWidget {
  @override
  StartUpScreenState createState() {
    return StartUpScreenState();
  }
}

class StartUpScreenState extends State<StartUpScreen> {
  Widget startUpWidget = Loading();
  AuthResult authResult;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FacebookLogin facebookLogin = FacebookLogin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser _user;
  bool hasError = false;

  @override
  initState() {
    super.initState();
    isUserSignedIn();
  }

  isUserSignedIn() async {
    try {
      bool isGoogleUserSignedIn = await googleSignIn.isSignedIn();
      bool isFacebookUserSignedIn = await facebookLogin.isLoggedIn;
      if (isGoogleUserSignedIn) {
        _user = await _auth.currentUser();
        if(mounted){
          setState(() {
            startUpWidget = Home(
                _user,
                true,
              );
          });
        }
      } else if (isFacebookUserSignedIn) {
        _user = await _auth.currentUser();
        if(mounted){
          setState(() {
            startUpWidget = Home(_user, false);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            startUpWidget = Signin(googleSignIn, facebookLogin, _auth);
          });
        }
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return hasError
        ? Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'retrySignIn',
              backgroundColor: Colors.deepOrangeAccent,
              onPressed: () {
                if (mounted) {
                  setState(() {
                    hasError = false;
                    startUpWidget = Signin(googleSignIn, facebookLogin, _auth);
                  });
                }
              },
              label: Text('Sign in'),
            ),
            body: Center(
              child: Text('error getting user info for current user'),
            ),
          )
        : startUpWidget;
  }
}

class Signin extends StatefulWidget {
  final GoogleSignIn googleSignIn;
  final FacebookLogin facebookLogin;
  final FirebaseAuth _auth;
  Signin(
    this.googleSignIn,
    this.facebookLogin,
    this._auth,
  );
  @override
  State<StatefulWidget> createState() {
    return SigninState(
      googleSignIn,
      facebookLogin,
      _auth,
    );
  }
}

class SigninState extends State<Signin> {
  bool isFacebookSigninButtonPressed = false;
  bool isGoogleSigninButtonPressed = false;
  bool isSigninSuccessful = false;
  final GoogleSignIn googleSignIn;
  final FacebookLogin facebookLogin;
  final FirebaseAuth _auth;
  AuthResult authResult;
  bool hasError = false;
  SigninState(
    this.googleSignIn,
    this.facebookLogin,
    this._auth,
  );

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken);
      authResult = (await _auth.signInWithCredential(credential));
      if (mounted) {
        setState(() {
          hasError = false;
          isSigninSuccessful = true;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          isSigninSuccessful = false;
          isFacebookSigninButtonPressed = false;
          isGoogleSigninButtonPressed = false;
          hasError = true;
        });
      }
      Fluttertoast.showToast(
        msg: 'Sign in failed',
      );
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
      final result = await facebookLogin.logInWithReadPermissions(['email']);
      switch (result.status) {
        case FacebookLoginStatus.loggedIn:
          final AuthCredential credential = FacebookAuthProvider.getCredential(
              accessToken: result.accessToken.token);
          authResult = (await _auth.signInWithCredential(credential));
          if (mounted) {
            setState(() {
              hasError = false;
              isSigninSuccessful = true;
            });
          }
          break;
        case FacebookLoginStatus.cancelledByUser:
          if (mounted) {
            setState(() {
              isSigninSuccessful = false;
              hasError = true;
              isGoogleSigninButtonPressed = false;
              isFacebookSigninButtonPressed = false;
            });
          }
          Fluttertoast.showToast(
            msg: 'Sign in failed',
          );
          break;
        case FacebookLoginStatus.error:
          if (mounted) {
            setState(() {
              isSigninSuccessful = false;
              hasError = true;
              isGoogleSigninButtonPressed = false;
              isFacebookSigninButtonPressed = false;
            });
          }
          Fluttertoast.showToast(
            msg: 'Sign in failed',
          );
          break;
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          isSigninSuccessful = false;
          isFacebookSigninButtonPressed = false;
          isGoogleSigninButtonPressed = false;
          hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    return hasError
        ? Scaffold(
            backgroundColor: Colors.deepOrangeAccent,
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  Text(
                    'SnapClick',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 50,
                        fontFamily: 'Fascinate'),
                  ),
                  SizedBox(
                    height: query.size.height / 2 - query.size.height / 3,
                  ),
                  isGoogleSigninButtonPressed
                      ? FloatingActionButton.extended(
                          heroTag: 'retrygoogleSignInDummy',
                          icon: Icon(FontAwesomeIcons.google),
                          backgroundColor: Colors.black87,
                          label: SizedBox(
                              width: 180,
                              child: Center(child: Text('Loading'))),
                          onPressed: () {},
                        )
                      : FloatingActionButton.extended(
                          heroTag: 'retrygoogleSignIn',
                          icon: Icon(FontAwesomeIcons.google),
                          backgroundColor: isFacebookSigninButtonPressed
                              ? Colors.black87
                              : Colors.black,
                          label: SizedBox(
                              width: 180,
                              child:
                                  Center(child: Text('Sign in with Google'))),
                          onPressed: () {
                            if (mounted && !isFacebookSigninButtonPressed) {
                              setState(() {
                                isGoogleSigninButtonPressed = true;
                                signInWithGoogle();
                              });
                            }
                          },
                        ),
                  SizedBox(
                    height: 20,
                  ),
                  isFacebookSigninButtonPressed
                      ? FloatingActionButton.extended(
                          heroTag: 'retryfacebookSignIn',
                          icon: Icon(FontAwesomeIcons.facebook),
                          backgroundColor: Colors.black87,
                          label: SizedBox(
                              width: 180,
                              child: Center(child: Text('Loading'))),
                          onPressed: () {},
                        )
                      : FloatingActionButton.extended(
                          heroTag: 'retryfacebookSignInDummy',
                          icon: Icon(FontAwesomeIcons.facebook),
                          backgroundColor: isGoogleSigninButtonPressed
                              ? Colors.black87
                              : Colors.black,
                          label: SizedBox(
                              width: 180,
                              child:
                                  Center(child: Text('Login with Facebook'))),
                          onPressed: () {
                            if (mounted && !isGoogleSigninButtonPressed) {
                              setState(() {
                                isFacebookSigninButtonPressed = true;
                                signInWithFacebook();
                              });
                            }
                          },
                        )
                ])))
        : isSigninSuccessful
            ? isGoogleSigninButtonPressed
                ? Home(authResult.user, true)
                : Home(authResult.user, false)
            : Scaffold(
                backgroundColor: Colors.deepOrangeAccent,
                body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                      Text(
                        'SnapClick',
                        style: TextStyle(fontSize: 50, fontFamily: 'Fascinate'),
                      ),
                      SizedBox(
                        height: query.size.height / 2 - query.size.height / 3,
                      ),
                      isGoogleSigninButtonPressed
                          ? FloatingActionButton.extended(
                              heroTag: 'googlesigninloading',
                              icon: Icon(FontAwesomeIcons.google),
                              backgroundColor: Colors.black87,
                              label: SizedBox(
                                  width: 180,
                                  child: Center(child: Text('Loading'))),
                              onPressed: () {},
                            )
                          : FloatingActionButton.extended(
                              heroTag: 'googlesignin',
                              icon: Icon(FontAwesomeIcons.google),
                              backgroundColor: isFacebookSigninButtonPressed
                                  ? Colors.black87
                                  : Colors.black,
                              label: SizedBox(
                                  width: 180,
                                  child: Center(
                                      child: Text('Sign in with Google'))),
                              onPressed: () {
                                if (mounted && !isFacebookSigninButtonPressed) {
                                  setState(() {
                                    isGoogleSigninButtonPressed = true;
                                    signInWithGoogle();
                                  });
                                }
                              },
                            ),
                      SizedBox(
                        height: 20,
                      ),
                      isFacebookSigninButtonPressed
                          ? FloatingActionButton.extended(
                              heroTag: 'facebooksigninloading',
                              icon: Icon(FontAwesomeIcons.facebook),
                              backgroundColor: Colors.black87,
                              label: SizedBox(
                                  width: 180,
                                  child: Center(child: Text('Loading'))),
                              onPressed: () {},
                            )
                          : FloatingActionButton.extended(
                              heroTag: 'facebooksignin',
                              icon: Icon(FontAwesomeIcons.facebook),
                              backgroundColor: isGoogleSigninButtonPressed
                                  ? Colors.black87
                                  : Colors.black,
                              label: SizedBox(
                                  width: 180,
                                  child: Center(
                                      child: Text('Login with Facebook'))),
                              onPressed: () {
                                if (mounted && !isGoogleSigninButtonPressed) {
                                  setState(() {
                                    isFacebookSigninButtonPressed = true;
                                    signInWithFacebook();
                                  });
                                }
                              },
                            )
                    ])));
  }
}
