//
//  AccountPickerUserWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt

protocol AccountPickerUserWalletsProvider {
    var userWalletsPublisher: AnyPublisher<[AccountPickerUserWallet], Never> { get }
}

struct AccountPickerUserWallet {
    let userWalletModel: any UserWalletModel
    let accounts: [any BaseAccountModel]
}

// MARK: - Factories

extension AccountPickerUserWalletsProvider where Self == CommonAccountPickerUserWalletsProvider {
    static func cryptoAccounts(in userWalletsProvider: any UserWalletSelectorUserWalletsProvider = .allUserWallets()) -> Self {
        CommonAccountPickerUserWalletsProvider(userWalletsProvider: userWalletsProvider, aggregator: BaseAccountModelsAggregator(.crypto))
    }

    static func cryptoJointAccounts(in userWalletsProvider: any UserWalletSelectorUserWalletsProvider = .allUserWallets()) -> Self {
        CommonAccountPickerUserWalletsProvider(
            userWalletsProvider: userWalletsProvider,
            aggregator: BaseAccountModelsAggregator(.crypto, .joint(.active))
        )
    }
}

// MARK: - Implementations

struct CommonAccountPickerUserWalletsProvider: AccountPickerUserWalletsProvider {
    private let userWalletModels: [any UserWalletModel]
    private let aggregator: BaseAccountModelsAggregator

    init(userWalletsProvider: any UserWalletSelectorUserWalletsProvider, aggregator: BaseAccountModelsAggregator) {
        userWalletModels = userWalletsProvider.userWalletModels
        self.aggregator = aggregator
    }

    var userWalletsPublisher: AnyPublisher<[AccountPickerUserWallet], Never> {
        guard userWalletModels.isNotEmpty else {
            return .just(output: [])
        }

        let aggregator = aggregator

        return userWalletModels
            .map { userWalletModel in
                aggregator
                    .modelsPublisher(from: userWalletModel.accountModelsManager)
                    .map { Optional(AccountPickerUserWallet(userWalletModel: userWalletModel, accounts: $0)) }
                    .prepend(nil)
            }
            .combineLatest()
            .map { $0.compactMap { $0 } }
            .eraseToAnyPublisher()
    }
}
