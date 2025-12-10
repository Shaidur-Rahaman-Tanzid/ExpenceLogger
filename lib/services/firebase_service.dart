import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';
import '../models/expense.dart';
import '../models/vehicle.dart';
import '../controllers/personalization_controller.dart';
import '../controllers/expense_controller.dart';
import 'database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FirebaseService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSyncing = false.obs;
  final RxBool autoSyncEnabled = true.obs;
  final RxString lastSyncTime = ''.obs;
  final RxBool realtimeSyncEnabled = true.obs;

  // Real-time listener subscription
  StreamSubscription<QuerySnapshot>? _expensesListener;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      currentUser.value = user;
      
      // Start/stop real-time sync based on user login status AND email verification
      if (user != null && user.emailVerified && realtimeSyncEnabled.value) {
        startRealtimeSync();
      } else {
        stopRealtimeSync();
      }
    });
  }

  @override
  void onClose() {
    stopRealtimeSync();
    super.onClose();
  }

  // Start real-time sync listener
  void startRealtimeSync() {
    final user = currentUser.value;
    if (user == null) return;
    
    // Only sync if email is verified
    if (!user.emailVerified) {
      print('⚠️ Real-time sync disabled: Email not verified');
      return;
    }

    // Cancel existing listener if any
    stopRealtimeSync();

    print('Starting real-time sync for user: ${user.uid}');

    // Listen to Firestore changes
    _expensesListener = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .snapshots()
        .listen(
      (snapshot) async {
        if (snapshot.metadata.hasPendingWrites) {
          // Skip local writes to avoid duplicate syncs
          return;
        }

        print('Firestore snapshot received: ${snapshot.docChanges.length} changes');

        for (var change in snapshot.docChanges) {
          try {
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              // Add or update expense in local database
              final expense = Expense.fromMap(change.doc.data()!);
              
              // Check if expense already exists locally
              final existingExpenses = await _dbHelper.getExpenses();
              final exists = existingExpenses.any((e) => e.id == expense.id);

              if (exists) {
                await _dbHelper.updateExpense(expense);
                print('Updated expense: ${expense.id}');
              } else {
                await _dbHelper.insertExpense(expense);
                print('Added expense: ${expense.id}');
              }

              // Refresh ExpenseController
              try {
                final expenseController = Get.find<ExpenseController>();
                await expenseController.fetchExpenses();
              } catch (e) {
                print('Error refreshing ExpenseController: $e');
              }
            } else if (change.type == DocumentChangeType.removed) {
              // Delete expense from local database
              final firestoreDocId = change.doc.id;
              
              // Find the expense by Firestore doc id and delete by SQLite internal id
              final existingExpenses = await _dbHelper.getExpenses();
              
              // Firestore doc ID is stored in the 'id' field as string
              // We need to find the expense and use its SQLite id to delete
              for (var expense in existingExpenses) {
                // Compare Firestore ID (stored as string in expense.id field)
                if (expense.id.toString() == firestoreDocId) {
                  if (expense.id != null) {
                    await _dbHelper.deleteExpense(expense.id!);
                    print('Deleted expense: $firestoreDocId');

                    // Refresh ExpenseController
                    try {
                      final expenseController = Get.find<ExpenseController>();
                      await expenseController.fetchExpenses();
                    } catch (e) {
                      print('Error refreshing ExpenseController: $e');
                    }
                  }
                  break;
                }
              }
            }
          } catch (e) {
            print('Error processing Firestore change: $e');
          }
        }

        // Update last sync time
        lastSyncTime.value = DateTime.now().toString();
      },
      onError: (error) {
        print('Error in real-time sync: $error');
      },
    );
  }

  // Stop real-time sync listener
  void stopRealtimeSync() {
    _expensesListener?.cancel();
    _expensesListener = null;
    print('Stopped real-time sync');
  }

  // Toggle real-time sync
  void toggleRealtimeSync(bool enabled) {
    realtimeSyncEnabled.value = enabled;
    if (enabled && currentUser.value != null) {
      startRealtimeSync();
    } else {
      stopRealtimeSync();
    }
  }

  // Check internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      // First check if we have any network connection
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // Then verify actual internet access by making a real connection
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      // If lookup fails, we don't have internet
      return false;
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      isLoading.value = true;

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      // Create user
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Send email verification with error handling
      try {
        await userCredential.user?.sendEmailVerification();
        print('✅ Verification email sent successfully to: $email');
      } catch (emailError) {
        print('⚠️ Error sending verification email: $emailError');
        // Continue even if email sending fails
      }

      // Reload user to get updated display name
      await userCredential.user?.reload();
      
      // Update currentUser with fresh data
      currentUser.value = _auth.currentUser;

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSync': FieldValue.serverTimestamp(),
      });

      // Sync profile to PersonalizationController
      try {
        final personalizationController = Get.find<PersonalizationController>();
        await personalizationController.syncFromFirebaseUser(
          name: name,
          email: email,
        );
      } catch (e) {
        print('Error syncing to PersonalizationController: $e');
      }

      isLoading.value = false;
      return {
        'success': true, 
        'message': 'Account created! Please check your email to verify your account.',
        'user': currentUser.value,
        'needsVerification': true,
      };
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String message = 'An error occurred';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak (minimum 6 characters)';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for this email';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid';
      } else {
        // Show detailed error for debugging
        message = 'Firebase Auth Error: ${e.code}\n${e.message}';
      }
      return {'success': false, 'message': message, 'errorCode': e.code};
    } catch (e) {
      isLoading.value = false;
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'errorDetails': e.toString(),
      };
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final name = userData?['name'] ?? userCredential.user?.displayName ?? '';
        final userEmail = userData?['email'] ?? userCredential.user?.email ?? '';

        // Sync profile to PersonalizationController
        try {
          final personalizationController = Get.find<PersonalizationController>();
          await personalizationController.syncFromFirebaseUser(
            name: name,
            email: userEmail,
          );
        } catch (e) {
          print('Error syncing to PersonalizationController: $e');
        }
      }

      isLoading.value = false;
      return {'success': true, 'message': 'Signed in successfully'};
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found for this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid';
      } else if (e.code == 'user-disabled') {
        message = 'This user account has been disabled';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      isLoading.value = false;
      return {'success': false, 'message': e.toString()};
    }
  }

  // Check if current user's email is verified
  bool isEmailVerified() {
    return currentUser.value?.emailVerified ?? false;
  }

  // Resend verification email
  Future<Map<String, dynamic>> resendVerificationEmail() async {
    try {
      final user = currentUser.value;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      if (user.emailVerified) {
        return {'success': false, 'message': 'Email is already verified'};
      }

      await user.sendEmailVerification();
      print('✅ Verification email resent successfully to: ${user.email}');
      return {
        'success': true,
        'message': 'Verification email sent! Please check your inbox and spam folder.',
      };
    } catch (e) {
      print('⚠️ Error resending verification email: $e');
      return {
        'success': false,
        'message': 'Failed to send verification email: ${e.toString()}',
      };
    }
  }

  // Reload user to check verification status
  Future<void> reloadUser() async {
    try {
      await currentUser.value?.reload();
      currentUser.value = _auth.currentUser;
    } catch (e) {
      print('Error reloading user: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      isLoading.value = true;

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      await _auth.sendPasswordResetEmail(email: email);

      isLoading.value = false;
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found for this email';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      isLoading.value = false;
      return {'success': false, 'message': e.toString()};
    }
  }

  // Change password for current user
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;

      final user = currentUser.value;
      if (user == null) {
        return {'success': false, 'message': 'Please sign in first'};
      }

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        isLoading.value = false;
        if (e.code == 'wrong-password') {
          return {'success': false, 'message': 'Current password is incorrect'};
        }
        return {'success': false, 'message': 'Authentication failed: ${e.message}'};
      }

      // Change password
      await user.updatePassword(newPassword);

      isLoading.value = false;
      return {'success': true, 'message': 'Password changed successfully'};
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String message = 'An error occurred';
      if (e.code == 'weak-password') {
        message = 'The new password is too weak (minimum 6 characters)';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please sign out and sign in again before changing password';
      } else {
        message = 'Error: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      isLoading.value = false;
      return {'success': false, 'message': e.toString()};
    }
  }

  // Upload local data to cloud
  Future<Map<String, dynamic>> uploadToCloud() async {
    try {
      final user = currentUser.value;
      if (user == null) {
        return {'success': false, 'message': 'Please sign in first'};
      }

      // Check if email is verified
      if (!user.emailVerified) {
        return {
          'success': false, 
          'message': 'Please verify your email before syncing data'
        };
      }

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      isSyncing.value = true;

      // Get all local expenses
      final expenses = await _dbHelper.getExpenses();

      if (expenses.isEmpty) {
        isSyncing.value = false;
        return {
          'success': true,
          'message': 'No local expenses to upload',
          'count': 0,
        };
      }

      // Upload each expense
      final batch = _firestore.batch();
      for (var expense in expenses) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .doc(expense.id.toString());

        batch.set(docRef, expense.toMap(), SetOptions(merge: true));
      }

      await batch.commit();

      // Update or create user document with last sync time
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'lastSync': FieldValue.serverTimestamp(),
          'email': user.email,
          'displayName': user.displayName,
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error updating user document: $e');
      }

      lastSyncTime.value = DateTime.now().toString();
      isSyncing.value = false;

      return {
        'success': true,
        'message': 'Data uploaded successfully',
        'count': expenses.length,
      };
    } catch (e) {
      isSyncing.value = false;
      print('Upload error details: $e');
      return {'success': false, 'message': 'Upload error: ${e.toString()}'};
    }
  }

  // Download cloud data to local
  Future<Map<String, dynamic>> downloadFromCloud() async {
    try {
      final user = currentUser.value;
      if (user == null) {
        return {'success': false, 'message': 'Please sign in first'};
      }

      // Check if email is verified
      if (!user.emailVerified) {
        return {
          'success': false, 
          'message': 'Please verify your email before syncing data'
        };
      }

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      isSyncing.value = true;

      // Get all cloud expenses - handle if collection doesn't exist yet
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .get();
      } catch (e) {
        print('Error fetching cloud expenses: $e');
        isSyncing.value = false;
        return {
          'success': true,
          'message': 'No cloud data found to download',
          'count': 0,
        };
      }

      if (snapshot.docs.isEmpty) {
        isSyncing.value = false;
        return {
          'success': true,
          'message': 'No cloud expenses to download',
          'count': 0,
        };
      }

      // Clear local database
      // await _dbHelper.clearAllData(); // Optional: only if full restore

      // Insert cloud expenses to local
      int count = 0;
      for (var doc in snapshot.docs) {
        try {
          final expense = Expense.fromMap(doc.data() as Map<String, dynamic>);
          await _dbHelper.insertExpense(expense);
          count++;
        } catch (e) {
          print('Error downloading expense ${doc.id}: $e');
        }
      }

      lastSyncTime.value = DateTime.now().toString();
      isSyncing.value = false;

      return {
        'success': true,
        'message': 'Data downloaded successfully',
        'count': count,
      };
    } catch (e) {
      isSyncing.value = false;
      print('Download error details: $e');
      return {'success': false, 'message': 'Download error: ${e.toString()}'};
    }
  }

  // Sync data (two-way sync)
  Future<Map<String, dynamic>> syncData() async {
    try {
      final user = currentUser.value;
      if (user == null) {
        return {'success': false, 'message': 'Please sign in first'};
      }

      // Check if email is verified
      if (!user.emailVerified) {
        return {
          'success': false, 
          'message': 'Please verify your email before syncing data'
        };
      }

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      isSyncing.value = true;

      // Get local expenses
      final localExpenses = await _dbHelper.getExpenses();

      // Get cloud expenses - use try-catch in case collection doesn't exist yet
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .get();
      } catch (e) {
        print('Error fetching cloud expenses: $e');
        // If collection doesn't exist, create it by uploading local data
        snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .limit(0)
            .get();
      }

      // Create maps for easier comparison
      final localMap = {for (var e in localExpenses) e.id: e};
      final cloudMap = <int?, Expense>{};
      
      // Safely parse cloud expenses
      for (var doc in snapshot.docs) {
        try {
          final expense = Expense.fromMap(doc.data() as Map<String, dynamic>);
          cloudMap[expense.id] = expense;
        } catch (e) {
          print('Error parsing expense document ${doc.id}: $e');
        }
      }

      int uploaded = 0;
      int downloaded = 0;

      // Upload local expenses not in cloud
      final batch = _firestore.batch();
      for (var expense in localExpenses) {
        if (!cloudMap.containsKey(expense.id)) {
          final docRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('expenses')
              .doc(expense.id.toString());
          batch.set(docRef, expense.toMap());
          uploaded++;
        }
      }
      
      if (uploaded > 0) {
        await batch.commit();
      }

      // Download cloud expenses not in local
      for (var cloudExpense in cloudMap.values) {
        if (!localMap.containsKey(cloudExpense.id)) {
          await _dbHelper.insertExpense(cloudExpense);
          downloaded++;
        }
      }

      // Update or create user document with last sync time
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'lastSync': FieldValue.serverTimestamp(),
          'email': user.email,
          'displayName': user.displayName,
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error updating user document: $e');
      }

      lastSyncTime.value = DateTime.now().toString();
      isSyncing.value = false;

      return {
        'success': true,
        'message': 'Data synced successfully',
        'uploaded': uploaded,
        'downloaded': downloaded,
      };
    } catch (e) {
      isSyncing.value = false;
      print('Sync error details: $e');
      return {'success': false, 'message': 'Sync error: ${e.toString()}'};
    }
  }

  // Auto sync when expense is added/updated
  Future<void> autoSyncExpense(Expense expense) async {
    if (!autoSyncEnabled.value || currentUser.value == null) return;
    
    // Check if email is verified before auto-syncing
    if (!currentUser.value!.emailVerified) {
      print('⚠️ Auto-sync skipped: Email not verified');
      return;
    }
    
    if (!await hasInternetConnection()) return;

    try {
      final user = currentUser.value!;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expense.id.toString())
          .set(expense.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Auto sync failed: $e');
    }
  }

  // Delete expense from cloud
  Future<void> deleteExpenseFromCloud(int expenseId) async {
    if (currentUser.value == null) return;
    
    // Check if email is verified before deleting from cloud
    if (!currentUser.value!.emailVerified) {
      print('⚠️ Cloud delete skipped: Email not verified');
      return;
    }
    
    if (!await hasInternetConnection()) return;

    try {
      final user = currentUser.value!;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expenseId.toString())
          .delete();
    } catch (e) {
      print('Delete from cloud failed: $e');
    }
  }

  // Get cloud storage stats
  Future<Map<String, dynamic>> getCloudStats() async {
    try {
      final user = currentUser.value;
      if (user == null) {
        return {'totalExpenses': 0, 'lastSync': 'Never'};
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .get();

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final lastSync = userDoc.data()?['lastSync'];

      return {
        'totalExpenses': snapshot.docs.length,
        'lastSync': lastSync != null
            ? (lastSync as Timestamp).toDate().toString()
            : 'Never',
      };
    } catch (e) {
      return {'totalExpenses': 0, 'lastSync': 'Error'};
    }
  }

  // ======================== Vehicle Sync Methods ========================

  // Upload vehicles to Firebase
  Future<Map<String, dynamic>> uploadVehiclesToCloud() async {
    final user = currentUser.value;
    if (user == null) {
      return {'success': false, 'message': 'User not logged in', 'uploaded': 0};
    }

    try {
      isLoading.value = true;
      final vehicles = await _dbHelper.getVehicles();
      
      if (vehicles.isEmpty) {
        return {'success': true, 'message': 'No vehicles to upload', 'uploaded': 0};
      }

      final batch = _firestore.batch();
      final vehiclesCollection = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicles');

      for (var vehicle in vehicles) {
        final docId = vehicle.id.toString();
        final docRef = vehiclesCollection.doc(docId);
        batch.set(docRef, vehicle.toMap(), SetOptions(merge: true));
      }

      await batch.commit();

      // Update last sync time
      await _firestore.collection('users').doc(user.uid).set({
        'lastVehicleSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      lastSyncTime.value = DateTime.now().toString();

      return {
        'success': true,
        'message': 'Vehicles uploaded successfully',
        'uploaded': vehicles.length,
      };
    } catch (e) {
      print('Error uploading vehicles: $e');
      return {
        'success': false,
        'message': 'Failed to upload vehicles: $e',
        'uploaded': 0,
      };
    } finally {
      isLoading.value = false;
    }
  }

  // Download vehicles from Firebase
  Future<Map<String, dynamic>> downloadVehiclesFromCloud() async {
    final user = currentUser.value;
    if (user == null) {
      return {
        'success': false,
        'message': 'User not logged in',
        'downloaded': 0
      };
    }

    try {
      isLoading.value = true;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .get();

      if (snapshot.docs.isEmpty) {
        print('No vehicles found in cloud');
        return {
          'success': true,
          'message': 'No vehicles in cloud',
          'downloaded': 0
        };
      }

      int downloadedCount = 0;
      for (var doc in snapshot.docs) {
        try {
          final vehicleData = doc.data();
          final vehicle = Vehicle.fromMap(vehicleData);

          // Check if vehicle exists locally
          final existingVehicle = await _dbHelper.getVehicleById(vehicle.id!);

          if (existingVehicle == null) {
            // Insert new vehicle
            await _dbHelper.insertVehicle(vehicle);
          } else {
            // Update existing vehicle if cloud version is newer
            if (vehicle.updatedAt.isAfter(existingVehicle.updatedAt)) {
              await _dbHelper.updateVehicle(vehicle);
            }
          }
          downloadedCount++;
        } catch (e) {
          print('Error processing vehicle doc ${doc.id}: $e');
        }
      }

      lastSyncTime.value = DateTime.now().toString();

      return {
        'success': true,
        'message': 'Vehicles downloaded successfully',
        'downloaded': downloadedCount,
      };
    } catch (e) {
      print('Error downloading vehicles: $e');
      return {
        'success': false,
        'message': 'Failed to download vehicles: $e',
        'downloaded': 0,
      };
    } finally {
      isLoading.value = false;
    }
  }

  // Sync vehicles (bidirectional)
  Future<Map<String, dynamic>> syncVehicles() async {
    final user = currentUser.value;
    if (user == null) {
      return {
        'success': false,
        'message': 'User not logged in',
        'uploaded': 0,
        'downloaded': 0,
      };
    }

    try {
      isSyncing.value = true;

      // First, upload local vehicles to cloud
      final uploadResult = await uploadVehiclesToCloud();
      
      // Then, download cloud vehicles to local
      final downloadResult = await downloadVehiclesFromCloud();

      return {
        'success': uploadResult['success'] && downloadResult['success'],
        'message': 'Vehicle sync completed',
        'uploaded': uploadResult['uploaded'],
        'downloaded': downloadResult['downloaded'],
      };
    } catch (e) {
      print('Error syncing vehicles: $e');
      return {
        'success': false,
        'message': 'Vehicle sync failed: $e',
        'uploaded': 0,
        'downloaded': 0,
      };
    } finally {
      isSyncing.value = false;
    }
  }

  // Auto-sync single vehicle (called after add/update/delete)
  Future<void> autoSyncVehicle(Vehicle vehicle, {bool isDelete = false}) async {
    if (!autoSyncEnabled.value) return;

    final user = currentUser.value;
    if (user == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(vehicle.id.toString());

      if (isDelete) {
        await docRef.delete();
      } else {
        await docRef.set(vehicle.toMap(), SetOptions(merge: true));
      }

      // Update last sync time
      await _firestore.collection('users').doc(user.uid).set({
        'lastVehicleSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Vehicle auto-synced successfully');
    } catch (e) {
      print('❌ Error auto-syncing vehicle: $e');
    }
  }

  // Get vehicle cloud statistics
  Future<Map<String, dynamic>> getVehicleCloudStats() async {
    try {
      final user = currentUser.value;
      if (user == null) {
        return {'totalVehicles': 0, 'lastSync': 'Never'};
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .get();

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final lastSync = userDoc.data()?['lastVehicleSync'];

      return {
        'totalVehicles': snapshot.docs.length,
        'lastSync': lastSync != null
            ? (lastSync as Timestamp).toDate().toString()
            : 'Never',
      };
    } catch (e) {
      return {'totalVehicles': 0, 'lastSync': 'Error'};
    }
  }

  // ========== ODO Entry Sync Methods ==========

  // Auto-sync single ODO entry
  Future<void> autoSyncOdoEntry(int vehicleId, Map<String, dynamic> odoEntry, {bool isDelete = false}) async {
    if (!autoSyncEnabled.value) return;

    final user = currentUser.value;
    if (user == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(vehicleId.toString())
          .collection('odo_entries')
          .doc(odoEntry['id'].toString());

      if (isDelete) {
        await docRef.delete();
        print('✅ ODO entry deleted from Firebase');
      } else {
        await docRef.set(odoEntry, SetOptions(merge: true));
        print('✅ ODO entry auto-synced to Firebase');
      }

      // Update last sync time
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(vehicleId.toString())
          .set({
        'lastOdoSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Error auto-syncing ODO entry: $e');
    }
  }

  // Sync all ODO entries for a vehicle
  Future<Map<String, dynamic>> syncOdoEntries(int vehicleId, List<Map<String, dynamic>> entries) async {
    int uploaded = 0;
    int failed = 0;

    for (var entry in entries) {
      try {
        await autoSyncOdoEntry(vehicleId, entry);
        uploaded++;
      } catch (e) {
        failed++;
        print('Failed to sync ODO entry: $e');
      }
    }

    return {'uploaded': uploaded, 'failed': failed};
  }

  // ========== Fuel Entry Sync Methods ==========

  // Auto-sync single fuel entry
  Future<void> autoSyncFuelEntry(int vehicleId, Map<String, dynamic> fuelEntry, {bool isDelete = false}) async {
    if (!autoSyncEnabled.value) return;

    final user = currentUser.value;
    if (user == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(vehicleId.toString())
          .collection('fuel_entries')
          .doc(fuelEntry['id'].toString());

      if (isDelete) {
        await docRef.delete();
        print('✅ Fuel entry deleted from Firebase');
      } else {
        await docRef.set(fuelEntry, SetOptions(merge: true));
        print('✅ Fuel entry auto-synced to Firebase');
      }

      // Update last sync time
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(vehicleId.toString())
          .set({
        'lastFuelSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Error auto-syncing fuel entry: $e');
    }
  }

  // Sync all fuel entries for a vehicle
  Future<Map<String, dynamic>> syncFuelEntries(int vehicleId, List<Map<String, dynamic>> entries) async {
    int uploaded = 0;
    int failed = 0;

    for (var entry in entries) {
      try {
        await autoSyncFuelEntry(vehicleId, entry);
        uploaded++;
      } catch (e) {
        failed++;
        print('Failed to sync fuel entry: $e');
      }
    }

    return {'uploaded': uploaded, 'failed': failed};
  }
}
