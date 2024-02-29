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

    @Published var actionSheet: ActionSheetBinder?

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

    func t() {}
}

extension QRScanViewCoordinator: QRScanViewRoutable {
    func openImagePicker() {
        imagePickerModel = PhotoSelectorViewModel { [weak self] image in
            self?.rootViewModel?.didSelectImage(image)
        }
    }

    func openSettings() {
        UIApplication.openSystemSettings()
    }

    //!
    func present(_ actionSheet: ActionSheetBinder) {
        self.actionSheet = actionSheet
    }
}

// MARK: - Options

extension QRScanViewCoordinator {
    struct Options {
        let code: Binding<String>
        let text: String
    }
}
