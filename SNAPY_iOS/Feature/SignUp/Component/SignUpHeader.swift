//
//  SignUpHeader.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/20/26.
//

import SwiftUI

struct SignUpHeader: View {
    var onBack: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                
                // 뒤로가기
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.textWhite)
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                
                Image("Login_TextLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 25)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 40)
            .padding(.trailing, 65)
        }
    }
}
