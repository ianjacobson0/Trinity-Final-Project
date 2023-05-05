//
//  MonitorView.swift
//  GPS Speed Limit Monitor
//
//  Created by Ian Jacobson on 3/9/23.
//

import SwiftUI

struct MonitorView: View {
    @EnvironmentObject var locationViewModel: LocationViewModel
    @State var monitor: String
    var body: some View {
        VStack {
            TextField(
                "User name",
                text: $monitor
            )
            Button("Add") {
                addMonitor(username: locationViewModel.username, monitor: monitor)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    locationViewModel.getMonitors(username: locationViewModel.username)
                }
            }
            .onAppear {
                locationViewModel.getMonitors(username: locationViewModel.username)
            }
            List {
                ForEach(locationViewModel.monitors, id: \.self) { monitor in
                    HStack {
                        Text("username: " + String(monitor.username))
                        Button("delete") {
                            delMonitor(username: locationViewModel.username, monitor: monitor.username)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                locationViewModel.getMonitors(username: locationViewModel.username)
                            }
                        }
                        
                    }
                    
                }
            }
        }
    }
}

struct MonitorView_Previews: PreviewProvider {
    static var previews: some View {
        MonitorView(monitor: "")
    }
}

func addMonitor(username: String, monitor: String) {
    print(username)
    print(monitor)
    let body: [String: Any] = ["data": ["monitor_user": monitor, "username": username]]
    let jsonData = try? JSONSerialization.data(withJSONObject: body)
    print(jsonData)
    let url = URL(string: "http://localhost:3000/add_monitor")!
    var request = URLRequest(url: url)
    
    request.httpMethod = "POST"
    request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            print("here")
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

func delMonitor(username: String, monitor: String) {
    print(username)
    print(monitor)
    let body: [String: Any] = ["data": ["monitor_user": monitor, "username": username]]
    let jsonData = try? JSONSerialization.data(withJSONObject: body)
    print(jsonData)
    let url = URL(string: "http://localhost:3000/monitors")!
    var request = URLRequest(url: url)
    
    request.httpMethod = "PUT"
    request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            print("here")
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

