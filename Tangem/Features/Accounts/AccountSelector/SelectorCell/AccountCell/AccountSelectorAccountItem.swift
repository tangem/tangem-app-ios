//
//  AccountSelectorAccountItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization

struct AccountSelectorAccountItem: Identifiable {
    let id: AnyHashable
    let name: String
    let tokensCount: String
    let icon: AccountModel.Icon
    let domainModel: any CryptoAccountModel
    let userWalletModel: any UserWalletModel
    let formattedBalanceTypePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never>
    let availability: AccountAvailability
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
    init(account: any CryptoAccountModel, userWalletModel: any UserWalletModel, availability: AccountAvailability) {
        id = account.id
        name = account.name
        self.userWalletModel = userWalletModel
        tokensCount = Localization.commonTokensCount(account.userTokensManager.userTokens.count)
        icon = account.icon
        domainModel = account
        formattedBalanceTypePublisher = account.fiatTotalBalanceProvider.totalFiatBalancePublisher
        self.availability = availability
    }
}
