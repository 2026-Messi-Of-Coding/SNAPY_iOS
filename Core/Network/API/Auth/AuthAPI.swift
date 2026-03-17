//
//  AuthAPI.swift
//  Qiri
//
//  Created by 김은찬 on 5/25/25.
//

import Foundation
import Moya
internal import Alamofire

enum AuthAPI {
    case login(email: String, password: String)
    case signup(email: String, password: String, firstName: String, lastName: String)
    case refresh(refreshToken: String)
    /// 내 정보 조회
    case getMe
    /// 계정 삭제
    case deleteMe
}

extension AuthAPI: TargetType {

    var baseURL: URL {
        return URL(string: "http://zipchak-backend.kro.kr:8080")!
    }
    
    var path: String {
        switch self {
        case .login:
            return "/api/auth/login"
        case .signup:
            return "/api/auth/signup"
        case .refresh:
            return "/api/auth/refresh"
        case .getMe:
            return "/api/user/me"
        case .deleteMe:
            return "/api/user/me"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .login:
            return .post
        case .signup:
            return .post
        case .refresh:
            return .post
        case .getMe:
            return .get
        case .deleteMe:
            return .delete
        }
    }
    
    var task: Task {
        switch self {
        case let .login(email, password):
            let params: [String: Any] = [
                "email": email,
                "password": password
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case let .signup(email, password, firstName, lastName):
            let params: [String: Any] = [
                "email": email,
                "password": password,
                "firstName" : firstName,
                "lastName" : lastName
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case let .refresh(refreshToken):
                    let body = RefreshRequest(refreshToken: refreshToken)
                    return .requestJSONEncodable(body)
        case .getMe:
            return .requestPlain
        case .deleteMe:
            return .requestPlain
                }
    }
    
    var headers: [String : String]? {
            switch self {
            case .login, .signup:
                return ["Content-Type": "application/json"]

            case .refresh:
                var headers: [String: String] = [
                    "Content-Type": "application/json"
                ]
                if let refresh = TokenStorage.refreshToken {
                    headers["Authorization"] = "Bearer \(refresh)"
                }
                return headers
            case .getMe:
                var headers: [String: String] = [
                    "Accept": "application/json"
                ]
                if let access = TokenStorage.accessToken {
                    headers["Authorization"] = "Bearer \(access)"
                }
                return headers
            case .deleteMe:
                var headers: [String: String] = [
                    "Accept": "application/json"
                ]
                if let access = TokenStorage.accessToken {
                    headers["Authorization"] = "Bearer \(access)"
                }
                return headers
            }
        }
}
