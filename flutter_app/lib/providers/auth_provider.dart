import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  FirebaseAuth? _auth;

  User? _user;
  String? _role; // "worker" or "employer"
  bool _isLoading = false;

  User? get user => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;

  AuthProvider() {
    try {
      _auth = FirebaseAuth.instance;
      _auth?.authStateChanges().listen((User? user) {
        // Only set user if email is verified or it's not a password provider (e.g. Google)
        if (user != null && user.providerData.any((p) => p.providerId == 'password') && !user.emailVerified) {
           _user = null;
        } else {
           _user = user;
        }
        notifyListeners();
      });
    } catch (e) {
      print("CRITICAL: Firebase Auth not initialized. App cannot proceed.");
      rethrow;
    }
  }

  void setRole(String selectedRole) {
    _role = selectedRole;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      UserCredential cred = await _auth!.signInWithEmailAndPassword(email: email, password: password);
      
      if (cred.user != null && !cred.user!.emailVerified) {
         await _auth!.signOut();
         throw Exception("Please verify your email address before logging in. Check your inbox and spam folder.");
      }

      // Fetch the actual role from Firestore so the app state is accurate
      if (cred.user != null) {
        var doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
        if (doc.exists && doc.data()!['role'] != null) {
          _role = doc.data()!['role'];
        }
      }
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> signup(String email, String password) async {
    if (_role == null) throw Exception("Please select a role first.");
    
    _setLoading(true);
    try {
      UserCredential? cred = await _auth?.createUserWithEmailAndPassword(email: email, password: password);
      
      if (cred?.user != null) {
         await cred!.user!.sendEmailVerification();
         String? idToken = await cred.user?.getIdToken();
         if (idToken != null) {
            await ApiService.registerUser(idToken, _role!);
         }
         // Logout immediately to force them to verify
         await _auth?.signOut();
         throw Exception("Registration successful! A verification email has been sent. Please verify your email before logging in.");
      }
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> signInWithGoogle() async {
    if (_role == null) throw Exception("Please select a role first.");
    _setLoading(true);
    String? fallbackGoogleIdToken;
    try {
      UserCredential cred;
      
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        cred = await _auth!.signInWithPopup(authProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
        if (googleUser == null) {
          _setLoading(false);
          return; // User canceled sign in
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        fallbackGoogleIdToken = googleAuth.idToken;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: null, // accessToken is no longer provided by default in v7.2.0
          idToken: googleAuth.idToken,
        );

        cred = await _auth!.signInWithCredential(credential);
      }
      
      if (cred.user != null) {
         var doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
         if (!doc.exists) {
            // New user via Google, register them on backend
            String? idToken = await cred.user?.getIdToken();
            if (idToken != null) {
               await ApiService.registerUser(idToken, _role!);
            }
         } else {
            // Existing user, update local role state
            if (doc.data()!['role'] != null) {
               _role = doc.data()!['role'];
            }
         }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
         if (fallbackGoogleIdToken != null) {
            try {
               final response = await ApiService.overrideGoogleLogin(fallbackGoogleIdToken);
               if (response.containsKey('custom_token')) {
                   await _auth!.signInWithCustomToken(response['custom_token']);
                   _setLoading(false);
                   return; // Success override!
               }
            } catch (_) {}
         }
         _setLoading(false);
         throw Exception("An account already exists with this email. Please login with your email/password instead.");
      }
      _setLoading(false);
      rethrow;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _auth?.sendPasswordResetEmail(email: email);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> logout() async {
    await _auth?.signOut();
    _role = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
