//
//  AccountWalletModelsAggregator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

enum AccountWalletModelsAggregator {
    static func walletModels(from accountModelsManager: AccountModelsManager) -> [any WalletModel] {
        return accountModelsManager
            .cryptoAccountModels
            .flatMap(\.walletModelsManager.walletModels)
    }

    static func walletModels(from userWalletModels: [any UserWalletModel]) -> [any WalletModel] {
        return userWalletModels.flatMap { walletModels(from: $0.accountModelsManager) }
    }

    static func walletModelsPublisher(from accountModelsManager: AccountModelsManager) -> AnyPublisher<[any WalletModel], Never> {
        return accountModelsManager
            .cryptoAccountModelsPublisher
            .flatMapLatest { cryptoAccounts -> AnyPublisher<[any WalletModel], Never> in
                guard cryptoAccounts.isNotEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                return cryptoAccounts
                    .map { cryptoAccount in
                        cryptoAccount
                            .walletModelsManager
                            .walletModelsPublisher
                    }
                    .combineLatest()
                    .map { $0.flattened() }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
