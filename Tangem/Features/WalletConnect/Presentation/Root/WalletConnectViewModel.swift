//
//  WalletConnectViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Dispatch
import enum TangemAssets.Assets
import TangemLocalization
import TangemLogger

@MainActor
final class WalletConnectViewModel: ObservableObject {
    private let interactor: WalletConnectInteractor
    private let userWalletRepository: any UserWalletRepository
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
        analyticsLogger: some WalletConnectAnalyticsLogger,
        logger: TangemLogger.Logger,
        coordinator: some WalletConnectRoutable,
        prefetchedConnectedDApps: [WalletConnectConnectedDApp]?
    ) {
        self.interactor = interactor
        self.userWalletRepository = userWalletRepository
        self.analyticsLogger = analyticsLogger
        self.logger = logger
        self.coordinator = coordinator

        if let prefetchedConnectedDApps {
            state = Self.makeState(from: prefetchedConnectedDApps, userWalletRepository: userWalletRepository, logger: logger)
            subscribeToConnectedDAppsUpdates()
        } else {
            state = .loading
            fetchConnectedDApps()
        }
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

        let allConnectedDApps = walletsWithDApps.flatMap(\.dApps)

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

    // [REDACTED_TODO_COMMENT]
    private func showDisconnectAllDAppsToast() {
        WalletConnectModuleFactory.makeSuccessToast(with: "Disconnected all dApps")
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
                state.dialog = .confirmationDialog(
                    .cameraAccessDenied(openSystemSettingsAction: openSystemSettingsAction)
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
        state = Self.makeState(from: connectedDApps, userWalletRepository: userWalletRepository, logger: logger)
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
        logger: TangemLogger.Logger
    ) -> WalletConnectViewState {
        guard !connectedDApps.isEmpty else {
            return .empty
        }

        let walletsWithDApps = Self.makeWalletsWithConnectedDApps(
            from: connectedDApps,
            userWalletRepository: userWalletRepository,
            logger: logger
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
        logger: TangemLogger.Logger
    ) -> [WalletConnectViewState.ContentState.WalletWithConnectedDApps] {
        var userWalletIDToConnectedDApps = [String: [WalletConnectConnectedDApp]]()
        var orderedUserWalletIDs = [String]()

        for dApp in connectedDApps {
            let connectedDApps: [WalletConnectConnectedDApp]

            if var addedDApps = userWalletIDToConnectedDApps[dApp.userWalletID] {
                addedDApps.append(dApp)
                connectedDApps = addedDApps
            } else {
                orderedUserWalletIDs.append(dApp.userWalletID)
                connectedDApps = [dApp]
            }

            userWalletIDToConnectedDApps[dApp.userWalletID] = connectedDApps
        }

        return orderedUserWalletIDs
            .compactMap { userWalletID in
                guard let dApps = userWalletIDToConnectedDApps[userWalletID] else { return nil }

                let walletName: String

                if let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == userWalletID }) {
                    walletName = userWalletModel.name
                } else {
                    logger.warning("UserWalletModel not found for \(dApps.map(\.dAppData.name).joined(separator: ", ")) dApps")
                    walletName = ""
                }

                return WalletConnectViewState.ContentState.WalletWithConnectedDApps(
                    walletId: userWalletID,
                    walletName: walletName,
                    dApps: dApps.map(WalletConnectViewState.ContentState.ConnectedDApp.init)
                )
            }
    }
}
