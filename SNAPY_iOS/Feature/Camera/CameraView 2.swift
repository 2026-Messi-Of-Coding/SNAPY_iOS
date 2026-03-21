import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var cameraVM: CameraViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if cameraVM.showPostConfirm {
                PostConfirmView()
                    .environmentObject(cameraVM)
            } else if cameraVM.showPreview {
                PhotoPreviewView()
                    .environmentObject(cameraVM)
            } else {
                cameraContentView
            }
        }
        .onAppear {
            cameraVM.checkCameraPermission()
        }
        .onDisappear {
            cameraVM.stopCamera()
        }
    }

    private var cameraContentView: some View {
        VStack(spacing: 0) {
            Text("추억이 남을 사진을 찍어보세요!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.top, 20)

            Spacer()

            // Dual camera preview
            ZStack {
                // Back camera (main - full size)
                if let backLayer = cameraVM.dualCamera.backPreviewLayer {
                    CameraPreviewView(previewLayer: backLayer)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.1))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .font(.system(size: 48))
                                Text("후면 카메라")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        )
                }

                // Front camera (small overlay - top left)
                VStack {
                    HStack {
                        ZStack {
                            if let frontLayer = cameraVM.dualCamera.frontPreviewLayer {
                                CameraPreviewView(previewLayer: frontLayer)
                                    .frame(width: 100, height: 130)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(white: 0.2))
                                    .frame(width: 100, height: 130)
                                    .overlay(
                                        VStack(spacing: 4) {
                                            Image(systemName: "camera.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 18))
                                            Text("전면")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 11))
                                        }
                                    )
                            }
                        }
                        .shadow(color: .black.opacity(0.5), radius: 5)
                        .padding(12)

                        Spacer()
                    }
                    Spacer()
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .padding(.horizontal, 16)

            // Photo count
            Text(cameraVM.photoCountText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.top, 20)

            // Capture controls
            HStack(spacing: 60) {
                Spacer()

                // Shutter button
                Button {
                    cameraVM.capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill(.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .disabled(cameraVM.capturedPhotos.count >= cameraVM.maxPhotos)

                // Switch camera info
                ZStack {
                    Circle()
                        .fill(Color(white: 0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                }

                Spacer()
            }
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
    }
}
