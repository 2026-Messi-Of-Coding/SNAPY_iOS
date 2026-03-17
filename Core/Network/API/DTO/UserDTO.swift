//
//  UserDTO.swift
//  JeepChak
//
//  Created by GPT on 1/10/26.
//

import Foundation

/// 내 정보 조회 응답 DTO
struct UserMeDTO: Codable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let createdAt: String?
    let updatedAt: String?
}

