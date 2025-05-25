//
//  WalletConnectDAppConnectionRequestViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import enum BlockchainSdk.Blockchain

@MainActor
final class WalletConnectDAppConnectionRequestViewModel: ObservableObject {
    private let getDAppConnectionProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase
    private let resolveAvailableBlockchainsUseCase: WalletConnectResolveAvailableBlockchainsUseCase
    private let connectDAppUseCase: WalletConnectConnectDAppUseCase

    private var loadedSessionProposal: WalletConnectSessionProposal?

    private var dAppLoadingTask: Task<Void, Never>?
    private var dAppConnectionTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectDAppConnectionRequestViewState

    private(set) var selectedUserWallet: any UserWalletModel
    private(set) var selectedBlockchains: [Blockchain]

    weak var coordinator: (any WalletConnectDAppConnectionProposalRoutable)?

    init(
        state: WalletConnectDAppConnectionRequestViewState,
        getDAppConnectionProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase,
        resolveAvailableBlockchainsUseCase: WalletConnectResolveAvailableBlockchainsUseCase,
        connectDAppUseCase: WalletConnectConnectDAppUseCase,
        selectedUserWallet: some UserWalletModel
    ) {
        self.state = state
        self.getDAppConnectionProposalUseCase = getDAppConnectionProposalUseCase
        self.resolveAvailableBlockchainsUseCase = resolveAvailableBlockchainsUseCase
        self.connectDAppUseCase = connectDAppUseCase
        self.selectedUserWallet = selectedUserWallet
        selectedBlockchains = []
    }

    deinit {
        dAppLoadingTask?.cancel()
        dAppConnectionTask?.cancel()
    }

    func updateSelectedUserWallet(_ selectedUserWallet: some UserWalletModel) {
        self.selectedUserWallet = selectedUserWallet
        state.walletSection.selectedUserWalletName = selectedUserWallet.name
        // [REDACTED_TODO_COMMENT]
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
                let blockchainsAvailabilityResult = resolveAvailableBlockchainsUseCase(
                    connectionProposal: dAppProposal,
                    selectedBlockchains: [],
                    userWallet: selectedUserWallet
                )
                self?.loadedSessionProposal = dAppProposal.sessionProposal
                self?.selectedBlockchains = Array(dAppProposal.requiredBlockchains)
                self?.updateState(dAppProposal: dAppProposal, blockchainsAvailabilityResult: blockchainsAvailabilityResult)
            } catch {
                self?.coordinator?.openErrorScreen(error: error)
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
        guard state.walletSection.selectionIsAvailable else { return }
        coordinator?.openWalletSelector()
    }

    private func handleNetworksRowTapped() {
        coordinator?.openNetworksSelector()
    }

    private func handleCancelButtonTapped() {
        coordinator?.dismiss()
    }

    private func handleConnectButtonTapped() {
        guard let loadedSessionProposal else { return }

        dAppConnectionTask?.cancel()

        dAppConnectionTask = Task { [selectedUserWallet, selectedBlockchains, connectDAppUseCase] in
            do {
                try await connectDAppUseCase(
                    proposal: loadedSessionProposal,
                    selectedBlockchains: selectedBlockchains,
                    selectedUserWallet: selectedUserWallet
                )
                print("done")
            } catch {
                print(error)
            }
        }
    }
}

// MARK: - State update and mapping

extension WalletConnectDAppConnectionRequestViewModel {
    private func updateState(
        dAppProposal: WalletConnectDAppConnectionProposal,
        blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult
    ) {
        let allRequiredBlockchainsAreAvailable = blockchainsAvailabilityResult.unavailableRequiredBlockchains.isEmpty
        let atLeastOneBlockchainIsSelected = !blockchainsAvailabilityResult.availableBlockchains.filter(\.isSelected).isEmpty

        state = .content(
            proposal: dAppProposal,
            selectedUserWalletName: selectedUserWallet.name,
            walletSelectionIsAvailable: state.walletSection.selectionIsAvailable,
            blockchainsAvailabilityResult: blockchainsAvailabilityResult,
            connectButtonIsEnabled: allRequiredBlockchainsAreAvailable && atLeastOneBlockchainIsSelected
        )
    }
}
