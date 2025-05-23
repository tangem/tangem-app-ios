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
    let connectionRequestViewModel: WalletConnectDAppConnectionRequestViewModel

    @Published private(set) var state: WalletConnectDAppConnectionProposalViewState

    private var cancellable: AnyCancellable?

    init(state: WalletConnectDAppConnectionProposalViewState, connectionRequestViewModel: WalletConnectDAppConnectionRequestViewModel) {
        self.state = state
        self.connectionRequestViewModel = connectionRequestViewModel

        cancellable = connectionRequestViewModel.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }

    func loadDAppProposal() {
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

    func dismiss() {
        // [REDACTED_TODO_COMMENT]
    }
}
