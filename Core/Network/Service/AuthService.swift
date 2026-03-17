////  AuthService.swift
////  Eodigo
////
////  Created by 김은찬 on 12/03/25.
////
//
//import Foundation
//import Moya
//
//enum AuthError: Error {
//    case noRefreshToken
//}
//
//final class AuthService {
//    static let shared = AuthService()
//    private let provider = MoyaProvider<AuthAPI>()
//    
//    private init() {}
//    
//    // 로그인
//    func login(email: String, password: String) async throws -> LoginResponse {
//        let result = await provider.requestAsync(.login(email: email, password: password))
//        switch result {
//        case .success(let response):
//            let decoded = try JSONDecoder().decode(LoginResponse.self, from: response.data)
//            
//            // 토큰 저장
//            TokenStorage.accessToken = decoded.accessToken
//            TokenStorage.refreshToken = decoded.refreshToken
//            
//            return decoded
//
//        case .failure(let error):
//            throw error
//        }
//    }
//    
//    // 회원가입
//    func signup(
//        firstName: String,
//        lastName: String,
//        email: String,
//        password: String
//    ) async throws -> SignUpResponse {
//        let result = await provider.requestAsync(
//            .signup(email: email, password: password, firstName: firstName, lastName: lastName)
//        )
//        switch result {
//        case .success(let response):
//            let decoded = try JSONDecoder().decode(SignUpResponse.self, from: response.data)
//            return decoded
//        case .failure(let error):
//            throw error
//        }
//    }
//
//    // 토큰 재발급
//    func refreshTokens() async throws -> LoginResponse {
//        // 로컬 refreshToken 체크
//        guard let refresh = TokenStorage.refreshToken, !refresh.isEmpty else {
//            throw AuthError.noRefreshToken
//        }
//
//        // refresh 토큰을 넣어서 api 호출
//        let result = await provider.requestAsync(.refresh(refreshToken: refresh))
//        
//        switch result {
//        case .success(let response):
//            let decoded = try JSONDecoder().decode(LoginResponse.self, from: response.data)
//            
//            // 새 토큰 저장
//            TokenStorage.accessToken = decoded.accessToken
//            TokenStorage.refreshToken = decoded.refreshToken
//            
//            print("토큰 리프레시 완료")
//            return decoded
//
//        case .failure(let error):
//            TokenStorage.clear()
//            throw error
//        }
//    }
//
//    // 계정 삭제
//    func deleteMe() async throws -> String {
//        let result = await provider.requestAsync(.deleteMe)
//        switch result {
//        case .success(let response):
//            // 래핑/비래핑 모두 허용
//            if let wrapped = try? JSONDecoder().decode(ApiResponse<String>.self, from: response.data) {
//                if wrapped.success { return wrapped.message }
//                throw NSError(
//                    domain: "AuthService",
//                    code: response.statusCode,
//                    userInfo: [NSLocalizedDescriptionKey: wrapped.message]
//                )
//            }
//
//            // 빈 응답 처리
//            let raw = String(data: response.data, encoding: .utf8) ?? ""
//            return raw.isEmpty ? "계정이 삭제되었습니다." : raw
//
//        case .failure(let error):
//            throw error
//        }
//    }
//
//    // 내 정보 조회
//    func getMe() async throws -> UserMeDTO {
//        let result = await provider.requestAsync(.getMe)
//        switch result {
//        case .success(let response):
//            // 래핑/비래핑 모두 허용
//            if let wrapped = try? JSONDecoder().decode(ApiResponse<UserMeDTO>.self, from: response.data) {
//                if wrapped.success, let data = wrapped.data { return data }
//                throw NSError(
//                    domain: "AuthService",
//                    code: response.statusCode,
//                    userInfo: [NSLocalizedDescriptionKey: wrapped.message]
//                )
//            }
//
//            return try JSONDecoder().decode(UserMeDTO.self, from: response.data)
//
//        case .failure(let error):
//            throw error
//        }
//    }
//}
