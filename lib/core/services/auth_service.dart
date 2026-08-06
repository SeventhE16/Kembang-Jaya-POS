import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();
  firebase_auth.User? get currentUser => _auth.currentUser;

  Future<firebase_auth.UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getUserModel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return User.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user model: $e');
      return null;
    }
  }

  Future<void> saveUserModel(User user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Future<firebase_auth.UserCredential> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerStaff(String email, String password, String name, String storeId) async {
    try {
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempRegister',
        options: Firebase.app().options,
      );
      final tempAuth = firebase_auth.FirebaseAuth.instanceFor(app: tempApp);
      final cred = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (cred.user != null) {
        final newUser = User(
          id: cred.user!.uid,
          name: name,
          email: email,
          role: UserRole.staff,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          storeId: storeId,
          allowedFeatures: ['sales', 'holdOrders'], // Terbatas untuk staff
        );
        await _firestore.collection('users').doc(cred.user!.uid).set(newUser.toJson());
      }
      
      await tempApp.delete();
    } catch (e) {
      print('Error registering staff: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      if (currentUser != null) {
        await currentUser!.updatePassword(newPassword);
      } else {
        throw Exception("User not logged in");
      }
    } catch (e) {
      rethrow;
    }
  }
}
