//
//  AccountsAwareTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts

protocol AccountsAwareTokenSelectorWalletsProvider {
    var wallets: [AccountsAwareTokenSelectorWallet] { get }
}

// MARK: - Implementations

extension AccountsAwareTokenSelectorWalletsProvider where Self == CommonAccountsAwareTokenSelectorWalletsProvider {
    static func common() -> Self { .init() }
}

// MARK: - Wallet

struct AccountsAwareTokenSelectorWallet {
    let wallet: UserWalletInfo
    let accounts: AccountType
    let accountsPublisher: AnyPublisher<AccountType, Never>
}

extension AccountsAwareTokenSelectorWallet {
    enum AccountType {
        case single(AccountsAwareTokenSelectorAccount)
        case multiple([AccountsAwareTokenSelectorAccount])
    }
}

// MARK: - Nested Account

struct AccountsAwareTokenSelectorAccount {
    let cryptoAccount: any CryptoAccountModel
    let itemsProvider: AccountsAwareTokenSelectorCryptoAccountModelItemsProvider
}

// MARK: - Account's items

struct AccountsAwareTokenSelectorItem: Hashable, Identifiable {
    var id: String { walletModel.id.id }

    let userWalletInfo: UserWalletInfo
    let account: any CryptoAccountModel
    let walletModel: any WalletModel

    var cryptoBalanceProvider: TokenBalanceProvider { walletModel.totalTokenBalanceProvider }
    var fiatBalanceProvider: TokenBalanceProvider { walletModel.fiatTotalTokenBalanceProvider }

    func isMatching(searchText: String) -> Bool {
        let matchingName = walletModel.tokenItem.name.lowercased().contains(searchText.lowercased())
        let matchingSymbol = walletModel.tokenItem.currencySymbol.lowercased().contains(searchText.lowercased())

        return matchingName || matchingSymbol
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(userWalletInfo.id)
        hasher.combine(account.id)
        hasher.combine(walletModel.id)
    }

    static func == (lhs: AccountsAwareTokenSelectorItem, rhs: AccountsAwareTokenSelectorItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension AccountsAwareTokenSelectorItem {
    enum AvailabilityType {
        case available
        case unavailable(reason: AccountsAwareTokenSelectorItemViewModel.DisabledReason)
    }
}
