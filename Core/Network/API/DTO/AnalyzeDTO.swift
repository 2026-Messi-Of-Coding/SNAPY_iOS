//
//  AnalyzeDTO.swift
//  JeepChak
//
//  Created by 김은찬 on 12/3/25.
//

import Foundation

// 매물분석 Request
struct AnalyzeRequestDTO: Codable {
    let propertyId: Int
    let marketPrice: Int
    let deposit: Int
    let monthlyRent: Int
}

// 대처방안 Request
struct RiskSolutionRequestDTO: Codable {
    let propertyId: Int
    let marketPrice: Int
    let deposit: Int
    let monthlyRent: Int
}

// Response
struct AnalyzeResponseDTO: Codable {
    let totalRisk: Int
    let details: [AnalyzeDetailItem]
    let comment: String
}

struct AnalyzeDetailItem: Codable {
    let original: String
    let analysisText: String
}

// 대처 방안 Response
struct RiskSolutionResponseDTO: Codable {
    let coping: [CopingItem]
    let checklist: [String]
}

struct CopingItem: Codable {
    let title: String
    let list: [String]
}
