//
//  ConnectionsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Combine.Published
import protocol Combine.ObservableObject
import struct TangemFoundation.UserWalletId
import enum TangemLocalization.Localization
import struct TangemLogger.Logger
import TangemMCP
import struct TangemUIUtils.ConfirmationDialogViewModel

@MainActor
final class ConnectionsViewModel: ObservableObject {
    private let interactor: ConnectionsInteractor
    private let userWalletRepository: any UserWalletRepository
    private let cryptoAccountsGlobalStateProvider: any CryptoAccountsGlobalStateProvider
    private let logger: TangemLogger.Logger

    private weak var coordinator: (any ConnectionsRoutable)?

    private var connectedDAppsUpdatesTask: Task<Void, Never>?
    private var extendConnectedDAppSessionsTask: Task<Void, Never>?
    private var fetchMCPSessionsTask: Task<Void, Never>?
    private var newMCPSessionPollingTask: Task<Void, Never>?
    private var disconnectAllTask: Task<Void, Never>?

    private static let newMCPSessionFetchDelays: [Duration] = [.seconds(2), .seconds(2), .seconds(3), .seconds(3), .seconds(5)]

    @Published private(set) var state: ConnectionsViewState

    init(
        interactor: ConnectionsInteractor,
        userWalletRepository: some UserWalletRepository,
        cryptoAccountsGlobalStateProvider: some CryptoAccountsGlobalStateProvider,
        logger: TangemLogger.Logger,
        coordinator: some ConnectionsRoutable,
        prefetchedConnectedDApps: [WalletConnectConnectedDApp]?
    ) {
        self.interactor = interactor
        self.userWalletRepository = userWalletRepository
        self.cryptoAccountsGlobalStateProvider = cryptoAccountsGlobalStateProvider
        self.logger = logger
        self.coordinator = coordinator

        state = Self.makeInitialState(
            prefetchedConnectedDApps: prefetchedConnectedDApps,
            userWalletRepository: userWalletRepository,
            cryptoAccountsState: cryptoAccountsGlobalStateProvider.globalCryptoAccountsState()
        )

        subscribeToConnectedDAppsUpdates()
        extendConnectedDAppSessions()
        fetchMCPSessions()
    }

    deinit {
        connectedDAppsUpdatesTask?.cancel()
        extendConnectedDAppSessionsTask?.cancel()
        fetchMCPSessionsTask?.cancel()
        newMCPSessionPollingTask?.cancel()
        disconnectAllTask?.cancel()
    }
}

// MARK: - View actions handling

extension ConnectionsViewModel {
    func handle(action: ConnectionsViewAction) {
        switch action {
        case .viewDidAppear:
            Analytics.log(.connectionsScreenOpened, analyticsSystems: .all)

        case .tabSelected(let tabID):
            state.selectedTabID = tabID

        case .newConnectionButtonTapped:
            handleNewConnectionButtonTapped()

        case .disconnectAllButtonTapped:
            handleDisconnectAllButtonTapped()

        case .mcpSessionTapped(let session):
            coordinator?.openMCPSessionDetails(session, sessionRevokedAction: { [weak self] in
                self?.fetchMCPSessions()
            })

        case .mcpSessionsReloadButtonTapped:
            handleMCPSessionsReloadButtonTapped()

        case .dAppTapped(let dApp):
            coordinator?.openConnectedDAppDetails(dApp)

        case .closeDialogButtonTapped:
            state.modalDialog = nil
        }
    }

    private func handleNewConnectionButtonTapped() {
        switch interactor.checkCameraAccess() {
        case .cameraAccessDenied(let openSystemSettingsAction):
            state.modalDialog = .cameraAccessDeniedDialog(
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
            coordinator?.openQRScanner { [weak self] qrScanResult in
                self?.handleQRScanResult(qrScanResult)
            }
        }
    }

    private func handleQRScanResult(_ qrScanResult: ConnectionsQRScanResult) {
        switch qrScanResult {
        case .walletConnect(let uri, let source):
            handleWalletConnectQRScanResult(uri: uri, source: source)

        case .mcpConnectionRequest(let userCode, _):
            coordinator?.openMCPConnectionRequest(
                userCode: userCode,
                preselectedUserWalletID: state.selectedTabID,
                connectionAcceptedAction: { [weak self] userWalletID in
                    self?.pollForNewMCPSession(userWalletID: userWalletID)
                }
            )
        }
    }

    private func handleWalletConnectQRScanResult(uri: WalletConnectRequestURI, source: ConnectionsQRScanResult.Source) {
        let selectedUserWalletID = state.selectedTabID
        let walletConnectAvailability = userWalletRepository.models
            .first { $0.userWalletId == selectedUserWalletID }?
            .config
            .getFeatureAvailability(.walletConnect)

        if case .disabled(let localizedReason) = walletConnectAvailability {
            let alert = ConnectionsViewState.ModalDialog.Alert.walletConnectFeatureDisabled(
                reason: localizedReason ?? Localization.alertDemoFeatureDisabled
            )

            state.modalDialog = .alert(alert)
            return
        }

        switch source {
        case .qrCode:
            coordinator?.openDAppConnectionProposal(forURI: uri, source: .qrCode, preselectedUserWalletID: selectedUserWalletID)

        case .clipboard:
            coordinator?.openDAppConnectionProposal(forURI: uri, source: .clipboard, preselectedUserWalletID: selectedUserWalletID)
        }
    }

    private func handleDisconnectAllButtonTapped() {
        let alert = ConnectionsViewState.ModalDialog.Alert.disconnectAll(
            action: { [weak self] in
                Analytics.log(.connectionsDisconnectAllButtonTapped)
                self?.disconnectAll()
            }
        )

        state.modalDialog = .alert(alert)
    }

    private func handleMCPSessionsReloadButtonTapped() {
        let isAlreadyReloading = state.tabs.contains { tab in
            guard case .failed(let failedState) = tab.mcpSessionsSection.state else {
                return false
            }

            return failedState.isReloading
        }

        guard !isAlreadyReloading else { return }

        var tabs = state.tabs

        for index in tabs.indices {
            guard case .failed(var failedState) = tabs[index].mcpSessionsSection.state else {
                continue
            }

            failedState.isReloading = true
            tabs[index].mcpSessionsSection.state = .failed(failedState)
        }

        state.tabs = tabs
        fetchMCPSessions()
    }
}

// MARK: - Disconnect all

extension ConnectionsViewModel {
    private func disconnectAll() {
        disconnectAllTask?.cancel()
        fetchMCPSessionsTask?.cancel()
        stopPollingForNewMCPSession()

        let disconnectAllDApps = interactor.disconnectAllDApps
        let revokeDeviceMCPSessions = interactor.revokeDeviceMCPSessions

        disconnectAllTask = Task { [weak self, logger] in
            logger.debug("Disconnecting all dApps and revoking all MCP sessions")

            let dAppsError: WalletConnectDAppPersistenceError?
            let mcpSessionsError: MCPSessionClientError?

            // [REDACTED_USERNAME], ugly work around to preserve typed throws from async lets
            async let dAppsDisconnectionTask = Self.disconnectAllDApps(using: disconnectAllDApps)
            async let mcpSessionsRevocationTask = Self.revokeDeviceMCPSessions(using: revokeDeviceMCPSessions)

            do throws(WalletConnectDAppPersistenceError) {
                try await dAppsDisconnectionTask.get()
                dAppsError = nil
            } catch {
                dAppsError = error
            }

            do throws(MCPSessionClientError) {
                try await mcpSessionsRevocationTask.get()
                mcpSessionsError = nil
            } catch {
                mcpSessionsError = error
            }

            guard !Task.isCancelled else { return }

            self?.handleDisconnectAllCompletion(dAppsError: dAppsError, mcpSessionsError: mcpSessionsError)
        }

        updateNavigationBarTrailingButton()
    }

    private static func disconnectAllDApps(
        using disconnectAllDApps: WalletConnectDisconnectAllDAppsUseCase
    ) async -> Result<Void, WalletConnectDAppPersistenceError> {
        do throws(WalletConnectDAppPersistenceError) {
            return Result.success(try await disconnectAllDApps())
        } catch {
            return Result.failure(error)
        }
    }

    private static func revokeDeviceMCPSessions(
        using revokeDeviceMCPSessions: RevokeDeviceMCPSessionsUseCase
    ) async -> Result<Void, MCPSessionClientError> {
        do throws(MCPSessionClientError) {
            return Result.success(try await revokeDeviceMCPSessions())
        } catch {
            return Result.failure(error)
        }
    }

    private func handleDisconnectAllCompletion(
        dAppsError: WalletConnectDAppPersistenceError?,
        mcpSessionsError: MCPSessionClientError?
    ) {
        disconnectAllTask = nil

        if let dAppsError {
            logger.error("Failed to disconnect all dApps", error: dAppsError)
        }

        if let mcpSessionsError {
            logger.error("Failed to revoke all MCP sessions", error: mcpSessionsError)
            fetchMCPSessions()
        } else {
            updateMCPSessionsSections(with: [])
        }

        if dAppsError != nil {
            coordinator?.displayDisconnectAllFailed()
        } else if let mcpSessionsError {
            coordinator?.display(error: mcpSessionsError)
        } else {
            coordinator?.displayDisconnectAllSucceeded()
        }

        updateNavigationBarTrailingButton()
    }
}

// MARK: - Navigation bar

extension ConnectionsViewModel {
    private func updateNavigationBarTrailingButton() {
        let hasConnections = state.tabs.contains { tab in
            switch (tab.mcpSessionsSection.state, tab.dAppsSection?.state) {
            case (.content(let sessions), _) where !sessions.isEmpty: true
            case (_, .content(.flat(let dApps))?) where !dApps.isEmpty: true
            case (_, .content(.byAccount(let accountSections))?) where !accountSections.isEmpty: true
            default: false
            }
        }

        state.navigationBar.trailingButton = hasConnections
            ? ConnectionsViewState.NavigationBar.TrailingButton(isEnabled: disconnectAllTask == nil)
            : nil
    }
}

// MARK: - WalletConnect dApps loading

extension ConnectionsViewModel {
    private func subscribeToConnectedDAppsUpdates() {
        connectedDAppsUpdatesTask?.cancel()

        connectedDAppsUpdatesTask = Task { [weak self, streamConnectedDApps = interactor.streamConnectedDApps] in
            for await connectedDApps in await streamConnectedDApps() {
                guard let self else { return }
                logger.debug("Received \(connectedDApps.count) connected dApps")
                updateDAppsSections(with: connectedDApps)
            }
        }
    }

    private func extendConnectedDAppSessions() {
        extendConnectedDAppSessionsTask?.cancel()

        extendConnectedDAppSessionsTask = Task { [extendConnectedDApps = interactor.extendConnectedDApps, logger] in
            logger.debug("Extending connected dApp sessions")
            await extendConnectedDApps()
            logger.debug("Connected dApp sessions extension finished")
        }
    }

    private func updateDAppsSections(with connectedDApps: [WalletConnectConnectedDApp]) {
        let cryptoAccountsState = cryptoAccountsGlobalStateProvider.globalCryptoAccountsState()
        var tabs = state.tabs

        for index in tabs.indices where tabs[index].dAppsSection != nil {
            guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == tabs[index].id }) else {
                continue
            }

            let dAppsGrouping = Self.makeDAppsGrouping(
                for: userWalletModel,
                connectedDApps: connectedDApps,
                cryptoAccountsState: cryptoAccountsState
            )

            tabs[index].dAppsSection?.state = .content(dAppsGrouping)
        }

        state.tabs = tabs
        updateNavigationBarTrailingButton()
    }
}

// MARK: - MCP sessions loading

extension ConnectionsViewModel {
    private func fetchMCPSessions() {
        fetchMCPSessionsTask?.cancel()

        fetchMCPSessionsTask = Task { [weak self, fetchSessions = interactor.fetchMCPSessions, logger] in
            do throws(MCPSessionClientError) {
                logger.debug("Fetching MCP sessions")
                let sessions = try await fetchSessions()

                guard !Task.isCancelled else { return }

                logger.debug("Fetched \(sessions.count) MCP sessions")
                self?.updateMCPSessionsSections(with: sessions)
            } catch {
                guard !Task.isCancelled else { return }

                logger.error("Failed to fetch MCP sessions", error: error)
                self?.updateMCPSessionsSectionsWithFailure()
            }
        }
    }

    private func pollForNewMCPSession(userWalletID: UserWalletId) {
        stopPollingForNewMCPSession()
        fetchMCPSessionsTask?.cancel()

        let knownSessionIDs = knownMCPSessionIDs(of: userWalletID)
        updateAwaitingNewMCPSession(true, userWalletID: userWalletID)

        newMCPSessionPollingTask = Task { [
            weak self,
            fetchSessions = interactor.fetchMCPSessions,
            fetchDelays = Self.newMCPSessionFetchDelays,
            logger
        ] in
            var hasFetchedSessions = false

            for fetchDelay in fetchDelays {
                do {
                    try await Task.sleep(for: fetchDelay)
                } catch {
                    return
                }

                do throws(MCPSessionClientError) {
                    let sessions = try await fetchSessions()

                    guard !Task.isCancelled else { return }

                    hasFetchedSessions = true
                    logger.debug("Fetched \(sessions.count) MCP sessions while waiting for a new one")
                    self?.updateMCPSessionsSections(with: sessions)

                    if let knownSessionIDs, sessions.contains(where: { $0.userWalletID == userWalletID && !knownSessionIDs.contains($0.id) }) {
                        break
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    logger.error("Failed to fetch MCP sessions while waiting for a new one", error: error)
                }
            }

            if !hasFetchedSessions, knownSessionIDs == nil {
                self?.updateMCPSessionsSectionsWithFailure()
            }

            self?.updateAwaitingNewMCPSession(false, userWalletID: userWalletID)
        }
    }

    private func knownMCPSessionIDs(of userWalletID: UserWalletId) -> Set<MCPSession.ID>? {
        guard
            let tab = state.tabs.first(where: { $0.id == userWalletID }),
            case .content(let sessionRows) = tab.mcpSessionsSection.state
        else {
            return nil
        }

        return Set(sessionRows.map(\.id))
    }

    private func stopPollingForNewMCPSession() {
        newMCPSessionPollingTask?.cancel()
        newMCPSessionPollingTask = nil

        var tabs = state.tabs

        for index in tabs.indices {
            tabs[index].mcpSessionsSection.isAwaitingNewSession = false
        }

        state.tabs = tabs
    }

    private func updateAwaitingNewMCPSession(_ isAwaitingNewSession: Bool, userWalletID: UserWalletId) {
        guard let index = state.tabs.firstIndex(where: { $0.id == userWalletID }) else {
            return
        }

        state.tabs[index].mcpSessionsSection.isAwaitingNewSession = isAwaitingNewSession
    }

    private func updateMCPSessionsSections(with sessions: [MCPSession]) {
        let sessionsByUserWalletID = Dictionary(grouping: sessions, by: \.userWalletID)
        var tabs = state.tabs

        for index in tabs.indices {
            let sessionRows = (sessionsByUserWalletID[tabs[index].id] ?? []).map(
                ConnectionsViewState.UserWalletTab.MCPSessionsSection.SessionRow.init(session:)
            )
            tabs[index].mcpSessionsSection.state = .content(sessionRows)
        }

        state.tabs = tabs
        updateNavigationBarTrailingButton()
    }

    private func updateMCPSessionsSectionsWithFailure() {
        var tabs = state.tabs

        for index in tabs.indices {
            tabs[index].mcpSessionsSection.state = .failed(ConnectionsViewState.UserWalletTab.MCPSessionsSection.FailedState())
        }

        state.tabs = tabs
        updateNavigationBarTrailingButton()
    }
}

// MARK: - State factory

extension ConnectionsViewModel {
    private static func makeInitialState(
        prefetchedConnectedDApps: [WalletConnectConnectedDApp]?,
        userWalletRepository: some UserWalletRepository,
        cryptoAccountsState: CryptoAccounts.State
    ) -> ConnectionsViewState {
        let unlockedUserWalletModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }

        let tabs = unlockedUserWalletModels.map { userWalletModel in
            makeUserWalletTab(
                for: userWalletModel,
                prefetchedConnectedDApps: prefetchedConnectedDApps,
                cryptoAccountsState: cryptoAccountsState
            )
        }

        guard let firstTab = tabs.first else {
            preconditionFailure("Connections screen requires at least one unlocked user wallet. Developer mistake.")
        }

        let selectedUserWalletID = userWalletRepository.selectedModel?.userWalletId
        let selectedTab = tabs.first { $0.id == selectedUserWalletID } ?? firstTab

        return ConnectionsViewState(tabs: tabs, selectedTabID: selectedTab.id)
    }

    private static func makeUserWalletTab(
        for userWalletModel: some UserWalletModel,
        prefetchedConnectedDApps: [WalletConnectConnectedDApp]?,
        cryptoAccountsState: CryptoAccounts.State
    ) -> ConnectionsViewState.UserWalletTab {
        let tabItem = ConnectionsViewState.UserWalletTab.TabItem(
            id: userWalletModel.userWalletId,
            name: userWalletModel.name,
            thumbnail: userWalletModel.config.walletThumbnailType
        )

        let dAppsSection: ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection?

        if userWalletModel.config.isFeatureVisible(.walletConnect) {
            let dAppsSectionState: ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection.State = prefetchedConnectedDApps
                .map { connectedDApps in
                    .content(
                        makeDAppsGrouping(
                            for: userWalletModel,
                            connectedDApps: connectedDApps,
                            cryptoAccountsState: cryptoAccountsState
                        )
                    )
                }
                ?? .loading

            dAppsSection = ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection(state: dAppsSectionState)
        } else {
            dAppsSection = nil
        }

        return ConnectionsViewState.UserWalletTab(
            tabItem: tabItem,
            mcpSessionsSection: ConnectionsViewState.UserWalletTab.MCPSessionsSection(state: .loading),
            dAppsSection: dAppsSection
        )
    }

    private static func makeDAppsGrouping(
        for userWalletModel: some UserWalletModel,
        connectedDApps: [WalletConnectConnectedDApp],
        cryptoAccountsState: CryptoAccounts.State
    ) -> ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection.DAppsGrouping {
        let userWalletID = userWalletModel.userWalletId.stringValue
        let userWalletDApps = connectedDApps.filter { $0.userWalletID == userWalletID }
        let dAppsByAccountID = Dictionary(grouping: userWalletDApps, by: \.accountId)

        var accountSections: [ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection.AccountSection] = []

        func appendAccountSection(for account: any CryptoAccountModel) {
            let accountID = account.id.walletConnectIdentifierString

            guard let accountDApps = dAppsByAccountID[accountID], !accountDApps.isEmpty else {
                return
            }

            accountSections.append(
                ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection.AccountSection(
                    id: accountID,
                    icon: account.icon.erased,
                    name: account.name,
                    dApps: accountDApps.map(ConnectionsViewState.UserWalletTab.WalletConnectDAppsSection.DApp.init)
                )
            )
        }

        for accountModel in userWalletModel.accountModelsManager.accountModels {
            switch accountModel {
            case .standard(.single(let account)):
                appendAccountSection(for: account)

            case .standard(.multiple(let accounts)):
                accounts.forEach(appendAccountSection(for:))

            case .joint, .tangemPay, .polymarket, .collectibles:
                break
            }
        }

        switch cryptoAccountsState {
        case .single:
            return .flat(accountSections.flatMap(\.dApps))

        case .multiple:
            return .byAccount(accountSections)
        }
    }
}
