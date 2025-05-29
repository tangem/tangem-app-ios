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
    private let dAppID: Int
    private let walletConnectService: any WCService
    private let closeAction: () -> Void

    private var disconnectDAppTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectConnectedDAppDetailsViewState

    init(
        state: WalletConnectConnectedDAppDetailsViewState,
        dAppID: Int,
        walletConnectService: some WCService,
        closeAction: @escaping () -> Void
    ) {
        self.state = state
        self.dAppID = dAppID
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

        disconnectDAppTask?.cancel()
        disconnectDAppTask = Task { [walletConnectService, closeAction, dAppID] in
            await walletConnectService.disconnectSession(with: dAppID)
            closeAction()
        }
    }
}
