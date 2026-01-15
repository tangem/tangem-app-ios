//
//  TangemPayExpressTokenFeeManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct TangemPayExpressTokenFeeManager: ExpressTokenFeeManager {
    let tokenItem: TokenItem

    func tokenFeeManager(providerId: ExpressProvider.Id) -> TokenFeeManager {
        TokenFeeManager(
            feeProviders: [.empty(feeTokenItem: tokenItem)],
            initialSelectedProvider: .empty(feeTokenItem: tokenItem),
            selectedFeeOption: .market
        )
    }

    func selectedFeeProvider(providerId: ExpressProvider.Id) -> (any TokenFeeProvider)? { nil }

    func fees(providerId: ExpressProvider.Id) -> TokenFeesList { [] }

    func supportedFeeTokenProviders(providerId: ExpressProvider.Id) -> [any TokenFeeProvider] { [] }

    func updateSelectedFeeTokenProviderInAllManagers(tokenFeeProvider: any TokenFeeProvider) {}
}
