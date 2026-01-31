import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../services/firebase_service.dart';

class BudgetController extends GetxController {
  // Observable variables
  final weeklyBudget = 0.0.obs;
  final monthlyBudget = 0.0.obs;
  final weeklySpent = 0.0.obs;
  final monthlySpent = 0.0.obs;
  final notificationsEnabled = false.obs;
  final isLoading = false.obs;

  // Alert flags
  final hasShownWeeklyAlert = false.obs;
  final hasShownMonthlyAlert = false.obs;

  // Track if this is the first load of the session
  bool _isFirstLoad = true;

  static const String _weeklyBudgetKey = 'weekly_budget';
  static const String _monthlyBudgetKey = 'monthly_budget';
  static const String _notificationsKey = 'notifications_enabled';

  @override
  void onInit() {
    super.onInit();
    loadBudgetSettings();
    _setupFirebaseSync();
  }

  /// Setup listeners for Firebase sync
  void _setupFirebaseSync() {
    if (Get.isRegistered<FirebaseService>()) {
      final firebaseService = Get.find<FirebaseService>();
      
      // Sync from Firebase when user logs in
      ever(firebaseService.currentUser, (User? user) {
        if (user != null) {
          syncSettingsFromFirebase();
        }
      });
      
      // Initial check if user is already logged in
      if (firebaseService.currentUser.value != null) {
        syncSettingsFromFirebase();
      }
    }
  }

  /// Sync settings to Firebase
  Future<void> syncSettingsToFirebase() async {
    try {
      if (!Get.isRegistered<FirebaseService>()) return;
      final firebaseService = Get.find<FirebaseService>();
      final user = firebaseService.currentUser.value;
      
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'settings': {
             'weeklyBudget': weeklyBudget.value,
             'monthlyBudget': monthlyBudget.value,
             'notificationsEnabled': notificationsEnabled.value,
             'lastUpdated': FieldValue.serverTimestamp(),
          }
        }, SetOptions(merge: true));
        print('✅ Settings synced to Firebase');
      }
    } catch (e) {
      print('❌ Error syncing settings to Firebase: $e');
    }
  }

  /// Sync settings FROM Firebase
  Future<void> syncSettingsFromFirebase() async {
     try {
      if (!Get.isRegistered<FirebaseService>()) return;
      final firebaseService = Get.find<FirebaseService>();
      final user = firebaseService.currentUser.value;
      
      if (user != null) {
        print('📥 Syncing settings from Firebase...');
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (doc.exists && doc.data() != null && doc.data()!['settings'] != null) {
           final settings = doc.data()!['settings'];
           
           bool changed = false;

           // Update local values if they exist in Firestore
           if (settings['weeklyBudget'] != null) {
             double val = (settings['weeklyBudget'] as num).toDouble();
             if (weeklyBudget.value != val) {
                weeklyBudget.value = val;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble(_weeklyBudgetKey, val);
                changed = true;
             }
           }
           
           if (settings['monthlyBudget'] != null) {
             double val = (settings['monthlyBudget'] as num).toDouble();
             if (monthlyBudget.value != val) {
                monthlyBudget.value = val;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble(_monthlyBudgetKey, val);
                changed = true;
             }
           }
           
           if (settings['notificationsEnabled'] != null) {
             bool val = settings['notificationsEnabled'] as bool;
             if (notificationsEnabled.value != val) {
                notificationsEnabled.value = val;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_notificationsKey, val);
             }
           }
           
           print('✅ Settings synced FROM Firebase (Updated: $changed)');
           
           if (changed) {
             // Reset alert flags if budget changed remotely
             hasShownWeeklyAlert.value = false;
             hasShownMonthlyAlert.value = false;
             _isFirstLoad = true;
             
             // Re-calculate spending logic
             calculateSpending(); 
           }
        }
      }
    } catch (e) {
      print('❌ Error syncing settings FROM Firebase: $e');
    }
  }

  /// Check if this is the first load (for showing alerts only once per session)
  bool get shouldShowAlerts => _isFirstLoad;

  /// Mark that initial alerts have been shown
  void markInitialAlertsShown() {
    _isFirstLoad = false;
  }

  /// Load budget settings from SharedPreferences
  Future<void> loadBudgetSettings() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();

      weeklyBudget.value = prefs.getDouble(_weeklyBudgetKey) ?? 0.0;
      monthlyBudget.value = prefs.getDouble(_monthlyBudgetKey) ?? 0.0;
      notificationsEnabled.value = prefs.getBool(_notificationsKey) ?? false;

      print('💰 BudgetController - loadBudgetSettings():');
      print('   Weekly Budget: ${weeklyBudget.value}');
      print('   Monthly Budget: ${monthlyBudget.value}');
      print('   Notifications Enabled: ${notificationsEnabled.value}');

      await calculateSpending();
    } catch (e) {
      print('Error loading budget settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Calculate weekly and monthly spending
  Future<void> calculateSpending() async {
    try {
      final expenses = await DatabaseHelper().getExpenses();
      final now = DateTime.now();

      // Calculate weekly spending (this week - from Monday to Sunday)
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      // Week ends on Sunday (7 days from Monday)
      final weekEnd = weekStart.add(const Duration(days: 7));

      weeklySpent.value = expenses
          .where((expense) {
            // Only count expenses (positive amounts), not income (negative amounts)
            if (expense.amount <= 0) return false;

            final expenseDate = DateTime(
              expense.date.year,
              expense.date.month,
              expense.date.day,
            );
            // Include expenses from Monday to Sunday of this week
            return (expenseDate.isAtSameMomentAs(weekStart) || expenseDate.isAfter(weekStart)) &&
                   expenseDate.isBefore(weekEnd);
          })
          .fold(0.0, (sum, expense) => sum + expense.amount);

      // Calculate monthly spending (this month)
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = monthStart.month == 12
          ? DateTime(monthStart.year + 1, 1, 1)
          : DateTime(monthStart.year, monthStart.month + 1, 1);

      monthlySpent.value = expenses
          .where((expense) {
            // Only count expenses (positive amounts), not income (negative amounts)
            if (expense.amount <= 0) return false;

            final expenseDate = DateTime(
              expense.date.year,
              expense.date.month,
              expense.date.day,
            );
            // Include expenses from 1st of this month to last day of this month
            return (expenseDate.isAtSameMomentAs(monthStart) || expenseDate.isAfter(monthStart)) &&
                   expenseDate.isBefore(nextMonthStart);
          })
          .fold(0.0, (sum, expense) => sum + expense.amount);

      print('📊 BudgetController - calculateSpending():');
      print('   Weekly Spent: ${weeklySpent.value} (Budget: ${weeklyBudget.value})');
      print('   Weekly Exceeded: $isWeeklyBudgetExceeded');
      print('   Monthly Spent: ${monthlySpent.value} (Budget: ${monthlyBudget.value})');
      print('   Monthly Exceeded: $isMonthlyBudgetExceeded');
    } catch (e) {
      print('Error calculating spending: $e');
    }
  }

  /// Update weekly budget
  Future<void> updateWeeklyBudget(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_weeklyBudgetKey, value);
      weeklyBudget.value = value;
      hasShownWeeklyAlert.value = false; // Reset alert flag
      _isFirstLoad = true; // Allow alerts to show again after budget update
      
      // Sync to Firebase
      syncSettingsToFirebase();
    } catch (e) {
      print('Error updating weekly budget: $e');
    }
  }

  /// Update monthly budget
  Future<void> updateMonthlyBudget(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_monthlyBudgetKey, value);
      monthlyBudget.value = value;
      hasShownMonthlyAlert.value = false; // Reset alert flag
      _isFirstLoad = true; // Allow alerts to show again after budget update
      
      // Sync to Firebase
      syncSettingsToFirebase();
    } catch (e) {
      print('Error updating monthly budget: $e');
    }
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, value);
      notificationsEnabled.value = value;
      
      // Sync to Firebase
      syncSettingsToFirebase();
    } catch (e) {
      print('Error updating notification settings: $e');
    }
  }

  /// Refresh all budget data
  Future<void> refresh() async {
    await loadBudgetSettings();
  }

  /// Check if weekly budget is exceeded
  bool get isWeeklyBudgetExceeded =>
      weeklyBudget.value > 0 && weeklySpent.value >= weeklyBudget.value;

  /// Check if monthly budget is exceeded
  bool get isMonthlyBudgetExceeded =>
      monthlyBudget.value > 0 && monthlySpent.value >= monthlyBudget.value;

  /// Get weekly over amount
  double get weeklyOverAmount => weeklySpent.value - weeklyBudget.value;

  /// Get monthly over amount
  double get monthlyOverAmount => monthlySpent.value - monthlyBudget.value;

  /// Reset alert flags (call when dialog is shown)
  void markWeeklyAlertShown() {
    hasShownWeeklyAlert.value = true;
  }

  void markMonthlyAlertShown() {
    hasShownMonthlyAlert.value = true;
  }
}
