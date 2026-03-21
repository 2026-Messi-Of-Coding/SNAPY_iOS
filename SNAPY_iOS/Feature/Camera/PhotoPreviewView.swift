import SwiftUI

struct PhotoPreviewView: View {
    @EnvironmentObject var cameraVM: CameraViewModel

    private var lastPhoto: (front: UIImage?, back: UIImage?)? {
        cameraVM.capturedPhotos.last
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("사진 촬영 완료! 계속 하시겠습니까?")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.top, 20)

            Spacer()

            // Photo preview with dual images
            ZStack {
                // Back camera image (main)
                if let backImage = lastPhoto?.back {
                    Image(uiImage: backImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.15))
                }

                // Front camera image (small overlay)
                VStack {
                    HStack {
                        if let frontImage = lastPhoto?.front {
                            Image(uiImage: frontImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 130)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .black.opacity(0.5), radius: 5)
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(white: 0.25))
                                .frame(width: 100, height: 130)
                        }
                        Spacer()
                    }
                    .padding(12)
                    Spacer()
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .padding(.horizontal, 16)

            Spacer()

            // Action buttons
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
                    if cameraVM.capturedPhotos.count >= cameraVM.maxPhotos {
                        cameraVM.proceedToPost()
                    } else {
                        cameraVM.confirmPhoto()
                    }
                } label: {
                    Text("다음으로")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
