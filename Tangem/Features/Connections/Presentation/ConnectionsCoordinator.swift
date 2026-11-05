//
//  ConnectionsCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Combine.Published
import class Dispatch.DispatchQueue
import TangemAssets
import struct TangemFoundation.UserWalletId
import enum TangemLocalization.Localization
import struct TangemMCP.MCPSession
import struct TangemUI.TangemSnackbar
import class TangemUI.Toast

@MainActor
final class ConnectionsCoordinator: @MainActor CoordinatorObject {
    typealias InputOptions = Options
    typealias OutputOptions = Void

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var viewModel: ConnectionsViewModel?
    @Published var qrScanCoordinator: ConnectionsQRScanCoordinator?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        viewModel = ConnectionsModuleFactory.makeViewModel(
            coordinator: self,
            prefetchedConnectedDApps: options.prefetchedConnectedDApps
        )
    }
}

extension ConnectionsCoordinator {
    struct Options {
        let prefetchedConnectedDApps: [WalletConnectConnectedDApp]?
    }
}

// MARK: - ConnectionsRoutable

extension ConnectionsCoordinator: ConnectionsRoutable {
    func openQRScanner(completion: @escaping (ConnectionsQRScanResult) -> Void) {
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

    func openMCPConnectionRequest(
        userCode: String,
        preselectedUserWalletID: UserWalletId,
        connectionAcceptedAction: @escaping (UserWalletId) -> Void
    ) {
        guard let viewModel = MCPModuleFactory.makeConnectionRequestViewModel(
            userCode: userCode,
            preselectedUserWalletID: preselectedUserWalletID,
            connectionAcceptedAction: connectionAcceptedAction
        ) else {
            assertionFailure("Attempting to open MCP connection request without user wallets. Developer mistake.")
            return
        }

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func openMCPSessionDetails(_ session: MCPSession, sessionRevokedAction: @escaping () -> Void) {
        let revokedActionWithToast = { [weak self] in
            self?.presentSuccessSnackbar(title: Localization.mcpSessionRevoked)
            sessionRevokedAction()
        }

        guard let viewModel = MCPModuleFactory.makeSessionDetailsViewModel(session: session, sessionRevokedAction: revokedActionWithToast) else {
            assertionFailure("Attempting to open MCP session details for a user wallet that is not found. Developer mistake.")
            return
        }

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func openDAppConnectionProposal(
        forURI uri: WalletConnectRequestURI,
        source: Analytics.WalletConnectSessionSource,
        preselectedUserWalletID: UserWalletId
    ) {
        guard userWalletRepository.models.contains(where: { $0.config.isFeatureVisible(.walletConnect) }) else {
            presentErrorSnackbar(title: Localization.wcConnectionsNoWalletconnectWallets)
            return
        }

        guard let viewModel = WalletConnectModuleFactory.makeDAppConnectionViewModel(
            forURI: uri,
            source: source,
            preselectedUserWalletID: preselectedUserWalletID
        ) else {
            return
        }
        viewModel.loadDAppProposal()
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func openConnectedDAppDetails(_ dApp: WalletConnectConnectedDApp) {
        let dAppDetailsViewModel = WalletConnectModuleFactory.makeConnectedDAppDetailsViewModel(dApp)
        floatingSheetPresenter.enqueue(sheet: dAppDetailsViewModel)
    }

    func displayDisconnectAllSucceeded() {
        presentSuccessSnackbar(title: Localization.wcConnectionsDisconnectAllSuccess)
    }

    func displayDisconnectAllFailed() {
        presentErrorSnackbar(title: Localization.commonSomethingWentWrong)
    }

    func display(error: some Error) {
        guard let errorMessage = error.toUniversalError().errorDescription else {
            return
        }

        presentErrorSnackbar(title: errorMessage)
    }
}

// MARK: - Snackbars

extension ConnectionsCoordinator {
    private func presentSuccessSnackbar(title: String) {
        let snackbar = TangemSnackbar(title: title)
            .icon(DesignSystem.Icons.Checkmark.regular20)
            .iconColor(DesignSystem.Color.iconAccentBlue)

        Toast(view: snackbar)
            .present(layout: .top(padding: 20), type: .temporary())
    }

    private func presentErrorSnackbar(title: String) {
        let snackbar = TangemSnackbar(title: title)
            .icon(DesignSystem.Icons.Error.filled20)
            .iconColor(DesignSystem.Color.iconStatusError)

        Toast(view: snackbar)
            .present(layout: .top(padding: 20), type: .temporary())
    }
}
