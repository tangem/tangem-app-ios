//
//  WalletConnectViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import enum TangemAssets.Assets
import TangemLocalization
import TangemLogger
import TangemFoundation
import struct TangemUIUtils.ConfirmationDialogViewModel

@MainActor
final class WalletConnectViewModel: ObservableObject {
    private let interactor: WalletConnectInteractor
    private let userWalletRepository: any UserWalletRepository
    private let cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider
    private let analyticsLogger: any WalletConnectAnalyticsLogger
    private let logger: TangemLogger.Logger

    private weak var coordinator: (any WalletConnectRoutable)?

    private var initialLoadingTask: Task<Void, Never>?
    private var connectedDAppsUpdateHandleTask: Task<Void, Never>?
    private var disconnectAllDAppsTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectViewState

    init(
        interactor: WalletConnectInteractor,
        userWalletRepository: some UserWalletRepository,
        cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider,
        analyticsLogger: some WalletConnectAnalyticsLogger,
        logger: TangemLogger.Logger,
        coordinator: some WalletConnectRoutable,
        prefetchedConnectedDApps: [WalletConnectConnectedDApp]?
    ) {
        self.interactor = interactor
        self.userWalletRepository = userWalletRepository
        self.cryptoAccountsGlobalStateProvider = cryptoAccountsGlobalStateProvider
        self.analyticsLogger = analyticsLogger
        self.logger = logger
        self.coordinator = coordinator

        if let prefetchedConnectedDApps {
            state = Self.makeState(
                from: prefetchedConnectedDApps,
                userWalletRepository: userWalletRepository,
                cryptoAccountsState: cryptoAccountsGlobalStateProvider.globalCryptoAccountsState()
            )
        } else {
            state = .loading
            fetchConnectedDApps()
        }

        subscribeToConnectedDAppsUpdates()
    }

    deinit {
        initialLoadingTask?.cancel()
        connectedDAppsUpdateHandleTask?.cancel()
        disconnectAllDAppsTask?.cancel()
    }

    private func fetchConnectedDApps() {
        initialLoadingTask?.cancel()

        initialLoadingTask = Task { [interactor, logger, weak self] in
            await interactor.extendConnectedDApps()

            guard !Task.isCancelled else { return }

            let connectedDApps: [WalletConnectConnectedDApp]

            do throws(WalletConnectDAppPersistenceError) {
                connectedDApps = try await interactor.getConnectedDApps()
            } catch {
                connectedDApps = []
                logger.error("Initial dApps list fetch failed", error: error)
            }

            self?.handle(viewEvent: .connectedDAppsChanged(connectedDApps))
            self?.subscribeToConnectedDAppsUpdates()
        }
    }

    private func subscribeToConnectedDAppsUpdates() {
        connectedDAppsUpdateHandleTask = Task { [weak self, getConnectedDAppsStream = interactor.getConnectedDApps] in
            for await connectedDApps in await getConnectedDAppsStream() {
                self?.handle(viewEvent: .connectedDAppsChanged(connectedDApps))
            }
        }
    }

    private func disconnectAllConnectedDApps() {
        guard case .content(let walletsWithDApps) = state.contentState else { return }

        connectedDAppsUpdateHandleTask?.cancel()
        disconnectAllDAppsTask?.cancel()

        let allConnectedDApps = walletsWithDApps.flatMap { wallet in
            wallet.accountSections.flatMap(\.dApps) + wallet.walletLevelDApps
        }

        disconnectAllDAppsTask = Task { [weak self, disconnectDApp = interactor.disconnectDApp, analyticsLogger, logger] in
            await withTaskGroup(of: Void.self) { group in
                for dApp in allConnectedDApps {
                    group.addTask {
                        do {
                            try await disconnectDApp(dApp.domainModel)
                            analyticsLogger.logDAppDisconnected(dAppData: dApp.domainModel.dAppData)
                        } catch {
                            logger.error("Failed to disconnect \(dApp.domainModel.dAppData.name) dApp", error: error)
                        }
                    }
                }
            }

            self?.showDisconnectAllDAppsToast()
            self?.state.contentState = .empty
            self?.subscribeToConnectedDAppsUpdates()
        }
    }

    private func showDisconnectAllDAppsToast() {
        WalletConnectModuleFactory.makeSuccessToast(with: Localization.wcDisconnectAllAlertTitle)
            .present(layout: .top(padding: 20), type: .temporary())
    }
}

// MARK: - View events handling

extension WalletConnectViewModel {
    func handle(viewEvent: WalletConnectViewEvent) {
        switch viewEvent {
        case .viewDidAppear:
            handleViewDidAppear()

        case .newConnectionButtonTapped:
            handleNewConnectionButtonTapped()

        case .disconnectAllDAppsButtonTapped:
            handleDisconnectAllDAppsButtonTapped()

        case .dAppTapped(let dApp):
            handleDAppButtonTapped(dApp)

        case .connectedDAppsChanged(let connectedDApps):
            handleConnectedDAppsChanged(connectedDApps)

        case .closeDialogButtonTapped:
            handleCloseDialogButtonTapped()
        }
    }

    private func handleViewDidAppear() {
        analyticsLogger.logScreenOpened()
    }

    private func handleNewConnectionButtonTapped() {
        guard !state.newConnectionButton.isLoading else { return }

        do {
            let newDAppConnectionResult = try interactor.establishDAppConnection()

            switch newDAppConnectionResult {
            case .cameraAccessDenied(let openSystemSettingsAction):
                state.dialog = .cameraAccessDeniedDialog(
                    ConfirmationDialogViewModel(
                        title: Localization.commonCameraDeniedAlertTitle,
                        subtitle: Localization.commonCameraDeniedAlertMessage,
                        buttons: [
                            ConfirmationDialogViewModel.Button(
                                title: Localization.commonCameraAlertButtonSettings,
                                role: nil,
                                action: openSystemSettingsAction
                            ),
                        ]
                    )
                )

            case .canOpenQRScanner:
                coordinator?.openQRScanner { [weak self] result in
                    let source: Analytics.WalletConnectSessionSource
                    let sessionURI: WalletConnectRequestURI

                    switch result {
                    case .fromClipboard(let uri):
                        source = .clipboard
                        sessionURI = uri
                    case .fromQRCode(let uri):
                        source = .qrCode
                        sessionURI = uri
                    }

                    self?.coordinator?.openDAppConnectionProposal(forURI: sessionURI, source: source)
                }
            }
        } catch {
            let disabledReason: String

            if let reason = error.reason {
                disabledReason = reason
            } else {
                assertionFailure("Wallet connect disabled reason is missing.")
                disabledReason = Localization.alertDemoFeatureDisabled
            }

            state.dialog = .alert(.featureDisabled(reason: disabledReason))
        }
    }

    private func handleDisconnectAllDAppsButtonTapped() {
        let disconnectAllDAppsAction: () -> Void = { [weak self, analyticsLogger] in
            self?.disconnectAllConnectedDApps()
            analyticsLogger.logDisconnectAllButtonTapped()
        }

        state.dialog = .alert(.disconnectAllDApps(action: disconnectAllDAppsAction))
    }

    private func handleDAppButtonTapped(_ dApp: WalletConnectConnectedDApp) {
        coordinator?.openConnectedDAppDetails(dApp)
    }

    private func handleConnectedDAppsChanged(_ connectedDApps: [WalletConnectConnectedDApp]) {
        state = Self.makeState(
            from: connectedDApps,
            userWalletRepository: userWalletRepository,
            cryptoAccountsState: cryptoAccountsGlobalStateProvider.globalCryptoAccountsState()
        )
    }

    private func handleCloseDialogButtonTapped() {
        state.dialog = nil
    }
}

// MARK: - Factory methods and state mapping

extension WalletConnectViewModel {
    private static func makeState(
        from connectedDApps: [WalletConnectConnectedDApp],
        userWalletRepository: some UserWalletRepository,
        cryptoAccountsState: CryptoAccounts.State
    ) -> WalletConnectViewState {
        guard !connectedDApps.isEmpty else {
            return .empty
        }

        let walletsWithDApps = makeWalletsWithConnectedDApps(
            from: connectedDApps,
            userWalletRepository: userWalletRepository,
            cryptoAccountsState: cryptoAccountsState
        )

        guard !walletsWithDApps.isEmpty else {
            return .empty
        }

        return WalletConnectViewState(
            contentState: .content(walletsWithDApps),
            dialog: nil,
            newConnectionButton: WalletConnectViewState.NewConnectionButton(isLoading: false)
        )
    }

    private static func makeWalletsWithConnectedDApps(
        from connectedDApps: [WalletConnectConnectedDApp],
        userWalletRepository: some UserWalletRepository,
        cryptoAccountsState: CryptoAccounts.State
    ) -> [WalletConnectViewState.ContentState.WalletWithConnectedDApps] {
        let walletIdToV1DApps: [String: [WalletConnectViewState.ContentState.ConnectedDApp]] = {
            let pairs = connectedDApps.compactMap { dApp -> (String, WalletConnectViewState.ContentState.ConnectedDApp)? in
                guard case .v1(let legacy) = dApp else { return nil }
                return (legacy.userWalletID, .init(domainModel: dApp))
            }

            return Dictionary(grouping: pairs, by: { $0.0 })
                .mapValues { $0.map(\.1) }
        }()

        let accountIdToV2DApps: [DAppsV2Key: [WalletConnectViewState.ContentState.ConnectedDApp]] = {
            let pairs = connectedDApps.compactMap { dApp -> (DAppsV2Key, WalletConnectViewState.ContentState.ConnectedDApp)? in
                guard case .v2(let current) = dApp else { return nil }
                let key = DAppsV2Key(userWalletID: current.wrapped.userWalletID, accountID: current.accountId)

                return (key, .init(domainModel: dApp))
            }

            return Dictionary(grouping: pairs, by: { $0.0 })
                .mapValues { $0.map(\.1) }
        }()

        var result: [WalletConnectViewState.ContentState.WalletWithConnectedDApps] = []

        for wallet in userWalletRepository.models {
            let walletId = wallet.userWalletId.stringValue
            let walletLevel = walletIdToV1DApps[walletId] ?? []

            var accountSections: [WalletConnectViewState.ContentState.AccountSection] = []
            var accountsWithSessions = 0

            func appendSection(for account: any CryptoAccountModel) {
                let accountId = account.id.walletConnectIdentifierString
                let key = DAppsV2Key(userWalletID: walletId, accountID: accountId)

                guard let dApps = accountIdToV2DApps[key], !dApps.isEmpty else { return }

                accountsWithSessions += 1
                accountSections.append(
                    WalletConnectViewState.ContentState.AccountSection(
                        id: accountId,
                        icon: account.icon,
                        name: account.name,
                        dApps: dApps
                    )
                )
            }

            for accountModel in wallet.accountModelsManager.accountModels {
                switch accountModel {
                case .standard(.single(let account)):
                    appendSection(for: account)

                case .standard(.multiple(let accounts)):
                    accounts.forEach(appendSection(for:))
                }
            }

            switch cryptoAccountsState {
            case .single:
                let combined = accountSections.flatMap(\.dApps) + walletLevel
                guard !combined.isEmpty else { continue }

                result.append(
                    WalletConnectViewState.ContentState.WalletWithConnectedDApps(
                        walletId: walletId,
                        walletName: wallet.name,
                        accountSections: [],
                        walletLevelDApps: combined
                    )
                )
            case .multiple:
                guard !accountSections.isEmpty || !walletLevel.isEmpty else { continue }

                result.append(
                    WalletConnectViewState.ContentState.WalletWithConnectedDApps(
                        walletId: walletId,
                        walletName: wallet.name,
                        accountSections: accountSections,
                        walletLevelDApps: walletLevel
                    )
                )
            }
        }

        return result.sorted { $0.walletName.localizedCompare($1.walletName) == .orderedAscending }
    }
}

// MARK: - Auxiliary types

private extension WalletConnectViewModel {
    struct DAppsV2Key: Hashable {
        let userWalletID: String
        let accountID: String
    }
}
