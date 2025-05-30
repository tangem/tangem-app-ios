//
//  WalletConnectDAppConnectionRequestViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import enum BlockchainSdk.Blockchain
import TangemLocalization

@MainActor
final class WalletConnectDAppConnectionRequestViewModel: ObservableObject {
    private let getDAppConnectionProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase
    private let resolveAvailableBlockchainsUseCase: WalletConnectResolveAvailableBlockchainsUseCase
    private let connectDAppUseCase: WalletConnectConnectDAppUseCase

    private var cachedDAppProposal: WalletConnectDAppConnectionProposal?
    private(set) var cachedBlockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult?

    private var dAppLoadingTask: Task<Void, Never>?
    private var dAppConnectionTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectDAppConnectionRequestViewState

    private(set) var selectedUserWallet: any UserWalletModel

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
    }

    deinit {
        dAppLoadingTask?.cancel()
        dAppConnectionTask?.cancel()
    }

    func updateSelectedUserWallet(_ selectedUserWallet: some UserWalletModel) {
        self.selectedUserWallet = selectedUserWallet
        state.walletSection.selectedUserWalletName = selectedUserWallet.name

        guard let cachedDAppProposal else { return }

        let blockchainsAvailabilityResult = resolveAvailableBlockchainsUseCase(
            sessionProposal: cachedDAppProposal.sessionProposal,
            selectedBlockchains: cachedBlockchainsAvailabilityResult?.retrieveSelectedBlockchains() ?? [],
            userWallet: selectedUserWallet
        )

        cachedBlockchainsAvailabilityResult = blockchainsAvailabilityResult
        updateState(dAppProposal: cachedDAppProposal, blockchainsAvailabilityResult: blockchainsAvailabilityResult)
    }

    func updateSelectedBlockchains(_ selectedBlockchains: [Blockchain]) {
        guard let cachedDAppProposal else { return }

        let blockchainsAvailabilityResult = resolveAvailableBlockchainsUseCase(
            sessionProposal: cachedDAppProposal.sessionProposal,
            selectedBlockchains: selectedBlockchains,
            userWallet: selectedUserWallet
        )

        cachedBlockchainsAvailabilityResult = blockchainsAvailabilityResult
        updateState(dAppProposal: cachedDAppProposal, blockchainsAvailabilityResult: blockchainsAvailabilityResult)
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

        dAppLoadingTask = Task { [weak self, getDAppConnectionProposalUseCase, resolveAvailableBlockchainsUseCase, selectedUserWallet] in
            do {
                let dAppProposal = try await getDAppConnectionProposalUseCase()
                let blockchainsAvailabilityResult = resolveAvailableBlockchainsUseCase(
                    sessionProposal: dAppProposal.sessionProposal,
                    selectedBlockchains: [],
                    userWallet: selectedUserWallet
                )

                self?.cachedDAppProposal = dAppProposal
                self?.cachedBlockchainsAvailabilityResult = blockchainsAvailabilityResult

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
        guard
            !state.connectButton.isLoading,
            let cachedDAppProposal,
            let cachedBlockchainsAvailabilityResult
        else {
            return
        }

        state.connectButton.isLoading = true

        dAppConnectionTask?.cancel()
        dAppConnectionTask = Task { [weak self, selectedUserWallet, connectDAppUseCase] in
            do {
                try await connectDAppUseCase(
                    proposal: cachedDAppProposal.sessionProposal,
                    selectedBlockchains: cachedBlockchainsAvailabilityResult.retrieveSelectedBlockchains(),
                    selectedUserWallet: selectedUserWallet
                )
                self?.coordinator?.showSuccessToast(with: "\(cachedDAppProposal.dApp.name) has been connected")
                self?.coordinator?.dismiss()
            } catch {
                // [REDACTED_TODO_COMMENT]
                self?.coordinator?.showErrorToast(with: error.localizedDescription)
            }

            self?.state.connectButton.isLoading = false
        }
    }
}

// MARK: - State updates and mapping

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

extension WalletConnectDAppConnectionRequestViewState {
    static func loading(selectedUserWalletName: String, walletSelectionIsAvailable: Bool) -> WalletConnectDAppConnectionRequestViewState {
        WalletConnectDAppConnectionRequestViewState(
            dAppDescriptionSection: WalletConnectDAppDescriptionViewModel.loading,
            connectionRequestSection: ConnectionRequestSection.loading,
            dAppVerificationWarningSection: nil,
            walletSection: WalletSection(selectedUserWalletName: selectedUserWalletName, selectionIsAvailable: walletSelectionIsAvailable),
            networksSection: NetworksSection(state: .loading),
            networksWarningSection: nil,
            connectButton: .connect(isEnabled: false, isLoading: false)
        )
    }

    fileprivate static func content(
        proposal: WalletConnectDAppConnectionProposal,
        selectedUserWalletName: String,
        walletSelectionIsAvailable: Bool,
        blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult,
        connectButtonIsEnabled: Bool
    ) -> WalletConnectDAppConnectionRequestViewState {
        WalletConnectDAppConnectionRequestViewState(
            dAppDescriptionSection: WalletConnectDAppDescriptionViewModel.content(
                WalletConnectDAppDescriptionViewModel.ContentState(
                    dAppData: proposal.dApp,
                    verificationStatus: proposal.verificationStatus
                )
            ),
            connectionRequestSection: ConnectionRequestSection.content(ConnectionRequestSection.ContentState(isExpanded: false)),
            dAppVerificationWarningSection: WalletConnectWarningNotificationViewModel(proposal.verificationStatus),
            walletSection: WalletSection(selectedUserWalletName: selectedUserWalletName, selectionIsAvailable: walletSelectionIsAvailable),
            networksSection: NetworksSection(blockchainsAvailabilityResult: blockchainsAvailabilityResult),
            networksWarningSection: WalletConnectWarningNotificationViewModel(blockchainsAvailabilityResult),
            connectButton: .connect(isEnabled: connectButtonIsEnabled, isLoading: false)
        )
    }
}

private extension WalletConnectDAppConnectionRequestViewState.ConnectionRequestSection {
    mutating func toggleIsExpanded() {
        guard case .content(var contentState) = self else { return }
        contentState.isExpanded.toggle()
        self = .content(contentState)
    }
}

private extension WalletConnectDAppConnectionRequestViewState.NetworksSection {
    init(blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult) {
        guard blockchainsAvailabilityResult.unavailableRequiredBlockchains.isEmpty else {
            self.init(state: .content(.init(selectionMode: .requiredNetworksAreMissing)))
            return
        }

        let availableSelectionMode = AvailableSelectionMode(
            blockchains: blockchainsAvailabilityResult.retrieveSelectedBlockchains()
        )
        let contentState = ContentState(selectionMode: .available(availableSelectionMode))
        self.init(state: .content(contentState))
    }
}

private extension WalletConnectDAppConnectionRequestViewState.NetworksSection.AvailableSelectionMode {
    init(blockchains: [Blockchain]) {
        let remainingBlockchainsCounter: String?

        let maximumIconsCount = 4
        let imageProvider = NetworkImageProvider()
        let prefixedBlockchains: [BlockchainSdk.Blockchain]

        let shouldShowRemainingBlockchainsCounter = blockchains.count > maximumIconsCount

        if shouldShowRemainingBlockchainsCounter {
            let blockchainsCountToTake = maximumIconsCount - 1
            prefixedBlockchains = Array(blockchains.prefix(blockchainsCountToTake))
            remainingBlockchainsCounter = "+\(blockchains.count - blockchainsCountToTake)"
        } else {
            prefixedBlockchains = blockchains
            remainingBlockchainsCounter = nil
        }

        self.init(
            blockchainLogoAssets: prefixedBlockchains.map { blockchain in
                imageProvider.provide(by: blockchain, filled: true)
            },
            remainingBlockchainsCounter: remainingBlockchainsCounter
        )
    }
}

private extension WalletConnectWarningNotificationViewModel {
    init?(_ verificationStatus: WalletConnectDAppVerificationStatus) {
        switch verificationStatus {
        case .verified:
            return nil

        case .unknownDomain:
            self = .dAppUnknownDomain

        case .malicious:
            self = .dAppKnownSecurityRisk
        }
    }

    init?(_ blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult) {
        guard blockchainsAvailabilityResult.unavailableRequiredBlockchains.isEmpty else {
            self = .requiredNetworksAreUnavailableForSelectedWallet(
                blockchainsAvailabilityResult.unavailableRequiredBlockchains.map(\.displayName)
            )
            return
        }

        let atLeastOneBlockchainIsSelected = !blockchainsAvailabilityResult.availableBlockchains.filter(\.isSelected).isEmpty

        guard atLeastOneBlockchainIsSelected else {
            self = .noBlockchainsAreSelected
            return
        }

        return nil
    }
}
