//
//  Incident.swift
//  GPS Speed Limit Monitor
//
//  Created by Ian Jacobson on 12/27/22.
//

import Foundation

struct Incident: Identifiable, Codable {
    var id: Int
    var longitude: Float
    var latitude: Float
    var speed: Int
    var speed_limit: Int
}
