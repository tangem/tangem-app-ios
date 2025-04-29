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

    private lazy var cameraAccessProvider = AVWalletConnectCameraAccessProvider()
    private let openSystemSettingsAction = UIApplication.openSystemSettings

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Main view model

    @MainActor
    @Published private(set) var legacyViewModel: OldWalletConnectViewModel?

    @MainActor
    @Published private(set) var viewModel: WalletConnectViewModel?

    // MARK: - Child coordinators

    @MainActor
    @Published var qrScanCoordinator: WalletConnectQRScanCoordinator?

    @MainActor
    @Published var legacyQRScanViewCoordinator: QRScanViewCoordinator?

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
                    cameraAccessProvider: cameraAccessProvider,
                    openSystemSettingsAction: openSystemSettingsAction
                )

                viewModel = WalletConnectViewModel(
                    walletConnectService: walletConnectService,
                    userWalletRepository: userWalletRepository,
                    establishDAppConnectionUseCase: establishDAppConnectionUseCase,
                    coordinator: self
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
    func openQRScanner(clipboardURI: WalletConnectRequestURI?, completion: @escaping (WalletConnectQRScanResult) -> Void) {
        let coordinator = WalletConnectQRScanCoordinator(
            dismissAction: { [weak self] qrScanResult in
                if let qrScanResult {
                    completion(qrScanResult)
                }

                self?.qrScanCoordinator = nil
            }
        )

        let options = WalletConnectQRScanCoordinator.Options(
            clipboardURI: clipboardURI,
            cameraAccessProvider: cameraAccessProvider,
            openSystemSettingsAction: openSystemSettingsAction
        )
        coordinator.start(with: options)
        qrScanCoordinator = coordinator
    }

    func legacyOpenQRScanner(with codeBinding: Binding<String>) {
        let coordinator = QRScanViewCoordinator { [weak self] in
            self?.legacyQRScanViewCoordinator = nil
        }

        let options = QRScanViewCoordinator.Options(code: codeBinding, text: "")
        coordinator.start(with: options)
        legacyQRScanViewCoordinator = coordinator
    }
}
