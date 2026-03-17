//
//  ChecklistRequest.swift
//  JeepChak
//
//  Created by 김은찬 on 11/15/25.
//

import Foundation

// MARK: - Request Models
struct ChecklistGenerateRequest: Codable {
    let propertyId: Int
}

struct ChecklistItemRequest: Codable {
    let content: String
    let severity: String
}

// 체크리스트 저장 요청
struct ChecklistSaveRequest: Codable {
    let propertyId: Int
    let items: [ChecklistSaveItem]
}

struct ChecklistSaveItem: Codable {
    let content: String
    /// NONE | NORMAL | WARNING | DANGER
    let severity: String
    let memo: String
}

// 체크리스트 수정 요청
struct ChecklistUpdateRequest: Codable {
    let itemId: Int?
    let memo: String?
    let severity: String?
}

struct GenerateChecklistRequest: Codable {
    let propertyId: Int
}

// MARK: - Response
struct ChecklistResponse: Codable {
    let checklistId: Int
    let propertyId: Int
    let itemCount: Int
    let createdAt: String
}

// 체크리스트 목록 조회 응답
struct ChecklistListResponse: Codable {
    let checklistId: Int
    let propertyId: Int
    let createdAt: String
    let itemCount: Int
}

struct GeneratedChecklistResponse: Codable {
    let contents: [String]?
    
    // 기존 content 필드와의 호환성을 위한 계산 속성
    var content: String? {
        return contents?.first
    }
    
    // 이니셜라이저 추가
    init(contents: [String]?) {
        self.contents = contents
    }
}

struct ChecklistDetailResponse: Codable {
    let checklistId: Int
    let propertyId: Int
    let items: [ChecklistItemDetail]
}

/// 서버 severity가 Int(0~3) 또는 String("NONE" | "NORMAL" | "WARNING" | "DANGER")로 올 수 있어 둘 다 지원
enum ChecklistSeverity: String, Codable {
    case NONE
    case NORMAL
    case WARNING
    case DANGER

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let raw = try? container.decode(String.self) {
            let upper = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if let v = ChecklistSeverity(rawValue: upper) {
                self = v
                return
            }
        }

        if let intValue = try? container.decode(Int.self) {
            switch intValue {
            case 1: self = .NORMAL
            case 2: self = .WARNING
            case 3: self = .DANGER
            default: self = .NONE
            }
            return
        }

        self = .NONE
    }
}

struct ChecklistItemDetail: Codable {
    let itemId: Int
    let content: String
    let severity: ChecklistSeverity
    let memo: String?
}

// 체크리스트 수정 응답
struct ChecklistUpdateResponse: Codable {
    let checklistId: Int
    let propertyId: Int
    let updatedItemCount: Int
    let updatedAt: String
}
