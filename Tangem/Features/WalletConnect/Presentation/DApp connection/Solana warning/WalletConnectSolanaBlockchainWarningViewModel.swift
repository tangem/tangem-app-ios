//
//  WalletConnectSolanaBlockchainWarningViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import enum BlockchainSdk.Blockchain

@MainActor
final class WalletConnectSolanaBlockchainWarningViewModel: ObservableObject {
    private let navigationCloseButtonAction: () -> Void
    private let cancelButtonAction: () -> Void
    private let connectAnywayButtonAction: () async -> Void

    private var connectAnywayTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectSolanaBlockchainWarningViewState

    init(
        navigationCloseButtonAction: @escaping () -> Void,
        cancelButtonAction: @escaping () -> Void,
        connectAnywayButtonAction: @escaping () async -> Void
    ) {
        self.navigationCloseButtonAction = navigationCloseButtonAction
        self.cancelButtonAction = cancelButtonAction
        self.connectAnywayButtonAction = connectAnywayButtonAction

        state = WalletConnectSolanaBlockchainWarningViewState(
            iconAsset: NetworkImageProvider().provide(by: .solana(curve: .ed25519, testnet: false), filled: true)
        )
    }

    deinit {
        connectAnywayTask?.cancel()
    }

    func handle(viewEvent: WalletConnectSolanaBlockchainWarningViewEvent) {
        switch viewEvent {
        case .navigationCloseButtonTapped:
            connectAnywayTask?.cancel()
            navigationCloseButtonAction()

        case .cancelButtonTapped:
            connectAnywayTask?.cancel()
            cancelButtonAction()

        case .connectAnywayButtonTapped:
            handleConnectAnywayButtonTapped()
        }
    }

    private func handleConnectAnywayButtonTapped() {
        guard !state.connectAnywayButton.isLoading else { return }

        state.connectAnywayButton.isLoading = true

        connectAnywayTask = Task { [weak self] in
            await self?.connectAnywayButtonAction()
            self?.state.connectAnywayButton.isLoading = false
        }
    }
}
