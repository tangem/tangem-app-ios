//
//  WalletConnectEstablishDAppConnectionUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class WalletConnectEstablishDAppConnectionUseCase {
    private let userWalletRepository: any UserWalletRepository
    private let cameraAccessProvider: any WalletConnectCameraAccessProvider
    private let openSystemSettingsAction: () -> Void

    init(
        userWalletRepository: some UserWalletRepository,
        cameraAccessProvider: some WalletConnectCameraAccessProvider,
        openSystemSettingsAction: @escaping () -> Void
    ) {
        self.userWalletRepository = userWalletRepository
        self.cameraAccessProvider = cameraAccessProvider
        self.openSystemSettingsAction = openSystemSettingsAction
    }

    func callAsFunction() throws(FeatureDisabledError) -> Result {
        try validateFeatureAvailability()

        let cameraAccessDenied = cameraAccessProvider.checkCameraAccess() == .denied

        return cameraAccessDenied
            ? .cameraAccessDenied(openSystemSettingsAction: openSystemSettingsAction)
            : .canOpenQRScanner
    }

    private func validateFeatureAvailability() throws(FeatureDisabledError) {
        guard let selectedWallet = userWalletRepository.selectedModel else { return }

        let walletConnectFeatureAvailability = selectedWallet.config.getFeatureAvailability(.walletConnect)

        switch walletConnectFeatureAvailability {
        case .available:
            break

        case .hidden, .disabled(.none):
            throw FeatureDisabledError(reason: nil)

        case .disabled(.some(let localizedReason)):
            throw FeatureDisabledError(reason: localizedReason)
        }
    }
}

// MARK: - Nested types

extension WalletConnectEstablishDAppConnectionUseCase {
    enum Result {
        case cameraAccessDenied(openSystemSettingsAction: () -> Void)
        case canOpenQRScanner
    }

    struct FeatureDisabledError: Swift.Error {
        let reason: String?
    }
}
