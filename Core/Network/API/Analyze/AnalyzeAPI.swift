//
//  AnalyzeAPI.swift
//  JeepChak
//
//  Created by 김은찬 on 12/3/25.
//

import Foundation
import Moya
internal import Alamofire

enum AnalyzeAPI {
    case analyze(request: AnalyzeRequestDTO, files: [URL])
    case getAnalyzeDetail(id: Int)
    case riskSolution(request: RiskSolutionRequestDTO, files: [URL])
    case getRiskSolution(id: Int)
}

extension AnalyzeAPI: TargetType {
    var baseURL: URL {
        URL(string: "http://zipchak-backend.kro.kr:8080")!
    }
    
    var path: String {
        switch self {
        case .analyze:
            return "/api/analysis"
        case .getAnalyzeDetail(let id):
            return "/api/analysis/\(id)"
        case .riskSolution:
            return "/api/risk/solution"
        case .getRiskSolution(let id):
            return "/api/risk/solution/\(id)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .analyze, .riskSolution:
            return .post
        case .getAnalyzeDetail, .getRiskSolution:
            return .get
        }
    }
    
    var task: Task {
        switch self {
        case .analyze(let request, let files):
            var formData: [Moya.MultipartFormData] = []
            
            // ✅ 서버가 @RequestPart("request") 형태(JSON 파트)를 요구하는 경우를 위해 request JSON도 함께 전송
            if let json = try? JSONEncoder().encode(request) {
                formData.append(
                    // Postman의 Text 필드처럼 filename 없이 보내야 서버가 "request" 파트를 올바르게 파싱하는 경우가 많음
                    Moya.MultipartFormData(
                        provider: .data(json),
                        name: "request",
                        mimeType: "application/json"
                    )
                )
            }
            
            for fileURL in files {
                let hasAccess = fileURL.startAccessingSecurityScopedResource()
                
                do {
                    // 파일이 실제로 존재하는지 확인
                    guard FileManager.default.fileExists(atPath: fileURL.path) else {
                        print("파일이 존재하지 않음: \(fileURL.path)")
                        if hasAccess {
                            fileURL.stopAccessingSecurityScopedResource()
                        }
                        continue
                    }
                    
                    // 파일 데이터 읽기
                    let fileData = try Data(contentsOf: fileURL)
                    let fileName = fileURL.lastPathComponent
                    
                    // 접근 권한 해제 (데이터를 이미 읽었으므로)
                    if hasAccess {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                    
                    formData.append(Moya.MultipartFormData(
                        provider: .data(fileData),
                        name: "files",
                        fileName: fileName,
                        mimeType: mimeType(for: fileURL)
                    ))
                    print("파일 추가 성공: \(fileName), 크기: \(fileData.count) bytes, mimeType: \(mimeType(for: fileURL))")
                } catch {
                    print("파일 읽기 실패: \(fileURL.lastPathComponent), 오류: \(error.localizedDescription)")
                    if hasAccess {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
            }
            
            // 파일이 하나도 추가되지 않았으면 오류
            let fileCount = formData.filter { $0.name == "files" }.count
            print("=== Multipart Form Data 구성 ===")
            print("전체 필드 수: \(formData.count)")
            print("파일 필드 수: \(fileCount)")
            print("데이터 필드: request(json)")
            if fileCount == 0 {
                print("경고: 업로드할 파일이 없습니다.")
            } else {
                print("파일이 성공적으로 추가되었습니다.")
            }
            print("==============================")
            
            return .uploadMultipart(formData)
            
        case .riskSolution(let request, let files):
            var formData: [Moya.MultipartFormData] = []

            // ✅ 서버가 @RequestPart("request") 형태(JSON 파트)를 요구하는 경우를 위해 request JSON도 함께 전송
            if let json = try? JSONEncoder().encode(request) {
                formData.append(
                    // Postman의 Text 필드처럼 filename 없이 전송
                    Moya.MultipartFormData(
                        provider: .data(json),
                        name: "request",
                        mimeType: "application/json"
                    )
                )
            }
            
            for fileURL in files {
                // 파일 접근 권한 확인 및 획득
                let hasAccess = fileURL.startAccessingSecurityScopedResource()
                
                do {
                    guard FileManager.default.fileExists(atPath: fileURL.path) else {
                        if hasAccess {
                            fileURL.stopAccessingSecurityScopedResource()
                        }
                        continue
                    }
                    
                    let fileData = try Data(contentsOf: fileURL)
                    let fileName = fileURL.lastPathComponent
                    
                    if hasAccess {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                    
                    formData.append(Moya.MultipartFormData(
                        provider: .data(fileData),
                        name: "files",
                        fileName: fileName,
                        mimeType: mimeType(for: fileURL)
                    ))
                } catch {
                    if hasAccess {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
            }
            
            return .uploadMultipart(formData)
            
        case .getAnalyzeDetail, .getRiskSolution:
            return .requestPlain
        }
    }
    
    var headers: [String: String]? {
        var headers: [String: String] = [
            "Accept": "application/json"
        ]
        
        switch self {
        case .analyze(_, let files), .riskSolution(_, let files):
            break
        default:
            headers["Content-Type"] = "application/json"
        }
        
        if let token = TokenStorage.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
    
    private func mimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "pdf":
            return "application/pdf"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        default:
            return "application/octet-stream"
        }
    }
}


