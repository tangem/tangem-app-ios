//
//  AccountSelectorAccountItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct AccountSelectorAccountItem: Identifiable {
    let id: String
    let walletId: String
    let name: String
    let tokensCount: String
    let icon: AccountModel.Icon
    let domainModel: any CryptoAccountModel
}

extension AccountSelectorAccountItem: Equatable {
    static func == (lhs: AccountSelectorAccountItem, rhs: AccountSelectorAccountItem) -> Bool {
        lhs.id == rhs.id
    }
}
