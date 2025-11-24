//
//  AccountSelectorCellModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum AccountSelectorCellModel: Equatable {
    case wallet(AccountSelectorWalletItem)
    case account(AccountSelectorAccountItem)
}

extension AccountSelectorCellModel {
    var cryptoAccountModel: any CryptoAccountModel {
        switch self {
        case .wallet(let walletModel):
            return walletModel.mainAccount

        case .account(let accountModel):
            return accountModel.domainModel
        }
    }

    var userWalletModel: any UserWalletModel {
        switch self {
        case .wallet(let walletModel):
            return walletModel.domainModel

        case .account(let accountModel):
            return accountModel.userWalletModel
        }
    }
}
