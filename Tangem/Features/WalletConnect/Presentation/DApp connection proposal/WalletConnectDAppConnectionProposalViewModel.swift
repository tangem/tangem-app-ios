//
//  WalletConnectDAppConnectionProposalViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class WalletConnectDAppConnectionProposalViewModel: ObservableObject {
    private let connectionRequestViewModel: WalletConnectDAppConnectionRequestViewModel
    private let dismissFlowAction: () -> Void

    private var connectionRequestViewModelCancellable: AnyCancellable?

    @Published private(set) var state: WalletConnectDAppConnectionProposalViewState

    init(
        state: WalletConnectDAppConnectionProposalViewState,
        connectionRequestViewModel: WalletConnectDAppConnectionRequestViewModel,
        dismissFlowAction: @escaping () -> Void
    ) {
        self.state = state
        self.connectionRequestViewModel = connectionRequestViewModel
        self.dismissFlowAction = dismissFlowAction

        connectionRequestViewModelCancellable = connectionRequestViewModel
            .objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
    }

    func beginDAppProposalLoading() {
        connectionRequestViewModel.handle(viewEvent: .dAppProposalLoadingRequested)
    }

    func switchToConnectionRequest() {
        state = .connectionRequest(connectionRequestViewModel)
    }
}

extension WalletConnectDAppConnectionProposalViewModel: WalletConnectDAppConnectionProposalRoutable {
    func openDomainVerification() {
        state = .verifiedDomain
    }

    func openWalletSelector() {
        state = .walletSelector
    }

    func openNetworksSelector() {
        state = .networkSelector
    }

    func openErrorScreen(error: some Error) {
        // [REDACTED_TODO_COMMENT]
    }

    func dismiss() {
        dismissFlowAction()
    }
}
