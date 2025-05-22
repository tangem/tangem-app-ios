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
    private let getDAppConnectionProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase
    private weak var coordinator: (any WalletConnectDAppConnectionProposalRoutable)?

    private var dAppLoadingTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectConnectionRequestViewState

    init(
        state: WalletConnectConnectionRequestViewState,
        getDAppConnectionProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase,
        coordinator: (any WalletConnectDAppConnectionProposalRoutable)?
    ) {
        self.state = state
        self.getDAppConnectionProposalUseCase = getDAppConnectionProposalUseCase
        self.coordinator = coordinator
    }

    deinit {
        dAppLoadingTask?.cancel()
    }
}

// MARK: - View events handling

extension WalletConnectConnectionRequestViewModel {
    func handle(viewEvent: WalletConnectConnectionRequestViewEvent) {
        switch viewEvent {
        case .navigationCloseButtonTapped:
            handleNavigationCloseButtonTapped()

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

    private func handleNavigationCloseButtonTapped() {
        coordinator?.dismiss()
    }

    private func handleViewDidAppear() {
        dAppLoadingTask?.cancel()

        dAppLoadingTask = Task { [weak self, getDAppConnectionProposalUseCase] in
            do {
                let dAppProposal = try await getDAppConnectionProposalUseCase()
                // [REDACTED_TODO_COMMENT]
            } catch {}
        }
    }

    private func handleVerifiedDomainIconTapped() {
        coordinator?.openDomainVerification()
    }

    private func handleConnectionRequestSectionHeaderTapped() {}

    private func handleWalletRowTapped() {
        coordinator?.openWalletSelector()
    }

    private func handleNetworksRowTapped() {
        coordinator?.openNetworksSelector()
    }

    private func handleCancelButtonTapped() {}

    private func handleConnectButtonTapped() {}
}
