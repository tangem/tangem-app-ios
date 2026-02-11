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
    @Published private(set) var viewModel: WalletConnectViewModel?

    // MARK: - Child coordinators

    @MainActor
    @Published var qrScanCoordinator: WalletConnectQRScanCoordinator?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            viewModel = WalletConnectModuleFactory.makeWalletConnectViewModel(
                coordinator: self,
                prefetchedConnectedDApps: options.prefetchedConnectedDApps
            )
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
                guard let qrScanResult else {
                    // [REDACTED_USERNAME], next runloop cycle is required to avoid 'Publishing changes from within view updates is not allowed'.
                    DispatchQueue.main.async {
                        self?.qrScanCoordinator = nil
                    }
                    return
                }

                completion(qrScanResult)
                self?.qrScanCoordinator = nil
            }
        )

        coordinator.start(with: options)
        qrScanCoordinator = coordinator
    }
}
