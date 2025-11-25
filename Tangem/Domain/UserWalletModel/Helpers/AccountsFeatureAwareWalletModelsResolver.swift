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
        if hasAccounts {
            AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
        } else {
            // accounts_fixes_needed_none
            userWalletModel.walletModelsManager.walletModels
        }
    }

    static func walletModels(for userWalletModels: [any UserWalletModel]) -> [any WalletModel] {
        userWalletModels.flatMap(walletModels(for:))
    }

    static func walletModelsPublisher(for userWalletModel: any UserWalletModel) -> AnyPublisher<[any WalletModel], Never> {
        if hasAccounts {
            AccountWalletModelsAggregator.walletModelsPublisher(from: userWalletModel.accountModelsManager)
        } else {
            // accounts_fixes_needed_none
            userWalletModel.walletModelsManager.walletModelsPublisher
        }
    }
}

// MARK: - Private helpers

private extension AccountsFeatureAwareWalletModelsResolver {
    static var hasAccounts: Bool {
        FeatureProvider.isAvailable(.accounts)
    }
}
