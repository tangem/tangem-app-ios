//
//  FeeCurrencyFinder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct FeeCurrencyFinder {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    func findFeeWalletModel(for walletModel: any WalletModel) -> Result? {
        findFeeWalletModel(userWalletId: walletModel.userWalletId, feeTokenItem: walletModel.feeTokenItem)
    }

    func findFeeWalletModel(userWalletId: UserWalletId, feeTokenItem: TokenItem) -> Result? {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
            return nil
        }

        // accounts_fixes_needed_send
        // also,
        // accounts_fixes_needed_express
        let walletModels = userWalletModel.walletModelsManager.walletModels

        guard let feeWalletModel = walletModels.first(where: { $0.tokenItem == feeTokenItem }) else {
            assertionFailure("Network currency WalletModel not found")
            return nil
        }

        return .init(userWalletModel: userWalletModel, feeWalletModel: feeWalletModel)
    }
}

extension FeeCurrencyFinder {
    struct Result {
        let userWalletModel: UserWalletModel
        let feeWalletModel: any WalletModel
    }
}
