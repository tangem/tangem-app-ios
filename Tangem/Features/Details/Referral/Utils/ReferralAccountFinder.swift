//
//  ReferralAccountFinder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum ReferralAccountFinder {
    static func find(forAddress address: String, accounts: [any CryptoAccountModel]) -> (any CryptoAccountModel)? {
        for account in accounts {
            let walletModels = account.walletModelsManager.walletModels

            for walletModel in walletModels {
                if walletModel.addresses.contains(where: { $0.value == address }) {
                    return account
                }
            }
        }

        return nil
    }
}
