import Cocoa
import SwiftUI
import CoreLocation
import UserNotifications
import MapKit
import Combine

struct Flight: Identifiable, Equatable {
    var id: String { icao24 }
    let icao24: String
    let callsign: String
    let origin: String
    var latitude: Double
    var longitude: Double
    let altitude: Double
    let velocity: Double
    let heading: Double
}

class FlightData: ObservableObject {
    @Published var flights: [Flight] = []
    @Published var selectedFlight: Flight?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.65, longitude: 77.23), // Default
        span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
    )
    
    var animationTimer: Timer?
    
    func startAnimation() {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.linear(duration: 0.5)) {
                    for i in 0..<self.flights.count {
                        let f = self.flights[i]
                        let v = f.velocity
                        let h = f.heading
                        
                        let distance = v * 0.5
                        let earthRadius = 6378137.0
                        
                        let dLat = (distance * cos(h * .pi / 180.0)) / earthRadius
                        let dLon = (distance * sin(h * .pi / 180.0)) / (earthRadius * cos(f.latitude * .pi / 180.0))
                        
                        self.flights[i].latitude += dLat * (180.0 / .pi)
                        self.flights[i].longitude += dLon * (180.0 / .pi)
                    }
                }
            }
        }
    }
}

struct FlightMarkerView: View {
    let flight: Flight
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "location.north.fill")
                .font(.system(size: isSelected ? 30 : 18, weight: .bold))
                .foregroundColor(isSelected ? .yellow : .white)
                .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 2)
                .rotationEffect(.degrees(flight.heading)) // Pure heading rotation
            
            Text(flight.callsign.isEmpty ? "Unknown" : flight.callsign)
                .font(.system(size: isSelected ? 16 : 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue.opacity(0.8) : Color.black.opacity(0.6))
                )
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                
            if isSelected {
                VStack(spacing: 2) {
                    Text("Alt: \(Int(flight.altitude))m")
                    Text("Spd: \(Int(flight.velocity * 3.6))km/h")
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(6)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
            }
        }
    }
}

struct WallpaperView: View {
    @ObservedObject var flightData: FlightData

    var body: some View {
        Map(coordinateRegion: $flightData.region, annotationItems: flightData.flights) { flight in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: flight.latitude, longitude: flight.longitude)) {
                FlightMarkerView(flight: flight, isSelected: flightData.selectedFlight?.icao24 == flight.icao24)
                    .onTapGesture {
                        withAnimation {
                            flightData.selectedFlight = flight
                        }
                    }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem!
    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    var timer: Timer?
    var notifiedFlights: Set<String> = []
    
    let flightData = FlightData()
    var desktopWindow: NSWindow?
    var wallpaperMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "location.north.fill", accessibilityDescription: "Air Radar")
        }
        
        let menu = NSMenu()
        wallpaperMenuItem = NSMenuItem(title: "Live Wallpaper", action: #selector(toggleWallpaper), keyEquivalent: "w")
        menu.addItem(wallpaperMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit AirRadar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            print("Notification permission granted: \(granted)")
        }
        
        flightData.startAnimation()
        timer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(checkFlights), userInfo: nil, repeats: true)
        checkFlights()
    }
    
    @objc func toggleWallpaper() {
        if desktopWindow != nil {
            desktopWindow?.close()
            desktopWindow = nil
            wallpaperMenuItem.state = .off
        } else {
            let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
            desktopWindow = NSWindow(
                contentRect: screenRect,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            desktopWindow?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
            desktopWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            desktopWindow?.backgroundColor = .clear
            desktopWindow?.isOpaque = false
            desktopWindow?.ignoresMouseEvents = false // Allow clicking on planes in wallpaper
            
            let wallpaperView = WallpaperView(flightData: flightData)
            desktopWindow?.contentView = NSHostingView(rootView: wallpaperView)
            desktopWindow?.makeKeyAndOrderFront(nil)
            wallpaperMenuItem.state = .on
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if userLocation == nil {
            userLocation = locations.last
            if let loc = locations.last {
                DispatchQueue.main.async {
                    self.flightData.region.center = loc.coordinate
                }
            }
            checkFlights()
        }
        userLocation = locations.last
    }
    
    @objc func checkFlights() {
        guard let location = userLocation else { return }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let radius = 0.5 
        
        let lamin = lat - radius
        let lamax = lat + radius
        let lomin = lon - radius
        let lomax = lon + radius
        
        let urlString = "https://opensky-network.org/api/states/all?lamin=\(lamin)&lomin=\(lomin)&lamax=\(lamax)&lomax=\(lomax)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let states = json["states"] as? [[Any]] {
                        
                        var currentFlights: [Flight] = []
                        
                        for state in states {
                            let icao24 = state[0] as? String ?? "Unknown"
                            let callsign = (state[1] as? String)?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
                            let originCountry = state[2] as? String ?? "Unknown"
                            let fLon = state[5] as? Double ?? 0
                            let fLat = state[6] as? Double ?? 0
                            let altitude = state[7] as? Double ?? 0
                            let velocity = state[9] as? Double ?? 0
                            let heading = state[10] as? Double ?? 0
                            
                            let flight = Flight(icao24: icao24, callsign: callsign, origin: originCountry, latitude: fLat, longitude: fLon, altitude: altitude, velocity: velocity, heading: heading)
                            currentFlights.append(flight)
                            
                            let flightLoc = CLLocation(latitude: fLat, longitude: fLon)
                            let distance = location.distance(from: flightLoc)
                            
                            if distance < 5000 {
                                if !self.notifiedFlights.contains(icao24) {
                                    self.notifiedFlights.insert(icao24)
                                    self.sendNotification(flight: flight)
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            if let selected = self.flightData.selectedFlight, !currentFlights.contains(where: { $0.icao24 == selected.icao24 }) {
                                self.flightData.selectedFlight = nil
                            }
                            self.flightData.flights = currentFlights
                        }
                    }
                } catch {
                    print("JSON error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    func sendNotification(flight: Flight) {
        let content = UNMutableNotificationContent()
        content.title = "Airplane Nearby! ✈️"
        let name = flight.callsign.isEmpty || flight.callsign == "Unknown" ? "An airplane" : "Flight \(flight.callsign)"
        content.body = "\(name) from \(flight.origin) is passing by your location."
        content.sound = UNNotificationSound.default
        content.userInfo = ["icao24": flight.icao24]
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let icao24 = userInfo["icao24"] as? String {
            DispatchQueue.main.async {
                if let flight = self.flightData.flights.first(where: { $0.icao24 == icao24 }) {
                    self.flightData.selectedFlight = flight
                    self.flightData.region.center = CLLocationCoordinate2D(latitude: flight.latitude, longitude: flight.longitude)
                }
                // Open wallpaper if not already open
                if self.desktopWindow == nil {
                    self.toggleWallpaper()
                }
            }
        }
        completionHandler()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
