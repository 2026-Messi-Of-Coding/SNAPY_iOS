//
//  ChecklistAPI.swift
//  JeepChak
//
//  Created by 김은찬 on 11/13/25.
//

import Foundation
import Moya
internal import Alamofire

enum ChecklistAPI {
    case generateChecklist(request: ChecklistGenerateRequest)
    case getChecklists
    case getChecklistDetail(id: Int)
    case saveChecklist(request: ChecklistSaveRequest)
    case updateChecklist(id: Int, items: [ChecklistUpdateRequest])
    case deleteChecklist(id: Int)
}


extension ChecklistAPI: TargetType {

    var baseURL: URL {
        URL(string: "http://zipchak-backend.kro.kr:8080")!
    }

    var path: String {
        switch self {
        case .generateChecklist:
            return "/api/checklist/generate"
        case .getChecklists, .saveChecklist:
            return "/api/checklist"
        case .getChecklistDetail(let id),
             .deleteChecklist(let id),
             .updateChecklist(let id, _):
            return "/api/checklist/\(id)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .generateChecklist, .saveChecklist: return .post
        case .getChecklists, .getChecklistDetail: return .get
        case .updateChecklist: return .put
        case .deleteChecklist: return .delete
        }
    }

    var task: Task {
        switch self {
        case .generateChecklist(let request):
            return .requestJSONEncodable(request)
            
        case .saveChecklist(let request):
            return .requestJSONEncodable(request)

        case .getChecklists, .getChecklistDetail, .deleteChecklist:
            return .requestPlain

        case .updateChecklist(_, let items):
            return .requestJSONEncodable(items)
        }
    }

    var headers: [String : String]? {
            var headers: [String: String] = [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
            
            if let token = TokenStorage.accessToken {
                headers["Authorization"] = "Bearer \(token)"
            }
            
            return headers
        }
}
