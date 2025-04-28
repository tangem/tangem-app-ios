//
//  WalletConnectCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

final class WalletConnectCoordinator: CoordinatorObject {
    @Injected(\.walletConnectService) private var walletConnectService: any OldWalletConnectService
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Main view model

    @MainActor
    @Published private(set) var legacyViewModel: OldWalletConnectViewModel?

    @MainActor
    @Published private(set) var viewModel: WalletConnectViewModel?

    // MARK: - Child coordinators

    @Published var qrScanViewCoordinator: QRScanViewCoordinator? = nil

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: WalletConnectCoordinator.Options) {
        Task { @MainActor in
            if FeatureProvider.isAvailable(.walletConnectUI) {
                let establishDAppConnectionUseCase = WalletConnectEstablishDAppConnectionUseCase(
                    userWalletRepository: userWalletRepository,
                    uriProvider: UIPasteBoardWalletConnectURIProvider(pasteboard: .general, parser: .init()),
                    cameraAccessProvider: AVWalletConnectCameraAccessProvider(),
                    openSystemSettingsAction: UIApplication.openSystemSettings
                )

                viewModel = WalletConnectViewModel(
                    walletConnectService: walletConnectService,
                    userWalletRepository: userWalletRepository,
                    establishDAppConnectionUseCase: establishDAppConnectionUseCase
                )
            } else {
                legacyViewModel = OldWalletConnectViewModel(disabledLocalizedReason: options.disabledLocalizedReason, coordinator: self)
            }
        }
    }
}

extension WalletConnectCoordinator {
    struct Options {
        let disabledLocalizedReason: String?
    }
}

extension WalletConnectCoordinator: WalletConnectRoutable {
    func openQRScanner(with codeBinding: Binding<String>) {
        let coordinator = QRScanViewCoordinator { [weak self] in
            self?.qrScanViewCoordinator = nil
        }

        let options = QRScanViewCoordinator.Options(code: codeBinding, text: "")
        coordinator.start(with: options)
        qrScanViewCoordinator = coordinator
    }
}
