//
//  WalletConnectConnectionRequestViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class WalletConnectConnectionRequestViewModel: ObservableObject {
    private let getDAppProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase

    private var dAppLoadingTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectConnectionRequestViewState

    init(state: WalletConnectConnectionRequestViewState, getDAppProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase) {
        self.state = state
        self.getDAppProposalUseCase = getDAppProposalUseCase
    }

    deinit {
        dAppLoadingTask?.cancel()
    }
}

// MARK: - View events handling

extension WalletConnectConnectionRequestViewModel {
    func handle(viewEvent: WalletConnectConnectionRequestViewEvent) {
        switch viewEvent {
        case .viewDidAppear:
            handleViewDidAppear()

        case .verifiedDomainIconTapped:
            handleVerifiedDomainIconTapped()

        case .connectionRequestSectionHeaderTapped:
            handleConnectionRequestSectionHeaderTapped()

        case .walletRowTapped:
            handleWalletRowTapped()

        case .networksRowTapped:
            handleNetworksRowTapped()

        case .cancelButtonTapped:
            handleCancelButtonTapped()

        case .connectButtonTapped:
            handleConnectButtonTapped()
        }
    }

    private func handleViewDidAppear() {
        dAppLoadingTask?.cancel()

        dAppLoadingTask = Task { [weak self, getDAppProposalUseCase] in
            do {
                let dAppProposal = try await getDAppProposalUseCase()
            } catch {
                // [REDACTED_TODO_COMMENT]
            }
        }
    }

    private func handleVerifiedDomainIconTapped() {
        state = .verifiedDomain
    }

    private func handleConnectionRequestSectionHeaderTapped() {}

    private func handleWalletRowTapped() {}

    private func handleNetworksRowTapped() {}

    private func handleCancelButtonTapped() {}

    private func handleConnectButtonTapped() {}
}
