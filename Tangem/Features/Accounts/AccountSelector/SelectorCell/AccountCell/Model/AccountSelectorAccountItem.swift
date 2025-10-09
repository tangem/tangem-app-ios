//
//  AccountSelectorAccountItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization
import Combine

struct AccountSelectorAccountItem: Identifiable {
    let id: String
    let name: String
    let tokensCount: String
    let icon: AccountModel.Icon
    let formattedBalanceTypePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never>
}

extension AccountSelectorAccountItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }

    static func == (lhs: AccountSelectorAccountItem, rhs: AccountSelectorAccountItem) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

extension AccountSelectorAccountItem {
    init(userWallet: any UserWalletModel, account: any CryptoAccountModel) {
        id = "\(account.id)"
        name = account.name
        tokensCount = Localization.commonTokensCount(account.walletModelsManager.walletModels.count)
        icon = account.icon
        formattedBalanceTypePublisher = account.formattedBalanceTypePublisher
    }
}
