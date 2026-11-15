//
//  ConnectionsQRScanCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAccessibilityIdentifiers
import class TangemUI.Toast
import struct TangemUI.WarningToast

final class ConnectionsQRScanCoordinator: CoordinatorObject {
    let dismissAction: Action<ConnectionsQRScanResult?>
    let popToRootAction: Action<PopToRootOptions>

    @MainActor
    @Published private(set) var viewModel: ConnectionsQRScanViewModel?

    required init(dismissAction: @escaping Action<ConnectionsQRScanResult?>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            viewModel = ConnectionsQRScanViewModel(
                state: ConnectionsQRScanViewState(),
                cameraAccessProvider: options.cameraAccessProvider,
                openSystemSettingsAction: options.openSystemSettingsAction,
                coordinator: self
            )
        }
    }
}

extension ConnectionsQRScanCoordinator {
    struct Options {
        let cameraAccessProvider: any WalletConnectCameraAccessProvider
        let openSystemSettingsAction: () -> Void
    }
}

extension ConnectionsQRScanCoordinator: ConnectionsQRScanRoutable {
    func dismiss(with result: ConnectionsQRScanResult?) {
        dismissAction(result)
    }

    func display(error: some Error) {
        guard let errorMessage = error.toUniversalError().errorDescription else {
            return
        }

        Toast(
            view: WarningToast(text: errorMessage)
                .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.errorToast)
        )
        .present(layout: .top(padding: 20), type: .temporary())
    }
}
