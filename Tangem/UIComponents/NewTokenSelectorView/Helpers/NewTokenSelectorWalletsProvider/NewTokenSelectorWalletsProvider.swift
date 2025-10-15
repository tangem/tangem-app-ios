//
//  NewTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts

protocol NewTokenSelectorWalletsProvider {
    var walletsPublisher: AnyPublisher<[NewTokenSelectorWallet], Never> { get }
}

// MARK: - Wallet

struct NewTokenSelectorWallet {
    let wallet: UserWalletInfo
    let accountsPublisher: AnyPublisher<AccountType, Never>
}

extension NewTokenSelectorWallet {
    enum AccountType {
        case single(NewTokenSelectorAccount)
        case multiple([NewTokenSelectorAccount])
    }
}

// MARK: - Nested Account

struct NewTokenSelectorAccount {
    let account: NewTokenSelectorItem.Account
    let itemsPublisher: AnyPublisher<[NewTokenSelectorItem], Never>
}

// MARK: - Account's items

struct NewTokenSelectorItem: Hashable {
    let wallet: Wallet
    let account: Account
    let walletModel: any WalletModel

    var cryptoBalanceProvider: TokenBalanceProvider { walletModel.totalTokenBalanceProvider }
    var fiatBalanceProvider: TokenBalanceProvider { walletModel.fiatTotalTokenBalanceProvider }

    func isMatching(searchText: String) -> Bool {
        let matchingName = walletModel.tokenItem.name.lowercased().contains(searchText.lowercased())
        let matchingSymbol = walletModel.tokenItem.currencySymbol.lowercased().contains(searchText.lowercased())

        return matchingName || matchingSymbol
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(wallet)
        hasher.combine(account)
        hasher.combine(walletModel.id)
    }

    static func == (lhs: NewTokenSelectorItem, rhs: NewTokenSelectorItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension NewTokenSelectorItem {
    struct Wallet: Hashable {
        let userWalletInfo: UserWalletInfo
    }

    struct Account: Hashable {
        let name: String
        let icon: AccountIconView.ViewData

        let walletModelsManager: any WalletModelsManager

        static func == (lhs: NewTokenSelectorItem.Account, rhs: NewTokenSelectorItem.Account) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(icon)
        }
    }
}
