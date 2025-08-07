//
//  WalletConnectCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

final class WalletConnectCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

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

    func start(with options: Options) {
        Task { @MainActor in
            if FeatureProvider.isAvailable(.walletConnectUI) {
                viewModel = WalletConnectModuleFactory.makeWalletConnectViewModel(
                    coordinator: self,
                    prefetchedConnectedDApps: options.prefetchedConnectedDApps
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
        let prefetchedConnectedDApps: [WalletConnectConnectedDApp]?
    }
}

extension WalletConnectCoordinator: WalletConnectRoutable {
    func openDAppConnectionProposal(forURI uri: WalletConnectRequestURI, source: Analytics.WalletConnectSessionSource) {
        guard let viewModel = WalletConnectModuleFactory.makeDAppConnectionViewModel(forURI: uri, source: source) else { return }
        viewModel.loadDAppProposal()
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func openConnectedDAppDetails(_ dApp: WalletConnectConnectedDApp) {
        floatingSheetPresenter.enqueue(sheet: WalletConnectModuleFactory.makeConnectedDAppDetailsViewModel(dApp))
    }

    func openQRScanner(completion: @escaping (WalletConnectQRScanResult) -> Void) {
        let (coordinator, options) = WalletConnectModuleFactory.makeQRScanFlow(
            dismissAction: { [weak self] qrScanResult in
                if let qrScanResult {
                    completion(qrScanResult)
                }

                self?.qrScanCoordinator = nil
            }
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
