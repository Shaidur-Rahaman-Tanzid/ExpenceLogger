# Fuel Efficiency Feature

## Summary
Added a user-provided fuel efficiency field to vehicles, allowing users to specify how many kilometers their vehicle runs per liter. This baseline value is used in fuel consumption calculations when actual data is insufficient.

## Changes Made

### 1. Vehicle Model (`lib/models/vehicle.dart`)
- Added `fuelEfficiency` field (double?) to store km/L value
- Updated constructor, `toMap()`, `fromMap()`, and `copyWith()` methods

### 2. Database Schema (`lib/services/database_helper.dart`)
- Incremented database version from 8 to 9
- Added `fuelEfficiency REAL` column to vehicles table in `_onCreate`
- Added migration for version 9 in `_onUpgrade` to add the column to existing databases

### 3. Add Vehicle Screen (`lib/screens/add_vehicle_screen.dart`)
- Added `_fuelEfficiencyController` TextEditingController
- Added fuel efficiency input field with:
  - Label: "Fuel Efficiency (km/L)"
  - Hint: "e.g., 15"
  - Icon: `Icons.eco`
  - Suffix: "km/L"
  - Validation: Optional, must be between 0-100 if provided
- Updated vehicle save logic to include fuel efficiency

### 4. Fuel Consumption Calculation (`lib/controllers/vehicle_details_controller.dart`)
Updated `calculateFuelStatistics()` to use user-provided fuel efficiency in multiple scenarios:

#### When no fuel entries exist:
- Converts km/L to L/100km using formula: `L/100km = 100 / km/L`
- Displays user's expected fuel consumption

#### When calculation data is insufficient:
- Falls back to user-provided value instead of showing "N/A"
- Uses it as baseline for:
  - Single fuel entry with less than 50km traveled
  - Any scenario where actual calculation isn't possible

#### Calculation Priority:
1. **Most Accurate**: 2+ full tank entries (actual measured data)
2. **Good**: 2+ consecutive fuel entries (actual measured data)
3. **Estimated**: Single full tank + 50km+ traveled (estimated from usage)
4. **Baseline**: User-provided fuel efficiency (user's expected value)
5. **None**: Shows "N/A" only if no data and no user input

## Benefits

1. **Better UX**: Users see meaningful statistics even with limited fuel entry data
2. **Realistic Expectations**: User can input manufacturer's claimed efficiency or their experience
3. **Progressive Enhancement**: System starts with user's baseline and improves with actual data
4. **Fuel Level & Range**: Can estimate remaining fuel and range even with just one refuel

## Usage

### Adding a Vehicle:
1. Fill in basic vehicle info
2. Enter "Fuel Efficiency" (e.g., 15 for 15 km/L)
3. This value is optional but recommended for better statistics

### How It Works:
- **With no fuel entries**: Shows consumption based on your input (15 km/L = 6.67 L/100km)
- **With 1 fuel entry**: Uses your baseline until you drive 50km+, then calculates from actual data
- **With 2+ fuel entries**: Calculates from actual data, your input becomes reference

## Example

If user inputs **15 km/L**:
- Converts to: **6.67 L/100km** (displayed as "Avg Consumption")
- With 50L tank: Shows **750 km range** (50L × 15 km/L)
- As user adds fuel entries, calculations become more accurate

## Database Migration

The migration is automatic:
- New installations: Column created in `_onCreate`
- Existing installations: Column added in `_onUpgrade` (version 8 → 9)
- No data loss, fully backward compatible

## Testing

To test the feature:
1. Restart the app: `flutter run -d emulator-5554`
2. Add a new vehicle with fuel efficiency (e.g., 15 km/L)
3. Check vehicle details - should show "6.67 L/100km" as avg consumption
4. Add fuel entries to see how it transitions from baseline to actual data

---

Created: January 1, 2026
