//
//  AccountsFeatureAwareWalletModelsResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

enum AccountsFeatureAwareWalletModelsResolver {
    static func walletModels(for userWalletModel: any UserWalletModel) -> [any WalletModel] {
        AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
    }

    static func walletModels(for userWalletModels: [any UserWalletModel]) -> [any WalletModel] {
        userWalletModels.flatMap(walletModels(for:))
    }

    static func walletModelsPublisher(for userWalletModel: any UserWalletModel) -> AnyPublisher<[any WalletModel], Never> {
        AccountWalletModelsAggregator.walletModelsPublisher(from: userWalletModel.accountModelsManager)
    }
}
