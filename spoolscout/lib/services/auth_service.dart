import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // initialize GoogleSignIn

  // sign-up method
  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Sign-Up Error: $e');
      return null;
    }
  }

  // sign-in method
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user; // return the signed-in user
    } catch (e) {
      print('Sign-In Error: $e');
      return null;
    }
  }

  // sign-out method
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut(); // sign out from Google as well
    } catch (e) {
      print('Sign-Out Error: $e');
    }
  }

  // Google sign-in method
  Future<User?> signInWithGoogle() async {
    try {
      // trigger the Google Sign-In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // if user cancels the Google Sign-In, return null
        print('Google Sign-In canceled by user');
        return null;
      }

      // obtain Google authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // create a new credential using the Google authentication token
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // authenticate with Firebase using the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user; // return the signed-in user
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }
}
