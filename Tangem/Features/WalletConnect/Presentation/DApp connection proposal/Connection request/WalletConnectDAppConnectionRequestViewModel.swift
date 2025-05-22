//
//  WalletConnectDAppConnectionRequestViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class WalletConnectDAppConnectionRequestViewModel: ObservableObject {
    private let getDAppConnectionProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase
    private var dAppLoadingTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectDAppConnectionRequestViewState
    weak var coordinator: (any WalletConnectDAppConnectionProposalRoutable)?

    init(
        state: WalletConnectDAppConnectionRequestViewState,
        getDAppConnectionProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase,
    ) {
        self.state = state
        self.getDAppConnectionProposalUseCase = getDAppConnectionProposalUseCase
    }

    deinit {
        dAppLoadingTask?.cancel()
    }
}

// MARK: - View events handling

extension WalletConnectDAppConnectionRequestViewModel {
    func handle(viewEvent: WalletConnectDAppConnectionRequestViewEvent) {
        switch viewEvent {
        case .navigationCloseButtonTapped:
            handleNavigationCloseButtonTapped()

        case .dAppProposalLoadingRequested:
            handleDAppProposalLoadingRequested()

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

    private func handleDAppProposalLoadingRequested() {
        dAppLoadingTask?.cancel()

        dAppLoadingTask = Task { [weak self, getDAppConnectionProposalUseCase] in
            do {
                let dAppProposal = try await getDAppConnectionProposalUseCase()
                // [REDACTED_TODO_COMMENT]
                self?.state = .content(proposal: dAppProposal, walletName: "Dummy wallet", walletSelectionIsAvailable: false)
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
