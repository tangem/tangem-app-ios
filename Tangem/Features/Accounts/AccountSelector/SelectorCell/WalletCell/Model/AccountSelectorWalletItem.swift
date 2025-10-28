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
import TangemFoundation

struct AccountSelectorWalletItem: Identifiable {
    let id: String
    let name: String
    let wallet: UserWallet
    let walletImageProvider: WalletImageProviding

    enum UserWallet: Hashable {
        case active(ActiveWallet)
        case locked(LockedWallet)

        struct ActiveWallet {
            let id: String
            let tokensCount: String
            let domainModel: any UserWalletModel
            let mainAccount: any CryptoAccountModel
            let formattedBalanceTypePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never>
        }

        struct LockedWallet {
            let domainModel: any UserWalletModel
            let cardsLabel: String
        }
    }
}

extension AccountSelectorWalletItem {
    /// Init for locked wallet
    init(userWallet: any UserWalletModel) {
        id = userWallet.userWalletId.stringValue
        name = userWallet.name
        walletImageProvider = userWallet.walletImageProvider
        wallet = .locked(.init(
            domainModel: userWallet,
            cardsLabel: userWallet.cardSetLabel
        ))
    }

    /// Init for active wallet
    init(userWallet: any UserWalletModel, cryptoAccountModel: any CryptoAccountModel) {
        id = userWallet.userWalletId.stringValue
        name = userWallet.name
        walletImageProvider = userWallet.walletImageProvider

        wallet = .active(.init(
            id: userWallet.userWalletId.stringValue,
            tokensCount: Localization.commonTokensCount(cryptoAccountModel.walletModelsManager.walletModels.count),
            domainModel: userWallet,
            mainAccount: cryptoAccountModel,
            formattedBalanceTypePublisher: cryptoAccountModel.fiatTotalBalanceProvider.totalFiatBalancePublisher
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

extension AccountSelectorWalletItem.UserWallet.LockedWallet: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(domainModel.userWalletId)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.domainModel.userWalletId == rhs.domainModel.userWalletId &&
            lhs.cardsLabel == rhs.cardsLabel
    }
}
