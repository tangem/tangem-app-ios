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

    func makeAction(for tokenItem: TokenItem) throws(Error) -> () -> Void {
        let userTokensManager = try getUserTokensManager(for: tokenItem)

        guard userTokensManager.canRemove(tokenItem) else {
            throw .conditionsNotMet(tokenItem.name)
        }

        return { hideToken(tokenItem, using: userTokensManager) }
    }

    private func getUserTokensManager(for tokenItem: TokenItem) throws(Error) -> UserTokensManager {
        guard FeatureProvider.isAvailable(.accounts) else {
            // accounts_fixes_needed_none
            return userWalletModel.userTokensManager
        }

        guard let cryptoAccountModel = userWalletModel
            .accountModelsManager
            .cryptoAccountModels
            .first(where: { $0.userTokensManager.contains(tokenItem, derivationInsensitive: false) })
        else {
            throw Error.unableToFindCryptoAccount(tokenItem.name)
        }

        return cryptoAccountModel.userTokensManager
    }

    private func hideToken(_ tokenItem: TokenItem, using userTokensManager: UserTokensManager) {
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
        case unableToFindCryptoAccount(String)
    }
}
