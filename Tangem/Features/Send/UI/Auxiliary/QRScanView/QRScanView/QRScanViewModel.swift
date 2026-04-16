//
//  QRScanViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import AVFoundation
import PhotosUI
import TangemLocalization
import struct TangemUIUtils.ConfirmationDialogViewModel

final class QRScanViewModel: ObservableObject, Identifiable {
    @Published var isFlashActive = false
    @Published var confirmationDialog: ConfirmationDialogViewModel?
    @Published var hasCameraAccess = false

    let code: Binding<String>
    let text: String
    let router: QRScanViewRoutable

    init(code: Binding<String>, text: String, router: QRScanViewRoutable) {
        self.code = code
        self.text = text
        self.router = router
    }

    func onAppear() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraAccess = true
        case .denied:
            presentAccessDeniedAlert()
        default:
            requestCameraAccess()
        }
    }

    func toggleFlash() {
        let newState = !isFlashActive
        setFlashState(isActive: newState)
    }

    private func setFlashState(isActive: Bool) {
        guard
            let camera = AVCaptureDevice.default(for: .video),
            camera.hasTorch
        else {
            isFlashActive = false
            return
        }

        do {
            try camera.lockForConfiguration()
            defer { camera.unlockForConfiguration() }

            camera.torchMode = isActive ? .on : .off
            isFlashActive = camera.isTorchActive
        } catch {
            isFlashActive = false
            AppLogger.error("Failed to toggle the flash", error: error)
        }
    }

    func scanFromGallery() {
        router.openImagePicker()
    }

    func didSelectImage(_ image: UIImage?) {
        guard
            let image,
            let code = scanQRCode(from: image)
        else {
            return
        }

        DispatchQueue.main.async {
            self.code.wrappedValue = code
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.router.dismiss()
        }
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }

            if granted {
                DispatchQueue.main.async {
                    self.hasCameraAccess = true
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.presentAccessDeniedAlert()
                }
            }
        }
    }

    private func presentAccessDeniedAlert() {
        let selectFromGalleryButton = ConfirmationDialogViewModel.Button(title: Localization.qrScannerCameraDeniedGalleryButton) { [router] in
            router.openImagePicker()
        }

        let settingsButton = ConfirmationDialogViewModel.Button(title: Localization.qrScannerCameraDeniedSettingsButton) { [router] in
            router.openSettings()
        }

        let cancelButton = ConfirmationDialogViewModel.Button(
            title: Localization.commonCancel,
            role: .cancel,
            action: { [router] in
                router.dismiss()
            }
        )

        confirmationDialog = ConfirmationDialogViewModel(
            title: Localization.qrScannerCameraDeniedTitle,
            subtitle: Localization.qrScannerCameraDeniedText,
            buttons: [
                selectFromGalleryButton,
                settingsButton,
                cancelButton,
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
}
