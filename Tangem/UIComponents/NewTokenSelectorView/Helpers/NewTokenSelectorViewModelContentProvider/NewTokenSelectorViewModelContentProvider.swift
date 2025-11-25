//
//  NewTokenSelectorViewModelContentProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts

protocol NewTokenSelectorViewModelContentProvider {
    var itemsPublisher: AnyPublisher<NewTokenSelectorList, Never> { get }
}

typealias NewTokenSelectorList = [NewTokenSelectorListItem]

struct NewTokenSelectorListItem: Hashable {
    let wallet: NewTokenSelectorItem.Wallet
    let list: [NewTokenSelectorAccountListItem]

    var hasMultipleAccounts: Bool {
        list.count > 1
    }
}

struct NewTokenSelectorAccountListItem: Hashable {
    let account: NewTokenSelectorItem.Account
    let items: [NewTokenSelectorItem]
}

struct NewTokenSelectorItem: Hashable {
    let wallet: Wallet
    let walletModel: any WalletModel

    var cryptoBalanceProvider: TokenBalanceProvider { walletModel.totalTokenBalanceProvider }
    var fiatBalanceProvider: TokenBalanceProvider { walletModel.fiatTotalTokenBalanceProvider }

    func hash(into hasher: inout Hasher) {
        hasher.combine(wallet)
        hasher.combine(walletModel.tokenItem)
    }

    static func == (lhs: NewTokenSelectorItem, rhs: NewTokenSelectorItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension NewTokenSelectorItem {
    struct Wallet: Hashable {
        let name: String
    }

    struct Account: Hashable {
        let icon: AccountIconView.ViewData
        let name: String
    }
}
