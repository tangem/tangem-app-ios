//
//  ManageTokensAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum ManageTokensAnalyticsLogger {
    static func logAddTokenToNonMainAccountIfNeeded(
        tokenItem: TokenItem,
        destination: TokenAccountDestination
    ) {
        guard
            FeatureProvider.isAvailable(.accounts),
            !destination.isMainAccount
        else {
            return
        }

        var params: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
        ]
        if let derivationPath = tokenItem.blockchainNetwork.derivationPath {
            params[.derivation] = derivationPath.rawPath
        }
        Analytics.log(event: .manageTokensCustomTokenAddedToAnotherAccount, params: params)
    }
}
