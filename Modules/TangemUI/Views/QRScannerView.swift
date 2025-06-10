//
//  QRScannerView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import AVFoundation
import SwiftUI

public struct QRScannerView: UIViewRepresentable {
    @Binding private var code: String
    @Environment(\.dismiss) private var dismissAction

    public init(code: Binding<String>) {
        _code = code
    }

    public func makeUIView(context: Context) -> QRScannerUIView {
        QRScannerUIView(delegate: context.coordinator)
    }

    public func updateUIView(_ uiView: QRScannerUIView, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(code: $code, dismissAction: dismissAction)
    }
}

public extension QRScannerView {
    final class Coordinator: NSObject, QRScannerUIView.Delegate {
        @Binding private var code: String
        private let dismissAction: DismissAction

        init(code: Binding<String>, dismissAction: DismissAction) {
            _code = code
            self.dismissAction = dismissAction
        }

        func qrScanningDidFail() {
            DispatchQueue.main.async {
                self.dismissAction()
            }
        }

        func qrScanningSucceeded(with qrCode: String) {
            code = qrCode

            DispatchQueue.main.async {
                self.dismissAction()
            }
        }
    }
}

public final class QRScannerUIView: UIView {
    protocol Delegate: AnyObject {
        func qrScanningDidFail()
        func qrScanningSucceeded(with qrCode: String)
    }

    private lazy var captureSession = AVCaptureSession()
    private let feedbackGenerator: UINotificationFeedbackGenerator
    private weak var delegate: (any Delegate)?

    init(delegate: some Delegate) {
        self.delegate = delegate
        feedbackGenerator = UINotificationFeedbackGenerator()

        super.init(frame: .zero)

        backgroundColor = .black
        clipsToBounds = true

        startSession()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override public var layer: AVCaptureVideoPreviewLayer {
        return super.layer as! AVCaptureVideoPreviewLayer
    }

    private func startSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            #if targetEnvironment(simulator)
            return
            #else
            scanningDidFail()
            return
            #endif
        }

        guard
            let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
            captureSession.canAddInput(videoInput)
        else {
            scanningDidFail()
            return
        }

        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()

        guard captureSession.canAddOutput(metadataOutput) else {
            scanningDidFail()
            return
        }

        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        layer.session = captureSession
        layer.videoGravity = .resizeAspectFill

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    private func scanningDidFail() {
        feedbackGenerator.notificationOccurred(.error)
        delegate?.qrScanningDidFail()
    }

    private func scanningSucceeded(with code: String) {
        feedbackGenerator.notificationOccurred(.success)
        delegate?.qrScanningSucceeded(with: code)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerUIView: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        captureSession.stopRunning()

        guard
            let readableCodeObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let qrCode = readableCodeObject.stringValue
        else {
            return
        }

        scanningSucceeded(with: qrCode)
    }
}
