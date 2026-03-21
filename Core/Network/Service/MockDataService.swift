//
//  MockDataService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/21/26.
//

import Foundation
import SwiftUI

final class MockDataService {
    static let shared = MockDataService()
    private init() {}
    
    
    // MARK: - Mock Profile
    func mockProfile() -> UserProfile {
        UserProfile(
            id: 1,
            username: "silver_c.ld",
            name: "김은찬",
            profileImageUrl: nil,
            backgroundImageUrl: nil,
            postCount: 5,
            friendCount: 13,
            streakCount: 2,
            mutualFriendsText: "zhnzx.8님, kimkihak08님 외 32명 친구 중 입니다"
        )
    }
}
