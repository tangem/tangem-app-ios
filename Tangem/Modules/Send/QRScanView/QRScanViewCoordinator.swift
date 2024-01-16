//
//  QRScanViewCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import AVFoundation

class QRScanViewCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published var imagePickerModel: PhotoSelectorViewModel?

    @Published private(set) var rootViewModel: QRScanViewModel?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = QRScanViewModel(code: options.code, text: options.text, router: self)
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

extension QRScanViewCoordinator: QRScanViewRoutable {
    func openImagePicker() {
        imagePickerModel = PhotoSelectorViewModel { [weak self] image in
            guard
                let image,
                let code = self?.scanQRCode(from: image)
            else {
                return
            }

            DispatchQueue.main.async {
                self?.rootViewModel?.code.wrappedValue = code
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self?.dismissAction(())
            }
        }
    }
}

// MARK: - Options

extension QRScanViewCoordinator {
    struct Options {
        let code: Binding<String>
        let text: String
    }
}
