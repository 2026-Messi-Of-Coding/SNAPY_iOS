import Foundation
import Combine
import Moya
import CombineMoya

final class LoanService {
    private let provider = MoyaProvider<LoanAPI>(
        plugins: [
            NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))
        ]
    )

    func createLoanGuide(request: LoanGuideRequestDTO) -> AnyPublisher<LoanGuideResponseDTO, Error> {
        provider.requestPublisher(.createLoanGuide(request: request))
            .tryMap { response in
                // 1) ApiResponse 래핑 형태
                if let wrapped = try? JSONDecoder().decode(ApiResponse<LoanGuideResponseDTO>.self, from: response.data) {
                    if wrapped.success, let data = wrapped.data {
                        return data
                    }
                    throw NSError(
                        domain: "LoanService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: wrapped.message]
                    )
                }

                // 2) 명세(객체) 형태
                return try JSONDecoder().decode(LoanGuideResponseDTO.self, from: response.data)
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}


