//
//  PropertyRequest.swift
//  JeepChak
//
//  Created by 김은찬 on 11/18/25.
//

import Foundation

struct PropertyRequest: Codable {
    let name: String
    let address: String
    let propertyType: String
    let floor: Int
    let builtYear: Int
    let area: Int
    let marketPrice: Int
    let leaseType: String
    let deposit: Int
    let monthlyRent: Int
    let memo: String
}

struct PropertyListResponse: Codable {
    let propertyId: Int
    let name: String
    let address: String
    let propertyType: String?
    let floor: Int?
    let area: Int?
    let marketPrice: Int?
    let leaseType: String?
    let deposit: Int?
    let monthlyRent: Int?
    let createdAt: String?
}

struct PropertyResponse: Codable {
    let propertyId: Int
    let name: String
    let address: String
    let propertyType: String
    let floor: Int
    let builtYear: Int
    let area: Int
    let marketPrice: Int?
    let leaseType: String?
    let deposit: Int?
    let monthlyRent: Int?
    let memo: String?
    let availableDate: String?
    let createdAt: String
}

struct ApiResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String
    let data: T?
}
