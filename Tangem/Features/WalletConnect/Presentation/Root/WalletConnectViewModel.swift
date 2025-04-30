//
//  WalletConnectViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Dispatch
import TangemLocalization
import TangemLogger

@MainActor
final class WalletConnectViewModel: ObservableObject {
    private let walletConnectService: any WCService
    private let userWalletRepository: any UserWalletRepository
    private let establishDAppConnectionUseCase: WalletConnectEstablishDAppConnectionUseCase

    private weak var coordinator: (any WalletConnectRoutable)?

    private let logger: Logger

    private var newSessionsTask: Task<Void, Never>?
    private var disconnectAllDAppsTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable>

    @Published private(set) var state: WalletConnectViewState

    init(
        state: WalletConnectViewState = .initial,
        walletConnectService: some WCService,
        userWalletRepository: some UserWalletRepository,
        establishDAppConnectionUseCase: WalletConnectEstablishDAppConnectionUseCase,
        coordinator: some WalletConnectRoutable
    ) {
        self.state = state
        self.walletConnectService = walletConnectService
        self.userWalletRepository = userWalletRepository
        self.establishDAppConnectionUseCase = establishDAppConnectionUseCase
        self.coordinator = coordinator

        logger = WCLogger
        cancellables = []

        bindToWalletConnectService()
    }

    deinit {
        newSessionsTask?.cancel()
        disconnectAllDAppsTask?.cancel()
    }

    private func bindToWalletConnectService() {
        newSessionsTask = Task { [weak self, walletConnectService] in
            for await sessions in await walletConnectService.newSessions {
                self?.handle(viewEvent: .connectedDAppsChanged(sessions))
            }
        }

        walletConnectService
            .canEstablishNewSessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canEstablishNewSession in
                self?.handle(viewEvent: .canConnectNewDAppStateChanged(canEstablishNewSession))
            }
            .store(in: &cancellables)
    }

    private func disconnectAllConnectedDApps() {
        guard case .withConnectedDApps(let walletsWithDApps) = state.contentState else { return }
        let allConnectedDApps = walletsWithDApps.flatMap(\.dApps)

        disconnectAllDAppsTask?.cancel()

        disconnectAllDAppsTask = Task { [weak self] in
            await withTaskGroup(of: Void.self) { group in
                for dApp in allConnectedDApps {
                    group.addTask {
                        await self?.walletConnectService.disconnectSession(with: dApp.id)
                    }
                }
            }

            self?.state.contentState = .empty(.init())
        }
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

        case .canConnectNewDAppStateChanged(let canConnectNewDApp):
            handleCanConnectNewDAppStateChanged(canConnectNewDApp)

        case .connectedDAppsChanged(let connectedDApps):
            handleConnectedDAppsChanged(connectedDApps)

        case .closeDialogButtonTapped:
            handleCloseDialogButtonTapped()
        }
    }

    private func handleViewDidAppear() {
        // [REDACTED_TODO_COMMENT]
    }

    private func handleNewConnectionButtonTapped() {
        do {
            let newDAppConnectionResult = try establishDAppConnectionUseCase()

            switch newDAppConnectionResult {
            case .cameraAccessDenied(let clipboardURI, let openSystemSettingsAction):
                let establishConnectionFromClipboardAction: (() -> Void)?

                if let clipboardURI {
                    establishConnectionFromClipboardAction = { [weak self] in
                        self?.walletConnectService.openSession(with: clipboardURI, source: .clipboard)
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
                coordinator?.openQRScanner(clipboardURI: clipboardURI) { [walletConnectService] result in
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

                    walletConnectService.openSession(with: sessionURI, source: source)
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

    private func handleDAppButtonTapped(_ dApp: WalletConnectSavedSession) {
        coordinator?.openConnectedDAppDetails(dApp)
    }

    private func handleCanConnectNewDAppStateChanged(_ canConnectNewDApp: Bool) {
        state.newConnectionButton.isLoading = !canConnectNewDApp
    }

    private func handleConnectedDAppsChanged(_ connectedDApps: [WalletConnectSavedSession]) {
        guard !connectedDApps.isEmpty else {
            state.contentState = .empty(.init())
            return
        }

        let userWalletIdToConnectedDApps = connectedDApps.grouped(by: \.userWalletId)

        let walletsWithDApps: [WalletConnectViewState.ContentState.WalletWithConnectedDApps] = userWalletIdToConnectedDApps
            .compactMap { userWalletId, dApps in
                guard let userWallet = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == userWalletId }) else {
                    return nil
                }

                return WalletConnectViewState.ContentState.WalletWithConnectedDApps(
                    walletId: userWalletId,
                    walletName: userWallet.name,
                    dApps: dApps
                )
            }

        state.contentState = .withConnectedDApps(walletsWithDApps)
    }

    private func handleCloseDialogButtonTapped() {
        state.dialog = nil
    }
}
