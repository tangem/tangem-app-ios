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
        let provider = EmptyTokenFeeProvider(
            feeTokenItem: tokenItem,
            bsdkFee: BSDKFee(
                BSDKAmount(
                    with: tokenItem.blockchain,
                    type: tokenItem.amountType,
                    value: 0
                )
            )
        )

        return CommonTokenFeeProvidersManager(
            feeProviders: [provider],
            initialSelectedProvider: provider
        )
    }

    func updateSelectedFeeOptionInAllManagers(feeOption: FeeOption) {}

    func updateSelectedFeeTokenItemInAllManagers(feeTokenItem: TokenItem) {}
}
