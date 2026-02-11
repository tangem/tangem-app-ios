//
//  AccountsAwareAddTokenFlowConfiguration.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts
import BlockchainSdk

/// Configuration for the AccountsAwareAddToken flow
struct AccountsAwareAddTokenFlowConfiguration {
    /// Get available TokenItems for an account. If returns single item, network selection is skipped.
    let getAvailableTokenItems: (AccountSelectorCellModel) -> [TokenItem]

    /// Check if token is already added to account (for readonly marking in network list)
    let isTokenAdded: (TokenItem, any CryptoAccountModel) -> Bool

    /// What happens after account is selected
    let accountSelectionBehavior: AccountSelectionBehavior

    /// What happens after token is added
    let postAddBehavior: PostAddBehavior

    /// Filter which accounts to show (based on supported blockchains)
    let accountFilter: ((any CryptoAccountModel, Set<Blockchain>) -> Bool)?

    /// Check if account is available (or already has token on all networks)
    let accountAvailabilityProvider: ((AccountAvailabilityContext) -> AccountAvailability)?

    let analyticsLogger: AddTokenFlowAnalyticsLogger

    init(
        getAvailableTokenItems: @escaping (AccountSelectorCellModel) -> [TokenItem],
        isTokenAdded: @escaping (TokenItem, any CryptoAccountModel) -> Bool,
        accountSelectionBehavior: AccountSelectionBehavior = .executeAccountSelection,
        postAddBehavior: PostAddBehavior,
        accountFilter: ((any CryptoAccountModel, Set<Blockchain>) -> Bool)? = nil,
        accountAvailabilityProvider: ((AccountAvailabilityContext) -> AccountAvailability)? = nil,
        analyticsLogger: AddTokenFlowAnalyticsLogger
    ) {
        self.getAvailableTokenItems = getAvailableTokenItems
        self.isTokenAdded = isTokenAdded
        self.accountSelectionBehavior = accountSelectionBehavior
        self.postAddBehavior = postAddBehavior
        self.accountFilter = accountFilter
        self.accountAvailabilityProvider = accountAvailabilityProvider
        self.analyticsLogger = analyticsLogger
    }
}

// MARK: - PostAddBehavior

extension AccountsAwareAddTokenFlowConfiguration {
    enum AccountSelectionBehavior {
        case executeAccountSelection
        case completeIfTokenIsAdded(executeAction: (TokenItem, AccountSelectorCellModel) -> Void)
    }

    enum PostAddBehavior {
        case showGetToken(GetTokenConfiguration)
        case executeAction((TokenItem, AccountSelectorCellModel) -> Void)
    }
}

// MARK: - AccountAvailabilityContext

extension AccountsAwareAddTokenFlowConfiguration {
    struct AccountAvailabilityContext {
        let account: any CryptoAccountModel
        let supportedBlockchains: Set<Blockchain>
    }
}

// MARK: - GetTokenConfiguration

extension AccountsAwareAddTokenFlowConfiguration {
    struct GetTokenConfiguration {
        let onBuy: (TokenItem, AccountSelectorCellModel) -> Void
        let onExchange: (TokenItem, AccountSelectorCellModel) -> Void
        let onReceive: (TokenItem, AccountSelectorCellModel) -> Void
        let onLater: () -> Void
    }
}
