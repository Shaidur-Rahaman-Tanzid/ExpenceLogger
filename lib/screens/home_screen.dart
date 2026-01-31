import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/expense_controller.dart';
import '../controllers/personalization_controller.dart';
import '../controllers/budget_controller.dart';
import '../services/currency_service.dart';
import '../widgets/app_drawer.dart';
import 'expense_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // GlobalKey to access Scaffold state
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Get or create BudgetController (singleton pattern)
  late final BudgetController budgetController;
  bool _isFirstLoad = false;

  @override
  void initState() {
    super.initState();

    // Check if BudgetController already exists
    try {
      budgetController = Get.find<BudgetController>();
      _isFirstLoad = false; // Controller exists, not first load
    } catch (e) {
      // Controller doesn't exist, create it
      budgetController = Get.put(BudgetController());
      _isFirstLoad = true; // First time creating controller
    }

    // Only check alerts on first load
    if (_isFirstLoad) {
      _checkBudgetAlerts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkBudgetAlerts() {
    // Only show alerts if this is the first load and controller says we should show them
    if (!budgetController.shouldShowAlerts) return;

    // Delay to ensure data is loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Mark that we've shown initial alerts
      budgetController.markInitialAlertsShown();

      // Check weekly budget
      if (budgetController.notificationsEnabled.value &&
          budgetController.isWeeklyBudgetExceeded &&
          !budgetController.hasShownWeeklyAlert.value) {
        budgetController.markWeeklyAlertShown();
        _showBudgetAlert(
          'Weekly Budget Exceeded!',
          'You have spent ${_formatCurrency(budgetController.weeklySpent.value)} out of your ${_formatCurrency(budgetController.weeklyBudget.value)} weekly budget.',
          Icons.calendar_view_week,
          Colors.orange,
        );
      }

      // Check monthly budget
      if (budgetController.notificationsEnabled.value &&
          budgetController.isMonthlyBudgetExceeded &&
          !budgetController.hasShownMonthlyAlert.value) {
        budgetController.markMonthlyAlertShown();
        _showBudgetAlert(
          'Monthly Budget Exceeded!',
          'You have spent ${_formatCurrency(budgetController.monthlySpent.value)} out of your ${_formatCurrency(budgetController.monthlyBudget.value)} monthly budget.',
          Icons.calendar_month,
          Colors.red,
        );
      }
    });
  }

  void _showBudgetAlert(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Consider reviewing your expenses in the Settings page.',
                        style: TextStyle(
                          fontSize: 13,
                          color: color.withOpacity(0.8),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.toNamed('/settings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: const Text('View Budget'),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    final currencyService = CurrencyService.instance;
    return currencyService.formatCurrency(amount);
  }

  String _getCategoryName(String category) {
    // Return translated category name
    return category.tr;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt_long;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'bills':
        return Colors.red;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'healthcare':
        return Colors.green;
      case 'education':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBudgetAlertBanner(
    String title,
    double spent,
    double budget,
    IconData icon,
    Color color,
  ) {
    final overAmount = spent - budget;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Over by ${_formatCurrency(overAmount)}',
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 14),
                ),
                Text(
                  'Spent: ${_formatCurrency(spent)} / ${_formatCurrency(budget)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.visibility, color: color),
            onPressed: () => Get.toNamed('/settings'),
            tooltip: 'View Budget Details',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the ExpenseController instance
    final ExpenseController controller = Get.find<ExpenseController>();
    final personalizationController = Get.find<PersonalizationController>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('app_name'.tr),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Theme Toggle Button
          Obx(() {
            final isDark = personalizationController.isDarkMode.value;
            return IconButton(
              onPressed: () {
                personalizationController.toggleDarkMode(!isDark);
              },
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 24),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            );
          }),
        ],
      ),
      drawer: AppDrawer(scaffoldKey: _scaffoldKey),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get today's expenses reactively
        final todayExpenses = controller.getTodayExpenses();

        // Filter expenses based on search query
        final filteredExpenses = todayExpenses.where((expense) {
          if (_searchQuery.isEmpty) return true;

          final query = _searchQuery.toLowerCase();
          return expense.title.toLowerCase().contains(query) ||
              expense.category.toLowerCase().contains(query) ||
              (expense.note?.toLowerCase().contains(query) ?? false) ||
              expense.amount.toString().contains(query);
        }).toList();

        final todayTotal = controller.totalToday.value;

        return Column(
          children: [
            // Budget Alert Banners - Using Obx for reactive updates
            Obx(() {
              if (budgetController.notificationsEnabled.value &&
                  budgetController.isWeeklyBudgetExceeded) {
                return _buildBudgetAlertBanner(
                  'Weekly Budget Exceeded',
                  budgetController.weeklySpent.value,
                  budgetController.weeklyBudget.value,
                  Icons.calendar_view_week,
                  Colors.orange,
                );
              }
              return const SizedBox.shrink();
            }),
            Obx(() {
              if (budgetController.notificationsEnabled.value &&
                  budgetController.isMonthlyBudgetExceeded) {
                return _buildBudgetAlertBanner(
                  'Monthly Budget Exceeded',
                  budgetController.monthlySpent.value,
                  budgetController.monthlyBudget.value,
                  Icons.calendar_month,
                  Colors.red,
                );
              }
              return const SizedBox.shrink();
            }),

            // Today's Total Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.4),
                        ]
                      : [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'todays_expenses'.tr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(todayTotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            if (todayExpenses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                  ),
                ),
              ),
            if (todayExpenses.isNotEmpty) const SizedBox(height: 16),

            // Expenses List
            Expanded(
              child: filteredExpenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'no_expenses_today'.tr
                                : 'No expenses found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'tap_to_add_first_expense'.tr
                                : 'Try different search terms',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];
                        return Dismissible(
                          key: Key(expense.id.toString()),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('delete_expense'.tr),
                                  content: Text(
                                    'Are you sure you want to delete "${expense.title}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text('cancel'.tr),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: Text('delete'.tr),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) async {
                            await controller.deleteExpense(expense.id!);
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              onTap: () async {
                                // Navigate and wait for result
                                await Get.to(
                                  () => ExpenseDetailScreen(expense: expense),
                                  transition: Transition.rightToLeft,
                                );
                                
                                // ExpenseController has already been updated by edit/delete operations
                                // The Obx widget will automatically refresh the UI
                              },
                              leading: CircleAvatar(
                                backgroundColor: _getCategoryColor(
                                  expense.category,
                                ).withOpacity(0.2),
                                child: Icon(
                                  _getCategoryIcon(expense.category),
                                  color: _getCategoryColor(expense.category),
                                ),
                              ),
                              title: Text(
                                expense.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getCategoryName(expense.category),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(expense.date),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (expense.note != null &&
                                      expense.note!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.note,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            expense.note!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (expense.voiceNotePath != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.mic,
                                          size: 14,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'voice_note_attached'.tr,
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (expense.imagePath != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.photo,
                                          size: 14,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'image_attached'.tr,
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.touch_app,
                                        size: 12,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'tap_for_details'.tr,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Text(
                                _formatCurrency(expense.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-expense'),
        tooltip: 'add_expense'.tr,
        child: const Icon(Icons.add),
      ),
    );
  }
}
