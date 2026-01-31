# Weekly Spent Value Fix

## Issue
The weekly spent value was showing incorrect amounts because the calculation was including all expenses from Monday of the current week all the way through the entire expense history, instead of just the current week.

## Root Cause
In `budget_controller.dart`, the filter condition was:
```dart
// WRONG - includes all expenses from Monday onwards through all history
return !expenseDate.isBefore(weekStart);
```

This only checked that expenses were **not before** Monday, but didn't check that they were **before** the end of the week. This meant expenses from previous weeks with the same day-of-week were being included.

## Solution
Fixed both `budget_controller.dart` and `settings_screen.dart` to use a proper week range calculation:

### Budget Controller Fix
**File:** `/lib/controllers/budget_controller.dart`

Changed the weekly spending calculation to:
```dart
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
```

**Also fixed monthly calculation** to properly handle all days of the current month:
```dart
final nextMonthStart = monthStart.month == 12
    ? DateTime(monthStart.year + 1, 1, 1)
    : DateTime(monthStart.year, monthStart.month + 1, 1);

monthlySpent.value = expenses
    .where((expense) {
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
```

### Settings Screen Fix
**File:** `/lib/screens/settings_screen.dart`

Updated the `_calculateSpending()` method to use the same consistent logic for calculating weekly and monthly ranges.

## Changes Summary
| Aspect | Before | After |
|--------|--------|-------|
| Week Range | Monday onwards (all history) | Monday to Sunday (current week only) |
| Month Range | 1st onwards (all history) | 1st to last day (current month only) |
| Accuracy | ❌ Shows accumulated sum from past | ✅ Shows only current week/month |

## Testing
The fix ensures that:
1. Weekly budget alerts only count expenses from the current week (Mon-Sun)
2. Monthly budget alerts only count expenses from the current month (1st-last day)
3. Budget displays show accurate spending information
4. Debug output in settings screen provides correct expense counts

## Files Modified
- `/lib/controllers/budget_controller.dart` - Main budget calculation logic
- `/lib/screens/settings_screen.dart` - Settings screen calculation logic (consistency)

