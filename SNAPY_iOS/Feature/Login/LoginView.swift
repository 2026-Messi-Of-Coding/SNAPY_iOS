//
//  LoginView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
            ZStack {
                Color.BackgroundBlack
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack(spacing: 12) {
                        ZStack {
                            Image("Login_Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 34)
                        }
                        Image("Login_TextLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 28)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("로그인하여 친구들의 SNAPY를\n확인해보세요!")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.textWhite)
                            .lineSpacing(10)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.15))
                            .frame(height: 400)

                        VStack(spacing: 16) {
                            // 이미지 영역
                            ZStack {
    
                            }

                            Text("SNAPY")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    SnapyButton(title: "SNAPY로 계속하기") {
                        withAnimation {
                            authVM.authFlow = .loginSelection
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
