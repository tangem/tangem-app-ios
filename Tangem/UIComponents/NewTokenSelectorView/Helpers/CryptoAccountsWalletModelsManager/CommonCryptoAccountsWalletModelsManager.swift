//
//  CommonCryptoAccountsWalletModelsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts

final class CommonCryptoAccountsWalletModelsManager {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private func map(userWalletModel: UserWalletModel) -> AnyPublisher<CryptoAccountsWallet, Never> {
        userWalletModel
            .accountModelsManager
            .accountModelsPublisher
            .map { $0.cryptoAccountModels }
            .flatMap { cryptoAccounts in
                let cryptoAccountModelPublishers = cryptoAccounts.map { cryptoAccountModel in
                    cryptoAccountModel
                        .walletModelsManager
                        .walletModelsPublisher
                        .map { walletModels in
                            CryptoAccountsWalletAccount(account: cryptoAccountModel, walletModels: walletModels)
                        }
                        .eraseToAnyPublisher()
                }

                return cryptoAccountModelPublishers
                    .combineLatest()
                    .map { cryptoAccountModels in
                        CryptoAccountsWallet(wallet: userWalletModel.name, accounts: cryptoAccountModels)
                    }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - CryptoAccountsWalletModelsManager

extension CommonCryptoAccountsWalletModelsManager: CryptoAccountsWalletModelsManager {
    var cryptoAccountModelWithWalletPublisher: AnyPublisher<[CryptoAccountsWallet], Never> {
        userWalletRepository.models
            .map { map(userWalletModel: $0) }
            .combineLatest()
    }
}
