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

class QRScanViewModel: ObservableObject, Identifiable {
    @Published var isFlashActive = false

    let code: Binding<String>
    let text: String
    let router: QRScanViewRoutable

    init(code: Binding<String>, text: String, router: QRScanViewRoutable) {
        self.code = code
        self.text = text
        self.router = router
    }

    func toggleFlash() {
        guard
            let camera = AVCaptureDevice.default(for: .video),
            camera.hasTorch
        else {
            return
        }

        do {
            try camera.lockForConfiguration()

            // Do it before the actual changes because it's not immediate
            withAnimation(nil) {
                isFlashActive = !camera.isTorchActive
            }

            camera.torchMode = camera.isTorchActive ? .off : .on
            camera.unlockForConfiguration()
        } catch {
            AppLog.shared.debug("Failed to toggle the flash")
            AppLog.shared.error(error)
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
