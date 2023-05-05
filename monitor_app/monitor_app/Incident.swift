//
//  Incident.swift
//  monitor_app
//
//  Created by Ian Jacobson on 4/4/23.
//

import Foundation

struct Incident: Identifiable, Decodable {
    var id: Int
    var lon: Float
    var lat: Float
    var speed: Int
    var owner_id: Int
    var username: String
    var speed_limit: Int
    var kind: String
}
