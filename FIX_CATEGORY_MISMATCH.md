# Fix: Category Mismatch Error in Edit Expense

## Problem
When editing vehicle-related expenses (fuel entries), the app crashed with:
```
There should be exactly one item with [DropdownButton]'s value: Transportation
```

## Root Cause
1. **Vehicle fuel entries** were being saved with category `"Transportation"` (capitalized)
2. **Category dropdown list** only contained `"transport"` (lowercase)
3. When opening the edit screen, the dropdown couldn't find a matching category

## Solution Applied

### 1. **Edit Expense Screen** (`lib/screens/edit_expense_screen.dart`)
Added category normalization in `initState()`:
- Converts category to lowercase
- Maps common variations to standard categories:
  - `"transportation"` → `"transport"`
  - `"food & dining"` → `"food"`
  - `"medical"` → `"healthcare"`
  - `"utilities"` → `"bills"`
  - `"fun"` → `"entertainment"`
- Falls back to default category if not found

```dart
// Normalize category name
String normalizedCategory = _expense.category.toLowerCase().trim();

// Map common variations
final categoryMap = {
  'transportation': 'transport',
  'food & dining': 'food',
  // ... more mappings
};

// Check if category exists in list
if (targetList.contains(normalizedCategory)) {
  _selectedCategory = normalizedCategory;
} else {
  _selectedCategory = _isIncome ? _incomeCategories[0] : _categories[0];
}
```

### 2. **Vehicle Details Controller** (`lib/controllers/vehicle_details_controller.dart`)

**Fixed Two Issues:**

#### A. Fuel Entry Creation (Line ~162)
Changed category from `"Transportation"` to `"transport"`:
```dart
// Before
category: 'Transportation',

// After
category: 'transport', // Matches standard category list
```

#### B. Fuel Entry Deletion Filter (Line ~262)
Made the filter case-insensitive to handle both old and new entries:
```dart
// Before
expense.category == 'Transportation'

// After
(expense.category.toLowerCase() == 'transportation' || 
 expense.category.toLowerCase() == 'transport')
```

## Impact

### ✅ Benefits:
1. **Edit screen works** for all vehicle expenses (old and new)
2. **Backward compatible** - handles existing "Transportation" entries
3. **Future-proof** - new fuel entries use correct "transport" category
4. **Robust** - handles category name variations gracefully
5. **No data loss** - all old fuel entries still work

### 📊 Affected Data:
- **New fuel entries**: Will be saved with `"transport"` category
- **Old fuel entries**: With `"Transportation"` will be automatically mapped to `"transport"` when editing
- **Deletion**: Works for both old and new category formats

## Testing Checklist
- [x] Edit vehicle fuel expense (with "Transportation" category)
- [x] Edit regular transport expense
- [x] Edit other category expenses
- [x] Add new fuel entry (saves with "transport")
- [x] Delete fuel entry (works for both formats)
- [x] Category dropdown displays correct selection
- [x] No crashes on edit screen

## Date
January 31, 2026
