<div align="center">
  <img src="https://img.icons8.com/color/96/000000/radar.png" alt="AirRadar Logo" width="80"/>
  <h1>AirRadar for macOS ✈️</h1>
  <p>A native macOS menu bar app that tracks airplanes flying over your location in real-time and turns your desktop into a live radar map.</p>
</div>

<br />

<div align="center">
  <!-- ⚠️ REPLACE THIS IMAGE LINK WITH YOUR GIF OR VIDEO DEMO -->
  <img src="https://via.placeholder.com/800x450.png?text=Upload+Your+Demo+Video/GIF+Here" alt="AirRadar Demo" />
</div>

<br />

## 🌟 Features

* **📡 Live Overhead Notifications**: Uses your Mac's location to detect when a flight enters a 5km radius above you and sends a native push notification with flight details.
* **🗺️ Live Desktop Wallpaper**: One click turns your macOS desktop background into a live, interactive map tracking overhead flights in real-time.
* **🎯 GPS Accurate Rotations**: Airplanes are represented by navigation arrows mathematically aligned with their exact true-track heading.
* **⚡ Smooth Animations**: Smooth, fluid tracking animation between API updates based on real-time velocity metrics.
* **🍎 100% Native**: Built entirely in Swift & SwiftUI. Lightweight and unobtrusive, living right in your menu bar.

## 🛠️ How it Works
AirRadar leverages the [OpenSky Network API](https://opensky-network.org) to continuously pull live aviation data. It calculates real-time coordinates, altitude, velocity, and heading. When a plane enters the geofenced area above your current location, it triggers an Apple push notification.

## 🚀 Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/AirRadar.git
   cd AirRadar
   ```
2. **Build and Run:**
   Execute the provided setup shell script. It will compile the Swift source code into a native `.app` bundle, sign it, and launch it immediately.
   ```bash
   ./AirRadar/setup.sh
   ```
3. **Permissions:**
   Upon first launch, macOS will ask for **Location** and **Notification** permissions. Both are required for the app to function properly.

## 💡 Usage
* Look for the **navigation arrow icon** `⇡` in your macOS Menu Bar.
* Click the icon to reveal the dropdown menu.
* Select **Live Wallpaper** to toggle the background radar map.
* Keep an eye on your notification center for alerts when planes fly directly overhead! Click a notification to snap the wallpaper map to that specific plane.

## 💻 Tech Stack
* **Language**: Swift 5+
* **Frameworks**: SwiftUI, AppKit, MapKit, CoreLocation, UserNotifications, Combine
* **Data Source**: OpenSky Network API

## 📝 License
This project is licensed under the MIT License - see the LICENSE file for details.

---
*Created with ❤️ for aviation enthusiasts.*
