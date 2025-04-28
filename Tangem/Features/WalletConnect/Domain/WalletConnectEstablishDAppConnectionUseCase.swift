//
//  WalletConnectEstablishDAppConnectionUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class WalletConnectEstablishDAppConnectionUseCase {
    private let userWalletRepository: any UserWalletRepository
    private let uriProvider: any WalletConnectURIProvider
    private let cameraAccessProvider: any WalletConnectCameraAccessProvider
    private let openSystemSettingsAction: () -> Void

    init(
        userWalletRepository: some UserWalletRepository,
        uriProvider: some WalletConnectURIProvider,
        cameraAccessProvider: some WalletConnectCameraAccessProvider,
        openSystemSettingsAction: @escaping () -> Void
    ) {
        self.userWalletRepository = userWalletRepository
        self.uriProvider = uriProvider
        self.cameraAccessProvider = cameraAccessProvider
        self.openSystemSettingsAction = openSystemSettingsAction
    }

    func callAsFunction() throws(FeatureDisabledError) -> Result {
        try validateFeatureAvailability()

        let clipboardURI = try? uriProvider.tryExtractClipboardURI()
        let cameraAccessDenied = cameraAccessProvider.checkCameraAccess() == .denied

        return cameraAccessDenied
            ? .cameraAccessDenied(clipboardURI: clipboardURI, openSystemSettingsAction: openSystemSettingsAction)
            : .canOpenQRScanner(clipboardURI: clipboardURI)
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
        case cameraAccessDenied(clipboardURI: WalletConnectRequestURI?, openSystemSettingsAction: () -> Void)
        case canOpenQRScanner(clipboardURI: WalletConnectRequestURI?)
    }

    struct FeatureDisabledError: Swift.Error {
        let reason: String?
    }
}
