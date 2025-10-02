//
//  AccountSelectorWalletItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct AccountSelectorWalletItem: Identifiable {
    let id: String
    let domainModel: any UserWalletModel
    let name: String
    let wallet: Wallet
    let walletImageProvider: WalletImageProviding

    enum Wallet {
        case active(ActiveWallet)
        case locked(LockedWallet)

        struct ActiveWallet {
            let tokensCount: String
            let account: any CryptoAccountModel
        }

        struct LockedWallet {
            let cardsLabel: String
        }
    }
}

extension AccountSelectorWalletItem: Equatable {
    init(userWallet: any UserWalletModel) {
        id = userWallet.userWalletId.stringValue
        domainModel = userWallet
        name = userWallet.name
        walletImageProvider = userWallet.walletImageProvider
        wallet = .locked(.init(
            cardsLabel: userWallet.cardSetLabel
        ))
    }

    init(userWallet: any UserWalletModel, account: any CryptoAccountModel) {
        id = userWallet.userWalletId.stringValue
        domainModel = userWallet
        name = userWallet.name
        walletImageProvider = userWallet.walletImageProvider
        wallet = .active(.init(
            tokensCount: Localization.commonTokensCount(account.walletModelsManager.walletModels.count),
            account: account
        ))
    }

    static func == (lhs: AccountSelectorWalletItem, rhs: AccountSelectorWalletItem) -> Bool {
        lhs.id == rhs.id
    }
}
