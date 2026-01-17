//
//  TangemPayExpressTokenFeeProvidersManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct TangemPayExpressTokenFeeProvidersManager: ExpressTokenFeeProvidersManager {
    let tokenItem: TokenItem

    func tokenFeeProvidersManager(providerId: ExpressProvider.Id) -> TokenFeeProvidersManager {
        CommonTokenFeeProvidersManager(
            feeProviders: [.empty(feeTokenItem: tokenItem)],
            initialSelectedProvider: .empty(feeTokenItem: tokenItem)
        )
    }

    func updateSelectedFeeOptionInAllManagers(feeOption: FeeOption) {}

    func updateSelectedFeeTokenItemInAllManagers(feeTokenItem: TokenItem) {}
}
