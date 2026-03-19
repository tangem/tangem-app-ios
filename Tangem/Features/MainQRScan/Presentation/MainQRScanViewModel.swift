//
//  MainQRScanViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Combine
import SwiftUI
import TangemLocalization
import TangemUIUtils

@MainActor
final class MainQRScanViewModel: ObservableObject {
    @Published private(set) var hasCameraAccess = false
    @Published private(set) var isFlashActive = false
    @Published private(set) var scannerViewID = UUID()
    @Published var confirmationDialog: ConfirmationDialogViewModel?

    let hintText: String

    private weak var coordinator: MainQRScanRoutable?
    private var didProduceResult = false

    init(coordinator: MainQRScanRoutable) {
        self.coordinator = coordinator
        hintText = Localization.mainQrScanHint
    }

    // MARK: - Actions

    func onViewAppear() {
        checkCameraAccess()
    }

    func onQRCodeScanned(_ code: String) {
        guard !didProduceResult else {
            return
        }

        didProduceResult = true
        coordinator?.didScanQRCode(code)
    }

    func onPasteFromClipboard(_ string: String?) {
        guard let string = string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !string.isEmpty else {
            return
        }

        guard !didProduceResult else { return }
        didProduceResult = true
        coordinator?.didScanQRCode(string)
    }

    func rearmScanner() {
        didProduceResult = false
        scannerViewID = UUID()
    }

    func onScannerFailure() {
        MainQRScanLogger.warning(MainQRScanLoggerStrings.scannerSessionFailed)
        turnOffFlashIfNeeded()
        presentAccessDeniedAlert()
    }

    func onCloseTapped() {
        coordinator?.closeQRScanner()
    }

    func toggleFlash() {
        setFlashState(isActive: !isFlashActive)
    }

    func turnOffFlashIfNeeded() {
        guard isFlashActive else {
            return
        }

        setFlashState(isActive: false)
    }

    func openGallery() {
        coordinator?.openImagePicker()
    }

    func didSelectImage(_ image: UIImage?) {
        guard
            let image,
            let code = scanQRCode(from: image)
        else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.onQRCodeScanned(code)
        }
    }

    // MARK: - Private

    private func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraAccess = true
        case .denied:
            presentAccessDeniedAlert()
        default:
            requestCameraAccess()
        }
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.hasCameraAccess = true
                } else {
                    self?.presentAccessDeniedAlert()
                }
            }
        }
    }

    private func presentAccessDeniedAlert() {
        confirmationDialog = ConfirmationDialogViewModel(
            title: nil,
            buttons: [
                .init(title: Localization.qrScannerCameraDeniedGalleryButton) { [weak self] in
                    self?.openGallery()
                },
                .init(title: Localization.qrScannerCameraDeniedSettingsButton) { [weak self] in
                    self?.coordinator?.openSettings()
                },
                .init(title: Localization.commonCancel, role: .cancel) { [weak self] in
                    self?.coordinator?.closeQRScanner()
                },
            ]
        )
    }

    private func scanQRCode(from image: UIImage) -> String? {
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard
            let ciImage = CIImage(image: image),
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: options)
        else {
            return nil
        }

        return detector
            .features(in: ciImage)
            .lazy
            .compactMap { $0 as? CIQRCodeFeature }
            .first?
            .messageString
    }

    private func setFlashState(isActive: Bool) {
        guard
            let camera = AVCaptureDevice.default(for: .video),
            camera.hasTorch
        else {
            withAnimation(nil) {
                isFlashActive = false
            }

            return
        }

        do {
            try camera.lockForConfiguration()
            defer { camera.unlockForConfiguration() }

            camera.torchMode = isActive ? .on : .off

            withAnimation(nil) {
                isFlashActive = camera.isTorchActive
            }
        } catch {
            withAnimation(nil) {
                isFlashActive = false
            }
            assertionFailure("Failed to configure camera torch: \(error)")
        }
    }
}

// MARK: - Router Protocol

@MainActor
protocol MainQRScanRoutable: AnyObject {
    func didScanQRCode(_ code: String)
    func closeQRScanner()
    func openImagePicker()
    func openSettings()
}
