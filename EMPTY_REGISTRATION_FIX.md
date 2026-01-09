# Empty Registration Number Fix

## Issue
Users couldn't create multiple vehicles with empty registration numbers. The system was treating all empty registrations as duplicates.

### Error Message:
```
❌ Error adding vehicle: Exception: A vehicle with registration number  already exists
```

## Root Cause
The duplicate check in `insertVehicle()` and `updateVehicle()` didn't account for empty registration numbers. It was checking if an empty string already exists in the database, which would always be true after the first vehicle with no registration.

## Solution
Modified the validation to **skip the duplicate check when registration number is empty or whitespace**.

### Changes in `database_helper.dart`

#### Before:
```dart
// Always checked for duplicates
final exists = await isRegistrationNumberExists(vehicle.registrationNumber);
if (exists) {
  throw Exception('A vehicle with registration number ${vehicle.registrationNumber} already exists');
}
```

#### After:
```dart
// Only check if registration is not empty
if (vehicle.registrationNumber.trim().isNotEmpty) {
  final exists = await isRegistrationNumberExists(vehicle.registrationNumber);
  if (exists) {
    throw Exception('A vehicle with registration number ${vehicle.registrationNumber} already exists');
  }
}
```

## Behavior Now

### ✅ Allowed:
- Multiple vehicles with **empty** registration
- Multiple vehicles with **whitespace-only** registration
- Unique registration numbers

### ❌ Still Prevented:
- Duplicate non-empty registration numbers
- Creating two vehicles with same registration "ABC-123"

## Example Use Cases

### Use Case 1: Personal Vehicles (No Registration)
```
Vehicle 1: Honda Bike (registration: "")     ✅ Allowed
Vehicle 2: Yamaha Bike (registration: "")    ✅ Allowed
Vehicle 3: Toyota Car (registration: "")     ✅ Allowed
```

### Use Case 2: Mix of Registered and Unregistered
```
Vehicle 1: Honda (registration: "")          ✅ Allowed
Vehicle 2: Toyota (registration: "ABC-123")  ✅ Allowed
Vehicle 3: Yamaha (registration: "")         ✅ Allowed
Vehicle 4: Suzuki (registration: "ABC-123")  ❌ Rejected (duplicate)
```

## Testing
1. Hot restart the app: Press `R` in terminal
2. Try adding multiple vehicles without registration
3. All should be created successfully
4. Try adding vehicles with the same registration → should be rejected

---
Fixed: January 1, 2026
