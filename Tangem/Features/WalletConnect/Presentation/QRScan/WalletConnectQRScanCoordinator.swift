//
//  WalletConnectQRScanCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import class TangemUI.Toast
import struct TangemUI.WarningToast

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
            viewModel = WalletConnectQRScanViewModel(
                state: WalletConnectQRScanViewState(),
                cameraAccessProvider: options.cameraAccessProvider,
                openSystemSettingsAction: options.openSystemSettingsAction,
                coordinator: self
            )
        }
    }
}

extension WalletConnectQRScanCoordinator {
    struct Options {
        let cameraAccessProvider: any WalletConnectCameraAccessProvider
        let openSystemSettingsAction: () -> Void
    }
}

extension WalletConnectQRScanCoordinator: WalletConnectQRScanRoutable {
    func dismiss(with result: WalletConnectQRScanResult?) {
        dismissAction(result)
    }

    func display(error: some Error) {
        guard let errorMessage = error.toUniversalError().errorDescription else {
            return
        }

        Toast(view: WarningToast(text: errorMessage))
            .present(layout: .top(padding: 20), type: .temporary())
    }
}
