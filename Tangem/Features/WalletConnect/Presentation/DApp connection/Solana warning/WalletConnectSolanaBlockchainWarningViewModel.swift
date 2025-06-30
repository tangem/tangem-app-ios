//
//  WalletConnectSolanaBlockchainWarningViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

@MainActor
final class WalletConnectSolanaBlockchainWarningViewModel {
    private let navigationCloseButtonAction: () -> Void,
    private let cancelButtonAction: () -> Void,
    private let connectAnywayButtonAction: () -> Void

    let state: WalletConnectSolanaBlockchainWarningViewState

    init(
        navigationCloseButtonAction: @escaping () -> Void,
        cancelButtonAction: @escaping () -> Void,
        connectAnywayButtonAction: @escaping () -> Void
    ) {
        self.navigationCloseButtonAction = navigationCloseButtonAction
        self.cancelButtonAction = cancelButtonAction
        self.connectAnywayButtonAction = connectAnywayButtonAction

        self.state = WalletConnectSolanaBlockchainWarningViewState()
    }

    func handle(viewEvent: WalletConnectSolanaBlockchainWarningViewEvent) {
        switch viewEvent {
        case .navigationCloseButtonTapped:
            navigationCloseButtonAction()

        case .cancelButtonTapped:
            cancelButtonAction()

        case .connectAnywayButtonTapped:
            connectAnywayButtonAction()
        }
    }
}
