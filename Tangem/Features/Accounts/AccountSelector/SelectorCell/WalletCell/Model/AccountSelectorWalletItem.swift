//
//  AccountSelectorWalletItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine

struct AccountSelectorWalletItem: Identifiable {
    let id: String
    let domainModel: any UserWalletModel
    let name: String
    let wallet: UserWallet
    let walletImageProvider: WalletImageProviding

    enum UserWallet: Hashable {
        case active(ActiveWallet)
        case locked(LockedWallet)

        struct ActiveWallet {
            let id: String
            let tokensCount: String
            let formattedBalanceTypePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never>
        }

        struct LockedWallet: Hashable {
            let cardsLabel: String
        }
    }
}

extension AccountSelectorWalletItem {
    init(userWallet: any UserWalletModel) {
        id = userWallet.userWalletId.stringValue
        domainModel = userWallet
        name = userWallet.name
        walletImageProvider = userWallet.walletImageProvider
        wallet = .locked(.init(
            cardsLabel: userWallet.cardSetLabel
        ))
    }

    init(userWallet: any UserWalletModel, account: AccountModel) {
        id = userWallet.userWalletId.stringValue
        domainModel = userWallet
        name = userWallet.name
        walletImageProvider = userWallet.walletImageProvider

        let tokensCount: Int
        let formattedBalanceTypePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never>

        switch account {
        case .standard(.single(let cryptoAccount)):
            tokensCount = cryptoAccount.walletModelsManager.walletModels.count
            formattedBalanceTypePublisher = cryptoAccount.formattedBalanceTypePublisher
        case .standard(.multiple):
            preconditionFailure("Multiple crypto accounts are not supported in AccountSelectorWalletItem")
        }

        wallet = .active(.init(
            id: userWallet.userWalletId.stringValue,
            tokensCount: Localization.commonTokensCount(tokensCount),
            formattedBalanceTypePublisher: formattedBalanceTypePublisher
        ))
    }
}

extension AccountSelectorWalletItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(wallet)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.wallet == rhs.wallet
    }
}

extension AccountSelectorWalletItem.UserWallet.ActiveWallet: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(tokensCount)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.tokensCount == rhs.tokensCount
    }
}
