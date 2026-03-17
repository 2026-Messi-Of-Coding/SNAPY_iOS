//
//  ChecklistService.swift
//  JeepChak
//
//  Created by 김은찬 on 11/15/25.
//

import Foundation
import Combine
import Moya
import CombineMoya

final class ChecklistService {
    private let provider = MoyaProvider<ChecklistAPI>(
        plugins: [
            NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))
        ]
    )
    
    func generateChecklist(request: ChecklistGenerateRequest) -> AnyPublisher<[GeneratedChecklistResponse], Error> {
        provider.requestPublisher(.generateChecklist(request: request))
            .tryMap { response in
                print("status:", response.statusCode)
                print(String(data: response.data, encoding: .utf8) ?? "nil")

                // 응답: {"success":true,"message":"success","data":{"contents":["질문1", "질문2", ...]}}
                let decoded = try JSONDecoder().decode(
                    ApiResponse<GeneratedChecklistResponse>.self,
                    from: response.data
                )
                
                if decoded.success {
                    // contents 배열을 처리
                    if let data = decoded.data, let contents = data.contents, !contents.isEmpty {
                        // contents 배열의 각 항목을 개별 GeneratedChecklistResponse로 변환
                        // 호환성을 위한 배열로 반환
                        return contents.map { content in
                            GeneratedChecklistResponse(contents: [content])
                        }
                    } else {
                        // data가 null이거나 contents가 없는 경우 빈 배열 반환
                        print("경고: contents 배열이 비어있거나 null입니다.")
                        return []
                    }
                } else {
                    let msg = decoded.message
                    throw NSError(
                        domain: "ChecklistService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: msg]
                    )
                }
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // 체크리스트 삭제: DELETE /api/checklist/{id}
    func deleteChecklist(id: Int) -> AnyPublisher<String, Error> {
        provider.requestPublisher(.deleteChecklist(id: id))
            .tryMap { response in
                // 응답: { message: "Checklist deleted successfully" }
                let decoded = try JSONDecoder().decode(
                    ApiResponse<String>.self,
                    from: response.data
                )
                
                if decoded.success {
                    return decoded.message
                } else {
                    throw NSError(
                        domain: "ChecklistService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: decoded.message]
                    )
                }
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // 체크리스트 저장: POST /api/checklist
    func saveChecklist(request: ChecklistSaveRequest) -> AnyPublisher<ChecklistResponse, Error> {
        provider.requestPublisher(.saveChecklist(request: request))
            .tryMap { response in
                let decoded = try JSONDecoder().decode(
                    ApiResponse<ChecklistResponse>.self,
                    from: response.data
                )
                if decoded.success, let data = decoded.data {
                    return data
                } else {
                    throw NSError(
                        domain: "ChecklistService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: decoded.message]
                    )
                }
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // 체크리스트 수정: PUT /api/checklist/{id}
    func updateChecklist(id: Int, items: [ChecklistUpdateRequest]) -> AnyPublisher<ChecklistUpdateResponse, Error> {
        provider.requestPublisher(.updateChecklist(id: id, items: items))
            .tryMap { response in
                let decoded = try JSONDecoder().decode(
                    ApiResponse<ChecklistUpdateResponse>.self,
                    from: response.data
                )
                if decoded.success, let data = decoded.data {
                    return data
                } else {
                    throw NSError(
                        domain: "ChecklistService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: decoded.message]
                    )
                }
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // 전체 체크리스트 조회: GET /api/checklist
    func getChecklists() -> AnyPublisher<[ChecklistListResponse], Error> {
        provider.requestPublisher(.getChecklists)
            .tryMap { response in
                // 1) ApiResponse 래핑 형태
                if let wrapped = try? JSONDecoder().decode(ApiResponse<[ChecklistListResponse]>.self, from: response.data) {
                    if wrapped.success {
                        return wrapped.data ?? []
                    }
                    throw NSError(
                        domain: "ChecklistService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: wrapped.message]
                    )
                }

                // 2) 명세(배열) 형태
                return try JSONDecoder().decode([ChecklistListResponse].self, from: response.data)
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    // 체크리스트 상세 조회: GET /api/checklist/{id}
    func getChecklistDetail(id: Int) -> AnyPublisher<ChecklistDetailResponse, Error> {
        provider.requestPublisher(.getChecklistDetail(id: id))
            .tryMap { response in
                if let wrapped = try? JSONDecoder().decode(ApiResponse<ChecklistDetailResponse>.self, from: response.data) {
                    if wrapped.success, let data = wrapped.data {
                        return data
                    }
                    throw NSError(
                        domain: "ChecklistService",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: wrapped.message]
                    )
                }

                return try JSONDecoder().decode(ChecklistDetailResponse.self, from: response.data)
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

}
