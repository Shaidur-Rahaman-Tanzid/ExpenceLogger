import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../controllers/expense_controller.dart';
import '../controllers/personalization_controller.dart';
import '../screens/budget_screen.dart';
import '../screens/cloud_sync_screen.dart';

class AppDrawer extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const AppDrawer({
    super.key,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
    final personalizationController = Get.find<PersonalizationController>();

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                              Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.4),
                            ]
                          : [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User Profile Section
                      Obx(() {
                        final hasImage = personalizationController
                            .profileImagePath.value.isNotEmpty;

                        return InkWell(
                          onTap: () {
                            Get.toNamed('/profile');
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: hasImage
                                      ? Image.file(
                                          File(personalizationController
                                              .profileImagePath.value),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                              child: Text(
                                                personalizationController
                                                    .getUserInitials(),
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Center(
                                          child: Text(
                                            personalizationController
                                                .getUserInitials(),
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      personalizationController
                                              .userName.value.isNotEmpty
                                          ? personalizationController
                                              .userName.value
                                          : 'Guest User',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      personalizationController
                                              .userEmail.value.isNotEmpty
                                          ? personalizationController
                                              .userEmail.value
                                          : 'Tap to set up profile',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      // App Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'app_name'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'app_tagline'.tr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _DrawerMenuItem(
                  icon: Icons.calendar_month,
                  title: 'summary'.tr,
                  subtitle: 'view_summary'.tr,
                  onTap: () async {
                    Navigator.pop(context);
                    await Get.toNamed('/monthly-summary');
                    scaffoldKey.currentState?.openDrawer();
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.bar_chart,
                  title: 'analytics'.tr,
                  subtitle: 'view_spending_analytics'.tr,
                  onTap: () async {
                    Navigator.pop(context);
                    await Get.toNamed('/analytics');
                    scaffoldKey.currentState?.openDrawer();
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.history,
                  title: 'expense_history'.tr,
                  subtitle: 'view_all_expenses'.tr,
                  onTap: () async {
                    Navigator.pop(context);
                    await Get.toNamed('/history');
                    scaffoldKey.currentState?.openDrawer();
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.trending_up,
                  title: 'income_history'.tr,
                  subtitle: 'view_all_incomes'.tr,
                  onTap: () async {
                    Navigator.pop(context);
                    await Get.toNamed('/income-history');
                    scaffoldKey.currentState?.openDrawer();
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.account_balance_wallet,
                  title: 'budgets_goals'.tr,
                  subtitle: 'manage_budgets_savings'.tr,
                  onTap: () async {
                    Navigator.pop(context);
                    await Get.to(() => const BudgetScreen());
                    scaffoldKey.currentState?.openDrawer();
                  },
                ),
                const Divider(),
                _DrawerMenuItem(
                  icon: Icons.cloud,
                  title: 'Cloud Backup & Sync',
                  subtitle: 'Backup and sync your data',
                  onTap: () async {
                    Navigator.pop(context);
                    await Get.to(() => const CloudSyncScreen());
                    scaffoldKey.currentState?.openDrawer();
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.settings,
                  title: 'settings'.tr,
                  subtitle: 'app_settings_budget'.tr,
                  onTap: () async {
                    Navigator.pop(context);
                    await Get.toNamed('/settings');
                    controller.fetchExpenses();
                    scaffoldKey.currentState?.openDrawer();
                  },
                ),
                const Divider(),
              ],
            ),
          ),
          // Version at bottom - outside ListView
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper widget for drawer menu items
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
