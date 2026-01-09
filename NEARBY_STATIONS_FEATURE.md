# Nearby Gas Stations Feature

## Overview
Added a map-based feature to show your current location and nearby petrol pumps/gas stations. This helps users quickly find fuel stations when they need to refuel their vehicles.

## Features

### ✅ Implemented
1. **Interactive Google Maps** - Full map view with zoom and pan
2. **Current Location** - Blue marker showing your position
3. **Sample Gas Stations** - Red markers for nearby stations
4. **Station Details** - Tap markers to see station info
5. **Distance Info** - Shows how far each station is
6. **Location Permission** - Smart permission handling
7. **Recenter Button** - Quickly return to your location
8. **Legend** - Visual guide for marker types

### 🔄 To Be Enhanced
- **Google Places API Integration** - Get real gas station data
- **Real-time Navigation** - Launch Google Maps for directions
- **Filter Options** - Filter by brand, price, amenities
- **Fuel Prices** - Show current fuel prices at stations
- **User Reviews** - Show ratings and reviews

## How to Use

### 1. From Vehicle Details Screen
1. Open any vehicle from your vehicle list
2. Tap the **Map icon** in the top-right corner
3. Grant location permission when prompted
4. View your location and nearby gas stations

### 2. On the Map
- **Blue marker** = Your current location
- **Red markers** = Nearby gas stations
- **Tap any red marker** = View station details
- **Tap "GET DIRECTIONS"** = Navigate to station (coming soon)
- **Refresh button** = Update your location

## Setup Requirements

### 1. Google Maps API Key (REQUIRED)

**⚠️ Important**: You need to get a Google Maps API key to use this feature.

#### Get API Key:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API (for real station data)
4. Create credentials → API Key
5. Restrict the key to your app

#### Add API Key:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

**iOS** (`ios/Runner/AppDelegate.swift`):
Add this import and configuration:
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 2. Install Dependencies

Run these commands:
```bash
flutter pub get
cd ios && pod install && cd ..
```

### 3. Test the Feature

```bash
# Run on Android
flutter run -d emulator-5554

# Run on iOS (if you have Mac)
flutter run -d <ios-simulator-id>
```

## Permissions Configured

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (`Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby gas stations on the map</string>
```

## Files Added/Modified

### New Files:
1. `lib/services/location_service.dart` - Location handling service
2. `lib/screens/nearby_stations_screen.dart` - Map screen
3. `NEARBY_STATIONS_FEATURE.md` - This documentation

### Modified Files:
1. `pubspec.yaml` - Added dependencies
2. `lib/screens/vehicle_details_screen.dart` - Added map button
3. `android/app/src/main/AndroidManifest.xml` - Added permissions & API key
4. `ios/Runner/Info.plist` - Added location permissions

## Dependencies Added

```yaml
google_maps_flutter: ^2.9.0  # Google Maps widget
geolocator: ^13.0.2          # Location services
geocoding: ^3.0.0            # Address conversion
```

## Current Limitations

### Sample Data
Currently showing **sample/dummy gas stations** around your location. The names and positions are for demonstration purposes.

### To Get Real Data
You need to integrate **Google Places API**:

```dart
// Example Places API call (not implemented yet)
final response = await http.get(
  Uri.parse(
    'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
    'location=${lat},${lng}&radius=5000&type=gas_station'
    '&key=YOUR_API_KEY'
  ),
);
```

## Troubleshooting

### Map shows gray screen
- Check if you added the correct API key
- Ensure Maps SDK is enabled in Google Cloud Console
- Check internet connection

### Location not working
- Grant location permission in app settings
- Enable Location Services on your device
- Check AndroidManifest.xml permissions

### Markers not showing
- Wait for location to be fetched
- Tap refresh button
- Check console for errors

## Future Enhancements

### Phase 2 (Recommended)
1. **Real Gas Station Data** - Integrate Google Places API
2. **Turn-by-Turn Navigation** - Open Google Maps with directions
3. **Fuel Price Comparison** - Show prices from different stations
4. **Favorite Stations** - Save frequently visited stations
5. **Offline Mode** - Cache recent gas station data

### Phase 3 (Advanced)
1. **AR Navigation** - Augmented reality directions
2. **Live Traffic** - Show traffic conditions to stations
3. **Queue Status** - See how busy a station is
4. **Payment Integration** - Pay for fuel through app
5. **Loyalty Programs** - Integrate station loyalty cards

## Testing Checklist

- [ ] Grant location permission
- [ ] See blue marker at your location
- [ ] See red markers for gas stations
- [ ] Tap red marker to view details
- [ ] Tap refresh button to update location
- [ ] Recenter button works
- [ ] Legend is visible
- [ ] Details bottom sheet shows correctly

## Cost Considerations

**Google Maps API Pricing** (as of 2024):
- Maps SDK for Android/iOS: Free up to 100,000 loads/month
- Places API: $17 per 1,000 requests (after free tier)
- Directions API: $5 per 1,000 requests

**Recommendation**: Start with sample data, monitor usage, then enable real API.

---

**Created**: January 1, 2026
**Status**: Ready for testing (with sample data)
**Next Step**: Add Google Maps API key and get real gas station data
