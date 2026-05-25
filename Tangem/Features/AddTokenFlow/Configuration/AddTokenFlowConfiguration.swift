//
//  AddTokenFlowConfiguration.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts
import BlockchainSdk

/// Configuration for the AddToken flow
struct AddTokenFlowConfiguration {
    /// Get available TokenItems for an account. If returns single item, network selection is skipped.
    let getAvailableTokenItems: (AccountSelectorCellModel) -> [TokenItem]

    /// Check if token is already added to account (for readonly marking in network list)
    let isTokenAdded: (TokenItem, any CryptoAccountModel) -> Bool

    /// What happens after account is selected
    let accountSelectionBehavior: AccountSelectionBehavior

    /// What happens after token is added
    let postAddBehavior: PostAddBehavior

    /// Filter which accounts to show (based on supported blockchains)
    let accountFilter: ((AccountContext) -> Bool)?

    /// Check if account is available (or already has token on all networks)
    let accountAvailabilityProvider: ((AccountContext) -> AccountAvailability)?

    let analyticsLogger: AddTokenFlowAnalyticsLogger

    init(
        getAvailableTokenItems: @escaping (AccountSelectorCellModel) -> [TokenItem],
        isTokenAdded: ((TokenItem, any CryptoAccountModel) -> Bool)? = nil,
        accountSelectionBehavior: AccountSelectionBehavior = .executeAccountSelection,
        postAddBehavior: PostAddBehavior,
        accountFilter: ((AccountContext) -> Bool)? = nil,
        accountAvailabilityProvider: ((AccountContext) -> AccountAvailability)? = nil,
        analyticsLogger: AddTokenFlowAnalyticsLogger = NoOpAddTokenFlowAnalyticsLogger()
    ) {
        self.getAvailableTokenItems = getAvailableTokenItems
        self.isTokenAdded = isTokenAdded ?? Self.defaultIsTokenAdded
        self.accountSelectionBehavior = accountSelectionBehavior
        self.postAddBehavior = postAddBehavior
        self.accountFilter = accountFilter
        self.accountAvailabilityProvider = accountAvailabilityProvider
        self.analyticsLogger = analyticsLogger
    }

    private static func defaultIsTokenAdded(_ tokenItem: TokenItem, _ account: any CryptoAccountModel) -> Bool {
        account.userTokensManager.contains(tokenItem, derivationInsensitive: true)
    }
}

// MARK: - Behaviors

extension AddTokenFlowConfiguration {
    typealias AccountSelectionActionWithContinuation = (TokenItem, AccountSelectorCellModel, @escaping () -> Void) -> Void

    enum AccountSelectionBehavior {
        case executeAccountSelection
        /// Custom action when account is selected. Call the continuation to proceed to network selection.
        case customExecuteAction(AccountSelectionActionWithContinuation)
    }

    enum PostAddBehavior {
        case showGetToken(GetTokenConfiguration)
        case executeAction((TokenItem, AccountSelectorCellModel) -> Void)
    }
}

// MARK: - AccountContext

extension AddTokenFlowConfiguration {
    struct AccountContext {
        let account: any CryptoAccountModel
        let supportedBlockchains: Set<Blockchain>
    }
}

// MARK: - GetTokenConfiguration

extension AddTokenFlowConfiguration {
    struct GetTokenConfiguration {
        let isBuyAvailable: (TokenItem, AccountSelectorCellModel) -> Bool
        let isExchangeAvailable: (TokenItem, AccountSelectorCellModel) -> Bool
        let onBuy: (TokenItem, AccountSelectorCellModel) -> Void
        let onExchange: (TokenItem, AccountSelectorCellModel) -> Void
        let onReceive: (TokenItem, AccountSelectorCellModel) -> Void
        let onLater: () -> Void
    }
}
