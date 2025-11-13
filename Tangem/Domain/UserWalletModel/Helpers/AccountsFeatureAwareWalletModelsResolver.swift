//
//  AccountsFeatureAwareWalletModelsResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum AccountsFeatureAwareWalletModelsResolver {
    static func walletModels(for userWalletModel: any UserWalletModel) -> [any WalletModel] {
        if FeatureProvider.isAvailable(.accounts) {
            AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
        } else {
            userWalletModel.walletModelsManager.walletModels
        }
    }
}
