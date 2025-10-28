import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "400224458947-ruqvml0cto5o7cgkmsm8ir8cbd9eammv.apps.googleusercontent.com",
    scopes: [
      'email',
      'profile',
    ],
  );

  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  GoogleSignInService();

  Future<GoogleSignInResult> signIn() async {
    try {
      // Check if user is already signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Attempt to sign in
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account != null) {
        // Get authentication details
        final GoogleSignInAuthentication auth = await account.authentication;
        
        return GoogleSignInResult(
          success: true,
          message: 'Sign-in successful',
          user: GoogleUser(
            id: account.id,
            email: account.email,
            displayName: account.displayName,
            photoUrl: account.photoUrl,
          ),
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
      } else {
        return GoogleSignInResult(
          success: false,
          message: 'Sign-in was cancelled by user',
        );
      }
    } catch (e) {
      return GoogleSignInResult(
        success: false,
        message: 'Sign-in failed: ${e.toString()}',
      );
    }
  }

  /// Sign in with Google and authenticate with Firebase
  Future<GoogleSignInResult> signInWithFirebase() async {
    try {
      // Check if user is already signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Attempt to sign in with Google
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account != null) {
        // Get authentication details
        final GoogleSignInAuthentication auth = await account.authentication;
        
        // Create credential for Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );

        // Sign in to Firebase
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          return GoogleSignInResult(
            success: true,
            message: 'Firebase sign-in successful',
            user: GoogleUser(
              id: firebaseUser.uid,
              email: firebaseUser.email,
              displayName: firebaseUser.displayName,
              photoUrl: firebaseUser.photoURL,
            ),
            accessToken: auth.accessToken,
            idToken: auth.idToken,
          );
        } else {
          return GoogleSignInResult(
            success: false,
            message: 'Firebase authentication failed',
          );
        }
      } else {
        return GoogleSignInResult(
          success: false,
          message: 'Sign-in was cancelled by user',
        );
      }
    } catch (e) {
      return GoogleSignInResult(
        success: false,
        message: 'Firebase sign-in failed: ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from both Google and Firebase
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<bool> isSignedIn() async {
    try {
      // Check both Google Sign-In and Firebase Auth status
      final bool googleSignedIn = await _googleSignIn.isSignedIn();
      final bool firebaseSignedIn = _firebaseAuth.currentUser != null;
      return googleSignedIn && firebaseSignedIn;
    } catch (e) {
      return false;
    }
  }

  Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return await _googleSignIn.currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Get the current Firebase user
  User? getCurrentFirebaseUser() {
    return _firebaseAuth.currentUser;
  }

  /// Stream of Firebase auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}

class GoogleSignInResult {
  final bool success;
  final String message;
  final GoogleUser? user;
  final String? accessToken;
  final String? idToken;

  GoogleSignInResult({
    required this.success,
    required this.message,
    this.user,
    this.accessToken,
    this.idToken,
  });
}

class GoogleUser {
  final String? id;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  GoogleUser({
    this.id,
    this.email,
    this.displayName,
    this.photoUrl,
  });
}
