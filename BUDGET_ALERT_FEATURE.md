# Budget Alert Notifications Feature

## Overview
Added alert notifications to the home screen that notify users when their weekly or monthly budgets are exceeded.

## Implementation Date
January 25, 2026

## Features

### 1. **Alert Dialog on App Launch**
- When the home screen loads, it checks if weekly or monthly budgets have been exceeded
- Shows a dialog alert with budget details
- Only shows once per session to avoid annoying users
- Provides quick navigation to Settings to review budget

### 2. **Visual Banner Alerts**
- Persistent banner at the top of the home screen when budget is exceeded
- Color-coded alerts:
  - **Orange** for weekly budget exceeded
  - **Red** for monthly budget exceeded
- Shows:
  - Budget type (Weekly/Monthly)
  - Amount over budget
  - Total spent vs budget limit
  - Quick link to Settings

### 3. **Respects User Preferences**
- Alerts only shown if notifications are enabled in Settings
- Users can toggle budget notifications on/off

## Technical Details

### Files Modified
- **`lib/screens/home_screen.dart`**
  - Added imports: `shared_preferences`, `database_helper`
  - Added state variables for budget tracking
  - Added `_loadBudgetSettings()` method to load budget from SharedPreferences
  - Added `_calculateSpending()` method to calculate weekly and monthly expenses
  - Added `_checkBudgetAlerts()` method to determine if alerts should be shown
  - Added `_showBudgetAlert()` method to display dialog alert
  - Added `_buildBudgetAlertBanner()` widget to create visual banner
  - Modified UI to show banners at top of home screen

### Budget Calculation Logic

**Weekly Budget:**
```dart
// Calculates spending from Monday of current week
final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
```

**Monthly Budget:**
```dart
// Calculates spending from 1st day of current month
final monthStart = DateTime(now.year, now.month, 1);
```

### Alert Trigger Conditions
1. Budget must be set (> 0)
2. Notifications must be enabled in Settings
3. Spending must be >= budget limit
4. Dialog alerts show only once per session using flags

## User Experience

### First Time Budget Exceeded
1. User opens the app
2. Dialog alert appears immediately with:
   - Icon and title (color-coded)
   - Exceeded amount message
   - Info box with suggestion
   - "Later" button to dismiss
   - "View Budget" button to go to Settings

### Continuous Visual Feedback
1. Banner appears at top of home screen
2. Shows real-time budget status
3. Tap eye icon to navigate to Settings
4. Banner remains until budget is adjusted or new week/month begins

## Example Scenarios

### Weekly Budget Exceeded
```
┌─────────────────────────────────────────┐
│ 📅 Weekly Budget Exceeded               │
│ Over by ₹100.00                         │
│ Spent: ₹600.00 / ₹500.00               │
│                                    👁️   │
└─────────────────────────────────────────┘
```

### Monthly Budget Exceeded
```
┌─────────────────────────────────────────┐
│ 📆 Monthly Budget Exceeded              │
│ Over by ₹500.00                         │
│ Spent: ₹2,500.00 / ₹2,000.00           │
│                                    👁️   │
└─────────────────────────────────────────┘
```

## Settings Integration
- Budget alerts work with existing Settings screen
- Budgets set in Settings > "Set Budgets" section
- Notification toggle in Settings > "Notifications" section
- Budget status cards show real-time spending progress

## Benefits
1. **Proactive Financial Management**: Users are immediately aware when overspending
2. **Non-Intrusive**: Can be disabled via Settings
3. **Visual Feedback**: Persistent banner provides constant reminder
4. **Quick Action**: Direct link to Settings for budget adjustment
5. **Session-Based Dialogs**: Prevents alert fatigue

## Testing Recommendations
1. Set a low weekly budget (e.g., ₹100)
2. Add expenses exceeding the budget
3. Close and reopen the app
4. Verify dialog alert appears
5. Check banner is visible on home screen
6. Toggle notifications off in Settings
7. Verify alerts no longer appear
8. Test with monthly budget as well

## Future Enhancements
- Push notifications when budget is about to be exceeded (80%, 90%, 100%)
- Daily spending summaries
- Budget recommendations based on spending patterns
- Category-specific budget alerts
- Weekly/Monthly spending trends

## Known Limitations
- Alerts only appear when home screen is loaded
- Dialog shows once per app session (not persisted across restarts)
- Requires manual budget setup in Settings
- No predictive warnings before budget is exceeded

## Related Files
- `lib/screens/settings_screen.dart` - Budget configuration
- `lib/services/database_helper.dart` - Expense data retrieval
- `lib/models/expense.dart` - Expense model

---

**Status**: ✅ Implemented and Ready for Testing
