//
//  WalletConnectDAppConnectionRequestViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import enum BlockchainSdk.Blockchain
import TangemFoundation
import TangemLocalization
import TangemLogger

@MainActor
final class WalletConnectDAppConnectionRequestViewModel: ObservableObject {
    private let interactor: WalletConnectDAppConnectionInteractor
    private let logger: TangemLogger.Logger
    private let analyticsLogger: any WalletConnectDAppConnectionRequestAnalyticsLogger
    private let hapticFeedbackGenerator: any WalletConnectHapticFeedbackGenerator

    private var selectedUserWallet: any UserWalletModel
    private var userWalletIDToBlockchainsAvailabilityResult: [UserWalletId: WalletConnectDAppBlockchainsAvailabilityResult]

    private var loadedDAppProposal: WalletConnectDAppConnectionProposal?

    private var dAppLoadingTask: Task<Void, Never>?
    private var dAppConnectionTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectDAppConnectionRequestViewState

    weak var coordinator: (any WalletConnectDAppConnectionRoutable)?

    init(
        state: WalletConnectDAppConnectionRequestViewState,
        interactor: WalletConnectDAppConnectionInteractor,
        analyticsLogger: some WalletConnectDAppConnectionRequestAnalyticsLogger,
        logger: TangemLogger.Logger,
        hapticFeedbackGenerator: some WalletConnectHapticFeedbackGenerator,
        selectedUserWallet: some UserWalletModel
    ) {
        self.state = state
        self.interactor = interactor
        self.logger = logger
        self.analyticsLogger = analyticsLogger

        self.hapticFeedbackGenerator = hapticFeedbackGenerator

        self.selectedUserWallet = selectedUserWallet
        userWalletIDToBlockchainsAvailabilityResult = [:]
    }

    deinit {
        dAppLoadingTask?.cancel()
        dAppConnectionTask?.cancel()
    }

    func updateSelectedUserWallet(_ selectedUserWallet: some UserWalletModel) {
        self.selectedUserWallet = selectedUserWallet
        state.walletSection.selectedUserWalletName = selectedUserWallet.name

        guard let loadedDAppProposal else { return }

        let previousBlockchainsAvailabilityResult = userWalletIDToBlockchainsAvailabilityResult[selectedUserWallet.userWalletId]
        let selectedBlockchains = previousBlockchainsAvailabilityResult?.retrieveSelectedBlockchains()
            ?? Array(loadedDAppProposal.sessionProposal.optionalBlockchains)

        let blockchainsAvailabilityResult = interactor.resolveAvailableBlockchains(
            sessionProposal: loadedDAppProposal.sessionProposal,
            selectedBlockchains: selectedBlockchains,
            userWallet: selectedUserWallet
        )

        userWalletIDToBlockchainsAvailabilityResult[selectedUserWallet.userWalletId] = blockchainsAvailabilityResult
        updateState(dAppProposal: loadedDAppProposal, blockchainsAvailabilityResult: blockchainsAvailabilityResult)
    }

    func updateSelectedBlockchains(_ selectedBlockchains: [Blockchain]) {
        guard let loadedDAppProposal else { return }

        let blockchainsAvailabilityResult = interactor.resolveAvailableBlockchains(
            sessionProposal: loadedDAppProposal.sessionProposal,
            selectedBlockchains: selectedBlockchains,
            userWallet: selectedUserWallet
        )

        userWalletIDToBlockchainsAvailabilityResult[selectedUserWallet.userWalletId] = blockchainsAvailabilityResult
        updateState(dAppProposal: loadedDAppProposal, blockchainsAvailabilityResult: blockchainsAvailabilityResult)
    }
}

// MARK: - DApp proposal loading

extension WalletConnectDAppConnectionRequestViewModel {
    func loadDAppConnectionProposal() {
        guard loadedDAppProposal == nil else { return }

        hapticFeedbackGenerator.prepareNotificationFeedback()
        dAppLoadingTask?.cancel()

        dAppLoadingTask = Task { [weak self, getDAppConnectionProposal = interactor.getDAppConnectionProposal, analyticsLogger] in
            // [REDACTED_USERNAME], due to Task's operation closure error erasing nature in current language version,
            // it is required to explicitly define error type in order to compile :/
            do throws(WalletConnectDAppProposalLoadingError) {
                analyticsLogger.logSessionInitiated()
                let dAppProposal = try await getDAppConnectionProposal()
                self?.handleLoadedDAppProposal(dAppProposal)
            } catch {
                self?.hapticFeedbackGenerator.errorNotificationOccurred()
                self?.coordinator?.display(proposalLoadingError: error)
                analyticsLogger.logSessionFailed(with: error)
            }
        }
    }

    private func handleLoadedDAppProposal(_ dAppProposal: WalletConnectDAppConnectionProposal) {
        analyticsLogger.logConnectionProposalReceived(dAppProposal)

        let blockchainsAvailabilityResult = interactor.resolveAvailableBlockchains(
            sessionProposal: dAppProposal.sessionProposal,
            selectedBlockchains: dAppProposal.sessionProposal.optionalBlockchains,
            userWallet: selectedUserWallet
        )

        loadedDAppProposal = dAppProposal
        userWalletIDToBlockchainsAvailabilityResult[selectedUserWallet.userWalletId] = blockchainsAvailabilityResult

        updateState(dAppProposal: dAppProposal, blockchainsAvailabilityResult: blockchainsAvailabilityResult)
        hapticFeedbackGenerator.successNotificationOccurred()
    }
}

// MARK: - DApp proposal connect / cancel

extension WalletConnectDAppConnectionRequestViewModel {
    private func connectDApp(with proposal: WalletConnectDAppConnectionProposal, selectedBlockchains: [Blockchain]) async {
        analyticsLogger.logConnectButtonTapped()

        let dAppSession: WalletConnectDAppSession

        do {
            dAppSession = try await interactor.approveDAppProposal(
                sessionProposal: proposal.sessionProposal,
                selectedBlockchains: selectedBlockchains,
                selectedUserWallet: selectedUserWallet
            )
        } catch {
            analyticsLogger.logDAppConnectionFailed(with: error)
            hapticFeedbackGenerator.errorNotificationOccurred()
            coordinator?.display(proposalApprovalError: error)
            return
        }

        do {
            try await interactor.persistConnectedDApp(
                connectionProposal: proposal,
                dAppSession: dAppSession,
                blockchains: selectedBlockchains,
                userWallet: selectedUserWallet
            )
        } catch {
            hapticFeedbackGenerator.errorNotificationOccurred()
            coordinator?.display(dAppPersistenceError: error)
            logger.error("Failed to persist \(proposal.dAppData.name) dApp", error: error)
            return
        }

        analyticsLogger.logDAppConnected(with: proposal.dAppData)
        hapticFeedbackGenerator.successNotificationOccurred()
        coordinator?.displaySuccessfulDAppConnection(with: proposal.dAppData.name)
        coordinator?.dismiss()
    }

    private func rejectDAppProposal() {
        if let loadedDAppProposal {
            Task { [rejectDAppProposal = interactor.rejectDAppProposal, analyticsLogger, logger] in
                do {
                    try await rejectDAppProposal(proposalID: loadedDAppProposal.sessionProposal.id)
                    analyticsLogger.logDAppDisconnected(with: loadedDAppProposal.dAppData)
                } catch {
                    logger.error("Failed to disconnect \(loadedDAppProposal.dAppData.name) dApp", error: error)
                }
            }
        }

        analyticsLogger.logCancelButtonTapped()
        coordinator?.dismiss()
    }
}

// MARK: - View events handling

extension WalletConnectDAppConnectionRequestViewModel {
    func handle(viewEvent: WalletConnectDAppConnectionRequestViewEvent) {
        switch viewEvent {
        case .navigationCloseButtonTapped:
            handleNavigationCloseButtonTapped()

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
        rejectDAppProposal()
    }

    private func handleVerifiedDomainIconTapped() {
        guard !state.dAppDescriptionSection.isLoading, let dAppName = loadedDAppProposal?.dAppData.name else { return }
        coordinator?.openVerifiedDomain(for: dAppName)
    }

    private func handleConnectionRequestSectionHeaderTapped() {
        state.connectionRequestSection.toggleIsExpanded()
    }

    private func handleWalletRowTapped() {
        guard state.walletSection.selectionIsAvailable else { return }
        coordinator?.openWalletSelector()
    }

    private func handleNetworksRowTapped() {
        guard let blockchainsAvailabilityResult = userWalletIDToBlockchainsAvailabilityResult[selectedUserWallet.userWalletId] else { return }
        coordinator?.openNetworksSelector(blockchainsAvailabilityResult)
    }

    private func handleCancelButtonTapped() {
        rejectDAppProposal()
    }

    private func handleConnectButtonTapped() {
        hapticFeedbackGenerator.prepareNotificationFeedback()

        guard
            !state.connectButton.isLoading,
            state.connectButton.isEnabled,
            let loadedDAppProposal,
            let blockchainsAvailabilityResult = userWalletIDToBlockchainsAvailabilityResult[selectedUserWallet.userWalletId]
        else {
            hapticFeedbackGenerator.warningNotificationOccurred()
            return
        }

        let selectedBlockchains = blockchainsAvailabilityResult.retrieveSelectedBlockchains()
        let allRequiredBlockchainsAreAvailable = blockchainsAvailabilityResult.unavailableRequiredBlockchains.isEmpty
        let atLeastOneBlockchainIsSelected = selectedBlockchains.isNotEmpty

        guard allRequiredBlockchainsAreAvailable, atLeastOneBlockchainIsSelected else {
            hapticFeedbackGenerator.warningNotificationOccurred()
            return
        }

        guard loadedDAppProposal.verificationStatus.isVerified else {
            coordinator?.openDomainVerificationWarning(
                loadedDAppProposal.verificationStatus,
                connectAnywayAction: { [weak self] in
                    await self?.connectDApp(with: loadedDAppProposal, selectedBlockchains: selectedBlockchains)
                }
            )
            return
        }

        state.connectButton.isLoading = true

        dAppConnectionTask?.cancel()
        dAppConnectionTask = Task { [weak self] in
            await self?.connectDApp(with: loadedDAppProposal, selectedBlockchains: selectedBlockchains)
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
        state = .content(
            proposal: dAppProposal,
            connectionRequestSectionIsExpanded: state.connectionRequestSection.isExpanded,
            selectedUserWalletName: selectedUserWallet.name,
            walletSelectionIsAvailable: state.walletSection.selectionIsAvailable,
            blockchainsAvailabilityResult: blockchainsAvailabilityResult
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
            connectButton: .connect(isEnabled: true, isLoading: true)
        )
    }

    fileprivate static func content(
        proposal: WalletConnectDAppConnectionProposal,
        connectionRequestSectionIsExpanded: Bool,
        selectedUserWalletName: String,
        walletSelectionIsAvailable: Bool,
        blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult
    ) -> WalletConnectDAppConnectionRequestViewState {
        let connectButtonIsEnabled = blockchainsAvailabilityResult.unavailableRequiredBlockchains.isEmpty
            && blockchainsAvailabilityResult.retrieveSelectedBlockchains().isNotEmpty

        return WalletConnectDAppConnectionRequestViewState(
            dAppDescriptionSection: WalletConnectDAppDescriptionViewModel.content(
                WalletConnectDAppDescriptionViewModel.ContentState(
                    dAppData: proposal.dAppData,
                    verificationStatus: proposal.verificationStatus
                )
            ),
            connectionRequestSection: ConnectionRequestSection.content(
                ConnectionRequestSection.ContentState(
                    isExpanded: connectionRequestSectionIsExpanded
                )
            ),
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
