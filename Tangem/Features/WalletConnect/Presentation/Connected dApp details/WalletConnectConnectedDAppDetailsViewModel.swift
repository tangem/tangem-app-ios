//
//  WalletConnectConnectedDAppDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class WalletConnectConnectedDAppDetailsViewModel: ObservableObject {
    private let connectedDApp: WalletConnectConnectedDApp
    private let disconnectDAppUseCase: WalletConnectDisconnectDAppUseCase
    private let closeAction: () -> Void

    private var disconnectDAppTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectConnectedDAppDetailsViewState

    init(
        state: WalletConnectConnectedDAppDetailsViewState,
        connectedDApp: WalletConnectConnectedDApp,
        disconnectDAppUseCase: WalletConnectDisconnectDAppUseCase,
        closeAction: @escaping () -> Void
    ) {
        self.state = state
        self.connectedDApp = connectedDApp
        self.disconnectDAppUseCase = disconnectDAppUseCase
        self.closeAction = closeAction
    }

    deinit {
        disconnectDAppTask?.cancel()
    }
}

// MARK: - View events handling

extension WalletConnectConnectedDAppDetailsViewModel {
    func handle(viewEvent: WalletConnectConnectedDAppDetailsViewEvent) {
        switch viewEvent {
        case .closeButtonTapped:
            closeAction()

        case .verifiedDomainIconTapped:
            handleVerifiedDomainIconTapped()

        case .disconnectButtonTapped:
            handleDisconnectButtonTapped()
        }
    }

    private func handleVerifiedDomainIconTapped() {
        guard case .dAppDetails(let dAppDetailsViewState) = state else { return }

        let viewModel = WalletConnectDAppDomainVerificationViewModel(
            verifiedDAppName: connectedDApp.dAppData.name,
            closeAction: { [weak self] in
                self?.state = .dAppDetails(dAppDetailsViewState)
            }
        )

        state = .verifiedDomain(viewModel)
    }

    private func handleDisconnectButtonTapped() {
        guard
            case .dAppDetails(var dAppDetailsViewState) = state,
            !dAppDetailsViewState.disconnectButton.isLoading
        else {
            return
        }

        dAppDetailsViewState.disconnectButton.isLoading = true
        state = .dAppDetails(dAppDetailsViewState)

        disconnectDAppTask?.cancel()
        disconnectDAppTask = Task { [disconnectDAppUseCase, closeAction, connectedDApp] in
            try? await disconnectDAppUseCase(connectedDApp)
            closeAction()
        }
    }
}
