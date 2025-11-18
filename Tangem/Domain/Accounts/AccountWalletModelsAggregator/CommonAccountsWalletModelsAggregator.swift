//
//  CommonAccountsWalletModelsAggregator.swift
//  Tangem
//
//  Created on 13.10.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class CommonAccountsWalletModelsAggregator {
    private let accountModelsManager: AccountModelsManager

    init(accountModelsManager: AccountModelsManager) {
        self.accountModelsManager = accountModelsManager
    }
}

// MARK: - AccountsWalletModelsAggregator

extension CommonAccountsWalletModelsAggregator: AccountsWalletModelsAggregating {
    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> {
        accountModelsManager
            .accountModelsPublisher
            .map { accountModels -> [any CryptoAccountModel] in
                accountModels.flatMap { accountModel in
                    switch accountModel {
                    case .standard(.single(let cryptoAccountModel)):
                        return [cryptoAccountModel]
                    case .standard(.multiple(let cryptoAccountModels)):
                        return cryptoAccountModels
                    default:
                        return []
                    }
                }
            }
            .flatMap { cryptoAccounts -> AnyPublisher<[any WalletModel], Never> in
                guard cryptoAccounts.isNotEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                let walletModelsPublishers = cryptoAccounts.map { cryptoAccount in
                    cryptoAccount
                        .walletModelsManager
                        .walletModelsPublisher
                }

                return walletModelsPublishers
                    .combineLatest()
                    .map { walletModelArrays in
                        walletModelArrays.flatMap { $0 }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
