//
//  WalletModelFinder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct WalletModelFinder {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    func findWalletModel(userWalletId: UserWalletId, tokenItem: TokenItem) -> Result? {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
            return nil
        }

        let walletModels = if FeatureProvider.isAvailable(.accounts) {
            AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
        } else {
            userWalletModel.walletModelsManager.walletModels
        }

        let walletModel = walletModels.first(where: { $0.tokenItem == tokenItem })

        guard let walletModel else {
            assertionFailure("Network currency WalletModel not found")
            return nil
        }

        return .init(userWalletModel: userWalletModel, walletModel: walletModel)
    }
}

extension WalletModelFinder {
    struct Result {
        let userWalletModel: UserWalletModel
        let walletModel: any WalletModel
    }
}
