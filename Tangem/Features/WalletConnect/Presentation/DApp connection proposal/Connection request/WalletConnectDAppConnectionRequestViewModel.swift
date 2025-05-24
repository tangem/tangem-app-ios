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
    private let resolveAvailableBlockchainsUseCase: WalletConnectResolveAvailableBlockchainsUseCase
    private let selectedUserWallet: any UserWalletModel

    private var dAppLoadingTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectDAppConnectionRequestViewState
    weak var coordinator: (any WalletConnectDAppConnectionProposalRoutable)?

    init(
        state: WalletConnectDAppConnectionRequestViewState,
        getDAppConnectionProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase,
        resolveAvailableBlockchainsUseCase: WalletConnectResolveAvailableBlockchainsUseCase,
        selectedUserWallet: some UserWalletModel
    ) {
        self.state = state
        self.getDAppConnectionProposalUseCase = getDAppConnectionProposalUseCase
        self.resolveAvailableBlockchainsUseCase = resolveAvailableBlockchainsUseCase
        self.selectedUserWallet = selectedUserWallet
    }

    deinit {
        dAppLoadingTask?.cancel()
    }

    private var debugLoadingState: WalletConnectDAppConnectionRequestViewState?
    private var debugContentState: WalletConnectDAppConnectionRequestViewState?
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

        dAppLoadingTask = Task { [weak self, getDAppConnectionProposalUseCase, resolveAvailableBlockchainsUseCase, selectedUserWallet] in
            do {
                let dAppProposal = try await getDAppConnectionProposalUseCase()
                let availableBlockchainsResult = resolveAvailableBlockchainsUseCase(
                    connectionProposal: dAppProposal,
                    selectedBlockchains: [],
                    userWallet: selectedUserWallet
                )
                self?.state = .content(proposal: dAppProposal, walletName: "Dummy wallet", walletSelectionIsAvailable: false)
            } catch {
                print(error)
            }
        }
    }

    private func handleVerifiedDomainIconTapped() {
        guard !state.dAppDescriptionSection.isLoading else { return }
        coordinator?.openDomainVerification()
    }

    private func handleConnectionRequestSectionHeaderTapped() {
        state.connectionRequestSection.toggleIsExpanded()
    }

    private func handleWalletRowTapped() {
        coordinator?.openWalletSelector()
    }

    private func handleNetworksRowTapped() {
        coordinator?.openNetworksSelector()
    }

    private func handleCancelButtonTapped() {}

    private func handleConnectButtonTapped() {
        if debugLoadingState == nil && state.connectionRequestSection.isLoading {
            debugLoadingState = state
        }

        if debugContentState == nil && state.connectionRequestSection.isLoading == false {
            debugContentState = state
        }

        guard let debugContentState, let debugLoadingState else { return }

        if state.connectionRequestSection.isLoading {
            state = debugContentState
        } else {
            state = debugLoadingState
        }
    }
}

// MARK: - State update and mapping

extension WalletConnectDAppConnectionRequestViewModel {

}
