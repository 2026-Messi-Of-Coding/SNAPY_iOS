import Foundation
import Moya
internal import Alamofire

enum LoanAPI {
    case createLoanGuide(request: LoanGuideRequestDTO)
}

extension LoanAPI: TargetType {
    var baseURL: URL { URL(string: "http://zipchak-backend.kro.kr:8080")! }

    var path: String {
        switch self {
        case .createLoanGuide:
            return "/api/loan"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createLoanGuide:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .createLoanGuide(let request):
            return .requestJSONEncodable(request)
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


