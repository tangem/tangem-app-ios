//
//  AccountsAwareMultiWalletMainContentViewSectionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class AccountsAwareMultiWalletMainContentViewSectionsProvider: MultiWalletMainContentViewSectionsProvider {
    private let userWalletModel: UserWalletModel

    private weak var itemViewModelFactory: MultiWalletMainContentItemViewModelFactory?

    init(
        userWalletModel: UserWalletModel
    ) {
        self.userWalletModel = userWalletModel
    }

    func makePlainSectionsPublisher() -> some Publisher<[MultiWalletMainContentPlainSection], Never> {
        // [REDACTED_TODO_COMMENT]
        return AnyPublisher.empty
    }

    func makeAccountSectionsPublisher() -> some Publisher<[MultiWalletMainContentAccountSection], Never> {
        let cryptoAccountModelsPublisher = makeCryptoAccountsPublisher()
            .map { cryptoAccounts -> [any CryptoAccountModel] in
                // When there is no multiple accounts, we don't need to show sections with accounts
                // Instead, plain sections will be used to show tokens of the single account
                guard cryptoAccounts.hasMultipleAccounts else {
                    return []
                }

                return Self.extractCryptoAccountModels(from: cryptoAccounts)
            }
            .share(replay: 1)

        let cryptoAccountModelsChangesPublisher = makeCryptoAccountsPublisher()
            .map { cryptoAccounts in
                return Self.extractCryptoAccountModels(from: cryptoAccounts)
            }
            .flatMap { cryptoAccountModels in
                return cryptoAccountModels
                    .map(\.didChangePublisher)
                    .combineLatest()
            }
            .withLatestFrom(cryptoAccountModelsPublisher)

        return cryptoAccountModelsPublisher
            .merge(with: cryptoAccountModelsChangesPublisher)
            .map { cryptoAccountModels in
                return cryptoAccountModels
                    .map { cryptoAccountModel in
                        // [REDACTED_TODO_COMMENT]
                        // [REDACTED_TODO_COMMENT]
                        let sectionModel = AccountItemViewModel(accountModel: cryptoAccountModel)

                        return MultiWalletMainContentAccountSection(
                            model: sectionModel,
                            items: [
                                // [REDACTED_TODO_COMMENT]
                            ]
                        )
                    }
            }
    }

    private func makeCryptoAccountsPublisher() -> some Publisher<[CryptoAccounts], Never> {
        return userWalletModel
            .accountModelsManager
            .accountModelsPublisher
            .map { $0.cryptoAccounts() }
    }

    private static func extractCryptoAccountModels(from cryptoAccounts: [CryptoAccounts]) -> [any CryptoAccountModel] {
        return cryptoAccounts
            .reduce(into: []) { result, cryptoAccount in
                switch cryptoAccount {
                case .single(let cryptoAccountModel):
                    result.append(cryptoAccountModel)
                case .multiple(let cryptoAccountModels):
                    result.append(contentsOf: cryptoAccountModels)
                }
            }
    }

    func setup(with itemViewModelFactory: any MultiWalletMainContentItemViewModelFactory) {
        self.itemViewModelFactory = itemViewModelFactory
    }
}
