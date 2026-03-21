//
//  DualCameraService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/21/26.
//

import AVFoundation
import UIKit
import Combine

final class DualCameraService: NSObject, ObservableObject {
    @Published var backCameraImage: UIImage?
    @Published var frontCameraImage: UIImage?
    @Published var isRunning = false
    @Published var backPreviewLayer: AVCaptureVideoPreviewLayer?
    @Published var frontPreviewLayer: AVCaptureVideoPreviewLayer?

    private var multiCamSession: AVCaptureMultiCamSession?
    private var backCameraOutput = AVCapturePhotoOutput()
    private var frontCameraOutput = AVCapturePhotoOutput()
    private var backVideoOutput = AVCaptureVideoDataOutput()
    private var frontVideoOutput = AVCaptureVideoDataOutput()

    private var backConnection: AVCaptureConnection?
    private var frontConnection: AVCaptureConnection?

    private let sessionQueue = DispatchQueue(label: "com.snapy.camera.session")
    private let videoOutputQueue = DispatchQueue(label: "com.snapy.camera.videoOutput")

    private var captureCompletion: ((UIImage?, UIImage?) -> Void)?
    private var capturedBackPhoto: UIImage?
    private var capturedFrontPhoto: UIImage?
    private var pendingCaptures = 0

    var isMultiCamSupported: Bool {
        AVCaptureMultiCamSession.isMultiCamSupported
    }

    // 백그라운드 스레드 실행 - 카메라 설정은 무거운 작업이라 메인 스레드 블로킹 방지
    func setupSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    // 멀티캠 지원 여부 체크
    private func configureSession() {
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("MultiCam not supported, falling back to single camera")
            configureSingleCameraSession()
            return
        }

        let session = AVCaptureMultiCamSession()
        session.beginConfiguration()

        // Back camera
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let backInput = try? AVCaptureDeviceInput(device: backCamera) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(backInput) {
            session.addInputWithNoConnections(backInput)
        }

        // 후면 카메라
        if session.canAddOutput(backCameraOutput) {
            session.addOutputWithNoConnections(backCameraOutput)

            // Input의 port를 직접 지정해서 Connection을 만듦 - 핵심 로직
            if let port = backInput.ports(for: .video, sourceDeviceType: backCamera.deviceType, sourceDevicePosition: .back).first {
                let connection = AVCaptureConnection(inputPorts: [port], output: backCameraOutput)
                if session.canAddConnection(connection) {
                    session.addConnection(connection)
                    backConnection = connection
                }
            }
        }

        // 후면 카메라 - 실시간 프리뷰
        if session.canAddOutput(backVideoOutput) {
            session.addOutputWithNoConnections(backVideoOutput)
            backVideoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)

            if let port = backInput.ports(for: .video, sourceDeviceType: backCamera.deviceType, sourceDevicePosition: .back).first {
                let connection = AVCaptureConnection(inputPorts: [port], output: backVideoOutput)
                if session.canAddConnection(connection) {
                    session.addConnection(connection)
                }
            }
        }

        // Front camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let frontInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(frontInput) {
            session.addInputWithNoConnections(frontInput)
        }

        // 전면 카메라 - 사진 촬영
        if session.canAddOutput(frontCameraOutput) {
            session.addOutputWithNoConnections(frontCameraOutput)

            if let port = frontInput.ports(for: .video, sourceDeviceType: frontCamera.deviceType, sourceDevicePosition: .front).first {
                let connection = AVCaptureConnection(inputPorts: [port], output: frontCameraOutput)
                connection.automaticallyAdjustsVideoMirroring = false
                // 좌우반전 적용
                connection.isVideoMirrored = true
                if session.canAddConnection(connection) {
                    session.addConnection(connection)
                    frontConnection = connection
                }
            }
        }

        // 전면 카메라 - 실시간 프리뷰
        if session.canAddOutput(frontVideoOutput) {
            session.addOutputWithNoConnections(frontVideoOutput)
            frontVideoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)

            if let port = frontInput.ports(for: .video, sourceDeviceType: frontCamera.deviceType, sourceDevicePosition: .front).first {
                let connection = AVCaptureConnection(inputPorts: [port], output: frontVideoOutput)
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
                if session.canAddConnection(connection) {
                    session.addConnection(connection)
                }
            }
        }

        session.commitConfiguration()
        self.multiCamSession = session

        // Create preview layers
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let session = self.multiCamSession else { return }

            let backLayer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: session)
            backLayer.videoGravity = .resizeAspectFill
            if let port = backInput.ports(for: .video, sourceDeviceType: backCamera.deviceType, sourceDevicePosition: .back).first {
                let layerConnection = AVCaptureConnection(inputPort: port, videoPreviewLayer: backLayer)
                if session.canAddConnection(layerConnection) {
                    session.addConnection(layerConnection)
                }
            }
            // 화면에 보이는 레이어
            self.backPreviewLayer = backLayer

            let frontLayer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: session)
            frontLayer.videoGravity = .resizeAspectFill
            if let port = frontInput.ports(for: .video, sourceDeviceType: frontCamera.deviceType, sourceDevicePosition: .front).first {
                let layerConnection = AVCaptureConnection(inputPort: port, videoPreviewLayer: frontLayer)
                layerConnection.automaticallyAdjustsVideoMirroring = false
                layerConnection.isVideoMirrored = true
                if session.canAddConnection(layerConnection) {
                    session.addConnection(layerConnection)
                }
            }
            //화면에 보여주는 레이어 - 좌우반전 적용
            self.frontPreviewLayer = frontLayer
        }
    }

    private func configureSingleCameraSession() {
        // Fallback for devices without multi-cam support (like simulator)
        DispatchQueue.main.async {
            self.isRunning = false
        }
    }

    // 카메라 세션 시작
    func startSession() {
        sessionQueue.async { [weak self] in
            self?.multiCamSession?.startRunning()
            DispatchQueue.main.async {
                self?.isRunning = true
            }
        }
    }
    // 카메라 세션 중지
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.multiCamSession?.stopRunning()
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
    }

    
    func capturePhotos(completion: @escaping (UIImage?, UIImage?) -> Void) {
        captureCompletion = completion
        capturedBackPhoto = nil
        capturedFrontPhoto = nil
        // 후면 1장 + 전면 1장 촬영
        pendingCaptures = 2

        backCameraOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        frontCameraOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension DualCameraService: AVCapturePhotoCaptureDelegate {
    // 촬영 완료시 delegate 호출
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // pendingCaptures가 0이 되면 completion으로 두 이미지를 함께 반환
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            pendingCaptures -= 1
            checkCaptureCompletion()
            return
        }

        if output == backCameraOutput {
            capturedBackPhoto = image
        } else if output == frontCameraOutput {
            capturedFrontPhoto = image
        }

        pendingCaptures -= 1
        checkCaptureCompletion()
    }

    private func checkCaptureCompletion() {
        guard pendingCaptures <= 0 else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.backCameraImage = self.capturedBackPhoto
            self.frontCameraImage = self.capturedFrontPhoto
            self.captureCompletion?(self.capturedBackPhoto, self.capturedFrontPhoto)
            self.captureCompletion = nil
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension DualCameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Used for live preview updates if needed
    }
}
