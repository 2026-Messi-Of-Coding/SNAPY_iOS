//
//  AnalyzeService.swift
//  JeepChak
//
//  Created by 김은찬 on 12/3/25.
//

import Foundation
import Combine
import Moya
import CombineMoya

final class AnalyzeService {
    private let provider = MoyaProvider<AnalyzeAPI>(
        plugins: [
            NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))
        ]
    )
    
    // MARK: - Debug helpers
    /// multipart/form-data는 바이너리가 포함되어 raw 전체 덤프가 위험하므로, 구조를 그대로 보여주는 "프리뷰"를 출력합니다.
    private func printMultipartRawPreview(requestJSON: String, files: [URL]) {
        let boundary = "zipchak.boundary.\(UUID().uuidString)"
        var preview = ""
        
        preview += "===== Multipart RAW Preview (boundary=\(boundary)) =====\n"
        preview += "--\(boundary)\r\n"
        preview += "Content-Disposition: form-data; name=\"request\"\r\n"
        preview += "Content-Type: application/json\r\n\r\n"
        preview += "\(requestJSON)\r\n"
        
        for fileURL in files {
            let fileName = fileURL.lastPathComponent
            let size = (try? Data(contentsOf: fileURL).count) ?? -1
            let mimeType: String = fileURL.pathExtension.lowercased() == "pdf" ? "application/pdf" : "application/octet-stream"
            
            preview += "--\(boundary)\r\n"
            preview += "Content-Disposition: form-data; name=\"files\"; filename=\"\(fileName)\"\r\n"
            preview += "Content-Type: \(mimeType)\r\n\r\n"
            preview += "<BINARY \(size) bytes>\r\n"
        }
        
        preview += "--\(boundary)--\r\n"
        preview += "=======================================================\n"
        print(preview)
        
        // curl 프리뷰(실제 boundary는 다를 수 있지만, 서버에 들어가는 형태를 그대로 재현)
        var curl = "curl -X POST 'http://zipchak-backend.kro.kr:8080/api/analysis' \\\n"
        curl += "  -H 'Accept: application/json' \\\n"
        if let token = TokenStorage.accessToken {
            curl += "  -H 'Authorization: Bearer \(token)' \\\n"
        }
        curl += "  -F 'request=\(requestJSON);type=application/json' \\\n"
        for fileURL in files {
            curl += "  -F 'files=@\(fileURL.path);type=application/pdf' \\\n"
        }
        print("===== curl Preview =====\n\(curl)\n========================")
    }
    
    // 위험도 분석 리포트
    func analyze(request: AnalyzeRequestDTO, files: [URL]) -> AnyPublisher<AnalyzeResponseDTO, Error> {
        // 요청 정보 로깅
        print("=== 분석 요청 정보 ===")
        print("propertyId: \(request.propertyId)")
        print("marketPrice: \(request.marketPrice)")
        print("deposit: \(request.deposit)")
        print("monthlyRent: \(request.monthlyRent)")
        let requestJSON = (try? JSONEncoder().encode(request))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        print("request(JSON): \(requestJSON)")
        print("파일 개수: \(files.count)")
        for (index, fileURL) in files.enumerated() {
            print("파일 \(index + 1): \(fileURL.lastPathComponent)")
        }
        if let token = TokenStorage.accessToken {
            print("토큰 존재: 예 (길이: \(token.count))")
        } else {
            print("토큰 존재: 아니오")
        }
        print("==================")
        
        // multipart raw 프리뷰(바이너리 제외)
        printMultipartRawPreview(requestJSON: requestJSON, files: files)
        
        return provider.requestPublisher(.analyze(request: request, files: files))
            .tryMap { response in
                print("=== 분석 응답 정보 ===")
                print("Status Code: \(response.statusCode)")
                print("Response Data 크기: \(response.data.count) bytes")

                // 2xx가 아니면 에러로 처리 (400도 여기서 잡아서 디코딩 에러 방지)
                guard (200..<300).contains(response.statusCode) else {
                    let raw = String(data: response.data, encoding: .utf8) ?? ""
                    let message = raw.isEmpty
                    ? "요청 실패 (status: \(response.statusCode))"
                    : raw
                    throw NSError(
                        domain: "AnalyzeService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: message]
                    )
                }
                
                // 응답 body가 비어있는 경우 처리
                guard !response.data.isEmpty else {
                    throw NSError(
                        domain: "AnalyzeService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "서버 응답이 비어있습니다."]
                    )
                }
                
                let responseBody = String(data: response.data, encoding: .utf8) ?? "디코딩 실패"
                print("응답 본문: \(responseBody)")
                
                let decoded = try JSONDecoder().decode(
                    ApiResponse<AnalyzeResponseDTO>.self,
                    from: response.data
                )
                if decoded.success, let data = decoded.data {
                    print("분석 성공!")
                    return data
                } else {
                    print("분석 실패: \(decoded.message)")
                    throw NSError(
                        domain: "AnalyzeService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: decoded.message]
                    )
                }
            }
            .mapError { error in
                print("에러 발생: \(error.localizedDescription)")
                return error
            }
            .eraseToAnyPublisher()
    }
    
    // 분석 내용 조회
    func getAnalyzeDetail(id: Int) -> AnyPublisher<AnalyzeResponseDTO, Error> {
        provider.requestPublisher(.getAnalyzeDetail(id: id))
            .tryMap { response in
                let decoded = try JSONDecoder().decode(
                    ApiResponse<AnalyzeResponseDTO>.self,
                    from: response.data
                )
                if decoded.success, let data = decoded.data {
                    return data
                } else {
                    throw NSError(
                        domain: "AnalyzeService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: decoded.message]
                    )
                }
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // 대처 방안 확인
    func riskSolution(request: RiskSolutionRequestDTO, files: [URL]) -> AnyPublisher<RiskSolutionResponseDTO, Error> {
        // 요청 raw 프리뷰(바이너리 제외)
        let requestJSON = (try? JSONEncoder().encode(request))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        print("=== 대처 방안 요청 정보 ===")
        print("request(JSON): \(requestJSON)")
        print("파일 개수: \(files.count)")
        for (index, fileURL) in files.enumerated() {
            print("파일 \(index + 1): \(fileURL.lastPathComponent)")
        }
        print("==================")
        printMultipartRawPreview(requestJSON: requestJSON, files: files)
        
        return provider.requestPublisher(.riskSolution(request: request, files: files))
            .tryMap { response in
                let decoded = try JSONDecoder().decode(
                    ApiResponse<RiskSolutionResponseDTO>.self,
                    from: response.data
                )
                if decoded.success, let data = decoded.data {
                    return data
                } else {
                    throw NSError(
                        domain: "AnalyzeService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: decoded.message]
                    )
                }
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // 대처 방안 조회
    func getRiskSolution(id: Int) -> AnyPublisher<RiskSolutionResponseDTO, Error> {
        provider.requestPublisher(.getRiskSolution(id: id))
            .tryMap { response in
                let decoded = try JSONDecoder().decode(
                    ApiResponse<RiskSolutionResponseDTO>.self,
                    from: response.data
                )
                if decoded.success, let data = decoded.data {
                    return data
                } else {
                    throw NSError(
                        domain: "AnalyzeService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: decoded.message]
                    )
                }
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

