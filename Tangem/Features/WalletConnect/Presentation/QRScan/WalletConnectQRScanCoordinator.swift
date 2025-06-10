//
//  WalletConnectQRScanCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class WalletConnectQRScanCoordinator: CoordinatorObject {
    let dismissAction: Action<WalletConnectQRScanResult?>
    let popToRootAction: Action<PopToRootOptions>

    @MainActor
    @Published private(set) var viewModel: WalletConnectQRScanViewModel?

    required init(dismissAction: @escaping Action<WalletConnectQRScanResult?>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            let pasteFromClipboardButton: WalletConnectQRScanViewState.PasteFromClipboardButton?

            if let clipboardURI = options.clipboardURI {
                pasteFromClipboardButton = WalletConnectQRScanViewState.PasteFromClipboardButton(clipboardURI: clipboardURI)
            } else {
                pasteFromClipboardButton = nil
            }

            let state = WalletConnectQRScanViewState(pasteFromClipboardButton: pasteFromClipboardButton)
            viewModel = WalletConnectQRScanViewModel(
                state: state,
                cameraAccessProvider: options.cameraAccessProvider,
                openSystemSettingsAction: options.openSystemSettingsAction,
                coordinator: self
            )
        }
    }
}

extension WalletConnectQRScanCoordinator {
    struct Options {
        let clipboardURI: WalletConnectRequestURI?
        let cameraAccessProvider: any WalletConnectCameraAccessProvider
        let openSystemSettingsAction: () -> Void
    }
}

extension WalletConnectQRScanCoordinator: WalletConnectQRScanRoutable {
    func openPhotoPicker() {}

    func openSystemSettings() {}

    func dismiss(with result: WalletConnectQRScanResult?) {
        dismissAction(result)
    }
}
