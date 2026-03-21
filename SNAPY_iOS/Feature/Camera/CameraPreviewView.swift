import SwiftUI
import AVFoundation

//UIViewRepresentable 로 감싸 SwiftUI에서도 프리뷰 처리
struct CameraPreviewView: UIViewRepresentable {
    // UIKit 카메라 레이어를 SwiftUI로 브릿징
    let previewLayer: AVCaptureVideoPreviewLayer?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }

    // 기존 프리뷰 레이어 제거 → 새 레이어 추가 → frame 맞춤
    func updateUIView(_ uiView: UIView, context: Context) {
        // Remove old layers
        uiView.layer.sublayers?.filter { $0 is AVCaptureVideoPreviewLayer }.forEach { $0.removeFromSuperlayer() }

        guard let previewLayer = previewLayer else { return }
        previewLayer.frame = uiView.bounds
        uiView.layer.addSublayer(previewLayer)

        // Update frame when layout changes
        DispatchQueue.main.async {
            previewLayer.frame = uiView.bounds
        }
    }
}
