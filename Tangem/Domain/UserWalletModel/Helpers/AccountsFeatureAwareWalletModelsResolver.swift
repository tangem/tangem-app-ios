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
        if FeatureProvider.isAvailable(.accounts) {
            AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
        } else {
            // accounts_fixes_needed_none
            userWalletModel.walletModelsManager.walletModels
        }
    }

    static func walletModelsPublisher(for userWalletModel: any UserWalletModel) -> AnyPublisher<[any WalletModel], Never> {
        if FeatureProvider.isAvailable(.accounts) {
            AccountWalletModelsAggregator.walletModelsPublisher(from: userWalletModel.accountModelsManager)
        } else {
            userWalletModel.walletModelsManager.walletModelsPublisher
        }
    }
}
