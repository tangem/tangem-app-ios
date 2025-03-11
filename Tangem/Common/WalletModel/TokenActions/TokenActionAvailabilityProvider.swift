//
//  TokenActionAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import enum BlockchainSdk.Blockchain

struct TokenActionAvailabilityProvider {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    private let userWalletConfig: UserWalletConfig
    private let walletModel: WalletModel
    private let exchangeCryptoUtility: ExchangeCryptoUtility

    init(
        userWalletConfig: UserWalletConfig,
        walletModel: WalletModel
    ) {
        self.userWalletConfig = userWalletConfig
        self.walletModel = walletModel
        exchangeCryptoUtility = ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.defaultAddress,
            amountType: walletModel.amountType
        )
    }

    /// Check if we have an address to interact with
    private func hasAddressToInteract() -> Bool {
        let addresses = walletModel.wallet.addresses
        let hasAtLeastOneAddress = addresses.contains { !$0.value.isEmpty }
        return hasAtLeastOneAddress
    }

    private func isContextMenuAvailable() -> Bool {
        guard let assetRequirementsManager = walletModel.assetRequirementsManager else {
            return true
        }

        switch assetRequirementsManager.requirementsCondition(for: walletModel.amountType) {
        case .paidTransactionWithFee(blockchain: .hedera, _, _):
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
        case unavailable(tokenName: String)
        case customToken
        case blockchainLoading
        case blockchainUnreachable
        case hasOnlyCachedBalance
        case cantSignLongTransactions
        case expressUnreachable
        case expressLoading
        case expressNotLoaded
    }

    var isSwapAvailable: Bool {
        if case .available = swapAvailability {
            return true
        }

        return false
    }

    var swapAvailability: SwapActionAvailabilityStatus {
        if walletModel.isCustom {
            return .customToken
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
        case .zeroWalletBalance,
             .hasPendingTransaction,
             .oldCard,
             .zeroFeeCurrencyBalance,
             .none:
            break
        }

        let state = expressAvailabilityProvider.expressAvailabilityUpdateStateValue

        switch state {
        case .updating:
            return .expressLoading
        case .failed:
            return .expressUnreachable
        case .updated:
            let swapState = expressAvailabilityProvider.swapState(for: walletModel.tokenItem)

            switch swapState {
            case .available:
                return .available
            case .unavailable:
                return .unavailable(tokenName: walletModel.tokenItem.name)
            case .notLoaded:
                return .expressNotLoaded
            }
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
    }

    var isSendAvailable: Bool {
        if case .available = sendAvailability {
            return true
        }

        return false
    }

    var sendAvailability: SendActionAvailabilityStatus {
        switch walletModel.sendingRestrictions {
        case .oldCard:
            return .oldCard
        case .cantSignLongTransactions:
            return .cantSignLongTransactions
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

        if !exchangeCryptoUtility.sellAvailable {
            return .unavailable(tokenName: walletModel.tokenItem.name)
        }

        switch walletModel.sendingRestrictions {
        case .oldCard:
            return .oldCard
        case .cantSignLongTransactions:
            return .cantSignLongTransactions
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
    }

    var isBuyAvailable: Bool {
        if case .available = buyAvailablity {
            return true
        }

        return false
    }

    var buyAvailablity: BuyActionAvailabilityStatus {
        if FeatureProvider.isAvailable(.onramp) {
            let state = expressAvailabilityProvider.expressAvailabilityUpdateStateValue

            switch state {
            case .updating:
                return .expressLoading
            case .failed:
                return .expressUnreachable
            case .updated:
                let onrampState = expressAvailabilityProvider.onrampState(for: walletModel.tokenItem)

                switch onrampState {
                case .available:
                    return .available
                case .unavailable:
                    return .unavailable(tokenName: walletModel.tokenItem.name)
                case .notLoaded:
                    return .expressNotLoaded
                }
            }
        } else {
            if let disabledLocalizedReason = userWalletConfig.getDisabledLocalizedReason(for: .exchange) {
                return .demo(disabledLocalizedReason: disabledLocalizedReason)
            }

            if !exchangeCryptoUtility.buyAvailable {
                return .unavailable(tokenName: walletModel.tokenItem.name)
            }

            return .available
        }
    }
}

// MARK: - Receive

extension TokenActionAvailabilityProvider {
    enum ReceiveActionAvailabilityStatus {
        case available
        case assetRequirement(blockchain: Blockchain)
    }

    var isReceiveAvailable: Bool {
        if case .available = receiveAvailablity {
            return true
        }

        return false
    }

    var receiveAvailablity: ReceiveActionAvailabilityStatus {
        let requirementsCondition = walletModel.assetRequirementsManager?.requirementsCondition(for: walletModel.amountType)

        switch requirementsCondition {
        case .paidTransactionWithFee(let blockchain, _, _):

            switch blockchain {
            case .hedera:
                return .assetRequirement(blockchain: blockchain)
            default:
                break
            }

        case .none:
            break
        }

        return .available
    }
}

// MARK: Stake

extension TokenActionAvailabilityProvider {
    var isStakeAvailable: Bool {
        let stakingFeatureProvider = StakingFeatureProvider(config: userWalletConfig)
        let canStake = stakingFeatureProvider.isAvailable(for: walletModel.tokenItem)

        if canStake, isSendAvailable {
            return true
        }

        return false
    }
}
