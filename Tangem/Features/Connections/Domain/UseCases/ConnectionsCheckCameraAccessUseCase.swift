//
//  ConnectionsCheckCameraAccessUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct ConnectionsCheckCameraAccessUseCase {
    private let cameraAccessProvider: any WalletConnectCameraAccessProvider
    private let openSystemSettingsAction: () -> Void

    init(cameraAccessProvider: some WalletConnectCameraAccessProvider, openSystemSettingsAction: @escaping () -> Void) {
        self.cameraAccessProvider = cameraAccessProvider
        self.openSystemSettingsAction = openSystemSettingsAction
    }

    func callAsFunction() -> Result {
        cameraAccessProvider.checkCameraAccess() == .denied
            ? .cameraAccessDenied(openSystemSettingsAction: openSystemSettingsAction)
            : .canOpenQRScanner
    }
}

// MARK: - Nested types

extension ConnectionsCheckCameraAccessUseCase {
    enum Result {
        case cameraAccessDenied(openSystemSettingsAction: () -> Void)
        case canOpenQRScanner
    }
}
