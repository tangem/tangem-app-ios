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
    enum AccountScope {
        case personal
        case personalAndJoint
    }

    static func walletModels(from accountModelsManager: AccountModelsManager) -> [any WalletModel] {
        return walletModelsManagers(from: accountModelsManager.accountModels).flatMap { $0.walletModels }
    }

    static func walletModels(from userWalletModels: [any UserWalletModel]) -> [any WalletModel] {
        return userWalletModels.flatMap { walletModels(from: $0.accountModelsManager) }
    }

    static func walletModelsPublisher(
        from accountModelsManager: AccountModelsManager,
        accountScope: AccountScope = .personalAndJoint
    ) -> AnyPublisher<[any WalletModel], Never> {
        return accountModelsManager
            .accountModelsPublisher
            .map { walletModelsManagers(from: $0, accountScope: accountScope) }
            // An account adds and drops wallet models over its lifetime, so the answer follows every account of its
            // own rather than the list they arrived in
            .flatMapLatest { walletModelsManagers -> AnyPublisher<[any WalletModel], Never> in
                guard walletModelsManagers.isNotEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                return walletModelsManagers
                    .map { $0.walletModelsPublisher }
                    .combineLatest()
                    .map { $0.flattened() }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private static func walletModelsManagers(
        from accountModels: [AccountModel],
        accountScope: AccountScope = .personalAndJoint
    ) -> [any WalletModelsManager] {
        return accountModels.flatMap { accountModel -> [any WalletModelsManager] in
            switch accountModel {
            case .standard(.single(let cryptoAccountModel)):
                return [cryptoAccountModel.walletModelsManager]
            case .standard(.multiple(let cryptoAccountModels)):
                return cryptoAccountModels.map { $0.walletModelsManager }
            case .joint(let jointAccountModels):
                return accountScope == .personalAndJoint ? jointAccountModels.map { $0.walletModelsManager } : []
            case .tangemPay, .polymarket, .collectibles:
                return []
            }
        }
    }
}
