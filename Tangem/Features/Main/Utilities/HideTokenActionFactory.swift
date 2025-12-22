//
//  HideTokenActionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HideTokenActionFactory {
    let userWalletModel: UserWalletModel

    func makeAction(tokenItem: TokenItem, walletModel: (any WalletModel)?) throws(Error) -> () -> Void {
        let userTokensManager = try getUserTokensManager(walletModel: walletModel, tokenName: tokenItem.name)

        guard userTokensManager.canRemove(tokenItem) else {
            throw .conditionsNotMet(tokenItem.name)
        }

        return { hideToken(tokenItem: tokenItem, using: userTokensManager) }
    }

    private func getUserTokensManager(walletModel: (any WalletModel)?, tokenName: String) throws(Error) -> UserTokensManager {
        guard FeatureProvider.isAvailable(.accounts) else {
            // accounts_fixes_needed_none
            return userWalletModel.userTokensManager
        }

        guard let walletModel else {
            throw .missingWalletModel(tokenName)
        }

        guard let cryptoAccountModel = walletModel.account else {
            throw .missingCryptoAccount(tokenName)
        }

        return cryptoAccountModel.userTokensManager
    }

    private func hideToken(tokenItem: TokenItem, using userTokensManager: UserTokensManager) {
        userTokensManager.remove(tokenItem)

        Analytics.log(
            event: .buttonRemoveToken,
            params: [
                Analytics.ParameterKey.token: tokenItem.currencySymbol,
                Analytics.ParameterKey.source: Analytics.ParameterValue.main.rawValue,
            ]
        )
    }
}

// MARK: - Auxiliary types

extension HideTokenActionFactory {
    enum Error: Swift.Error {
        case conditionsNotMet(String)
        case missingWalletModel(String)
        case missingCryptoAccount(String)
    }
}
