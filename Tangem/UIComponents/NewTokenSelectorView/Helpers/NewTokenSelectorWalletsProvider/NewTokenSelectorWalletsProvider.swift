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
    var wallets: [NewTokenSelectorWallet] { get }
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
    let cryptoAccount: any CryptoAccountModel
    let itemsPublisher: AnyPublisher<[NewTokenSelectorItem], Never>
}

// MARK: - Account's items

struct NewTokenSelectorItem: Hashable, Identifiable {
    var id: String { walletModel.id.id }

    let userWalletInfo: UserWalletInfo
    let account: any CryptoAccountModel
    let walletModel: any WalletModel
    let availabilityProvider: NewTokenSelectorItemAvailabilityProvider

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

    static func == (lhs: NewTokenSelectorItem, rhs: NewTokenSelectorItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension NewTokenSelectorItem {
    enum AvailabilityType {
        case available
        case unavailable(reason: NewTokenSelectorItemViewModel.DisabledReason)
    }
}
