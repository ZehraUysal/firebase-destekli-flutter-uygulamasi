import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? get currentUser => _firebaseAuth.currentUser; // => return anlamı
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges(); // kullanıcı giriş çıkış durumu anlık gelsin
  // KAYIT
  Future<void> createUser({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //GİRİŞ
  Future<void> logIn({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //ÇIKIŞ
  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }
}
