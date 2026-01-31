# Analytics Chart Zero Division Fix

## Issue
The analytics screen was crashing with the error:
```
FlGridData.horizontalInterval couldn't be zero
Failed assertion: line 562 pos 11: 'horizontalInterval != 0'
```

## Root Cause
When all expenses in a period were 0 or there were no expenses with non-zero values, the `maxY` variable would be calculated as 0. This caused the `horizontalInterval: maxY / 5` to evaluate to 0, which violated the fl_chart library's assertion that intervals cannot be zero.

## Solution
Added a safety check in all three chart methods to ensure `maxY` is never 0:

### Fixed Methods
1. **`_buildBarChart()`** - Weekly bar chart
2. **`_buildDailyBarChart()`** - Daily bar chart  
3. **`_buildMonthlyBarChart()`** - Monthly bar chart

### Code Changes
```dart
// Before
final maxY = dailyTotals.values.isEmpty
    ? 100.0
    : dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2;

// Used directly in chart
maxY: maxY,
horizontalInterval: maxY / 5,
```

```dart
// After
final maxY = dailyTotals.values.isEmpty
    ? 100.0
    : dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2;

// Ensure maxY is never 0 to avoid division by zero in horizontalInterval
final safeMaxY = maxY > 0 ? maxY : 100.0;

// Use safeMaxY in chart
maxY: safeMaxY,
horizontalInterval: safeMaxY / 5,
```

## Impact
- ✅ Prevents crashes when viewing analytics with zero-value expenses
- ✅ Charts display correctly with a default range of 0-100 when no data
- ✅ Grid lines are properly spaced (interval of 20 when using default 100)
- ✅ All three chart types now handle edge cases gracefully

## Testing Scenarios
1. **No expenses**: Charts show empty state message
2. **All zero expenses**: Charts display with 0-100 range
3. **Mixed expenses**: Charts calculate proper maxY and display normally
4. **Single non-zero expense**: Charts scale appropriately

## Files Modified
- `lib/screens/analytics_screen.dart`
  - Line ~260: `_buildBarChart()` 
  - Line ~382: `_buildDailyBarChart()`
  - Line ~506: `_buildMonthlyBarChart()`

## Date
January 31, 2026
