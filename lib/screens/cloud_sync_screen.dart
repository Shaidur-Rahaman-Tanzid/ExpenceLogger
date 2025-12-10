import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/firebase_service.dart';
import '../controllers/expense_controller.dart';
import 'firebase_debug_screen.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({Key? key}) : super(key: key);

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen>
    with SingleTickerProviderStateMixin {
  FirebaseService? _firebaseService;
  late TabController _tabController;

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  bool _signInPasswordVisible = false;
  bool _signUpPasswordVisible = false;
  bool _signUpConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Try to get FirebaseService, but handle if it's not available
    try {
      _firebaseService = Get.find<FirebaseService>();
    } catch (e) {
      print('FirebaseService not available: $e');
      _firebaseService = null;
    }
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_firebaseService == null) return;
    
    if (_signInEmailController.text.isEmpty ||
        _signInPasswordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final result = await _firebaseService!.signIn(
      email: _signInEmailController.text.trim(),
      password: _signInPasswordController.text,
    );

    if (result['success']) {
      Get.snackbar(
        'Success',
        result['message'],
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Show sync options dialog
      Get.dialog(
        AlertDialog(
          title: const Text('Restore Data?'),
          content: const Text(
            'Would you like to sync your data from cloud?\n\n'
            '• Sync Now: Merge cloud and local data\n'
            '• Download: Replace local with cloud data\n'
            '• Skip: Continue without syncing',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _handleDownload();
              },
              child: const Text('Download'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _handleSync();
              },
              child: const Text('Sync Now'),
            ),
          ],
        ),
      );
    } else {
      // Show detailed error
      Get.dialog(
        AlertDialog(
          title: const Text('Sign In Error'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['message'] ?? 'Unknown error occurred'),
                if (result['errorCode'] != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Error Code: ${result['errorCode']}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _handleSignUp() async {
    if (_signUpNameController.text.isEmpty ||
        _signUpEmailController.text.isEmpty ||
        _signUpPasswordController.text.isEmpty ||
        _signUpConfirmPasswordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_signUpPasswordController.text !=
        _signUpConfirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_signUpPasswordController.text.length < 6) {
      Get.snackbar(
        'Error',
        'Password must be at least 6 characters',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final result = await _firebaseService!.signUp(
      email: _signUpEmailController.text.trim(),
      password: _signUpPasswordController.text,
      name: _signUpNameController.text.trim(),
    );

    if (result['success']) {
      // Clear the form fields
      _signUpNameController.clear();
      _signUpEmailController.clear();
      _signUpPasswordController.clear();
      _signUpConfirmPasswordController.clear();

      // Refresh the currentUser to ensure profile is populated
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Show email verification message
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.email, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('Verify Your Email'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account created successfully!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(result['message']),
              const SizedBox(height: 12),
              const Text(
                'Please check your email inbox and click the verification link to activate your account.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${_firebaseService!.currentUser.value?.email}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can sync your data after verifying your email',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                // Don't show upload dialog - user needs to verify email first
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Show detailed error in dialog for debugging
      Get.dialog(
        AlertDialog(
          title: const Text('Sign Up Error'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['message'] ?? 'Unknown error occurred'),
                if (result['errorCode'] != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Error Code:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    result['errorCode'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                if (result['errorDetails'] != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Technical Details:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result['errorDetails'],
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Common Solutions:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Check your internet connection\n'
                  '• Verify Firebase is enabled in Console\n'
                  '• Check if Authentication is enabled\n'
                  '• Make sure google-services.json is correct',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Close')),
            ElevatedButton(
              onPressed: () {
                Get.back();
                // Copy error to clipboard (optional)
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleSync() async {
    final result = await _firebaseService!.syncData();

    if (result['success']) {
      // Refresh ExpenseController to show updated data
      try {
        final expenseController = Get.find<ExpenseController>();
        await expenseController.fetchExpenses();
      } catch (e) {
        print('Error refreshing expenses: $e');
      }

      Get.snackbar(
        'Success',
        '${result['message']}\nUploaded: ${result['uploaded']}, Downloaded: ${result['downloaded']}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'Sync Error',
        result['message'],
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleUpload() async {
    final result = await _firebaseService!.uploadToCloud();

    if (result['success']) {
      Get.snackbar(
        'Success',
        '${result['message']}\n${result['count']} expenses uploaded',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'],
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleDownload() async {
    // Show confirmation dialog
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Download from Cloud'),
        content: const Text(
          'This will replace all local data with cloud data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _firebaseService!.downloadFromCloud();

    if (result['success']) {
      // Refresh ExpenseController to show updated data
      try {
        final expenseController = Get.find<ExpenseController>();
        await expenseController.fetchExpenses();
      } catch (e) {
        print('Error refreshing expenses: $e');
      }

      Get.snackbar(
        'Success',
        '${result['message']}\n${result['count']} expenses downloaded',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'],
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleSignOut() async {
    await _firebaseService!.signOut();
    Get.snackbar(
      'Success',
      'Signed out successfully',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backup & Sync'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Firebase Debug Info',
            onPressed: () {
              Get.to(() => const FirebaseDebugScreen());
            },
          ),
        ],
      ),
      body: _firebaseService == null
          ? _buildFirebaseUnavailableMessage()
          : Obx(() {
              final user = _firebaseService!.currentUser.value;

              if (user == null) {
                // Show login/signup screen
                return Column(
                  children: [
                    Container(
                      color: Theme.of(context).primaryColor,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.white,
                        tabs: const [
                          Tab(text: 'Sign In'),
                          Tab(text: 'Sign Up'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [_buildSignInTab(), _buildSignUpTab()],
                      ),
                    ),
                  ],
                );
              } else {
                // Show sync options
                return _buildSyncOptions(user);
              }
            }),
    );
  }

  Widget _buildFirebaseUnavailableMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Cloud Sync Not Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Firebase is not configured for this platform (iOS).\n\n'
              'To enable cloud sync, the app needs proper Firebase configuration.\n\n'
              'Please contact the app developer for Firebase setup.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.cloud, size: 80, color: Theme.of(context).primaryColor),
          const SizedBox(height: 20),
          const Text(
            'Sign in to sync your data',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _signInEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signInPasswordController,
            obscureText: !_signInPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _signInPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _signInPasswordVisible = !_signInPasswordVisible;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => ElevatedButton(
              onPressed: _firebaseService!.isLoading.value
                  ? null
                  : _handleSignIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _firebaseService!.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.person_add,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'Create an account',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _signUpNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signUpEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signUpPasswordController,
            obscureText: !_signUpPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _signUpPasswordVisible = !_signUpPasswordVisible;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signUpConfirmPasswordController,
            obscureText: !_signUpConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _signUpConfirmPasswordVisible =
                        !_signUpConfirmPasswordVisible;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => ElevatedButton(
              onPressed: _firebaseService!.isLoading.value
                  ? null
                  : _handleSignUp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _firebaseService!.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncOptions(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  // Email verification status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: user.emailVerified 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: user.emailVerified ? Colors.green : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.emailVerified 
                              ? Icons.verified_user 
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: user.emailVerified ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.emailVerified 
                              ? 'Email Verified' 
                              : 'Email Not Verified',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: user.emailVerified ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Resend verification button
                  if (!user.emailVerified) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final result = await _firebaseService!.resendVerificationEmail();
                            if (mounted) {
                              Get.snackbar(
                                result['success'] ? 'Success' : 'Error',
                                result['message'],
                                backgroundColor: result['success']
                                    ? Colors.green.withOpacity(0.8)
                                    : Colors.red.withOpacity(0.8),
                                colorText: Colors.white,
                                duration: const Duration(seconds: 3),
                              );
                            }
                          },
                          icon: const Icon(Icons.email, size: 18),
                          label: const Text('Resend Verification'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            await _firebaseService!.reloadUser();
                            if (mounted) {
                              final isVerified = _firebaseService!.isEmailVerified();
                              Get.snackbar(
                                isVerified ? 'Verified!' : 'Not Yet Verified',
                                isVerified 
                                    ? 'Your email has been verified successfully!'
                                    : 'Please check your email and click the verification link.',
                                backgroundColor: isVerified
                                    ? Colors.green.withOpacity(0.8)
                                    : Colors.orange.withOpacity(0.8),
                                colorText: Colors.white,
                                duration: const Duration(seconds: 3),
                              );
                              setState(() {}); // Refresh UI
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Check Status'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Obx(
                    () => Text(
                      'Last Sync: ${_firebaseService!.lastSyncTime.value.isEmpty ? "Never" : _firebaseService!.lastSyncTime.value.split('.')[0]}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Email verification warning (if not verified)
          if (!user.emailVerified) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Verification Required',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please verify your email to enable cloud sync features.',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Auto sync toggle
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto Sync'),
                  subtitle: Text(
                    user.emailVerified
                        ? 'Automatically sync when you add/edit expenses'
                        : 'Verify your email to enable auto sync',
                  ),
                  value: _firebaseService!.autoSyncEnabled.value && user.emailVerified,
                  onChanged: user.emailVerified
                      ? (value) {
                          _firebaseService!.autoSyncEnabled.value = value;
                        }
                      : null,
                ),
                const Divider(height: 1),
                Obx(
                  () => SwitchListTile(
                    title: const Text('Real-time Sync'),
                    subtitle: Text(
                      user.emailVerified
                          ? 'Automatically sync changes from other devices'
                          : 'Verify your email to enable real-time sync',
                    ),
                    value: _firebaseService!.realtimeSyncEnabled.value && user.emailVerified,
                    onChanged: user.emailVerified
                        ? (value) {
                            _firebaseService!.toggleRealtimeSync(value);

                            Get.snackbar(
                              value ? 'Enabled' : 'Disabled',
                              value
                                  ? 'Real-time sync is now active. Changes from other devices will appear instantly.'
                                  : 'Real-time sync is disabled. Use manual sync to update.',
                              backgroundColor: value ? Colors.green : Colors.orange,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 3),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sync actions
          const Text(
            'Sync Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Obx(
            () => _SyncButton(
              icon: Icons.sync,
              title: 'Sync Now',
              subtitle: user.emailVerified 
                  ? 'Two-way sync between local and cloud'
                  : 'Email verification required',
              onPressed: (_firebaseService!.isSyncing.value || !user.emailVerified) 
                  ? null 
                  : _handleSync,
              color: Colors.blue,
            ),
          ),

          Obx(
            () => _SyncButton(
              icon: Icons.cloud_upload,
              title: 'Upload to Cloud',
              subtitle: user.emailVerified
                  ? 'Upload all local data to cloud'
                  : 'Email verification required',
              onPressed: (_firebaseService!.isSyncing.value || !user.emailVerified)
                  ? null
                  : _handleUpload,
              color: Colors.green,
            ),
          ),

          Obx(
            () => _SyncButton(
              icon: Icons.cloud_download,
              title: 'Download from Cloud',
              subtitle: user.emailVerified
                  ? 'Replace local data with cloud data'
                  : 'Email verification required',
              onPressed: (_firebaseService!.isSyncing.value || !user.emailVerified)
                  ? null
                  : _handleDownload,
              color: Colors.orange,
            ),
          ),

          const SizedBox(height: 20),

          // Cloud stats
          FutureBuilder<Map<String, dynamic>>(
            future: _firebaseService!.getCloudStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final stats = snapshot.data!;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cloud Storage Stats',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Expenses:'),
                          Text(
                            '${stats['totalExpenses']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Last Cloud Sync:'),
                          Flexible(
                            child: Text(
                              stats['lastSync'].toString().split('.')[0],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Sign out button
          OutlinedButton.icon(
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
            ),
          ),

          const SizedBox(height: 20),

          // Syncing indicator
          Obx(
            () => _firebaseService!.isSyncing.value
                ? const Card(
                    color: Colors.blue,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Syncing...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive password reset link'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final result = await _firebaseService!.resetPassword(
                emailController.text.trim(),
              );

              if (result['success']) {
                Get.snackbar(
                  'Success',
                  result['message'],
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  result['message'],
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;
  final Color color;

  const _SyncButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onPressed,
        enabled: onPressed != null,
      ),
    );
  }
}
