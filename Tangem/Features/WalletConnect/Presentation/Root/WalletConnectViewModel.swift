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
    private let establishDAppConnectionUseCase: WalletConnectEstablishDAppConnectionUseCase
    private let getConnectedDAppsUseCase: WalletConnectGetConnectedDAppsUseCase
    private let dAppsSessionExtender: WalletConnectDAppSessionsExtender
    private let disconnectDAppUseCase: WalletConnectDisconnectDAppUseCase
    private let userWalletRepository: any UserWalletRepository

    private weak var coordinator: (any WalletConnectRoutable)?

    private let logger: Logger

    private var initialLoadingTask: Task<Void, Never>?
    private var connectedDAppsUpdateHandleTask: Task<Void, Never>?
    private var disconnectAllDAppsTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectViewState

    init(
        state: WalletConnectViewState = .initial,
        establishDAppConnectionUseCase: WalletConnectEstablishDAppConnectionUseCase,
        getConnectedDAppsUseCase: WalletConnectGetConnectedDAppsUseCase,
        dAppsSessionExtender: WalletConnectDAppSessionsExtender,
        disconnectDAppUseCase: WalletConnectDisconnectDAppUseCase,
        userWalletRepository: some UserWalletRepository,
        coordinator: some WalletConnectRoutable
    ) {
        self.state = state
        self.establishDAppConnectionUseCase = establishDAppConnectionUseCase
        self.getConnectedDAppsUseCase = getConnectedDAppsUseCase
        self.dAppsSessionExtender = dAppsSessionExtender
        self.disconnectDAppUseCase = disconnectDAppUseCase
        self.userWalletRepository = userWalletRepository
        self.coordinator = coordinator

        logger = WCLogger
    }

    deinit {
        initialLoadingTask?.cancel()
        connectedDAppsUpdateHandleTask?.cancel()
        disconnectAllDAppsTask?.cancel()
    }

    func fetchConnectedDApps() {
        initialLoadingTask?.cancel()

        initialLoadingTask = Task { [dAppsSessionExtender, getConnectedDAppsUseCase, weak self] in
            await dAppsSessionExtender.extendConnectedDAppSessionsIfNeeded()

            guard !Task.isCancelled else { return }

            let connectedDApps: [WalletConnectConnectedDApp]

            do throws(WalletConnectDAppPersistenceError) {
                connectedDApps = try await getConnectedDAppsUseCase.callAsFunction()
            } catch {
                connectedDApps = []
            }

            self?.handle(viewEvent: .connectedDAppsChanged(connectedDApps))
            self?.subscribeToConnectedDAppsUpdates()
        }
    }

    private func subscribeToConnectedDAppsUpdates() {
        connectedDAppsUpdateHandleTask = Task { [weak self, getConnectedDAppsUseCase] in
            for await connectedDApps in await getConnectedDAppsUseCase() {
                self?.handle(viewEvent: .connectedDAppsChanged(connectedDApps))
            }
        }
    }

    private func disconnectAllConnectedDApps() {
        guard case .content(let walletsWithDApps) = state.contentState else { return }

        connectedDAppsUpdateHandleTask?.cancel()
        disconnectAllDAppsTask?.cancel()

        let allConnectedDApps = walletsWithDApps.flatMap(\.dApps)

        disconnectAllDAppsTask = Task { [weak self] in
            await withTaskGroup(of: Void.self) { group in
                for dApp in allConnectedDApps {
                    group.addTask {
                        try? await self?.disconnectDAppUseCase(dApp.domainModel)
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

    private func handleNewConnectionButtonTapped() {
        guard !state.newConnectionButton.isLoading else { return }

        do {
            let newDAppConnectionResult = try establishDAppConnectionUseCase()

            switch newDAppConnectionResult {
            case .cameraAccessDenied(let clipboardURI, let openSystemSettingsAction):
                let establishConnectionFromClipboardAction: (() -> Void)?

                if let clipboardURI {
                    establishConnectionFromClipboardAction = { [weak self] in
                        self?.coordinator?.openDAppConnectionProposal(forURI: clipboardURI, source: .clipboard)
                    }
                } else {
                    establishConnectionFromClipboardAction = nil
                }

                state.dialog = .confirmationDialog(
                    .cameraAccessDenied(
                        openSystemSettingsAction: openSystemSettingsAction,
                        establishConnectionFromClipboardURI: establishConnectionFromClipboardAction
                    )
                )

            case .canOpenQRScanner(let clipboardURI):
                coordinator?.openQRScanner(clipboardURI: clipboardURI) { [weak self] result in
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
        let disconnectAllDAppsAction: () -> Void = { [weak self] in
            self?.disconnectAllConnectedDApps()
        }

        state.dialog = .alert(.disconnectAllDApps(action: disconnectAllDAppsAction))
    }

    private func handleDAppButtonTapped(_ dApp: WalletConnectConnectedDApp) {
        coordinator?.openConnectedDAppDetails(dApp)
    }

    private func handleConnectedDAppsChanged(_ connectedDApps: [WalletConnectConnectedDApp]) {
        guard !connectedDApps.isEmpty else {
            state.contentState = .empty(.init())
            state.newConnectionButton.isLoading = false
            return
        }

        let walletsWithDApps = makeWalletsWithConnectedDApps(from: connectedDApps)

        guard !walletsWithDApps.isEmpty else {
            state.contentState = .empty(.init())
            state.newConnectionButton.isLoading = false
            return
        }

        state.contentState = .content(walletsWithDApps)
        state.newConnectionButton.isLoading = false
    }

    private func handleCloseDialogButtonTapped() {
        state.dialog = nil
    }
}

// MARK: - Factory methods and state mapping

extension WalletConnectViewModel {
    private func makeWalletsWithConnectedDApps(
        from connectedDApps: [WalletConnectConnectedDApp]
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

                let walletName = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == userWalletID })?.name ?? ""

                return WalletConnectViewState.ContentState.WalletWithConnectedDApps(
                    walletId: userWalletID,
                    walletName: walletName,
                    dApps: dApps.map(WalletConnectViewState.ContentState.ConnectedDApp.init)
                )
            }
    }
}
