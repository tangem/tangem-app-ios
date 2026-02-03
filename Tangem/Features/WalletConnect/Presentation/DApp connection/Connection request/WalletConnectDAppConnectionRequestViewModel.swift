//
//  WalletConnectDAppConnectionRequestViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import enum BlockchainSdk.Blockchain
import TangemFoundation
import TangemLocalization
import TangemLogger
import TangemUI
import TangemAssets

@MainActor
final class WalletConnectDAppConnectionRequestViewModel: ObservableObject {
    private let interactor: WalletConnectDAppConnectionInteractor
    private let logger: TangemLogger.Logger
    private let analyticsLogger: any WalletConnectDAppConnectionRequestAnalyticsLogger
    private let hapticFeedbackGenerator: any WalletConnectHapticFeedbackGenerator

    private var selectedUserWallet: any UserWalletModel
    private var userWalletIDToBlockchainsAvailabilityResult: [UserWalletId: WalletConnectDAppBlockchainsAvailabilityResult]
    private var accountCacheKeyToBlockchainsAvailabilityResult: [AccountCacheKey: WalletConnectDAppBlockchainsAvailabilityResult]
    private var selectedAccount: (any CryptoAccountModel)?
    private var hasMultipleAccounts: Bool = false

    private var loadedDAppProposal: WalletConnectDAppConnectionProposal?

    private var dAppLoadingTask: Task<Void, Never>?
    private var dAppConnectionTask: Task<Void, Never>?

    private var bag: Set<AnyCancellable>

    @Published private(set) var state: WalletConnectDAppConnectionRequestViewState

    weak var coordinator: (any WalletConnectDAppConnectionRoutable)?

    init(
        state: WalletConnectDAppConnectionRequestViewState,
        interactor: WalletConnectDAppConnectionInteractor,
        analyticsLogger: some WalletConnectDAppConnectionRequestAnalyticsLogger,
        logger: TangemLogger.Logger,
        hapticFeedbackGenerator: some WalletConnectHapticFeedbackGenerator,
        selectedUserWallet: some UserWalletModel,
    ) {
        self.state = state
        self.interactor = interactor
        self.logger = logger
        self.analyticsLogger = analyticsLogger

        self.hapticFeedbackGenerator = hapticFeedbackGenerator

        self.selectedUserWallet = selectedUserWallet

        let selectedAccountModel = selectedUserWallet.accountModelsManager.accountModels.firstStandard()

        switch selectedAccountModel {
        case .standard(.single(let account)):
            selectedAccount = account
        case .standard(.multiple(let accounts)):
            selectedAccount = accounts.first
            hasMultipleAccounts = true
        case .none:
            selectedAccount = nil
        }

        bag = []
        userWalletIDToBlockchainsAvailabilityResult = [:]
        accountCacheKeyToBlockchainsAvailabilityResult = [:]
    }

    deinit {
        dAppLoadingTask?.cancel()
        dAppConnectionTask?.cancel()
    }

    // [REDACTED_TODO_COMMENT]
    func updateSelectedUserWallet(_ selectedUserWallet: some UserWalletModel) {
        self.selectedUserWallet = selectedUserWallet
        state.walletSection?.selectedUserWalletName = selectedUserWallet.name

        guard let loadedDAppProposal else { return }

        let previousBlockchainsAvailabilityResult = userWalletIDToBlockchainsAvailabilityResult[selectedUserWallet.userWalletId]
        let selectedBlockchains = previousBlockchainsAvailabilityResult?.retrieveSelectedBlockchains().map(\.blockchain)
            ?? Array(loadedDAppProposal.sessionProposal.optionalBlockchains)

        let blockchainsAvailabilityResult = interactor.resolveAvailableBlockchains(
            sessionProposal: loadedDAppProposal.sessionProposal,
            selectedBlockchains: selectedBlockchains,
            userWallet: selectedUserWallet
        )

        userWalletIDToBlockchainsAvailabilityResult[selectedUserWallet.userWalletId] = blockchainsAvailabilityResult
        updateState(dAppProposal: loadedDAppProposal, blockchainsAvailabilityResult: blockchainsAvailabilityResult)
    }

    // [REDACTED_TODO_COMMENT]
    func updateSelectedBlockchainsForWallet(_ selectedBlockchains: [Blockchain]) {
        guard let loadedDAppProposal else { return }

        let blockchainsAvailabilityResult = interactor.resolveAvailableBlockchains(
            sessionProposal: loadedDAppProposal.sessionProposal,
            selectedBlockchains: selectedBlockchains,
            userWallet: selectedUserWallet
        )

        userWalletIDToBlockchainsAvailabilityResult[selectedUserWallet.userWalletId] = blockchainsAvailabilityResult
        updateState(dAppProposal: loadedDAppProposal, blockchainsAvailabilityResult: blockchainsAvailabilityResult)
    }

    func updateSelectedAccount(_ selectedAccount: (any CryptoAccountModel)?, selectedUserWallet: some UserWalletModel) {
        guard let loadedDAppProposal, let selectedAccount else { return }

        self.selectedAccount = selectedAccount
        self.selectedUserWallet = selectedUserWallet
        hasMultipleAccounts = selectedUserWallet.accountModelsManager.accountModels.cryptoAccounts().hasMultipleAccounts

        let cacheKey = AccountCacheKey(
            userWalletId: selectedUserWallet.userWalletId.stringValue,
            accountId: selectedAccount.id.walletConnectIdentifierString
        )
        let previousBlockchainsAvailabilityResult = accountCacheKeyToBlockchainsAvailabilityResult[cacheKey]
        let selectedBlockchains = previousBlockchainsAvailabilityResult?.retrieveSelectedBlockchains().map(\.blockchain)
            ?? Array(loadedDAppProposal.sessionProposal.optionalBlockchains)

        let blockchainsAvailabilityResult = interactor.resolveAvailableBlockchains(
            sessionProposal: loadedDAppProposal.sessionProposal,
            selectedBlockchains: selectedBlockchains,
            wcAccountsWalletModelProvider: selectedUserWallet.wcAccountsWalletModelProvider,
            account: selectedAccount
        )

        accountCacheKeyToBlockchainsAvailabilityResult[cacheKey] = blockchainsAvailabilityResult
        updateState(dAppProposal: loadedDAppProposal, blockchainsAvailabilityResult: blockchainsAvailabilityResult)
    }

    func updateSelectedBlockchainsForAccount(_ selectedBlockchains: [Blockchain]) {
        guard let loadedDAppProposal, let selectedAccount else { return }

        let blockchainsAvailabilityResult = interactor.resolveAvailableBlockchains(
            sessionProposal: loadedDAppProposal.sessionProposal,
            selectedBlockchains: selectedBlockchains,
            wcAccountsWalletModelProvider: selectedUserWallet.wcAccountsWalletModelProvider,
            account: selectedAccount
        )

        let cacheKey = AccountCacheKey(
            userWalletId: selectedUserWallet.userWalletId.stringValue,
            accountId: selectedAccount.id.walletConnectIdentifierString
        )
        accountCacheKeyToBlockchainsAvailabilityResult[cacheKey] = blockchainsAvailabilityResult
        updateState(dAppProposal: loadedDAppProposal, blockchainsAvailabilityResult: blockchainsAvailabilityResult)
    }
}

// MARK: - DApp proposal loading

extension WalletConnectDAppConnectionRequestViewModel {
    func loadDAppConnectionProposal() {
        guard loadedDAppProposal == nil else { return }

        hapticFeedbackGenerator.prepareNotificationFeedback()
        dAppLoadingTask?.cancel()

        dAppLoadingTask = Task { [weak self, getDAppConnectionProposal = interactor.getDAppConnectionProposal, logger, analyticsLogger] in
            // [REDACTED_USERNAME], due to Task's operation closure error erasing nature in current language version,
            // it is required to explicitly define error type in order to compile :/
            do throws(WalletConnectDAppProposalLoadingError) {
                analyticsLogger.logSessionInitiated()
                let dAppProposal = try await getDAppConnectionProposal()

                if FeatureProvider.isAvailable(.accounts) {
                    self?.handleLoadedDAppProposalForAccount(dAppProposal)
                } else {
                    self?.handleLoadedDAppProposalForWallet(dAppProposal)
                }
            } catch {
                // Ugly and explicit switch here due to https://github.com/swiftlang/swift/issues/74555 ([REDACTED_INFO])
                switch error {
                case .cancelledByUser:
                    logger.info("DApp proposal loading canceled by user.")
                case .uriAlreadyUsed,
                     .pairingFailed,
                     .invalidDomainURL,
                     .unsupportedDomain,
                     .unsupportedBlockchains,
                     .noBlockchainsProvidedByDApp,
                     .pairingTimeout:
                    analyticsLogger.logSessionFailed(with: error)
                    logger.error("Failed to load dApp proposal", error: error)
                    self?.hapticFeedbackGenerator.errorNotificationOccurred()
                    self?.coordinator?.display(proposalLoadingError: error)
                }
            }
        }
    }

    // [REDACTED_TODO_COMMENT]
    private func handleLoadedDAppProposalForWallet(_ dAppProposal: WalletConnectDAppConnectionProposal) {
        // No account should be passed here. This method will be deleted when migration is complete ([REDACTED_INFO])
        analyticsLogger.logConnectionProposalReceived(dAppProposal, accountAnalyticsProviding: nil)

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

    private func handleLoadedDAppProposalForAccount(_ dAppProposal: WalletConnectDAppConnectionProposal) {
        guard let selectedAccount else { return }

        analyticsLogger.logConnectionProposalReceived(dAppProposal, accountAnalyticsProviding: selectedAccount)

        let blockchainsAvailabilityResult = interactor.resolveAvailableBlockchains(
            sessionProposal: dAppProposal.sessionProposal,
            selectedBlockchains: dAppProposal.sessionProposal.optionalBlockchains,
            wcAccountsWalletModelProvider: selectedUserWallet.wcAccountsWalletModelProvider,
            account: selectedAccount
        )

        loadedDAppProposal = dAppProposal
        let cacheKey = AccountCacheKey(
            userWalletId: selectedUserWallet.userWalletId.stringValue,
            accountId: selectedAccount.id.walletConnectIdentifierString
        )
        accountCacheKeyToBlockchainsAvailabilityResult[cacheKey] = blockchainsAvailabilityResult

        updateState(dAppProposal: dAppProposal, blockchainsAvailabilityResult: blockchainsAvailabilityResult)
        hapticFeedbackGenerator.successNotificationOccurred()
    }
}

// MARK: - DApp proposal connect / cancel

extension WalletConnectDAppConnectionRequestViewModel {
    private func connectDApp(with proposal: WalletConnectDAppConnectionProposal, selectedBlockchains: [WalletConnectDAppBlockchain]) async {
        analyticsLogger.logConnectButtonTapped(
            dAppName: proposal.dAppData.name,
            accountAnalyticsProviding: selectedAccount
        )

        let dAppSession: WalletConnectDAppSession

        do {
            if FeatureProvider.isAvailable(.accounts), let selectedAccount {
                dAppSession = try await interactor.approveDAppProposal(
                    sessionProposal: proposal.sessionProposal,
                    selectedBlockchains: selectedBlockchains.map(\.blockchain),
                    wcAccountsWalletModelProvider: selectedUserWallet.wcAccountsWalletModelProvider,
                    selectedAccount: selectedAccount
                )
            } else {
                dAppSession = try await interactor.approveDAppProposal(
                    sessionProposal: proposal.sessionProposal,
                    selectedBlockchains: selectedBlockchains.map(\.blockchain),
                    selectedUserWallet: selectedUserWallet
                )
            }
        } catch WalletConnectDAppProposalApprovalError.cancelledByUser {
            logger.info("\(proposal.dAppData.name) dApp proposal approval canceled by user.")
            return
        } catch {
            analyticsLogger.logDAppConnectionFailed(with: error)
            logger.error("Failed to approve \(proposal.dAppData.name) dApp proposal", error: error)
            hapticFeedbackGenerator.errorNotificationOccurred()
            coordinator?.display(proposalApprovalError: error)
            return
        }

        do {
            if FeatureProvider.isAvailable(.accounts) {
                try await interactor.migrateToAccounts.migrateIfNeeded()
            }

            if FeatureProvider.isAvailable(.accounts), let selectedAccount {
                try await interactor.persistConnectedDApp(
                    connectionProposal: proposal,
                    dAppSession: dAppSession,
                    dAppBlockchains: selectedBlockchains,
                    selectedUserWallet: selectedUserWallet,
                    selectedAccount: selectedAccount
                )
            } else {
                try await interactor.persistConnectedDApp(
                    connectionProposal: proposal,
                    dAppSession: dAppSession,
                    dAppBlockchains: selectedBlockchains,
                    selectedUserWallet: selectedUserWallet
                )
            }
        } catch {
            hapticFeedbackGenerator.errorNotificationOccurred()
            coordinator?.display(dAppPersistenceError: error)
            logger.error("Failed to persist \(proposal.dAppData.name) dApp", error: error)
            return
        }

        analyticsLogger.logDAppConnected(with: proposal.dAppData, verificationStatus: proposal.verificationStatus)
        hapticFeedbackGenerator.successNotificationOccurred()
        coordinator?.displaySuccessfulDAppConnection(with: proposal.dAppData.name)
        coordinator?.dismiss()
    }

    private func rejectDAppProposal() {
        if let loadedDAppProposal {
            Task { [rejectDAppProposal = interactor.rejectDAppProposal, logger] in
                do {
                    try await rejectDAppProposal(proposalID: loadedDAppProposal.sessionProposal.id)
                } catch WalletConnectDAppProposalApprovalError.cancelledByUser {
                    logger.info("\(loadedDAppProposal.dAppData.name) dApp proposal rejection canceled by user.")
                } catch {
                    logger.error("Failed to reject \(loadedDAppProposal.dAppData.name) dApp proposal", error: error)
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

        case .accountRowTapped:
            handleAccountRowTapped()

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

    private func handleVerifiedDomainIconTapped() {
        guard !state.dAppDescriptionSection.isLoading else { return }
        coordinator?.openVerifiedDomain()
    }

    private func handleConnectionRequestSectionHeaderTapped() {
        state.connectionRequestSection.toggleIsExpanded()
    }

    private func handleWalletRowTapped() {
        guard state.walletSection?.selectionIsAvailable == true else { return }
        coordinator?.openWalletSelector()
    }

    private func handleAccountRowTapped() {
        guard state.connectionTargetSection?.selectionIsAvailable == true else { return }
        coordinator?.openAccountSelector()
    }

    private func handleNetworksRowTapped() {
        if FeatureProvider.isAvailable(.accounts) {
            guard let selectedAccount else { return }
            let cacheKey = AccountCacheKey(
                userWalletId: selectedUserWallet.userWalletId.stringValue,
                accountId: selectedAccount.id.walletConnectIdentifierString
            )
            guard let blockchainsAvailabilityResult = accountCacheKeyToBlockchainsAvailabilityResult[cacheKey] else { return }
            coordinator?.openNetworksSelector(blockchainsAvailabilityResult)
        } else {
            guard let blockchainsAvailabilityResult = userWalletIDToBlockchainsAvailabilityResult[selectedUserWallet.userWalletId] else { return }
            coordinator?.openNetworksSelector(blockchainsAvailabilityResult)
        }
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
            let blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult = {
                if FeatureProvider.isAvailable(.accounts), let selectedAccount {
                    let cacheKey = AccountCacheKey(userWalletId: selectedUserWallet.userWalletId.stringValue, accountId: selectedAccount.id.walletConnectIdentifierString)
                    return accountCacheKeyToBlockchainsAvailabilityResult[cacheKey]
                } else {
                    return userWalletIDToBlockchainsAvailabilityResult[selectedUserWallet.userWalletId]
                }
            }()
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
        let walletSection: WalletConnectDAppConnectionRequestViewState.WalletSection?
        let connectionTargetSection: WalletConnectDAppConnectionRequestViewState.ConnectionTargetSection?

        if FeatureProvider.isAvailable(.accounts), let selectedAccount {
            if hasMultipleAccounts {
                connectionTargetSection = .init(
                    selectionIsAvailable: true,
                    targetName: selectedAccount.name,
                    target: .account(.init(icon: selectedAccount.icon)),
                    state: .content
                )
            } else {
                connectionTargetSection = .init(
                    selectionIsAvailable: state.connectionTargetSection?.selectionIsAvailable == true,
                    targetName: selectedUserWallet.name, target: .wallet(),
                    state: .content
                )
            }
            walletSection = nil
        } else {
            walletSection = .init(selectedUserWalletName: selectedUserWallet.name, selectionIsAvailable: state.walletSection?.selectionIsAvailable == true)
            connectionTargetSection = nil
        }

        state = .content(
            proposal: dAppProposal,
            connectionRequestSectionIsExpanded: state.connectionRequestSection.isExpanded,
            walletSection: walletSection,
            connectionTargetSection: connectionTargetSection,
            blockchainsAvailabilityResult: blockchainsAvailabilityResult,
            verifiedDomainAction: { [weak self] in
                self?.handle(viewEvent: .verifiedDomainIconTapped)
            }
        )
    }
}

extension WalletConnectDAppConnectionRequestViewState {
    static func loading(selectedUserWalletName: String, targetSelectionIsAvailable: Bool) -> WalletConnectDAppConnectionRequestViewState {
        let walletSection: WalletSection?
        let connectionTargetSection: ConnectionTargetSection?

        if FeatureProvider.isAvailable(.accounts) {
            connectionTargetSection = .init(selectionIsAvailable: targetSelectionIsAvailable, targetName: "", target: .wallet(), state: .loading)
            walletSection = nil
        } else {
            walletSection = .init(selectedUserWalletName: selectedUserWalletName, selectionIsAvailable: targetSelectionIsAvailable)
            connectionTargetSection = nil
        }

        return WalletConnectDAppConnectionRequestViewState(
            dAppDescriptionSection: EntitySummaryView.ViewState.loading,
            connectionRequestSection: ConnectionRequestSection.loading,
            dAppVerificationWarningSection: nil,
            walletSection: walletSection,
            connectionTargetSection: connectionTargetSection,
            networksSection: NetworksSection(state: .loading),
            networksWarningSection: nil,
            connectButton: .connect(isEnabled: true, isLoading: true)
        )
    }

    fileprivate static func content(
        proposal: WalletConnectDAppConnectionProposal,
        connectionRequestSectionIsExpanded: Bool,
        walletSection: WalletSection? = nil,
        connectionTargetSection: ConnectionTargetSection? = nil,
        blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult,
        verifiedDomainAction: @escaping () -> Void
    ) -> WalletConnectDAppConnectionRequestViewState {
        let connectButtonIsEnabled = blockchainsAvailabilityResult.unavailableRequiredBlockchains.isEmpty
            && blockchainsAvailabilityResult.retrieveSelectedBlockchains().isNotEmpty

        let verifcationStatusIconConfig = EntitySummaryView.ViewState.TitleInfoConfig(
            imageType: Assets.Glyphs.verified,
            foregroundColor: Colors.Icon.accent,
            onTap: verifiedDomainAction
        )

        return WalletConnectDAppConnectionRequestViewState(
            dAppDescriptionSection: EntitySummaryView.ViewState.content(
                EntitySummaryView.ViewState.ContentState(
                    imageLocation: .remote(
                        EntitySummaryView.ViewState.ContentState.ImageLocation.RemoteImageConfig(iconURL: proposal.dAppData.icon)
                    ),
                    title: proposal.dAppData.name,
                    subtitle: proposal.dAppData.domain.host ?? "",
                    titleInfoConfig: proposal.verificationStatus.isVerified
                        ? verifcationStatusIconConfig
                        : nil
                )
            ),
            connectionRequestSection: ConnectionRequestSection.content(
                ConnectionRequestSection.ContentState(
                    isExpanded: connectionRequestSectionIsExpanded
                )
            ),
            dAppVerificationWarningSection: WalletConnectWarningNotificationViewModel(proposal.verificationStatus),
            walletSection: walletSection,
            connectionTargetSection: connectionTargetSection,
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
            blockchains: blockchainsAvailabilityResult.retrieveSelectedBlockchains().map(\.blockchain)
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

// MARK: - Auxiliary types

private extension WalletConnectDAppConnectionRequestViewModel {
    struct AccountCacheKey: Hashable {
        let userWalletId: String
        let accountId: String
    }
}
