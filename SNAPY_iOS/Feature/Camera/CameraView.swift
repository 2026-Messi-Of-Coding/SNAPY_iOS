
//
//  CameraView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text("멀티캠 카메라")
                    .font(.title2)
                    .foregroundColor(.white)

                Text("추후 구현 예정")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Button("닫기") {
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.4))
                .cornerRadius(12)
                .padding(.top, 20)
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
