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
    private let shouldDismissOnSuccess: Bool
    private let shouldDismissOnFailure: Bool
    private let onScanningFailure: (() -> Void)?

    public init(
        code: Binding<String>,
        shouldDismissOnSuccess: Bool = true,
        shouldDismissOnFailure: Bool = true,
        onScanningFailure: (() -> Void)? = nil
    ) {
        _code = code
        self.shouldDismissOnSuccess = shouldDismissOnSuccess
        self.shouldDismissOnFailure = shouldDismissOnFailure
        self.onScanningFailure = onScanningFailure
    }

    public func makeUIView(context: Context) -> QRScannerUIView {
        QRScannerUIView(delegate: context.coordinator)
    }

    public func updateUIView(_ uiView: QRScannerUIView, context: Context) {
        uiView.restartSessionIfNeeded()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            code: $code,
            dismissAction: dismissAction,
            shouldDismissOnSuccess: shouldDismissOnSuccess,
            shouldDismissOnFailure: shouldDismissOnFailure,
            onScanningFailure: onScanningFailure
        )
    }
}

public extension QRScannerView {
    final class Coordinator: NSObject, QRScannerUIView.Delegate {
        @Binding private var code: String
        private let dismissAction: DismissAction
        private let shouldDismissOnSuccess: Bool
        private let shouldDismissOnFailure: Bool
        private let onScanningFailure: (() -> Void)?

        init(
            code: Binding<String>,
            dismissAction: DismissAction,
            shouldDismissOnSuccess: Bool,
            shouldDismissOnFailure: Bool,
            onScanningFailure: (() -> Void)?
        ) {
            _code = code
            self.dismissAction = dismissAction
            self.shouldDismissOnSuccess = shouldDismissOnSuccess
            self.shouldDismissOnFailure = shouldDismissOnFailure
            self.onScanningFailure = onScanningFailure
        }

        func qrScanningDidFail() {
            DispatchQueue.main.async {
                self.onScanningFailure?()
                guard self.shouldDismissOnFailure else { return }
                self.dismissAction()
            }
        }

        func qrScanningSucceeded(with qrCode: String) {
            code = qrCode

            DispatchQueue.main.async {
                guard self.shouldDismissOnSuccess else { return }
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
    private let sessionQueue = DispatchQueue(label: "com.tangem.qrscanner.session")
    private let feedbackGenerator: UINotificationFeedbackGenerator
    private weak var delegate: (any Delegate)?
    private var isSessionConfigured = false
    private var isSessionStarting = false

    init(delegate: some Delegate) {
        self.delegate = delegate
        feedbackGenerator = UINotificationFeedbackGenerator()

        super.init(frame: .zero)

        backgroundColor = .black
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil else {
            return
        }

        if isSessionConfigured {
            restartSessionIfNeeded()
        } else {
            startSession()
        }
    }

    override public class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override public var layer: AVCaptureVideoPreviewLayer {
        return super.layer as! AVCaptureVideoPreviewLayer
    }

    func restartSessionIfNeeded() {
        guard isSessionConfigured, !captureSession.isRunning, !isSessionStarting else {
            return
        }

        if let output = captureSession.outputs.first as? AVCaptureMetadataOutput {
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        }

        isSessionStarting = true
        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isSessionStarting = false
            }
        }
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
        isSessionConfigured = true

        sessionQueue.async {
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
        guard
            let readableCodeObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let qrCode = readableCodeObject.stringValue
        else {
            return
        }

        scanningSucceeded(with: qrCode)
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
}
