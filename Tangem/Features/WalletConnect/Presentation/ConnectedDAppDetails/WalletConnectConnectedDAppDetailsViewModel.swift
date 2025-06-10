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
    private let walletConnectService: any WCService
    private let closeAction: () -> Void

    private var disconnectDAppTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectConnectedDAppDetailsViewState

    init(state: WalletConnectConnectedDAppDetailsViewState, walletConnectService: some WCService, closeAction: @escaping () -> Void) {
        self.state = state
        self.walletConnectService = walletConnectService
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

        case .disconnectButtonTapped:
            handleDisconnectButtonTapped()
        }
    }

    private func handleDisconnectButtonTapped() {
        guard !state.disconnectButton.isLoading else { return }

        state.disconnectButton.isLoading = true
        let dAppID = state.dAppDescriptionSection.id

        disconnectDAppTask?.cancel()
        disconnectDAppTask = Task { [walletConnectService, closeAction] in
            await walletConnectService.disconnectSession(with: dAppID)
            closeAction()
        }
    }
}
