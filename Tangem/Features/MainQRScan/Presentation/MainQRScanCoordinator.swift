//
//  MainQRScanCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

final class MainQRScanCoordinator: CoordinatorObject {
    let dismissAction: Action<String?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: MainQRScanViewModel?

    // MARK: - Child view models

    @Published var imagePickerModel: PhotoSelectorViewModel?

    required init(
        dismissAction: @escaping Action<String?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            rootViewModel = MainQRScanViewModel(coordinator: self)
        }
    }
}

// MARK: - Options

extension MainQRScanCoordinator {
    struct Options {}
}

// MARK: - MainQRScanRoutable

extension MainQRScanCoordinator: MainQRScanRoutable {
    func didScanQRCode(_ code: String) {
        dismissAction(code)
    }

    func closeQRScanner() {
        dismissAction(nil)
    }

    func openImagePicker() {
        imagePickerModel = PhotoSelectorViewModel { [weak self] image in
            self?.rootViewModel?.didSelectImage(image)
        }
    }

    func openSettings() {
        UIApplication.openSystemSettings()
    }
}
