//
//  BingResponse.swift
//  GPS Speed Limit Monitor
//
//  Created by Ian Jacobson on 4/7/23.
//

import Foundation

struct BingResponse: Decodable {
    var authenticationResultCode: String
    var brandLogoUri: String
    var copyright: String
    var resourceSets: [ResourceSet]
}

struct ResourceSet: Decodable {
    var estimatedTotal: Int
    var resources: [Resource]
}

struct Resource: Decodable {
    var __type: String
    var dataSourcesUsed: [Int]
    var snappedPoints: [Point]
}

struct Point: Decodable {
    var coordinate: Coordinate
    var index: Int
    var name: String
    var speedLimit: Int
    var speedUnit: String
}

struct Coordinate: Decodable {
    var latitude: Float
    var longitude: Float
}


