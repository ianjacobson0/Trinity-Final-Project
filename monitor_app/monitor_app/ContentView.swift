//
//  ContentView.swift
//  monitor_app
//
//  Created by Ian Jacobson on 3/22/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                TextField(
                    "User name",
                    text: $viewModel.username
                )
                NavigationLink(destination: IncidentView()) {
                    Text("login")
                }
            }
        }
        .environmentObject(viewModel)
    }
}

struct IncidentView: View {
    @EnvironmentObject var viewModel: ViewModel
    var body: some View {
        Text("incidents")
            .onAppear {
                viewModel.add_user(username: viewModel.username)
                viewModel.getUsers(monitor_user: viewModel.username)
            }
        VStack {
            ForEach(viewModel.incidents) { incident in
                HStack {
                    Text("username: " + String(incident.username))
                        .font(.system(size: 12))
                    Text(incident.kind)
                        .font(.system(size: 12))
                    Text("speed: " + String(incident.speed))
                    Text("speed limit: " + String(incident.speed_limit))
                }
                
            }
        }
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class ViewModel: NSObject, ObservableObject {
    @Published var username: String
    @Published var incidents: [Incident]
    override init() {
        self.username = ""
        self.incidents = []
    }
    
    func getUsers(monitor_user: String) {
        guard let url = URL(string: "http://localhost:3000/incidents?monitor_username=" + monitor_user) else { fatalError("Missing URL") }

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
                        let decodedIncidents = try JSONDecoder().decode([Incident].self, from: data)
                        self.incidents = decodedIncidents
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
    }
    func add_user(username: String) {
        let body: [String: Any] = ["data": ["username": username]]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        let url = URL(string: "http://localhost:3000/add_monitor_user")!
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
    
}




