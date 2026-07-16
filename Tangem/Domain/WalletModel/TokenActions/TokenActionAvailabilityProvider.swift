//
//  TokenActionAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import enum BlockchainSdk.Blockchain

struct TokenActionAvailabilityProvider {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    private let userWalletInfo: UserWalletInfo
    private let walletModel: any WalletModel
    private let sellCryptoUtility: SellCryptoUtility

    private var userWalletConfig: UserWalletConfig { userWalletInfo.config }

    init(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel
    ) {
        self.userWalletInfo = userWalletInfo
        self.walletModel = walletModel
        sellCryptoUtility = SellCryptoUtility(
            tokenItem: walletModel.tokenItem,
            address: walletModel.defaultAddressString
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

    /// Top-up operations (receive / onramp / swap-in) must be blocked on a card-linked wallet:
    /// such a wallet must not receive new funds, while withdrawing from it stays allowed.
    var isTopUpAvailable: Bool {
        userWalletInfo.backupState.isValid
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

        if userWalletConfig.isFeatureVisible(.swapping), !isSwapHidden {
            actions.append(.exchange)
        }

        if userWalletConfig.isFeatureVisible(.exchange) {
            actions.append(.buy)
            actions.append(.sell)
        }

        return actions
    }

    /// Uses for decide visibility on the long tap menu action buttons list on `TokenItemView`
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

        if userWalletConfig.isFeatureVisible(.swapping), isSwapAvailable {
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

        if userWalletConfig.isFeatureVisible(.swapping), isSwapAvailable {
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

    static func buildActionsForLockedSingleWallet() -> [TokenActionType] {
        [
            .receive,
            .send,
            .buy,
            .sell,
        ]
    }
}

// MARK: - Swap

extension TokenActionAvailabilityProvider {
    enum SwapActionAvailabilityStatus {
        case available
        case hidden
        case unavailable(tokenName: String)
        case customToken
        case blockchainLoading
        case blockchainUnreachable
        case hasOnlyCachedBalance
        case cantSignLongTransactions
        case expressUnreachable
        case expressLoading
        case expressNotLoaded
        case missingAssetRequirement
        case yieldModuleApproveNeeded
    }

    var isSwapAvailable: Bool {
        if case .available = swapAvailability {
            return true
        }

        return false
    }

    var isSwapHidden: Bool {
        if case .hidden = swapAvailability {
            return true
        }

        return false
    }

    var swapAvailability: SwapActionAvailabilityStatus {
        if walletModel.isCustom {
            return .customToken
        }

        if case .active(let info, _) = walletModel.yieldModuleManager?.state?.state, info.isAllowancePermissionRequired {
            return .yieldModuleApproveNeeded
        }

        if case .assetRequirement = receiveAvailability {
            return .missingAssetRequirement
        }

        switch walletModel.sendingRestrictions {
        case .cantSignLongTransactions:
            return .cantSignLongTransactions
        case .blockchainUnreachable:
            return .blockchainUnreachable
        case .blockchainLoading:
            return .blockchainLoading
        case .hasOnlyCachedBalance:
            return .hasOnlyCachedBalance
        case .hasPendingTransaction,
             .hasPendingWithdrawOrder,
             .oldCard,
             .zeroFeeCurrencyBalance,
             .noAccount,
             .zeroWalletBalance,
             .none:
            break
        }

        let assetsState = expressAvailabilityProvider.expressAvailabilityUpdateStateValue
        let tokenState = expressAvailabilityProvider.swapState(for: walletModel.tokenItem)

        switch (tokenState, assetsState) {
        case (.available, _):
            return .available
        case (.unavailable, .updating), (.notLoaded, .updating):
            return .expressLoading
        case (.notLoaded, .updated), (.unavailable, .updated):
            return .available // validation happens on Express screen
        case (.notLoaded, .failed), (.unavailable, .failed):
            return .expressUnreachable
        }
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
    }

    var isSendAvailable: Bool {
        if case .available = sendAvailability {
            return true
        }

        return false
    }

    var sendAvailability: SendActionAvailabilityStatus {
        if case .active(let info, _) = walletModel.yieldModuleManager?.state?.state, info.isAllowancePermissionRequired {
            return .yieldModuleApproveNeeded
        }

        switch walletModel.sendingRestrictions {
        case .oldCard:
            return .oldCard
        case .cantSignLongTransactions:
            return .cantSignLongTransactions
        case .hasPendingWithdrawOrder:
            return .hasPendingTransaction(blockchainDisplayName: Localization.tangempayTitle)
        case .hasPendingTransaction(let blockchain):
            return .hasPendingTransaction(blockchainDisplayName: blockchain.displayName)
        case .blockchainUnreachable:
            return .blockchainUnreachable
        case .blockchainLoading:
            return .blockchainLoading
        case .hasOnlyCachedBalance:
            return .hasOnlyCachedBalance
        case .zeroWalletBalance:
            return .zeroWalletBalance
        case .none, .zeroFeeCurrencyBalance:
            return .available
        case .noAccount:
            return .noAccount
        }
    }
}

// MARK: - Sell

extension TokenActionAvailabilityProvider {
    enum SellActionAvailabilityStatus {
        case available
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
        if let disabledLocalizedReason = userWalletConfig.getDisabledLocalizedReason(for: .exchange) {
            return .demo(disabledLocalizedReason: disabledLocalizedReason)
        }

        if case .active(let info, _) = walletModel.yieldModuleManager?.state?.state, info.isAllowancePermissionRequired {
            return .yieldModuleApproveNeeded
        }

        if !sellCryptoUtility.sellAvailable {
            return .unavailable(tokenName: walletModel.tokenItem.name)
        }

        switch walletModel.sendingRestrictions {
        case .oldCard:
            return .oldCard
        case .cantSignLongTransactions:
            return .cantSignLongTransactions
        case .hasPendingWithdrawOrder:
            return .hasPendingTransaction(blockchainDisplayName: Localization.tangempayTitle)
        case .hasPendingTransaction(let blockchain):
            return .hasPendingTransaction(blockchainDisplayName: blockchain.displayName)
        case .blockchainUnreachable:
            return .blockchainUnreachable
        case .blockchainLoading:
            return .blockchainLoading
        case .hasOnlyCachedBalance:
            return .hasOnlyCachedBalance
        case .zeroWalletBalance:
            return .zeroWalletBalance
        case .none, .zeroFeeCurrencyBalance:
            break
        case .noAccount:
            return .noAccount
        }

        return .available
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
        case incompleteBackup(UserWalletInfo)
    }

    /// `.incompleteBackup` keeps the buy entry interactive (shown/enabled) so the tap shows the support alert;
    /// only a genuine onramp/asset reason hides or disables it. Mirrors `isReceiveAvailable`.
    var isBuyAvailable: Bool {
        switch buyAvailablity {
        case .available, .incompleteBackup:
            return true
        case .unavailable, .expressUnreachable, .expressLoading, .expressNotLoaded, .demo, .missingAssetRequirement:
            return false
        }
    }

    var buyAvailablity: BuyActionAvailabilityStatus {
        if !isTopUpAvailable {
            return .incompleteBackup(userWalletInfo)
        }

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
        case assetRequirement
        case incompleteBackup(UserWalletInfo)
    }

    /// `.incompleteBackup` keeps the receive entry interactive (so the tap shows the support alert);
    /// only a real token-level requirement (`.assetRequirement`) hides/disables it.
    var isReceiveAvailable: Bool {
        switch receiveAvailability {
        case .available, .incompleteBackup:
            return true
        case .assetRequirement:
            return false
        }
    }

    var receiveAvailability: ReceiveActionAvailabilityStatus {
        // Card-linked blocks any top-up and must dominate: an asset requirement on a blockchain the
        // alert builder doesn't message (non xrp/stellar/hedera) would otherwise yield a nil alert and
        // silently let a card-linked wallet receive. Mirrors the incompleteBackup-first order in buyAvailablity.
        if !isTopUpAvailable {
            return .incompleteBackup(userWalletInfo)
        }

        if let _ = walletModel.assetRequirementsManager?.requirementsCondition(for: walletModel.tokenItem.amountType) {
            return .assetRequirement
        }

        return .available
    }
}

// MARK: - Dynamic Addresses Management

extension TokenActionAvailabilityProvider {
    enum DynamicAddressesActionAvailabilityStatus {
        case available
        case hasPendingTransaction(blockchainDisplayName: String)
    }

    var isDynamicAddressesActionAvailable: Bool {
        if case .available = dynamicAddressesAvailability {
            return true
        }

        return false
    }

    var dynamicAddressesAvailability: DynamicAddressesActionAvailabilityStatus {
        if case .hasPendingTransaction(let blockchain) = walletModel.sendingRestrictions {
            return .hasPendingTransaction(blockchainDisplayName: blockchain.displayName)
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
        case .notEnabled, .temporaryUnavailable:
            return false
        }
    }
}

// MARK: - Yield mode

extension TokenActionAvailabilityProvider {
    var yieldAPY: Decimal? {
        guard let yieldModuleState = walletModel.yieldModuleManager?.state,
              let apy = yieldModuleState.marketInfo?.apy else {
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
