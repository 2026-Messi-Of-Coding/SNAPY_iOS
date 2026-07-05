import SwiftUI

struct PhotoPreviewView: View {
    @EnvironmentObject var cameraVM: CameraViewModel
    @State private var isSwapped = false

    private var lastPhoto: (front: UIImage?, back: UIImage?)? {
        cameraVM.capturedPhotos.last
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(cameraVM.capturedTimeText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 40)

            Spacer()
                .frame(height: 30)

            // 듀얼캠
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // 풀사이즈: back 이미지
                    if let backImage = lastPhoto?.back {
                        Image(uiImage: backImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .opacity(isSwapped ? 0 : 1)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.15))
                    }

                    // 풀사이즈: front 이미지 (스왑 시 표시)
                    if let frontImage = lastPhoto?.front {
                        Image(uiImage: frontImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .opacity(isSwapped ? 1 : 0)
                    }

                    // PIP: 양쪽 이미지를 겹쳐서 크로스페이드
                    if let frontImage = lastPhoto?.front, let backImage = lastPhoto?.back {
                        DraggablePIP(
                            containerSize: geo.size,
                            pipWidth: 120,
                            pipHeight: 160,
                            padding: 12
                        ) {
                            ZStack {
                                Image(uiImage: frontImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(isSwapped ? 0 : 1)
                                Image(uiImage: backImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(isSwapped ? 1 : 0)
                            }
                        } onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.15, dampingFraction: 1)) {
                                isSwapped.toggle()
                            }
                        }
                    } else if let frontImage = lastPhoto?.front {
                        DraggablePIP(
                            containerSize: geo.size,
                            pipWidth: 120,
                            pipHeight: 160,
                            padding: 12
                        ) {
                            Image(uiImage: frontImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .padding(.horizontal, 16)

            Spacer()

            // 다시 찍기 / 저장하기 버튼
            HStack {
                Button {
                    cameraVM.retakePhoto()
                } label: {
                    Text("다시찍기")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }

                Spacer()

                Button {
                    Task { await cameraVM.savePhoto() }
                } label: {
                    Text(cameraVM.isUploading ? "업로드 중..." : "저장하기")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .disabled(cameraVM.isUploading)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .alert("업로드 실패", isPresented: .init(
            get: { cameraVM.errorMessage != nil },
            set: { if !$0 { cameraVM.errorMessage = nil } }
        )) {
            Button("확인") { cameraVM.errorMessage = nil }
        } message: {
            Text(cameraVM.errorMessage ?? "")
        }
    }
}
