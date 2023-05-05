//
//  ContentView.swift
//  GPS Speed Limit Monitor
//
//  Created by ian on 9/30/22.
//

import SwiftUI
import MapKit
import CoreLocation
import Foundation

struct ContentView: View {
    @StateObject var locationViewModel = LocationViewModel()

    
    var body: some View {
        NavigationView {
            VStack {
                TextField(
                    "User name",
                    text: $locationViewModel.username
                )
                NavigationLink(destination:MapView()) {
                    Text("login")
                }
            }
        }
        .environmentObject(locationViewModel)
    }
}

struct MapView: View {
    @EnvironmentObject var locationViewModel: LocationViewModel
    
    var body: some View {
        VStack {
            NavigationLink(destination:MonitorView(monitor: "")) {
                Text("monitors")
            }
            Text("Speeed Limit: " + String(locationViewModel.speedLimit))
            Map(coordinateRegion: $locationViewModel.region, showsUserLocation: true)
                .onAppear(perform: locationViewModel.requestPermission)
            Text(String(locationViewModel.currentSpeed))
                .foregroundColor(locationViewModel.textColor)
                .onAppear {
                    add_user(username: locationViewModel.username)
                }
        }
    }
}

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Location permissions
    var authorizationStatus: CLAuthorizationStatus
    // Username
    @Published var username: String
    @Published var speedLimit: Int
 
    // Map region
    @Published var region: MKCoordinateRegion
    private var span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    
    // Speed
    @Published var currentSpeed: CLLocationSpeed
    @Published var textColor: Color
    @Published var monitors: [Monitor]
    
    private var sameIncident: Bool
    
    // previous time and location
    private var prevLocation: CLLocation
    private var maxSpeed = 0.0
    //private var prevTime = Date()
    
    
    
    
    private let locationManager: CLLocationManager
    
    override init() {
        locationManager = CLLocationManager()
        authorizationStatus = locationManager.authorizationStatus
        self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: span)
        self.currentSpeed = 0
        self.sameIncident = false
        self.prevLocation = CLLocation(latitude: 0, longitude: 0)
        self.username = ""
        self.speedLimit = 0
        self.textColor = .black
        self.monitors = []
        
        
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func requestPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations.first?.coordinate
        region = MKCoordinateRegion(center: currentLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), span: span)
        currentSpeed = getSpeed(loc1: locations.first!.coordinate , loc2: prevLocation.coordinate)
        prevLocation = locations.first!
        var prevSpeed = 0.0
        getSpeedLimit(location: prevLocation.coordinate)
        var difference = currentSpeed - prevSpeed
        if (difference > 30.0) {
            update_incidents(username: username, longitude: Float(locations.first!.coordinate.longitude), latitude: Float(locations.first!.coordinate.latitude), speed: 0, speed_limit: speedLimit, type: "fast-accel")
        }
        
        if (Int(currentSpeed) > Int(speedLimit) + 10 && Int(currentSpeed) < 200) {
            textColor = .red
            sameIncident = true
            if (currentSpeed > maxSpeed) {
                maxSpeed = currentSpeed
            }
        } else {
            textColor = .black
            if (sameIncident) {
                update_incidents(username: username, longitude: Float(locations.first!.coordinate.longitude), latitude: Float(locations.first!.coordinate.latitude), speed: Int(maxSpeed), speed_limit: speedLimit, type: "speed")
                sameIncident = false
                maxSpeed = 0
            }
        }
        prevSpeed = currentSpeed
    }
    
    func getSpeed(loc1: CLLocationCoordinate2D, loc2: CLLocationCoordinate2D) -> Double {
        let lat1 = loc1.latitude
        let lon1 = loc1.longitude
        let lat2 = loc2.latitude
        let lon2 = loc2.longitude
        
        // Calculate distance between loc1 and loc2
        let p = 0.017453292519943295
        let a = 0.5 - cos((lat2 - lat1) * p)/2 +
                  cos(lat1 * p) * cos(lat2 * p) *
                  (1 - cos((lon2 - lon1) * p))/2
        let distance = 12742 * asin(sqrt(a))
        
        let milesDistance = distance * 0.6213711922
        return milesDistance * 360
    }
    
    func getSpeedLimit(location: CLLocationCoordinate2D) {
        guard let url = URL(string: "http://dev.virtualearth.net/REST/v1/Routes/SnapToRoad?points=" + String(location.latitude) + "," + String(location.longitude) + "&includeSpeedLimit=True&speedUnit=mph&key=AhPFa31L7MO_A8jNN6xYNFzjyYK9uxz6lYPcN25XYqbYbScrsWorczREySnpT9A9") else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }

            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decoded = try JSONDecoder().decode(BingResponse.self, from: data)
                        self.speedLimit = decoded.resourceSets[0].resources[0].snappedPoints[0].speedLimit
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
    }
    
    func getMonitors(username: String) {
        print("GET MONITORS")
        guard let url = URL(string: "http://localhost:3000/monitors?username=" + username) else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }

            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decoded = try JSONDecoder().decode([Monitor].self, from: data)
                        self.monitors = decoded
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
    }
    
}

func update_incidents(username: String, longitude: Float, latitude: Float, speed: Int, speed_limit: Int, type: String) {
    let body: [String: Any] = ["data": ["username": username, "longitude": longitude, "latitude": latitude, "speed": speed, "speed_limit": speed_limit, "type": type]]
    let jsonData = try? JSONSerialization.data(withJSONObject: body)
    let url = URL(string: "http://localhost:3000/update")!
    var request = URLRequest(url: url)
    
    request.httpMethod = "POST"
    request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Check for Error
            if let error = error {
                print("Error took place \(error)")
                return
            }
     
            // Convert HTTP Response Data to a String
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
            }
    }
    task.resume()
}

func add_user(username: String) {
    let body: [String: Any] = ["data": ["username": username]]
    let jsonData = try? JSONSerialization.data(withJSONObject: body)
    let url = URL(string: "http://localhost:3000/add_user")!
    var request = URLRequest(url: url)
    
    request.httpMethod = "POST"
    request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Check for Error
            if let error = error {
                print("Error took place \(error)")
                return
            }
     
            // Convert HTTP Response Data to a String
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
            }
    }
    task.resume()
}


struct ContentViewPreview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
