// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Sign up with email and password
  // Sign up with email and password
Future<UserCredential?> signUpWithEmail({
  required String email,
  required String password,
  required String name,
}) async {
  try {
    print('🔵 Starting sign up process for: $email');
    print('🔵 Firebase Auth instance: ${_auth.app.name}');
    
    // Create user account
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    print('✅ User account created: ${userCredential.user?.uid}');

    // Update display name
    await userCredential.user?.updateDisplayName(name);
    print('✅ Display name updated: $name');

    // Create user document in Firestore
    if (userCredential.user != null) {
      print('🔵 Creating user document in Firestore...');
      await _createUserDocument(
        userId: userCredential.user!.uid,
        email: email,
        name: name,
      );
      print('✅ User document created successfully');
    }

    print('✅ Sign up completed successfully!');
    return userCredential;
  } on FirebaseAuthException catch (e) {
    print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
    print('❌ Stack trace: ${e.stackTrace}');
    throw _handleAuthException(e);
  } on FirebaseException catch (e) {
    print('❌ FirebaseException: ${e.code} - ${e.message}');
    print('❌ Plugin: ${e.plugin}');
    throw 'Firebase error: ${e.message}';
  } catch (e, stackTrace) {
    print('❌ Unexpected error during sign up: $e');
    print('Stack trace: $stackTrace');
    throw 'An unexpected error occurred. Please try again. Error: $e';
  }
}

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 Starting sign in process for: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Sign in successful: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      print('❌ Unexpected error during sign in: $e');
      print('Stack trace: $stackTrace');
      throw 'An unexpected error occurred. Please try again. Error: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('🔵 Signing out user: ${currentUser?.email}');
      await _auth.signOut();
      print('✅ Sign out successful');
    } catch (e, stackTrace) {
      print('❌ Error during sign out: $e');
      print('Stack trace: $stackTrace');
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('🔵 Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Password reset email sent');
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      print('❌ Error sending password reset email: $e');
      print('Stack trace: $stackTrace');
      throw 'Failed to send reset email. Please try again.';
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      print('🔵 Creating Firestore document for user: $userId');
      
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'name': name,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ User document created in Firestore');

      // Initialize user stats
      print('🔵 Initializing user stats...');
      await _initializeUserStats(userId);
      print('✅ User stats initialized');
    } catch (e, stackTrace) {
      print('❌ Error creating user document: $e');
      print('Stack trace: $stackTrace');
      // Don't throw here - let the sign up continue even if Firestore fails
      // The user account is already created
    }
  }

  // Initialize user statistics
  Future<void> _initializeUserStats(String userId) async {
    try {
      final periods = ['week', 'month', 'all'];
      
      for (var period in periods) {
        print('🔵 Creating stats for period: $period');
        await _firestore
            .collection('user_stats')
            .doc(userId)
            .collection('periods')
            .doc(period)
            .set({
          'total_predictions': 0,
          'win_rate': 0.0,
          'won': 0,
          'lost': 0,
          'avg_odds': 0.0,
          'profit': '+0.0',
          'league_performance': [],
          'recent_results': [],
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      print('✅ All stats periods created');
    } catch (e, stackTrace) {
      print('❌ Error initializing user stats: $e');
      print('Stack trace: $stackTrace');
      // Don't throw - stats can be initialized later
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) {
        print('⚠️ No current user found');
        return null;
      }

      print('🔵 Fetching user data for: ${currentUser!.uid}');
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) {
        print('⚠️ User document does not exist');
        return null;
      }

      print('✅ User data fetched successfully');
      return doc.data();
    } catch (e, stackTrace) {
      print('❌ Error getting user data: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? email,
  }) async {
    try {
      if (currentUser == null) {
        print('⚠️ No current user to update');
        return;
      }

      print('🔵 Updating user profile for: ${currentUser!.uid}');

      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        await currentUser!.updateDisplayName(name);
        updates['name'] = name;
        print('✅ Display name updated: $name');
      }

      if (email != null) {
        await currentUser!.updateEmail(email);
        updates['email'] = email;
        print('✅ Email updated: $email');
      }

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updates);
      
      print('✅ User profile updated in Firestore');
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      print('❌ Error updating profile: $e');
      print('Stack trace: $stackTrace');
      throw 'Failed to update profile. Please try again.';
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) {
        print('⚠️ No current user to delete');
        return;
      }

      final userId = currentUser!.uid;
      print('🔵 Deleting account for: $userId');

      // Delete user document
      await _firestore.collection('users').doc(userId).delete();
      print('✅ User document deleted');

      // Delete user stats
      await _deleteUserStats(userId);
      print('✅ User stats deleted');

      // Delete authentication account
      await currentUser!.delete();
      print('✅ Auth account deleted');
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      print('❌ Error deleting account: $e');
      print('Stack trace: $stackTrace');
      throw 'Failed to delete account. Please try again.';
    }
  }

  // Delete user statistics
  Future<void> _deleteUserStats(String userId) async {
    try {
      final periods = ['week', 'month', 'all'];
      
      for (var period in periods) {
        await _firestore
            .collection('user_stats')
            .doc(userId)
            .collection('periods')
            .doc(period)
            .delete();
      }

      await _firestore.collection('user_stats').doc(userId).delete();
    } catch (e, stackTrace) {
      print('❌ Error deleting user stats: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      default:
        return 'Authentication error: ${e.message ?? "Unknown error"}';
    }
  }
}