//
//  AccountCryptoModelsAggregator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Picks out of the account list the accounts that keep crypto tokens: the wallet's own ones and the joint ones it
/// takes part in, which are built on accounts of its own and answer to the same protocol. Nothing else is left out by
/// choice — a TangemPay or a Polymarket account is an account of an altogether different kind.
/// - Warning: A joint account is operated by its members together, so anything that goes on to sign for what it finds
/// here has to tell the two kinds apart itself.
enum AccountCryptoModelsAggregator {
    static func cryptoAccountModels(from accountModelsManager: AccountModelsManager) -> [any CryptoAccountModel] {
        cryptoAccountModels(from: accountModelsManager.accountModels)
    }

    static func cryptoAccountModels(from userWalletModels: [any UserWalletModel]) -> [any CryptoAccountModel] {
        userWalletModels.flatMap { cryptoAccountModels(from: $0.accountModelsManager) }
    }

    static func cryptoAccountModels(from accountModels: [AccountModel]) -> [any CryptoAccountModel] {
        accountModels.flatMap { accountModel -> [any CryptoAccountModel] in
            switch accountModel {
            case .standard(.single(let cryptoAccountModel)): [cryptoAccountModel]
            case .standard(.multiple(let cryptoAccountModels)): cryptoAccountModels
            case .joint(let jointAccountModels): jointAccountModels
            case .tangemPay, .polymarket, .collectibles: []
            }
        }
    }

    static func cryptoAccountModelsPublisher(from accountModelsManager: AccountModelsManager) -> AnyPublisher<[any CryptoAccountModel], Never> {
        accountModelsManager
            .accountModelsPublisher
            .map(cryptoAccountModels(from:))
            .eraseToAnyPublisher()
    }
}
