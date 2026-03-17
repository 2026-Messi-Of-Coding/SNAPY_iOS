//
//  MoyaProvider.swift
//  JeepChak
//
//  Created by 김은찬 on 12/4/25.
//

import Moya

extension MoyaProvider {
    func requestAsync(_ target: Target) async -> Result<Response, MoyaError> {
        await withCheckedContinuation { continuation in
            self.request(target) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
