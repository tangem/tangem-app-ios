//
//  TokenActionAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import enum BlockchainSdk.Blockchain
import TangemMacro

struct TokenActionAvailabilityProvider {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    private let userWalletInfo: UserWalletInfo
    private let walletModel: any WalletModel
    private let sellCryptoUtility: SellCryptoUtility

    private var userWalletConfig: UserWalletConfig { userWalletInfo.config }
    private var hardwareLimitationsUtil: HardwareLimitationsUtil { HardwareLimitationsUtil(config: userWalletConfig) }

    init(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel
    ) {
        self.userWalletInfo = userWalletInfo
        self.walletModel = walletModel
        sellCryptoUtility = SellCryptoUtility(
            tokenItem: walletModel.tokenItem,
            address: walletModel.defaultAddressString,
            userWalletId: userWalletInfo.id
        )
    }

    /// Check if we have an address to interact with
    private func hasAddressToInteract() -> Bool {
        let addresses = walletModel.addresses
        let hasAtLeastOneAddress = addresses.contains { !$0.value.isEmpty }
        return hasAtLeastOneAddress
    }

    private func isContextMenuAvailable() -> Bool {
        guard let assetRequirementsManager = walletModel.assetRequirementsManager else {
            return true
        }

        switch assetRequirementsManager.requirementsCondition(for: walletModel.tokenItem.amountType) {
        case .paidTransactionWithFee(blockchain: .hedera, _, _):
            return false

        case .requiresTrustline:
            return false

        case .paidTransactionWithFee, .none:
            return true
        }
    }
}

// MARK: - Global action availability

extension TokenActionAvailabilityProvider {
    func isTokenInteractionAvailable() -> Bool {
        return hasAddressToInteract()
    }
}

// MARK: - Buttons and Context Menu Builder

extension TokenActionAvailabilityProvider {
    /// Uses for decide visibility on the hotizontal action buttons list on `TokenDetails/SingleWalletMain`
    func buildAvailableButtonsList() -> [TokenActionType] {
        guard isTokenInteractionAvailable() else {
            return []
        }

        var actions: [TokenActionType] = []

        actions.append(contentsOf: [.receive, .send])

        if userWalletConfig.isFeatureVisible(.swapping) {
            actions.append(.exchange)
        }

        if userWalletConfig.isFeatureVisible(.exchange) {
            actions.append(.buy)
            actions.append(.sell)
        }

        return actions
    }

    /// Uses for decide visibility on the long tap menu action buttons list on the Main token rows (`TokenRow`)
    func buildTokenContextActions() -> [TokenActionType] {
        guard isTokenInteractionAvailable(), isContextMenuAvailable() else {
            return []
        }

        var availableActions: [TokenActionType] = []

        availableActions.append(.copyAddress)

        if isReceiveAvailable {
            availableActions.append(.receive)
        }

        if isSendAvailable {
            availableActions.append(.send)
        }

        if userWalletConfig.isFeatureVisible(.swapping), isSwapAvailable(direction: .build(for: walletModel)) {
            availableActions.append(.exchange)
        }

        if userWalletConfig.isFeatureVisible(.exchange) {
            if isBuyAvailable {
                availableActions.append(.buy)
            }

            if isSellAvailable {
                availableActions.append(.sell)
            }
        }

        if isStakeAvailable {
            availableActions.append(.stake)
        }

        return availableActions
    }

    /// Limited actions for Markets
    func buildMarketsTokenContextActions() -> [TokenActionType] {
        guard isTokenInteractionAvailable(), isContextMenuAvailable() else {
            return []
        }

        var availableActions: [TokenActionType] = []

        if userWalletConfig.isFeatureVisible(.exchange) {
            if isBuyAvailable {
                availableActions.append(.buy)
            }
        }

        if userWalletConfig.isFeatureVisible(.swapping), isSwapAvailable(direction: .build(for: walletModel)) {
            availableActions.append(.exchange)
        }

        if isReceiveAvailable {
            availableActions.append(.receive)
        }

        if isStakeAvailable {
            availableActions.append(.stake)
        }

        if let yieldAPY {
            availableActions.append(.yield(apy: PercentFormatter().format(yieldAPY, option: .interval)))
        }

        return availableActions
    }
}

// MARK: - Swap

extension TokenActionAvailabilityProvider {
    @CaseFlagable
    enum SwapSourceActionAvailabilityStatus {
        case available
        case jointAccountsComingSoon
        case customToken
        case blockchainLoading
        case blockchainUnreachable
        case hasOnlyCachedBalance
        case cantSignLongTransactions
        case expressUnreachable
        case expressLoading
        case missingAssetRequirement
        case yieldModuleApproveNeeded
    }

    @CaseFlagable
    enum SwapReceiveActionAvailabilityStatus {
        case available
        case customToken
        case missingAssetRequirement
        case expressUnreachable
        case expressLoading
    }

    func isSwapAvailable(direction: SwapDirection) -> Bool {
        switch direction {
        case .from: swapSourceAvailability().isAvailable
        case .to: swapReceiveAvailability().isAvailable
        }
    }

    func swapSourceAvailability() -> SwapSourceActionAvailabilityStatus {
        if walletModel.isJointAccountParticipant {
            return .jointAccountsComingSoon
        }

        if walletModel.isCustom {
            return .customToken
        }

        if case .active(let info, _) = walletModel.yieldModuleManager?.state?.state, info.isAllowancePermissionRequired {
            return .yieldModuleApproveNeeded
        }

        if case .assetRequirement = receiveAvailability {
            return .missingAssetRequirement
        }

        switch sendAvailability {
        case .cantSignLongTransactions:
            return .cantSignLongTransactions
        case .blockchainUnreachable:
            return .blockchainUnreachable
        case .blockchainLoading:
            return .blockchainLoading
        case .hasOnlyCachedBalance:
            return .hasOnlyCachedBalance
        case .available,
             .hasPendingTransaction,
             .oldCard,
             .zeroFeeCurrencyBalance,
             .noAccount,
             .zeroWalletBalance,
             .yieldModuleApproveNeeded:
            break
        }

        switch expressSwapState() {
        case .available: return .available
        case .loading: return .expressLoading
        case .unreachable: return .expressUnreachable
        }
    }

    func swapReceiveAvailability() -> SwapReceiveActionAvailabilityStatus {
        if walletModel.isCustom {
            return .customToken
        }

        if case .assetRequirement = receiveAvailability {
            return .missingAssetRequirement
        }

        switch expressSwapState() {
        case .available: return .available
        case .loading: return .expressLoading
        case .unreachable: return .expressUnreachable
        }
    }

    private func expressSwapState() -> ExpressSwapState {
        let assetsState = expressAvailabilityProvider.expressAvailabilityUpdateStateValue
        let tokenState = expressAvailabilityProvider.swapState(for: walletModel.tokenItem)

        switch (tokenState, assetsState) {
        case (.available, _):
            return .available
        case (.unavailable, .updating), (.notLoaded, .updating):
            return .loading
        case (.notLoaded, .updated), (.unavailable, .updated):
            return .available // validation happens on Express screen
        case (.notLoaded, .failed), (.unavailable, .failed):
            return .unreachable
        }
    }

    private enum ExpressSwapState {
        case available
        case loading
        case unreachable
    }
}

// MARK: - Send

extension TokenActionAvailabilityProvider {
    enum SendActionAvailabilityStatus {
        case available
        case zeroWalletBalance
        case cantSignLongTransactions
        case hasPendingTransaction(blockchainDisplayName: String)
        case blockchainUnreachable
        case blockchainLoading
        case oldCard
        case hasOnlyCachedBalance
        case yieldModuleApproveNeeded
        case noAccount
        case zeroFeeCurrencyBalance(configuration: NotEnoughFeeConfiguration)
    }

    var isSendAvailable: Bool {
        switch sendAvailability {
        case .available, .zeroFeeCurrencyBalance:
            return true
        case .zeroWalletBalance,
             .cantSignLongTransactions,
             .hasPendingTransaction,
             .blockchainUnreachable,
             .blockchainLoading,
             .oldCard,
             .hasOnlyCachedBalance,
             .yieldModuleApproveNeeded,
             .noAccount:
            return false
        }
    }

    var sendAvailability: SendActionAvailabilityStatus {
        if case .active(let info, _) = walletModel.yieldModuleManager?.state?.state, info.isAllowancePermissionRequired {
            return .yieldModuleApproveNeeded
        }

        switch hardwareLimitationsUtil.getSendLimitations(walletModel.tokenItem) {
        case .oldCard:
            return .oldCard
        case .longHashes, .oldDevice:
            return .cantSignLongTransactions
        case .none:
            break
        }

        switch walletModel.availableBalanceProvider.balanceType {
        case .loading(.none):
            return .blockchainLoading
        case .empty(.noAccount):
            return .noAccount
        case .empty, .failure(.none):
            return .blockchainUnreachable
        case .loading(.some), .failure(.some):
            return .hasOnlyCachedBalance
        case .loaded(let value) where value == .zero:
            return .zeroWalletBalance
        case .loaded:
            break
        }

        if walletModel.pendingTransactionsProvider.hasAnyBlockingPendingTransactions {
            return .hasPendingTransaction(blockchainDisplayName: walletModel.tokenItem.blockchain.displayName)
        }

        if !walletModel.hasFeeCurrency(), let configuration = makeNotEnoughFeeConfiguration() {
            return .zeroFeeCurrencyBalance(configuration: configuration)
        }

        return .available
    }

    private func makeNotEnoughFeeConfiguration() -> NotEnoughFeeConfiguration? {
        do {
            let feeWalletModelFinderResult = try WalletModelFinder.findWalletModel(tokenItem: walletModel.feeTokenItem)
            let availabilityProvider = TokenActionAvailabilityProvider(
                userWalletInfo: feeWalletModelFinderResult.userWalletModel.userWalletInfo,
                walletModel: feeWalletModelFinderResult.walletModel
            )

            let tokenIconInfo = TokenIconInfoBuilder().build(
                for: walletModel.feeTokenItem.amountType,
                in: walletModel.feeTokenItem.blockchain,
                isCustom: walletModel.isCustom
            )

            return NotEnoughFeeConfiguration(
                amountCurrencySymbol: walletModel.tokenItem.currencySymbol,
                amountCurrencyBlockchainName: walletModel.tokenItem.blockchain.displayName,
                transactionAmountTypeName: walletModel.tokenItem.name,
                feeAmountTypeName: walletModel.feeTokenItem.name,
                feeAmountTypeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
                feeTokenIconInfo: tokenIconInfo,
                networkName: walletModel.tokenItem.networkName,
                currencyButtonTitle: walletModel.tokenItem.blockchain.feeDisplayName,
                isFeeCurrencyPurchaseAllowed: availabilityProvider.isBuyAvailable,
                feeCurrencyBalance: walletModel.getFeeCurrencyBalance()
            )
        } catch {
            AppLogger.error(error: "FeeWalletModel didn't found")
            return nil
        }
    }
}

// MARK: - Sell

extension TokenActionAvailabilityProvider {
    @CaseFlagable
    enum SellActionAvailabilityStatus {
        case available
        case jointAccountsComingSoon
        case unavailable(tokenName: String)
        case zeroWalletBalance
        case cantSignLongTransactions
        case hasPendingTransaction(blockchainDisplayName: String)
        case blockchainUnreachable
        case blockchainLoading
        case oldCard
        case hasOnlyCachedBalance
        case demo(disabledLocalizedReason: String)
        case yieldModuleApproveNeeded
        case noAccount
    }

    var isSellAvailable: Bool {
        if case .available = sellAvailability {
            return true
        }

        return false
    }

    var sellAvailability: SellActionAvailabilityStatus {
        if walletModel.isJointAccountParticipant {
            return .jointAccountsComingSoon
        }

        if let disabledLocalizedReason = userWalletConfig.getDisabledLocalizedReason(for: .exchange) {
            return .demo(disabledLocalizedReason: disabledLocalizedReason)
        }

        if case .active(let info, _) = walletModel.yieldModuleManager?.state?.state, info.isAllowancePermissionRequired {
            return .yieldModuleApproveNeeded
        }

        if !sellCryptoUtility.sellAvailable {
            return .unavailable(tokenName: walletModel.tokenItem.name)
        }

        switch sendAvailability {
        case .oldCard:
            return .oldCard
        case .cantSignLongTransactions:
            return .cantSignLongTransactions
        case .hasPendingTransaction(let blockchainDisplayName):
            return .hasPendingTransaction(blockchainDisplayName: blockchainDisplayName)
        case .blockchainUnreachable:
            return .blockchainUnreachable
        case .blockchainLoading:
            return .blockchainLoading
        case .hasOnlyCachedBalance:
            return .hasOnlyCachedBalance
        case .zeroWalletBalance:
            return .zeroWalletBalance
        case .yieldModuleApproveNeeded:
            return .yieldModuleApproveNeeded
        case .noAccount:
            return .noAccount
        case .available, .zeroFeeCurrencyBalance:
            return .available
        }
    }
}

// MARK: - Buy

extension TokenActionAvailabilityProvider {
    enum BuyActionAvailabilityStatus {
        case available
        case unavailable(tokenName: String)
        case expressUnreachable
        case expressLoading
        case expressNotLoaded
        case demo(disabledLocalizedReason: String)
        case missingAssetRequirement
    }

    var isBuyAvailable: Bool {
        switch buyAvailablity {
        case .available:
            return true
        case .unavailable, .expressUnreachable, .expressLoading, .expressNotLoaded, .demo, .missingAssetRequirement:
            return false
        }
    }

    var buyAvailablity: BuyActionAvailabilityStatus {
        if case .assetRequirement = receiveAvailability {
            return .missingAssetRequirement
        }

        let assetsState = expressAvailabilityProvider.expressAvailabilityUpdateStateValue
        let tokenState = expressAvailabilityProvider.onrampState(for: walletModel.tokenItem)

        switch (tokenState, assetsState) {
        case (.available, _):
            return .available
        case (.unavailable, .updating), (.notLoaded, .updating):
            return .expressLoading
        case (.notLoaded, .updated):
            return .expressNotLoaded
        case (.unavailable, .updated):
            // Onramp doesn't support this token — open Buy anyway; the onramp screen shows the "not supported" notice.
            return .available
        case (.notLoaded, .failed), (.unavailable, .failed):
            return .expressUnreachable
        }
    }
}

// MARK: - Receive

extension TokenActionAvailabilityProvider {
    enum ReceiveActionAvailabilityStatus {
        case available
        case assetRequirement(Blockchain)
    }

    var isReceiveAvailable: Bool {
        switch receiveAvailability {
        case .available:
            return true
        case .assetRequirement:
            return false
        }
    }

    var receiveAvailability: ReceiveActionAvailabilityStatus {
        if let _ = walletModel.assetRequirementsManager?.requirementsCondition(for: walletModel.tokenItem.amountType) {
            return .assetRequirement(walletModel.tokenItem.blockchain)
        }

        return .available
    }
}

// MARK: - Warning

extension TokenActionAvailabilityProvider {
    /// Unlike the availability statuses, a warning doesn't block the action:
    /// the user is alerted and can proceed with the action right from the alert.
    enum TokenActionAvailabilityWarningType {
        case incompleteBackup(UserWalletInfo)
    }

    var availabilityWarningType: TokenActionAvailabilityWarningType? {
        userWalletInfo.backupState.isValid ? nil : .incompleteBackup(userWalletInfo)
    }
}

// MARK: - Dynamic Addresses Management

extension TokenActionAvailabilityProvider {
    enum DynamicAddressesActionAvailabilityStatus {
        case available
        case hasPendingTransaction(blockchainDisplayName: String)
    }

    var dynamicAddressesAvailability: DynamicAddressesActionAvailabilityStatus {
        if walletModel.pendingTransactionsProvider.hasAnyBlockingPendingTransactions {
            return .hasPendingTransaction(blockchainDisplayName: walletModel.tokenItem.blockchain.displayName)
        }

        return .available
    }
}

// MARK: Stake

extension TokenActionAvailabilityProvider {
    var isStakeAvailable: Bool {
        isStakeFeatureAvailable && isSendAvailable && isStakingOfferAvailable
    }

    /// Checks whether staking is available for the token without considering `isSendAvailable`.
    var isStakeFeatureAvailable: Bool {
        let stakingFeatureProvider = StakingFeatureProvider(config: userWalletConfig)
        let canStake = stakingFeatureProvider.isAvailable(for: walletModel.tokenItem)

        return canStake
    }

    private var isStakingOfferAvailable: Bool {
        switch walletModel.stakingManagerState {
        case .staked:
            return true
        case .availableToStake(let yield):
            return yield.isAvailable
        case .loading(let cached), .loadingError(_, let cached):
            return cached != nil
        case .notEnabled, .temporaryUnavailable, .unavailableInRegion:
            return false
        }
    }
}

// MARK: - Yield mode

extension TokenActionAvailabilityProvider {
    enum YieldModuleActionAvailabilityStatus {
        case available
        case jointAccountsComingSoon
    }

    var isYieldModuleAvailable: Bool {
        if case .available = yieldModuleAvailability {
            return true
        }

        return false
    }

    var yieldModuleAvailability: YieldModuleActionAvailabilityStatus {
        walletModel.isJointAccountParticipant ? .jointAccountsComingSoon : .available
    }

    var yieldAPY: Decimal? {
        guard let yieldModuleState = walletModel.yieldModuleManager?.state,
              let apy = yieldModuleState.marketInfo?.effectiveApy else {
            return nil
        }

        let actualState: YieldModuleManagerState = switch yieldModuleState.state {
        case .failedToLoad(_, .some(let cachedState)):
            cachedState
        default:
            yieldModuleState.state
        }

        switch actualState {
        case .loading(.none):
            return nil
        case .loading(.some):
            return apy
        case .failedToLoad:
            return nil
        case .active, .notActive, .disabled, .processing:
            return apy
        }
    }
}
